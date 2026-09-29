-- Public entry points for online rooms. Wrappers stay security invoker.

drop policy if exists profiles_trusted_write on public.profiles;
create policy profiles_trusted_write on public.profiles
  for update
  using (current_setting('keda.trusted', true) = '1')
  with check (current_setting('keda.trusted', true) = '1');

revoke select on public.online_answers from anon, authenticated;

create or replace function private.online_view(p_room uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  r public.online_rooms;
  c public.online_cards;
  v_you public.online_players;
  v_question jsonb;
  v_total integer;
begin
  select * into r from public.online_rooms where id = p_room;
  select * into v_you from public.online_players where room_id = p_room and user_id = auth.uid();
  select * into c from public.online_cards where room_id = p_room and position = r.question_index;
  select count(*) into v_total from public.online_cards where room_id = p_room;

  if r.status in ('playing', 'reveal') and c.room_id is not null then
    v_question := jsonb_build_object(
      'position', c.position,
      'round_no', c.round_no,
      'prompt', c.prompt,
      'emoji', c.emoji,
      'category', c.category,
      'answers', c.answers
    );
  end if;

  return jsonb_build_object(
    'room', jsonb_build_object(
      'id', r.id,
      'code', r.code,
      'mode', r.mode,
      'status', r.status,
      'host_id', r.host_id,
      'question_index', r.question_index,
      'round_index', r.round_index,
      'seconds', r.seconds,
      'phase_ends', r.phase_ends,
      'opened_at', r.opened_at,
      'rematch_id', r.rematch_id
    ),
    'server_now', pg_catalog.now(),
    'total', v_total,
    'you', jsonb_build_object(
      'ready', v_you.ready,
      'score', v_you.score,
      'xp', v_you.xp_awarded,
      'answered', exists (
        select 1 from public.online_answers a
        where a.room_id = p_room and a.user_id = auth.uid() and a.position = r.question_index
      )
    ),
    'players', coalesce((
      select jsonb_agg(jsonb_build_object(
        'user_id', p.user_id,
        'name', p.display_name,
        'avatar', p.avatar_emoji,
        'ready', p.ready,
        'connected', p.connected,
        'score', p.score,
        'xp', p.xp_awarded,
        'answered', exists (
          select 1 from public.online_answers a
          where a.room_id = p.room_id and a.user_id = p.user_id and a.position = r.question_index
        )
      ) order by p.score desc, p.joined_at)
      from public.online_players p
      where p.room_id = p_room
    ), '[]'::jsonb),
    'question', v_question,
    'reveal', case when r.status = 'reveal' then r.public_state else null end,
    'round', case when r.status = 'round_result' then r.public_state else null end,
    'summary', case when r.status = 'finished' then r.summary else null end,
    'answers', case
      when r.status in ('reveal', 'round_result', 'finished') then coalesce((
        select jsonb_agg(jsonb_build_object(
          'user_id', a.user_id,
          'correct', a.correct,
          'points', a.points,
          'elapsed_ms', a.elapsed_ms,
          'answer_id', a.answer_id
        ))
        from public.online_answers a
        where a.room_id = p_room and a.position = r.question_index
      ), '[]'::jsonb)
      else '[]'::jsonb
    end
  );
end;
$$;

create or replace function private.create_online_room(p_mode text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
  v_code text;
  v_profile public.profiles;
  v_try integer := 0;
begin
  if auth.uid() is null then
    raise exception 'Necesitas iniciar sesión';
  end if;
  if p_mode not in ('battle', 'quick', 'duel') then
    raise exception 'Modo no válido';
  end if;
  select * into v_profile from public.profiles where id = auth.uid();
  loop
    v_try := v_try + 1;
    v_code := private.room_code();
    exit when not exists (select 1 from public.online_rooms where code = v_code) or v_try > 8;
  end loop;
  insert into public.online_rooms (code, host_id, mode, seconds)
  values (v_code, auth.uid(), p_mode, case when p_mode = 'quick' then 8 else 12 end)
  returning id into v_id;
  insert into public.online_players (room_id, user_id, display_name, avatar_emoji)
  values (v_id, auth.uid(), v_profile.display_name, v_profile.avatar_emoji);
  return v_id;
end;
$$;

create or replace function private.join_online_room(p_code text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.online_rooms;
  v_profile public.profiles;
  v_count integer;
begin
  if auth.uid() is null then
    raise exception 'Necesitas iniciar sesión';
  end if;
  select * into r from public.online_rooms where code = upper(trim(p_code));
  if not found then
    raise exception 'No hay ninguna sala con ese código';
  end if;
  if exists (select 1 from public.online_players where room_id = r.id and user_id = auth.uid()) then
    return r.id;
  end if;
  if r.status <> 'lobby' then
    raise exception 'La partida ya ha empezado';
  end if;
  select count(*) into v_count from public.online_players where room_id = r.id;
  if r.mode = 'duel' and v_count >= 2 then
    raise exception 'El duelo ya tiene dos jugadores';
  end if;
  if v_count >= 20 then
    raise exception 'La sala está llena';
  end if;
  select * into v_profile from public.profiles where id = auth.uid();
  insert into public.online_players (room_id, user_id, display_name, avatar_emoji)
  values (r.id, auth.uid(), v_profile.display_name, v_profile.avatar_emoji);
  return r.id;
end;
$$;

create or replace function private.set_online_ready(p_room uuid, p_ready boolean)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.online_rooms;
begin
  r := private.member_room(p_room);
  if r.status <> 'lobby' then
    raise exception 'La sala ya no admite cambios';
  end if;
  update public.online_players
  set ready = p_ready
  where room_id = p_room and user_id = auth.uid();
  perform private.pump_room(p_room);
  return private.online_view(p_room);
end;
$$;

create or replace function private.online_sync(p_room uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.member_room(p_room);
  perform private.pump_room(p_room);
  return private.online_view(p_room);
end;
$$;

create or replace function private.online_answer(p_room uuid, p_answer uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.online_rooms;
  c public.online_cards;
  v_elapsed integer;
  v_limit integer;
  v_correct boolean := false;
  v_points integer := 0;
  v_known boolean;
begin
  perform private.member_room(p_room);
  select * into r from public.online_rooms where id = p_room for update;
  if r.status <> 'playing' then
    return private.online_view(p_room);
  end if;
  if exists (
    select 1 from public.online_answers
    where room_id = p_room and user_id = auth.uid() and position = r.question_index
  ) then
    return private.online_view(p_room);
  end if;

  select * into c from public.online_cards where room_id = p_room and position = r.question_index;
  v_elapsed := greatest(0, floor(extract(epoch from (pg_catalog.now() - r.opened_at)) * 1000)::integer);
  v_limit := r.seconds * 1000;

  if v_elapsed <= v_limit + 1500 then
    if r.mode = 'quick' then
      v_correct := true;
    else
      select exists (
        select 1 from jsonb_array_elements(c.answers) item
        where (item ->> 'id')::uuid = p_answer
      ) into v_known;
      if not coalesce(v_known, false) then
        raise exception 'Esa respuesta no pertenece a la pregunta';
      end if;
      v_correct := p_answer = c.correct_id;
    end if;
    if v_correct then
      v_points := greatest(100, round(1000 * greatest(0, (v_limit - v_elapsed)::numeric / v_limit))::integer);
    end if;
  end if;

  insert into public.online_answers (room_id, user_id, position, answer_id, correct, points, elapsed_ms)
  values (p_room, auth.uid(), r.question_index, p_answer, v_correct, v_points, v_elapsed);
  perform private.refresh_scores(p_room);
  perform private.pump_room(p_room);
  return private.online_view(p_room);
end;
$$;

create or replace function private.online_rematch(p_room uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.online_rooms;
  v_id uuid;
  v_code text;
  v_try integer := 0;
  v_player record;
begin
  r := private.member_room(p_room);
  if r.status <> 'finished' then
    raise exception 'La partida todavía no ha terminado';
  end if;
  if r.rematch_id is not null then
    return r.rematch_id;
  end if;
  loop
    v_try := v_try + 1;
    v_code := private.room_code();
    exit when not exists (select 1 from public.online_rooms where code = v_code) or v_try > 8;
  end loop;
  insert into public.online_rooms (code, host_id, mode, seconds)
  values (v_code, auth.uid(), r.mode, r.seconds)
  returning id into v_id;
  for v_player in
    select user_id, display_name, avatar_emoji
    from public.online_players
    where room_id = p_room and connected
  loop
    insert into public.online_players (room_id, user_id, display_name, avatar_emoji, ready)
    values (v_id, v_player.user_id, v_player.display_name, v_player.avatar_emoji, false);
  end loop;
  update public.online_rooms set rematch_id = v_id where id = p_room;
  return v_id;
end;
$$;

create or replace function private.leave_online_room(p_room uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.online_rooms;
  v_left integer;
begin
  r := private.member_room(p_room);
  if r.status = 'lobby' then
    delete from public.online_players where room_id = p_room and user_id = auth.uid();
    select count(*) into v_left from public.online_players where room_id = p_room;
    if v_left = 0 then
      delete from public.online_rooms where id = p_room;
      return;
    end if;
    if r.host_id = auth.uid() then
      update public.online_rooms
      set host_id = (
        select user_id from public.online_players
        where room_id = p_room
        order by joined_at
        limit 1
      )
      where id = p_room;
    end if;
    return;
  end if;
  update public.online_players set connected = false, ready = false
  where room_id = p_room and user_id = auth.uid();
  perform private.pump_room(p_room);
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
      'role', p.role,
      'rating', p.rating,
      'banner', p.banner,
      'frame', p.frame
    ),
    'league', private.league_for_rating(p.rating),
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

create or replace function private.my_recent()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Necesitas iniciar sesión';
  end if;
  return coalesce((
    select jsonb_agg(row_to_json(x))
    from (
      select * from (
        select 'local'::text as kind,
               g.game_type as mode,
               g.finished_at,
               coalesce((g.summary ->> 'host_won')::boolean, false) as won,
               case when coalesce((g.summary ->> 'host_won')::boolean, false) then 'win' else 'loss' end as result,
               g.xp_awarded as xp
        from public.games g
        where g.host_id = auth.uid() and g.status = 'finished'
        union all
        select 'online'::text,
               r.mode,
               r.phase_ends,
               case
                 when r.summary is null then false
                 when coalesce((r.summary ->> 'tie')::boolean, false) then false
                 else (r.summary -> 'ranking' -> 0 ->> 'user_id') = auth.uid()::text
               end,
               case
                 when coalesce((r.summary ->> 'tie')::boolean, false) then 'tie'
                 when (r.summary -> 'ranking' -> 0 ->> 'user_id') = auth.uid()::text then 'win'
                 else 'loss'
               end,
               p.xp_awarded
        from public.online_rooms r
        join public.online_players p on p.room_id = r.id and p.user_id = auth.uid()
        where r.status = 'finished'
      ) u
      order by finished_at desc nulls last
      limit 8
    ) x
  ), '[]'::jsonb);
end;
$$;

create or replace function public.create_online_room(p_mode text)
returns uuid language sql security invoker set search_path = '' as $$ select private.create_online_room(p_mode); $$;

create or replace function public.join_online_room(p_code text)
returns uuid language sql security invoker set search_path = '' as $$ select private.join_online_room(p_code); $$;

create or replace function public.set_online_ready(p_room uuid, p_ready boolean)
returns jsonb language sql security invoker set search_path = '' as $$ select private.set_online_ready(p_room, p_ready); $$;

create or replace function public.online_sync(p_room uuid)
returns jsonb language sql security invoker set search_path = '' as $$ select private.online_sync(p_room); $$;

create or replace function public.online_answer(p_room uuid, p_answer uuid)
returns jsonb language sql security invoker set search_path = '' as $$ select private.online_answer(p_room, p_answer); $$;

create or replace function public.online_rematch(p_room uuid)
returns uuid language sql security invoker set search_path = '' as $$ select private.online_rematch(p_room); $$;

create or replace function public.leave_online_room(p_room uuid)
returns void language sql security invoker set search_path = '' as $$ select private.leave_online_room(p_room); $$;

create or replace function public.my_recent()
returns jsonb language sql security invoker set search_path = '' as $$ select private.my_recent(); $$;

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
        'create_online_room', 'join_online_room', 'set_online_ready', 'online_sync',
        'online_answer', 'online_rematch', 'leave_online_room', 'my_recent', 'my_profile'
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
        'create_online_room', 'join_online_room', 'set_online_ready', 'online_sync',
        'online_answer', 'online_rematch', 'leave_online_room', 'my_recent', 'my_profile',
        'online_view', 'pump_room', 'deal_online', 'grant_online', 'finish_online'
      )
  loop
    execute format('revoke all on function %s from public, anon', r.sig);
    execute format('grant execute on function %s to authenticated', r.sig);
  end loop;
end $$;

notify pgrst, 'reload schema';
