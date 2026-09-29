-- Tabú, Responde rápido, profile, admin and public wrappers.

create or replace function private.taboo_scores(p_game_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'team_key', t.key,
    'name', t.name,
    'color', t.color,
    'score', coalesce(sc.score, 0),
    'correct', coalesce(sc.correct, 0),
    'forbidden', coalesce(sc.forbidden, 0),
    'passed', coalesce(sc.passed, 0)
  ) order by coalesce(sc.score, 0) desc), '[]'::jsonb)
  from (
    select value ->> 'key' as key, value ->> 'name' as name, value ->> 'color' as color
    from jsonb_array_elements((select config -> 'teams' from public.games where id = p_game_id))
  ) t
  left join (
    select team_key,
           sum(points)::integer as score,
           count(*) filter (where result = 'correct')::integer as correct,
           count(*) filter (where result = 'forbidden')::integer as forbidden,
           count(*) filter (where result = 'pass')::integer as passed
    from public.taboo_events
    where game_id = p_game_id
    group by team_key
  ) sc on sc.team_key = t.key;
$$;

create or replace function private.start_taboo_turn(p_game_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  g public.games;
  v_rounds integer;
  v_seconds integer;
  v_team_count integer;
  v_total integer;
  v_next integer;
  v_team_key text;
  v_team_name text;
  v_members integer;
  v_nth integer;
  v_player uuid;
  v_name text;
begin
  g := private.load_game(p_game_id);
  if g.game_type <> 'taboo' then
    raise exception 'Esta partida no es Tabú';
  end if;
  if g.status = 'finished' then
    raise exception 'Esta partida ya ha terminado';
  end if;
  if exists (select 1 from public.taboo_turns where game_id = p_game_id and ended_at is null) then
    raise exception 'Termina el turno actual antes de pasar al siguiente';
  end if;

  v_rounds := coalesce((g.config ->> 'rounds')::integer, 3);
  if v_rounds not between 1 and 5 then v_rounds := 3; end if;
  v_seconds := coalesce((g.config ->> 'seconds')::integer, 60);
  if v_seconds not in (30, 45, 60, 90) then v_seconds := 60; end if;
  v_team_count := jsonb_array_length(g.config -> 'teams');
  v_total := v_rounds * v_team_count;
  v_next := coalesce((select max(turn_index) + 1 from public.taboo_turns where game_id = p_game_id), 0);
  if v_next >= v_total then
    raise exception 'Ya no quedan turnos';
  end if;

  v_team_key := g.config -> 'teams' -> (v_next % v_team_count) ->> 'key';
  v_team_name := g.config -> 'teams' -> (v_next % v_team_count) ->> 'name';
  select count(*) into v_members from public.game_players where game_id = p_game_id and team_key = v_team_key;
  v_nth := (v_next / v_team_count) % v_members;
  select id, display_name into v_player, v_name
  from (
    select id, display_name, row_number() over (order by seat) - 1 as rn
    from public.game_players
    where game_id = p_game_id and team_key = v_team_key
  ) s
  where rn = v_nth;

  insert into public.taboo_turns (game_id, turn_index, player_id, team_key)
  values (p_game_id, v_next, v_player, v_team_key);

  update public.games
  set status = 'playing',
      config = config || jsonb_build_object('rounds', v_rounds, 'seconds', v_seconds)
  where id = p_game_id;

  return jsonb_build_object(
    'turn_index', v_next,
    'total', v_total,
    'seconds', v_seconds,
    'player_id', v_player,
    'player_name', v_name,
    'team_key', v_team_key,
    'team_name', v_team_name,
    'scores', private.taboo_scores(p_game_id)
  );
end;
$$;

create or replace function private.next_taboo_card(p_game_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  g public.games;
  v_turn public.taboo_turns;
  v_open uuid;
  v_payload jsonb;
  v_source uuid;
  v_difficulty text;
  v_cats uuid[];
  v_rounds integer;
  v_teams integer;
  v_cap integer;
  v_dealt integer;
begin
  g := private.load_game(p_game_id);
  select * into v_turn from public.taboo_turns where game_id = p_game_id and ended_at is null;
  if v_turn.id is null then
    raise exception 'No hay un turno en marcha';
  end if;

  select id, payload, source_id into v_open, v_payload, v_source
  from public.match_cards
  where game_id = p_game_id and consumed = false
  order by position desc
  limit 1;

  if v_open is not null then
    return jsonb_build_object('empty', false, 'card_id', v_source, 'card', v_payload, 'player_id', v_turn.player_id);
  end if;

  v_rounds := coalesce((g.config ->> 'rounds')::integer, 3);
  v_teams := jsonb_array_length(g.config -> 'teams');
  v_cap := v_rounds * v_teams * 12;
  select count(*) into v_dealt from public.match_cards where game_id = p_game_id;
  if v_dealt >= v_cap then
    return jsonb_build_object('empty', true);
  end if;

  v_difficulty := private.clean_difficulty(g.config ->> 'difficulty');
  v_cats := private.uuid_list(g.config -> 'category_ids');

  select t.id,
    jsonb_build_object('word', t.word, 'emoji', t.emoji, 'forbidden', to_jsonb(t.forbidden), 'category', c.name)
  into v_source, v_payload
  from public.taboo_cards t
  join public.taboo_categories c on c.id = t.category_id
  where t.active and c.active
    and (v_difficulty is null or t.difficulty = v_difficulty)
    and (cardinality(v_cats) = 0 or t.category_id = any (v_cats))
    and not exists (
      select 1 from public.match_cards mc
      where mc.game_id = p_game_id and mc.source_id = t.id
    )
  order by random()
  limit 1;

  if v_source is null then
    return jsonb_build_object('empty', true);
  end if;

  insert into public.match_cards (game_id, position, source_id, payload, assigned_player, opened_at)
  values (p_game_id, v_dealt, v_source, v_payload, v_turn.player_id, now());

  return jsonb_build_object('empty', false, 'card_id', v_source, 'card', v_payload, 'player_id', v_turn.player_id);
end;
$$;

create or replace function private.taboo_mark(p_game_id uuid, p_result text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  g public.games;
  v_turn public.taboo_turns;
  v_card uuid;
  v_source uuid;
  v_seconds integer;
  v_points integer;
begin
  g := private.load_game(p_game_id);
  if p_result not in ('correct', 'forbidden', 'pass') then
    raise exception 'Resultado no válido';
  end if;
  select * into v_turn from public.taboo_turns where game_id = p_game_id and ended_at is null;
  if v_turn.id is null then
    raise exception 'No hay un turno en marcha';
  end if;
  v_seconds := coalesce((g.config ->> 'seconds')::integer, 60);
  if now() > v_turn.started_at + make_interval(secs => v_seconds + 3) then
    raise exception 'Se acabó el tiempo de este turno';
  end if;

  select id, source_id into v_card, v_source
  from public.match_cards
  where game_id = p_game_id and consumed = false
  order by position desc
  limit 1
  for update;
  if v_card is null then
    raise exception 'No hay una tarjeta en juego';
  end if;

  v_points := case p_result when 'correct' then 1 when 'forbidden' then -1 else 0 end;
  insert into public.taboo_events (game_id, card_id, player_id, team_key, result, points)
  values (p_game_id, v_source, v_turn.player_id, v_turn.team_key, p_result, v_points);
  update public.match_cards set consumed = true where id = v_card;

  return jsonb_build_object('ok', true, 'points', v_points, 'scores', private.taboo_scores(p_game_id));
end;
$$;

create or replace function private.end_taboo_turn(p_game_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  g public.games;
  v_turn uuid;
  v_player uuid;
  v_team text;
  v_card uuid;
  v_source uuid;
  v_total integer;
  v_done integer;
begin
  g := private.load_game(p_game_id);
  select id, player_id, team_key into v_turn, v_player, v_team
  from public.taboo_turns where game_id = p_game_id and ended_at is null;
  if v_turn is null then
    raise exception 'No hay un turno en marcha';
  end if;

  select id, source_id into v_card, v_source
  from public.match_cards
  where game_id = p_game_id and consumed = false
  order by position desc
  limit 1;
  if v_card is not null then
    insert into public.taboo_events (game_id, card_id, player_id, team_key, result, points)
    values (p_game_id, v_source, v_player, v_team, 'pass', 0)
    on conflict (game_id, card_id) do nothing;
    update public.match_cards set consumed = true where id = v_card;
  end if;

  update public.taboo_turns set ended_at = now() where id = v_turn;
  v_total := coalesce((g.config ->> 'rounds')::integer, 3) * jsonb_array_length(g.config -> 'teams');
  select count(*) into v_done from public.taboo_turns where game_id = p_game_id and ended_at is not null;
  return jsonb_build_object('ok', true, 'finished_rounds', v_done >= v_total, 'scores', private.taboo_scores(p_game_id));
end;
$$;

create or replace function private.finish_taboo(p_game_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  g public.games;
  v_max integer;
  v_host_team text;
  v_host_score integer;
  v_host_won boolean;
  v_correct integer;
  v_failed integer;
  v_forbidden integer;
  v_clean integer := 0;
  v_best text;
  v_results jsonb;
  v_teams jsonb;
  v_events integer;
begin
  g := private.load_game(p_game_id);
  if g.game_type <> 'taboo' then
    raise exception 'Esta partida no es Tabú';
  end if;
  if g.status = 'finished' then
    return g.summary;
  end if;
  if exists (select 1 from public.taboo_turns where game_id = p_game_id and ended_at is null) then
    perform private.end_taboo_turn(p_game_id);
  end if;
  select count(*) into v_events from public.taboo_events where game_id = p_game_id;
  if v_events = 0 then
    raise exception 'Todavía no habéis jugado ninguna palabra';
  end if;

  select team_key into v_host_team from public.game_players where game_id = p_game_id and is_host;
  select coalesce(max(score), 0) into v_max
  from (
    select coalesce(sum(points), 0) as score
    from public.game_players gp
    left join public.taboo_events e on e.player_id = gp.id
    where gp.game_id = p_game_id
    group by gp.team_key
  ) s;
  select coalesce(sum(points), 0) into v_host_score
  from public.taboo_events where game_id = p_game_id and team_key = v_host_team;
  v_host_won := v_host_score = v_max;

  select count(*) filter (where result = 'correct'),
         count(*) filter (where result = 'pass'),
         count(*) filter (where result = 'forbidden')
  into v_correct, v_failed, v_forbidden
  from public.taboo_events e
  join public.game_players gp on gp.id = e.player_id and gp.is_host
  where e.game_id = p_game_id;

  if coalesce(v_correct, 0) >= 5 and coalesce(v_forbidden, 0) = 0 then
    v_clean := 1;
  end if;

  select gp.display_name into v_best
  from public.game_players gp
  left join public.taboo_events e on e.player_id = gp.id and e.result = 'correct'
  where gp.game_id = p_game_id
  group by gp.id, gp.display_name
  order by count(e.id) desc, gp.display_name
  limit 1;

  v_teams := private.taboo_scores(p_game_id);
  select coalesce(jsonb_agg(jsonb_build_object(
    'player_id', gp.id,
    'score', coalesce(ps.points, 0),
    'won', coalesce(ts.score, 0) = v_max,
    'details', jsonb_build_object('name', gp.display_name, 'team_key', gp.team_key)
  )), '[]'::jsonb)
  into v_results
  from public.game_players gp
  left join (
    select player_id, sum(points)::integer as points
    from public.taboo_events where game_id = p_game_id group by player_id
  ) ps on ps.player_id = gp.id
  left join (
    select team_key, sum(points)::integer as score
    from public.taboo_events where game_id = p_game_id group by team_key
  ) ts on ts.team_key = gp.team_key
  where gp.game_id = p_game_id;

  return private.apply_progress(
    p_game_id,
    v_host_won,
    0,
    jsonb_build_object(
      'taboo_played', 1,
      'taboo_wins', case when v_host_won then 1 else 0 end,
      'taboo_correct', coalesce(v_correct, 0),
      'taboo_failed', coalesce(v_failed, 0),
      'taboo_forbidden', coalesce(v_forbidden, 0),
      'taboo_clean', v_clean
    ),
    v_results,
    jsonb_build_object(
      'game_type', 'taboo',
      'winner_label', (
        select string_agg(t ->> 'name', ' y ')
        from jsonb_array_elements(v_teams) t
        where (t ->> 'score')::integer = v_max
      ),
      'teams', v_teams,
      'taboo', jsonb_build_object(
        'correct', coalesce(v_correct, 0),
        'failed', coalesce(v_failed, 0),
        'forbidden', coalesce(v_forbidden, 0),
        'best_player', v_best
      )
    )
  );
end;
$$;

create or replace function private.quick_alive(p_game_id uuid)
returns integer[]
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(array_agg(gp.seat order by gp.seat), '{}'::integer[])
  from public.game_players gp
  where gp.game_id = p_game_id
    and not exists (
      select 1 from public.quick_events e
      where e.game_id = p_game_id and e.player_id = gp.id and e.success = false
    );
$$;

create or replace function private.next_quick(p_game_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  g public.games;
  v_mode text;
  v_seconds integer;
  v_per integer;
  v_players integer;
  v_events integer;
  v_player uuid;
  v_name text;
  v_seat integer;
  v_source uuid;
  v_prompt text;
  v_emoji text;
  v_category text;
  v_difficulty text;
  v_cats uuid[];
  v_open uuid;
  v_payload jsonb;
begin
  g := private.load_game(p_game_id);
  if g.game_type <> 'quick' then
    raise exception 'Esta partida no es Responde rápido';
  end if;
  if g.status = 'finished' then
    raise exception 'Esta partida ya ha terminado';
  end if;

  select id, payload, source_id, assigned_player
  into v_open, v_payload, v_source, v_player
  from public.match_cards
  where game_id = p_game_id and consumed = false
  order by position desc
  limit 1;
  if v_open is not null then
    select display_name, seat into v_name, v_seat from public.game_players where id = v_player;
    return jsonb_build_object(
      'prompt_id', v_source,
      'prompt', v_payload ->> 'prompt',
      'emoji', v_payload ->> 'emoji',
      'category', v_payload ->> 'category',
      'player_id', v_player,
      'player_name', v_name,
      'seat', v_seat,
      'seconds', coalesce((g.config ->> 'seconds')::integer, 10)
    );
  end if;

  v_mode := case when g.config ->> 'mode' = 'elimination' then 'elimination' else 'individual' end;
  v_seconds := coalesce((g.config ->> 'seconds')::integer, 10);
  if v_seconds not in (5, 10) then v_seconds := 10; end if;
  v_per := coalesce((g.config ->> 'questions_per_player')::integer, 5);
  if v_per not in (3, 5, 8) then v_per := 5; end if;
  select count(*) into v_players from public.game_players where game_id = p_game_id;
  select count(*) into v_events from public.quick_events where game_id = p_game_id;

  if v_mode = 'individual' and v_events >= v_players * v_per then
    raise exception 'Ya habéis respondido todas las preguntas';
  end if;
  if v_mode = 'elimination' and v_events > 0 and cardinality(private.quick_alive(p_game_id)) <= 1 then
    raise exception 'Ya hay un ganador';
  end if;

  if v_mode = 'elimination' then
    select gp.id, gp.display_name, gp.seat into v_player, v_name, v_seat
    from public.game_players gp
    where gp.game_id = p_game_id
      and gp.seat = any (private.quick_alive(p_game_id))
    order by gp.seat
    offset (v_events % greatest(cardinality(private.quick_alive(p_game_id)), 1))
    limit 1;
  else
    select gp.id, gp.display_name, gp.seat into v_player, v_name, v_seat
    from public.game_players gp
    where gp.game_id = p_game_id
    order by gp.seat
    offset (v_events % v_players) limit 1;
  end if;

  v_difficulty := private.clean_difficulty(g.config ->> 'difficulty');
  v_cats := private.uuid_list(g.config -> 'category_ids');
  select q.id, q.prompt, c.emoji, c.name
  into v_source, v_prompt, v_emoji, v_category
  from public.quick_questions q
  join public.quick_categories c on c.id = q.category_id
  where q.active and c.active
    and (v_difficulty is null or q.difficulty = v_difficulty)
    and (cardinality(v_cats) = 0 or q.category_id = any (v_cats))
    and not exists (
      select 1 from public.match_cards mc where mc.game_id = p_game_id and mc.source_id = q.id
    )
  order by random()
  limit 1;

  if v_source is null then
    raise exception 'No hay retos con esos filtros';
  end if;

  insert into public.match_cards (game_id, position, source_id, payload, assigned_player, opened_at)
  values (
    p_game_id,
    v_events,
    v_source,
    jsonb_build_object('prompt', v_prompt, 'emoji', v_emoji, 'category', v_category),
    v_player,
    now()
  );

  update public.games
  set status = 'playing',
      config = config || jsonb_build_object('mode', v_mode, 'seconds', v_seconds, 'questions_per_player', v_per)
  where id = p_game_id;

  return jsonb_build_object(
    'prompt_id', v_source,
    'prompt', v_prompt,
    'emoji', v_emoji,
    'category', v_category,
    'player_id', v_player,
    'player_name', v_name,
    'seat', v_seat,
    'seconds', v_seconds
  );
end;
$$;

create or replace function private.quick_mark(p_game_id uuid, p_success boolean)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  g public.games;
  v_card uuid;
  v_source uuid;
  v_player uuid;
  v_opened timestamptz;
  v_seconds integer;
  v_elapsed integer;
  v_ok boolean;
  v_prev integer;
  v_streak integer;
  v_points integer;
  v_mode text;
  v_players integer;
  v_events integer;
  v_per integer;
  v_done boolean := false;
begin
  g := private.load_game(p_game_id);
  v_seconds := coalesce((g.config ->> 'seconds')::integer, 10);
  select id, source_id, assigned_player, opened_at
  into v_card, v_source, v_player, v_opened
  from public.match_cards
  where game_id = p_game_id and consumed = false
  order by position desc
  limit 1
  for update;
  if v_card is null then
    raise exception 'No hay un reto en juego';
  end if;

  v_elapsed := greatest(0, floor(extract(epoch from (now() - v_opened)) * 1000)::integer);
  v_ok := coalesce(p_success, false) and v_elapsed <= (v_seconds * 1000 + 1500);
  select coalesce(streak, 0) into v_prev
  from public.quick_events
  where game_id = p_game_id and player_id = v_player
  order by created_at desc
  limit 1;
  v_streak := case when v_ok then coalesce(v_prev, 0) + 1 else 0 end;
  v_points := case when v_ok then 1 else 0 end;
  if v_ok and v_streak % 3 = 0 then
    v_points := v_points + 1;
  end if;

  insert into public.quick_events (game_id, prompt_id, player_id, success, points, streak, elapsed_ms)
  values (p_game_id, v_source, v_player, v_ok, v_points, v_streak, v_elapsed);
  update public.match_cards set consumed = true where id = v_card;

  v_mode := coalesce(g.config ->> 'mode', 'individual');
  v_per := coalesce((g.config ->> 'questions_per_player')::integer, 5);
  select count(*) into v_players from public.game_players where game_id = p_game_id;
  select count(*) into v_events from public.quick_events where game_id = p_game_id;
  if v_mode = 'elimination' then
    v_done := cardinality(private.quick_alive(p_game_id)) <= 1;
  else
    v_done := v_events >= v_players * v_per;
  end if;

  return jsonb_build_object(
    'success', v_ok,
    'points', v_points,
    'streak', v_streak,
    'elapsed_ms', v_elapsed,
    'done', v_done,
    'alive', private.quick_alive(p_game_id)
  );
end;
$$;

create or replace function private.finish_quick(p_game_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  g public.games;
  v_mode text;
  v_max integer;
  v_host uuid;
  v_host_score integer;
  v_host_won boolean;
  v_correct integer;
  v_wrong integer;
  v_best_streak integer;
  v_time bigint;
  v_time_n integer;
  v_best text;
  v_results jsonb;
  v_alive integer[];
  v_events integer;
begin
  g := private.load_game(p_game_id);
  if g.game_type <> 'quick' then
    raise exception 'Esta partida no es Responde rápido';
  end if;
  if g.status = 'finished' then
    return g.summary;
  end if;
  select count(*) into v_events from public.quick_events where game_id = p_game_id;
  if v_events = 0 then
    raise exception 'Todavía no habéis jugado ningún reto';
  end if;

  v_mode := coalesce(g.config ->> 'mode', 'individual');
  v_alive := private.quick_alive(p_game_id);
  select id into v_host from public.game_players where game_id = p_game_id and is_host;

  if v_mode = 'elimination' and cardinality(v_alive) = 1 then
    select coalesce(sum(points), 0) into v_max from public.quick_events where game_id = p_game_id and player_id = v_host;
    v_host_won := v_host = (
      select gp.id from public.game_players gp
      where gp.game_id = p_game_id and gp.seat = v_alive[1]
    );
    select coalesce(jsonb_agg(jsonb_build_object(
      'player_id', gp.id,
      'score', coalesce(ps.points, 0),
      'won', gp.seat = v_alive[1],
      'details', jsonb_build_object('name', gp.display_name)
    )), '[]'::jsonb)
    into v_results
    from public.game_players gp
    left join (
      select player_id, sum(points)::integer as points
      from public.quick_events where game_id = p_game_id group by player_id
    ) ps on ps.player_id = gp.id
    where gp.game_id = p_game_id;
  else
    select coalesce(max(score), 0) into v_max
    from (
      select coalesce(sum(e.points), 0) as score
      from public.game_players gp
      left join public.quick_events e on e.player_id = gp.id
      where gp.game_id = p_game_id
      group by gp.id
    ) s;
    select coalesce(sum(points), 0) into v_host_score
    from public.quick_events where game_id = p_game_id and player_id = v_host;
    v_host_won := v_max > 0 and v_host_score = v_max;
    select coalesce(jsonb_agg(jsonb_build_object(
      'player_id', gp.id,
      'score', coalesce(ps.points, 0),
      'won', coalesce(ps.points, 0) = v_max and v_max > 0,
      'details', jsonb_build_object('name', gp.display_name)
    )), '[]'::jsonb)
    into v_results
    from public.game_players gp
    left join (
      select player_id, sum(points)::integer as points
      from public.quick_events where game_id = p_game_id group by player_id
    ) ps on ps.player_id = gp.id
    where gp.game_id = p_game_id;
  end if;

  select count(*) filter (where success),
         count(*) filter (where not success),
         coalesce(max(streak), 0),
         coalesce(sum(elapsed_ms), 0),
         count(*)
  into v_correct, v_wrong, v_best_streak, v_time, v_time_n
  from public.quick_events
  where game_id = p_game_id and player_id = v_host;

  select gp.display_name into v_best
  from public.game_players gp
  left join public.quick_events e on e.player_id = gp.id
  where gp.game_id = p_game_id
  group by gp.id, gp.display_name
  order by coalesce(sum(e.points), 0) desc, gp.display_name
  limit 1;

  if v_mode = 'elimination' and cardinality(v_alive) = 1 then
    select display_name into v_best
    from public.game_players
    where game_id = p_game_id and seat = v_alive[1];
  end if;

  return private.apply_progress(
    p_game_id,
    v_host_won,
    coalesce(v_best_streak, 0),
    jsonb_build_object(
      'quick_played', 1,
      'quick_wins', case when v_host_won then 1 else 0 end,
      'quick_correct', coalesce(v_correct, 0),
      'quick_wrong', coalesce(v_wrong, 0),
      'quick_best_streak', coalesce(v_best_streak, 0),
      'quick_time_ms', coalesce(v_time, 0),
      'quick_time_count', coalesce(v_time_n, 0)
    ),
    v_results,
    jsonb_build_object(
      'game_type', 'quick',
      'winner_label', v_best,
      'mode', v_mode,
      'quick', jsonb_build_object(
        'correct', coalesce(v_correct, 0),
        'wrong', coalesce(v_wrong, 0),
        'best_streak', coalesce(v_best_streak, 0),
        'best_player', v_best,
        'avg_ms', case when coalesce(v_time_n, 0) = 0 then 0 else (v_time / v_time_n)::integer end
      ),
      'players', v_results
    )
  );
end;
$$;

create or replace function private.finish_match(p_game_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  g public.games;
begin
  g := private.load_game(p_game_id);
  if g.status = 'finished' then
    return g.summary;
  end if;
  if g.game_type = 'quiz' then
    return private.finish_quiz(p_game_id);
  elsif g.game_type = 'taboo' then
    return private.finish_taboo(p_game_id);
  elsif g.game_type = 'quick' then
    return private.finish_quick(p_game_id);
  elsif g.game_type = 'impostor' then
    if g.status = 'guessing' then
      raise exception 'El impostor todavía puede adivinar la palabra';
    end if;
    if exists (select 1 from public.impostor_secrets where game_id = p_game_id and winner_side is not null) then
      return private.finish_impostor(p_game_id);
    end if;
    raise exception 'Termina la votación antes de cerrar la partida';
  end if;
  raise exception 'Juego no válido';
end;
$$;
