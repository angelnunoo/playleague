-- Public wrappers. They stay security invoker; the private functions do the privileged work.

create or replace function private.get_match(p_game_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  g public.games;
  v_body jsonb;
begin
  g := private.load_game(p_game_id);
  v_body := jsonb_build_object(
    'id', g.id,
    'game_type', g.game_type,
    'status', g.status,
    'config', g.config,
    'xp_awarded', g.xp_awarded,
    'summary', g.summary,
    'players', private.players_json(p_game_id)
  );

  if g.game_type = 'quiz' then
    v_body := v_body || jsonb_build_object('quiz', private.quiz_view(p_game_id));
  elsif g.game_type = 'impostor' then
    v_body := v_body || jsonb_build_object('impostor', jsonb_build_object(
      'ready', exists (select 1 from public.impostor_secrets where game_id = p_game_id),
      'votes', coalesce((
        select jsonb_agg(voter_seat order by voter_seat)
        from public.impostor_votes where game_id = p_game_id
      ), '[]'::jsonb),
      'accused_seat', (select accused_seat from public.impostor_secrets where game_id = p_game_id),
      'accused_name', (
        select gp.display_name
        from public.impostor_secrets s
        join public.game_players gp on gp.game_id = s.game_id and gp.seat = s.accused_seat
        where s.game_id = p_game_id
      )
    ));
  elsif g.game_type = 'taboo' then
    v_body := v_body || jsonb_build_object('taboo', jsonb_build_object(
      'scores', private.taboo_scores(p_game_id),
      'open_turn', (
        select jsonb_build_object(
          'turn_index', t.turn_index,
          'player_id', t.player_id,
          'player_name', gp.display_name,
          'team_key', t.team_key,
          'started_at', t.started_at
        )
        from public.taboo_turns t
        join public.game_players gp on gp.id = t.player_id
        where t.game_id = p_game_id and t.ended_at is null
      )
    ));
  elsif g.game_type = 'quick' then
    v_body := v_body || jsonb_build_object('quick', jsonb_build_object(
      'alive', private.quick_alive(p_game_id),
      'events', coalesce((
        select jsonb_agg(jsonb_build_object(
          'player_id', e.player_id,
          'success', e.success,
          'points', e.points,
          'streak', e.streak
        ) order by e.created_at)
        from public.quick_events e where e.game_id = p_game_id
      ), '[]'::jsonb)
    ));
  end if;

  return v_body;
end;
$$;

create or replace function private.my_profile()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  p public.profiles;
  s public.user_stats;
  v_best text;
begin
  if v_user is null then
    raise exception 'Necesitas iniciar sesión';
  end if;
  select * into p from public.profiles where id = v_user;
  select * into s from public.user_stats where user_id = v_user;
  select c.name into v_best
  from public.quiz_category_stats qs
  join public.quiz_categories c on c.id = qs.category_id
  where qs.user_id = v_user and (qs.correct + qs.wrong) >= 3
  order by qs.correct::numeric / nullif(qs.correct + qs.wrong, 0) desc, qs.correct desc
  limit 1;

  return jsonb_build_object(
    'profile', jsonb_build_object(
      'id', p.id,
      'username', p.username,
      'display_name', p.display_name,
      'avatar_emoji', p.avatar_emoji,
      'title', p.title,
      'xp', p.xp,
      'level', p.level,
      'role', p.role
    ),
    'stats', jsonb_build_object(
      'games_played', s.games_played,
      'wins', s.wins,
      'losses', s.losses,
      'current_streak', s.current_streak,
      'best_streak', s.best_streak,
      'quiz_played', s.quiz_played,
      'quiz_wins', s.quiz_wins,
      'quiz_correct', s.quiz_correct,
      'quiz_wrong', s.quiz_wrong,
      'quiz_best_streak', s.quiz_best_streak,
      'quiz_expert_correct', s.quiz_expert_correct,
      'quiz_perfect', s.quiz_perfect,
      'impostor_played', s.impostor_played,
      'impostor_times', s.impostor_times,
      'impostor_wins', s.impostor_wins,
      'impostor_caught', s.impostor_caught,
      'impostor_catches', s.impostor_catches,
      'impostor_word_guesses', s.impostor_word_guesses,
      'taboo_played', s.taboo_played,
      'taboo_correct', s.taboo_correct,
      'taboo_failed', s.taboo_failed,
      'taboo_forbidden', s.taboo_forbidden,
      'taboo_wins', s.taboo_wins,
      'taboo_clean', s.taboo_clean,
      'quick_played', s.quick_played,
      'quick_correct', s.quick_correct,
      'quick_wrong', s.quick_wrong,
      'quick_best_streak', s.quick_best_streak,
      'quick_wins', s.quick_wins,
      'quick_time_total_ms', s.quick_time_total_ms,
      'quick_time_count', s.quick_time_count
    ),
    'progress', jsonb_build_object(
      'level', p.level,
      'xp', p.xp,
      'floor', private.xp_to_reach(p.level),
      'ceil', private.xp_to_reach(p.level + 1)
    ),
    'best_category', v_best,
    'admin', p.role = 'admin'
  );
end;
$$;

create or replace function private.claim_admin()
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Necesitas iniciar sesión';
  end if;
  if exists (select 1 from public.profiles where role = 'admin') then
    return false;
  end if;
  perform set_config('keda.trusted', '1', true);
  update public.profiles set role = 'admin' where id = auth.uid();
  return true;
end;
$$;

create or replace function private.admin_exists()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.profiles where role = 'admin');
$$;

create or replace function private.admin_overview()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not private.is_admin() then
    raise exception 'Solo el administrador';
  end if;
  return jsonb_build_object(
    'users', (select count(*) from public.profiles),
    'games', (select count(*) from public.games),
    'finished', (select count(*) from public.games where status = 'finished'),
    'quiz_questions', (select count(*) from public.quiz_questions where active),
    'impostor_words', (select count(*) from public.impostor_words where active),
    'taboo_cards', (select count(*) from public.taboo_cards where active),
    'quick_questions', (select count(*) from public.quick_questions where active),
    'pending', (select count(*) from public.content_submissions where status = 'pending')
  );
end;
$$;

create or replace function private.import_quiz(p_rows jsonb)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_row jsonb;
  v_category uuid;
  v_question uuid;
  v_inserted integer := 0;
  v_index integer;
  v_answers jsonb;
  v_correct integer;
  v_text text;
begin
  if not private.is_admin() then
    raise exception 'Solo el administrador';
  end if;
  if jsonb_typeof(p_rows) <> 'array' or jsonb_array_length(p_rows) > 500 then
    raise exception 'Envía entre 1 y 500 preguntas';
  end if;

  for v_row in select value from jsonb_array_elements(p_rows) loop
    select id into v_category from public.quiz_categories where slug = v_row ->> 'category_slug';
    if v_category is null then
      raise exception 'Categoría desconocida: %', coalesce(v_row ->> 'category_slug', '');
    end if;
    if private.clean_difficulty(v_row ->> 'difficulty') is null then
      raise exception 'Dificultad no válida';
    end if;
    v_answers := v_row -> 'answers';
    v_correct := (v_row ->> 'correct_index')::integer;
    if jsonb_typeof(v_answers) <> 'array' or jsonb_array_length(v_answers) <> 4 or v_correct not between 0 and 3 then
      raise exception 'Cada pregunta necesita 4 respuestas y un índice correcto';
    end if;
    if char_length(coalesce(v_row ->> 'prompt', '')) < 8 then
      raise exception 'Hay una pregunta demasiado corta';
    end if;

    insert into public.quiz_questions (category_id, difficulty, prompt)
    values (v_category, v_row ->> 'difficulty', trim(v_row ->> 'prompt'))
    on conflict (category_id, prompt) do nothing
    returning id into v_question;

    if v_question is not null then
      v_index := 0;
      for v_text in select value from jsonb_array_elements_text(v_answers) loop
        insert into public.quiz_answers (question_id, text, is_correct, sort_order)
        values (v_question, left(trim(v_text), 160), v_index = v_correct, v_index);
        v_index := v_index + 1;
      end loop;
      v_inserted := v_inserted + 1;
    end if;
    v_question := null;
  end loop;
  return v_inserted;
end;
$$;

create or replace function private.import_impostor(p_rows jsonb)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_row jsonb;
  v_category uuid;
  v_inserted integer := 0;
begin
  if not private.is_admin() then
    raise exception 'Solo el administrador';
  end if;
  if jsonb_typeof(p_rows) <> 'array' or jsonb_array_length(p_rows) > 500 then
    raise exception 'Envía entre 1 y 500 palabras';
  end if;
  for v_row in select value from jsonb_array_elements(p_rows) loop
    select id into v_category from public.impostor_categories where slug = v_row ->> 'category_slug';
    if v_category is null then
      raise exception 'Categoría desconocida: %', coalesce(v_row ->> 'category_slug', '');
    end if;
    insert into public.impostor_words (category_id, word, emoji, difficulty)
    values (
      v_category,
      trim(v_row ->> 'word'),
      coalesce(nullif(v_row ->> 'emoji', ''), '🕵️'),
      coalesce(private.clean_difficulty(v_row ->> 'difficulty'), 'normal')
    )
    on conflict (category_id, word) do nothing;
    if found then
      v_inserted := v_inserted + 1;
    end if;
  end loop;
  return v_inserted;
end;
$$;

create or replace function private.import_taboo(p_rows jsonb)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_row jsonb;
  v_category uuid;
  v_inserted integer := 0;
  v_forbidden text[];
begin
  if not private.is_admin() then
    raise exception 'Solo el administrador';
  end if;
  if jsonb_typeof(p_rows) <> 'array' or jsonb_array_length(p_rows) > 500 then
    raise exception 'Envía entre 1 y 500 tarjetas';
  end if;
  for v_row in select value from jsonb_array_elements(p_rows) loop
    select id into v_category from public.taboo_categories where slug = v_row ->> 'category_slug';
    if v_category is null then
      raise exception 'Categoría desconocida: %', coalesce(v_row ->> 'category_slug', '');
    end if;
    select coalesce(array_agg(value), '{}'::text[]) into v_forbidden
    from jsonb_array_elements_text(v_row -> 'forbidden');
    if cardinality(v_forbidden) < 3 then
      raise exception 'Cada tarjeta necesita al menos 3 palabras prohibidas';
    end if;
    insert into public.taboo_cards (category_id, word, emoji, forbidden, difficulty)
    values (
      v_category,
      trim(v_row ->> 'word'),
      coalesce(nullif(v_row ->> 'emoji', ''), '🗣️'),
      v_forbidden,
      coalesce(private.clean_difficulty(v_row ->> 'difficulty'), 'normal')
    )
    on conflict (category_id, word) do nothing;
    if found then
      v_inserted := v_inserted + 1;
    end if;
  end loop;
  return v_inserted;
end;
$$;

create or replace function private.import_quick(p_rows jsonb)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_row jsonb;
  v_category uuid;
  v_inserted integer := 0;
begin
  if not private.is_admin() then
    raise exception 'Solo el administrador';
  end if;
  if jsonb_typeof(p_rows) <> 'array' or jsonb_array_length(p_rows) > 500 then
    raise exception 'Envía entre 1 y 500 retos';
  end if;
  for v_row in select value from jsonb_array_elements(p_rows) loop
    select id into v_category from public.quick_categories where slug = v_row ->> 'category_slug';
    if v_category is null then
      raise exception 'Categoría desconocida: %', coalesce(v_row ->> 'category_slug', '');
    end if;
    insert into public.quick_questions (category_id, prompt, difficulty)
    values (
      v_category,
      trim(v_row ->> 'prompt'),
      coalesce(private.clean_difficulty(v_row ->> 'difficulty'), 'normal')
    )
    on conflict (category_id, prompt) do nothing;
    if found then
      v_inserted := v_inserted + 1;
    end if;
  end loop;
  return v_inserted;
end;
$$;

create or replace function private.review_submission(p_id uuid, p_status text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_row public.content_submissions;
  v_count integer := 0;
begin
  if not private.is_admin() then
    raise exception 'Solo el administrador';
  end if;
  if p_status not in ('approved', 'rejected') then
    raise exception 'Estado no válido';
  end if;
  select * into v_row from public.content_submissions where id = p_id;
  if not found then
    raise exception 'Envío no encontrado';
  end if;
  if p_status = 'approved' and v_row.status = 'pending' then
    if v_row.kind = 'quiz' then
      v_count := private.import_quiz(jsonb_build_array(v_row.payload));
    elsif v_row.kind = 'impostor' then
      v_count := private.import_impostor(jsonb_build_array(v_row.payload));
    elsif v_row.kind = 'taboo' then
      v_count := private.import_taboo(jsonb_build_array(v_row.payload));
    elsif v_row.kind = 'quick' then
      v_count := private.import_quick(jsonb_build_array(v_row.payload));
    end if;
  end if;
  update public.content_submissions set status = p_status where id = p_id;
  return jsonb_build_object('ok', true, 'imported', v_count);
end;
$$;

-- Wrappers
create or replace function public.create_match(p_game_type text, p_config jsonb, p_players jsonb)
returns uuid language sql security invoker set search_path = '' as $$ select private.create_match(p_game_type, p_config, p_players); $$;

create or replace function public.draw_quiz(p_game_id uuid)
returns jsonb language sql security invoker set search_path = '' as $$ select private.draw_quiz(p_game_id); $$;

create or replace function public.focus_quiz(p_game_id uuid, p_question_id uuid)
returns jsonb language sql security invoker set search_path = '' as $$ select private.focus_quiz(p_game_id, p_question_id); $$;

create or replace function public.answer_quiz(p_game_id uuid, p_question_id uuid, p_answer_id uuid)
returns jsonb language sql security invoker set search_path = '' as $$ select private.answer_quiz(p_game_id, p_question_id, p_answer_id); $$;

create or replace function public.finish_match(p_game_id uuid)
returns jsonb language sql security invoker set search_path = '' as $$ select private.finish_match(p_game_id); $$;

create or replace function public.prepare_impostor(p_game_id uuid)
returns jsonb language sql security invoker set search_path = '' as $$ select private.prepare_impostor(p_game_id); $$;

create or replace function public.reveal_role(p_game_id uuid, p_seat integer)
returns jsonb language sql security invoker set search_path = '' as $$ select private.reveal_role(p_game_id, p_seat); $$;

create or replace function public.start_voting(p_game_id uuid)
returns jsonb language sql security invoker set search_path = '' as $$ select private.start_voting(p_game_id); $$;

create or replace function public.cast_vote(p_game_id uuid, p_voter_seat integer, p_target_seat integer)
returns jsonb language sql security invoker set search_path = '' as $$ select private.cast_vote(p_game_id, p_voter_seat, p_target_seat); $$;

create or replace function public.resolve_impostor(p_game_id uuid)
returns jsonb language sql security invoker set search_path = '' as $$ select private.resolve_impostor(p_game_id); $$;

create or replace function public.impostor_guess(p_game_id uuid, p_guess text)
returns jsonb language sql security invoker set search_path = '' as $$ select private.impostor_guess(p_game_id, p_guess); $$;

create or replace function public.start_taboo_turn(p_game_id uuid)
returns jsonb language sql security invoker set search_path = '' as $$ select private.start_taboo_turn(p_game_id); $$;

create or replace function public.next_taboo_card(p_game_id uuid)
returns jsonb language sql security invoker set search_path = '' as $$ select private.next_taboo_card(p_game_id); $$;

create or replace function public.taboo_mark(p_game_id uuid, p_result text)
returns jsonb language sql security invoker set search_path = '' as $$ select private.taboo_mark(p_game_id, p_result); $$;

create or replace function public.end_taboo_turn(p_game_id uuid)
returns jsonb language sql security invoker set search_path = '' as $$ select private.end_taboo_turn(p_game_id); $$;

create or replace function public.next_quick(p_game_id uuid)
returns jsonb language sql security invoker set search_path = '' as $$ select private.next_quick(p_game_id); $$;

create or replace function public.quick_mark(p_game_id uuid, p_success boolean)
returns jsonb language sql security invoker set search_path = '' as $$ select private.quick_mark(p_game_id, p_success); $$;

create or replace function public.get_match(p_game_id uuid)
returns jsonb language sql security invoker set search_path = '' as $$ select private.get_match(p_game_id); $$;

create or replace function public.my_profile()
returns jsonb language sql security invoker set search_path = '' as $$ select private.my_profile(); $$;

create or replace function public.claim_admin()
returns boolean language sql security invoker set search_path = '' as $$ select private.claim_admin(); $$;

create or replace function public.admin_exists()
returns boolean language sql security invoker set search_path = '' as $$ select private.admin_exists(); $$;

create or replace function public.is_admin()
returns boolean language sql security invoker set search_path = '' as $$ select private.is_admin(); $$;

create or replace function public.admin_overview()
returns jsonb language sql security invoker set search_path = '' as $$ select private.admin_overview(); $$;

create or replace function public.import_quiz(p_rows jsonb)
returns integer language sql security invoker set search_path = '' as $$ select private.import_quiz(p_rows); $$;

create or replace function public.import_impostor(p_rows jsonb)
returns integer language sql security invoker set search_path = '' as $$ select private.import_impostor(p_rows); $$;

create or replace function public.import_taboo(p_rows jsonb)
returns integer language sql security invoker set search_path = '' as $$ select private.import_taboo(p_rows); $$;

create or replace function public.import_quick(p_rows jsonb)
returns integer language sql security invoker set search_path = '' as $$ select private.import_quick(p_rows); $$;

create or replace function public.review_submission(p_id uuid, p_status text)
returns jsonb language sql security invoker set search_path = '' as $$ select private.review_submission(p_id, p_status); $$;

do $$
declare
  r record;
begin
  for r in
    select format('%I.%I(%s)', n.nspname, p.proname, pg_get_function_identity_arguments(p.oid)) as sig
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in (
        'create_match', 'draw_quiz', 'focus_quiz', 'answer_quiz', 'finish_match',
        'prepare_impostor', 'reveal_role', 'start_voting', 'cast_vote', 'resolve_impostor',
        'impostor_guess', 'start_taboo_turn', 'next_taboo_card', 'taboo_mark', 'end_taboo_turn',
        'next_quick', 'quick_mark', 'get_match', 'my_profile', 'claim_admin', 'admin_exists',
        'is_admin', 'admin_overview', 'import_quiz', 'import_impostor', 'import_taboo',
        'import_quick', 'review_submission'
      )
  loop
    execute format('revoke all on function %s from public, anon, authenticated', r.sig);
    execute format('grant execute on function %s to authenticated', r.sig);
  end loop;

  for r in
    select format('%I.%I(%s)', n.nspname, p.proname, pg_get_function_identity_arguments(p.oid)) as sig
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'private'
      and p.proname in (
        'create_match', 'draw_quiz', 'focus_quiz', 'answer_quiz', 'finish_match',
        'prepare_impostor', 'reveal_role', 'start_voting', 'cast_vote', 'resolve_impostor',
        'impostor_guess', 'start_taboo_turn', 'next_taboo_card', 'taboo_mark', 'end_taboo_turn',
        'next_quick', 'quick_mark', 'get_match', 'my_profile', 'claim_admin', 'admin_exists',
        'is_admin', 'admin_overview', 'import_quiz', 'import_impostor', 'import_taboo',
        'import_quick', 'review_submission'
      )
  loop
    execute format('revoke all on function %s from public, anon', r.sig);
    execute format('grant execute on function %s to authenticated', r.sig);
  end loop;
end $$;

notify pgrst, 'reload schema';
