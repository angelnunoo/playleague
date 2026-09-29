-- Match creation and the four games.

create or replace function private.create_match(
  p_game_type text,
  p_config jsonb,
  p_players jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_game_id uuid := gen_random_uuid();
  v_player jsonb;
  v_index integer := 0;
  v_host_count integer := 0;
  v_name text;
  v_count integer;
  v_team_count integer;
  v_gap integer;
  v_is_host boolean;
  v_team text;
begin
  if v_uid is null then
    raise exception 'Necesitas iniciar sesión';
  end if;
  if p_game_type not in ('quiz', 'impostor', 'taboo', 'quick') then
    raise exception 'Juego no válido';
  end if;
  if jsonb_typeof(p_players) <> 'array' then
    raise exception 'Jugadores no válidos';
  end if;

  v_count := jsonb_array_length(p_players);
  if p_game_type = 'impostor' and (v_count < 3 or v_count > 12) then
    raise exception 'Impostor necesita entre 3 y 12 jugadores';
  elsif p_game_type in ('quiz', 'taboo') and (v_count < 2 or v_count > 16) then
    raise exception 'Hacen falta entre 2 y 16 jugadores';
  elsif v_count < 1 or v_count > 16 then
    raise exception 'Número de jugadores no válido';
  end if;

  if p_game_type in ('quiz', 'taboo') then
    if jsonb_typeof(p_config -> 'teams') <> 'array' then
      raise exception 'Faltan los equipos';
    end if;
    v_team_count := jsonb_array_length(p_config -> 'teams');
    if v_team_count < 2 or v_team_count > 4 or v_team_count > v_count then
      raise exception 'El número de equipos no es válido';
    end if;
  end if;

  insert into public.games (id, host_id, game_type, status, config)
  values (v_game_id, v_uid, p_game_type, 'setup', coalesce(p_config, '{}'::jsonb));

  for v_player in select value from jsonb_array_elements(p_players) loop
    v_name := trim(coalesce(v_player ->> 'name', ''));
    if char_length(v_name) < 1 or char_length(v_name) > 24 then
      raise exception 'Cada nombre debe tener entre 1 y 24 caracteres';
    end if;
    v_is_host := coalesce((v_player ->> 'is_host')::boolean, false);
    if v_is_host then
      v_host_count := v_host_count + 1;
    end if;
    v_team := nullif(v_player ->> 'team_key', '');
    if p_game_type in ('quiz', 'taboo') then
      if v_team is null or not exists (
        select 1 from jsonb_array_elements(p_config -> 'teams') t
        where t ->> 'key' = v_team
      ) then
        raise exception 'Hay un jugador sin equipo';
      end if;
    else
      v_team := null;
    end if;

    insert into public.game_players (game_id, user_id, display_name, is_host, seat, team_key)
    values (v_game_id, case when v_is_host then v_uid else null end, v_name, v_is_host, v_index, v_team);
    v_index := v_index + 1;
  end loop;

  if v_host_count <> 1 then
    raise exception 'Debe haber exactamente un anfitrión';
  end if;

  if exists (
    select 1 from public.game_players
    where game_id = v_game_id
    group by lower(display_name)
    having count(*) > 1
  ) then
    raise exception 'Los nombres no pueden repetirse';
  end if;

  if p_game_type in ('quiz', 'taboo') then
    if (select count(distinct team_key) from public.game_players where game_id = v_game_id) <> v_team_count then
      raise exception 'Todos los equipos necesitan jugadores';
    end if;
    select max(cnt) - min(cnt) into v_gap
    from (
      select count(*) as cnt
      from public.game_players
      where game_id = v_game_id
      group by team_key
    ) sizes;
    if v_gap > 1 then
      raise exception 'Los equipos tienen que quedar equilibrados';
    end if;
  end if;

  return v_game_id;
end;
$$;

create or replace function private.quiz_view(p_game_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  g public.games;
  v_questions jsonb;
  v_responses jsonb;
  v_scores jsonb;
begin
  select * into g from public.games where id = p_game_id;
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', mc.source_id,
    'position', mc.position,
    'prompt', mc.payload ->> 'prompt',
    'difficulty', mc.payload ->> 'difficulty',
    'category', mc.payload ->> 'category',
    'emoji', mc.payload ->> 'emoji',
    'answers', mc.payload -> 'answers',
    'opened', mc.opened_at is not null
  ) order by mc.position), '[]'::jsonb)
  into v_questions
  from public.match_cards mc
  where mc.game_id = p_game_id;

  select coalesce(jsonb_agg(jsonb_build_object(
    'question_id', r.question_id,
    'player_id', r.player_id,
    'correct', r.correct,
    'points', r.points,
    'correct_text', r.correct_text,
    'answer_id', r.answer_id
  )), '[]'::jsonb)
  into v_responses
  from public.quiz_responses r
  where r.game_id = p_game_id;

  select coalesce(jsonb_agg(jsonb_build_object(
    'team_key', t.key,
    'name', t.name,
    'color', t.color,
    'score', coalesce(sc.score, 0)
  ) order by t.ord), '[]'::jsonb)
  into v_scores
  from (
    select value ->> 'key' as key,
           value ->> 'name' as name,
           value ->> 'color' as color,
           ordinality - 1 as ord
    from jsonb_array_elements(g.config -> 'teams') with ordinality
  ) t
  left join (
    select gp.team_key, sum(r.points)::integer as score
    from public.quiz_responses r
    join public.game_players gp on gp.id = r.player_id
    where r.game_id = p_game_id
    group by gp.team_key
  ) sc on sc.team_key = t.key;

  return jsonb_build_object(
    'questions', v_questions,
    'responses', v_responses,
    'scores', v_scores,
    'seconds', coalesce((g.config ->> 'seconds')::integer, 15)
  );
end;
$$;

create or replace function private.draw_quiz(p_game_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  g public.games;
  v_count integer;
  v_seconds integer;
  v_difficulty text;
  v_cats uuid[];
  v_existing integer;
begin
  g := private.load_game(p_game_id);
  if g.game_type <> 'quiz' then
    raise exception 'Esta partida no es un quiz';
  end if;
  if g.status = 'finished' then
    raise exception 'Esta partida ya ha terminado';
  end if;

  select count(*) into v_existing from public.match_cards where game_id = p_game_id;
  if v_existing = 0 then
    v_count := coalesce((g.config ->> 'question_count')::integer, 10);
    if v_count not in (5, 10, 15, 20, 30) then
      v_count := 10;
    end if;
    v_seconds := coalesce((g.config ->> 'seconds')::integer, 15);
    if v_seconds not in (10, 15, 20, 30) then
      v_seconds := 15;
    end if;
    v_difficulty := private.clean_difficulty(g.config ->> 'difficulty');
    v_cats := private.uuid_list(g.config -> 'category_ids');

    insert into public.match_cards (game_id, position, source_id, payload)
    select p_game_id, row_number() over (order by q.shuffle) - 1, q.id,
      jsonb_build_object(
        'prompt', q.prompt,
        'difficulty', q.difficulty,
        'category', q.category,
        'emoji', q.emoji,
        'answers', q.answers
      )
    from (
      select qq.id, qq.prompt, qq.difficulty, c.name as category, c.emoji, random() as shuffle,
        (
          select jsonb_agg(jsonb_build_object('id', a.id, 'text', a.text) order by a.ord)
          from (
            select id, text, random() as ord
            from public.quiz_answers
            where question_id = qq.id
          ) a
        ) as answers
      from public.quiz_questions qq
      join public.quiz_categories c on c.id = qq.category_id
      where qq.active
        and c.active
        and (v_difficulty is null or qq.difficulty = v_difficulty)
        and (cardinality(v_cats) = 0 or qq.category_id = any (v_cats))
      order by random()
      limit v_count
    ) q
    where jsonb_array_length(q.answers) >= 2;

    if (select count(*) from public.match_cards where game_id = p_game_id) = 0 then
      raise exception 'No hay preguntas suficientes con esos filtros';
    end if;

    update public.games
    set status = 'playing',
        config = config || jsonb_build_object('seconds', v_seconds, 'question_count', v_count)
    where id = p_game_id;
  elsif g.status = 'setup' then
    update public.games set status = 'playing' where id = p_game_id;
  end if;

  return private.quiz_view(p_game_id);
end;
$$;

create or replace function private.focus_quiz(p_game_id uuid, p_question_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  g public.games;
  v_position integer;
  v_opened timestamptz;
  v_card uuid;
  v_next integer;
begin
  g := private.load_game(p_game_id);
  if g.status <> 'playing' then
    raise exception 'La partida no está en juego';
  end if;

  select id, position, opened_at into v_card, v_position, v_opened
  from public.match_cards
  where game_id = p_game_id and source_id = p_question_id
  for update;

  if v_card is null then
    raise exception 'Esa pregunta no está en la partida';
  end if;

  select min(mc.position) into v_next
  from public.match_cards mc
  where mc.game_id = p_game_id
    and not exists (
      select 1 from public.quiz_responses r
      where r.game_id = p_game_id and r.question_id = mc.source_id
    );

  if v_position <> v_next then
    raise exception 'Esa pregunta no toca todavía';
  end if;

  if v_opened is null then
    update public.match_cards set opened_at = now() where id = v_card;
  end if;
  return jsonb_build_object('ok', true, 'player_id', private.quiz_answerer(p_game_id, v_position));
end;
$$;

create or replace function private.answer_quiz(
  p_game_id uuid,
  p_question_id uuid,
  p_answer_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  g public.games;
  v_card uuid;
  v_position integer;
  v_opened timestamptz;
  v_next integer;
  v_player uuid;
  v_seconds integer;
  v_elapsed integer;
  v_difficulty text;
  v_correct boolean := false;
  v_correct_text text;
  v_correct_id uuid;
  v_points integer := 0;
  v_belongs boolean;
begin
  g := private.load_game(p_game_id);
  if g.status <> 'playing' then
    raise exception 'La partida no está en juego';
  end if;

  select id, position, opened_at into v_card, v_position, v_opened
  from public.match_cards
  where game_id = p_game_id and source_id = p_question_id
  for update;

  if v_card is null then
    raise exception 'Esa pregunta no está en la partida';
  end if;

  select min(mc.position) into v_next
  from public.match_cards mc
  where mc.game_id = p_game_id
    and not exists (
      select 1 from public.quiz_responses r
      where r.game_id = p_game_id and r.question_id = mc.source_id
    );

  if v_position <> v_next then
    raise exception 'Esa pregunta no toca todavía';
  end if;
  if v_opened is null then
    raise exception 'La pregunta todavía no se ha mostrado';
  end if;

  v_seconds := coalesce((g.config ->> 'seconds')::integer, 15);
  v_elapsed := greatest(0, floor(extract(epoch from (now() - v_opened)) * 1000)::integer);
  v_player := private.quiz_answerer(p_game_id, v_position);

  select qq.difficulty, a.id, a.text
  into v_difficulty, v_correct_id, v_correct_text
  from public.quiz_questions qq
  join public.quiz_answers a on a.question_id = qq.id and a.is_correct
  where qq.id = p_question_id
  limit 1;

  if p_answer_id is not null and v_elapsed <= (v_seconds * 1000 + 2000) then
    select exists (
      select 1 from public.quiz_answers
      where id = p_answer_id and question_id = p_question_id
    ) into v_belongs;
    if not v_belongs then
      raise exception 'Respuesta no válida';
    end if;
    v_correct := p_answer_id = v_correct_id;
  end if;

  if v_correct then
    v_points := case v_difficulty
      when 'easy' then 1
      when 'normal' then 2
      when 'hard' then 3
      when 'expert' then 5
      else 1
    end;
    if v_elapsed >= 700 and v_elapsed < (v_seconds * 300) then
      v_points := v_points + 1;
    end if;
  end if;

  insert into public.quiz_responses (
    game_id, question_id, player_id, answer_id, correct, points, elapsed_ms, correct_text
  ) values (
    p_game_id, p_question_id, v_player, p_answer_id, v_correct, v_points, v_elapsed, v_correct_text
  );

  update public.match_cards set consumed = true where id = v_card;

  return jsonb_build_object(
    'correct', v_correct,
    'points', v_points,
    'correct_answer_id', v_correct_id,
    'correct_text', v_correct_text,
    'player_id', v_player,
    'elapsed_ms', v_elapsed,
    'quiz', private.quiz_view(p_game_id)
  );
end;
$$;
