-- Finishing a quiz, plus Impostor, Tabú and Responde rápido.

create or replace function private.finish_quiz(p_game_id uuid)
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
  v_wrong integer;
  v_host_correct integer;
  v_host_wrong integer;
  v_expert integer;
  v_streak integer := 0;
  v_best integer := 0;
  v_row record;
  v_total_cards integer;
  v_best_player text;
  v_best_category text;
  v_accuracy integer;
  v_results jsonb;
  v_teams jsonb;
  v_perfect integer := 0;
begin
  g := private.load_game(p_game_id);
  if g.game_type <> 'quiz' then
    raise exception 'Esta partida no es un quiz';
  end if;
  if g.status = 'finished' then
    return g.summary;
  end if;
  if (select count(*) from public.quiz_responses where game_id = p_game_id) = 0 then
    raise exception 'Todavía no habéis respondido ninguna pregunta';
  end if;

  select gp.team_key into v_host_team
  from public.game_players gp
  where gp.game_id = p_game_id and gp.is_host;

  select coalesce(max(score), 0) into v_max
  from (
    select coalesce(sum(r.points), 0) as score
    from public.game_players gp
    left join public.quiz_responses r on r.player_id = gp.id
    where gp.game_id = p_game_id
    group by gp.team_key
  ) s;

  select coalesce(sum(r.points), 0) into v_host_score
  from public.quiz_responses r
  join public.game_players gp on gp.id = r.player_id
  where r.game_id = p_game_id and gp.team_key = v_host_team;

  v_host_won := v_max > 0 and v_host_score = v_max;

  select count(*) filter (where correct), count(*) filter (where not correct)
  into v_correct, v_wrong
  from public.quiz_responses where game_id = p_game_id;

  select count(*) filter (where r.correct), count(*) filter (where not r.correct)
  into v_host_correct, v_host_wrong
  from public.quiz_responses r
  join public.game_players gp on gp.id = r.player_id and gp.is_host
  where r.game_id = p_game_id;

  select count(*) into v_expert
  from public.quiz_responses r
  join public.game_players gp on gp.id = r.player_id and gp.is_host
  join public.quiz_questions q on q.id = r.question_id
  where r.game_id = p_game_id and r.correct and q.difficulty = 'expert';

  for v_row in
    select r.correct
    from public.quiz_responses r
    join public.game_players gp on gp.id = r.player_id and gp.is_host
    join public.match_cards mc on mc.game_id = r.game_id and mc.source_id = r.question_id
    where r.game_id = p_game_id
    order by mc.position
  loop
    if v_row.correct then
      v_streak := v_streak + 1;
      v_best := greatest(v_best, v_streak);
    else
      v_streak := 0;
    end if;
  end loop;

  select count(*) into v_total_cards from public.match_cards where game_id = p_game_id;
  if v_total_cards >= 10 and v_wrong = 0 and (v_correct + v_wrong) = v_total_cards then
    v_perfect := 1;
  end if;

  insert into public.quiz_category_stats (user_id, category_id, correct, wrong)
  select (g).host_id, q.category_id,
         count(*) filter (where r.correct)::integer,
         count(*) filter (where not r.correct)::integer
  from public.quiz_responses r
  join public.game_players gp on gp.id = r.player_id and gp.is_host
  join public.quiz_questions q on q.id = r.question_id
  where r.game_id = p_game_id
  group by q.category_id, (g).host_id
  on conflict (user_id, category_id) do update
    set correct = public.quiz_category_stats.correct + excluded.correct,
        wrong = public.quiz_category_stats.wrong + excluded.wrong;

  select gp.display_name into v_best_player
  from public.game_players gp
  left join public.quiz_responses r on r.player_id = gp.id
  where gp.game_id = p_game_id
  group by gp.id, gp.display_name
  order by coalesce(sum(r.points), 0) desc, gp.display_name
  limit 1;

  select c.name into v_best_category
  from public.quiz_responses r
  join public.quiz_questions q on q.id = r.question_id
  join public.quiz_categories c on c.id = q.category_id
  where r.game_id = p_game_id
  group by c.id, c.name
  order by (count(*) filter (where r.correct))::numeric / count(*) desc, count(*) desc
  limit 1;

  v_accuracy := coalesce(round(100.0 * v_correct / nullif(v_correct + v_wrong, 0))::integer, 0);

  select coalesce(jsonb_agg(jsonb_build_object(
    'team_key', t.key,
    'name', t.name,
    'color', t.color,
    'score', coalesce(sc.score, 0),
    'correct', coalesce(sc.correct, 0),
    'wrong', coalesce(sc.wrong, 0)
  ) order by coalesce(sc.score, 0) desc), '[]'::jsonb)
  into v_teams
  from (
    select value ->> 'key' as key, value ->> 'name' as name, value ->> 'color' as color
    from jsonb_array_elements(g.config -> 'teams')
  ) t
  left join (
    select gp.team_key,
           sum(r.points)::integer as score,
           count(*) filter (where r.correct)::integer as correct,
           count(*) filter (where not r.correct)::integer as wrong
    from public.game_players gp
    left join public.quiz_responses r on r.player_id = gp.id
    where gp.game_id = p_game_id
    group by gp.team_key
  ) sc on sc.team_key = t.key;

  select coalesce(jsonb_agg(jsonb_build_object(
    'player_id', gp.id,
    'score', coalesce(ps.points, 0),
    'won', coalesce(ts.score, 0) = v_max and v_max > 0,
    'details', jsonb_build_object('name', gp.display_name, 'team_key', gp.team_key)
  )), '[]'::jsonb)
  into v_results
  from public.game_players gp
  left join (
    select player_id, sum(points)::integer as points
    from public.quiz_responses where game_id = p_game_id group by player_id
  ) ps on ps.player_id = gp.id
  left join (
    select team_key, sum(points)::integer as score
    from public.quiz_responses r
    join public.game_players p on p.id = r.player_id
    where r.game_id = p_game_id
    group by team_key
  ) ts on ts.team_key = gp.team_key
  where gp.game_id = p_game_id;

  return private.apply_progress(
    p_game_id,
    v_host_won,
    v_best,
    jsonb_build_object(
      'quiz_played', 1,
      'quiz_wins', case when v_host_won then 1 else 0 end,
      'quiz_correct', coalesce(v_host_correct, 0),
      'quiz_wrong', coalesce(v_host_wrong, 0),
      'quiz_best_streak', v_best,
      'quiz_expert_correct', coalesce(v_expert, 0),
      'quiz_perfect', v_perfect
    ),
    v_results,
    jsonb_build_object(
      'game_type', 'quiz',
      'winner_label', (
        select string_agg(t ->> 'name', ' y ')
        from jsonb_array_elements(v_teams) t
        where (t ->> 'score')::integer = v_max and v_max > 0
      ),
      'teams', v_teams,
      'quiz', jsonb_build_object(
        'correct', v_correct,
        'wrong', v_wrong,
        'accuracy', v_accuracy,
        'best_player', v_best_player,
        'best_category', v_best_category,
        'questions', v_total_cards
      )
    )
  );
end;
$$;

create or replace function private.prepare_impostor(p_game_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  g public.games;
  v_n integer;
  v_players integer;
  v_difficulty text;
  v_cats uuid[];
  v_word_id uuid;
  v_word text;
  v_emoji text;
  v_category text;
  v_seats integer[];
begin
  g := private.load_game(p_game_id);
  if g.game_type <> 'impostor' then
    raise exception 'Esta partida no es Impostor';
  end if;
  if exists (select 1 from public.impostor_secrets where game_id = p_game_id) then
    return jsonb_build_object('ok', true, 'players', private.players_json(p_game_id));
  end if;

  select count(*) into v_players from public.game_players where game_id = p_game_id;
  v_n := coalesce((g.config ->> 'impostor_count')::integer, 0);
  if v_n = 0 then
    v_n := case when v_players >= 6 and random() >= 0.5 then 2 else 1 end;
  end if;
  if v_players < 4 then
    v_n := 1;
  end if;
  if v_n < 1 or v_n > 2 or v_n >= v_players then
    raise exception 'Número de impostores no válido';
  end if;

  v_difficulty := private.clean_difficulty(g.config ->> 'difficulty');
  v_cats := private.uuid_list(g.config -> 'category_ids');

  select w.id, w.word, w.emoji, c.name
  into v_word_id, v_word, v_emoji, v_category
  from public.impostor_words w
  join public.impostor_categories c on c.id = w.category_id
  where w.active and c.active
    and (v_difficulty is null or w.difficulty = v_difficulty)
    and (cardinality(v_cats) = 0 or w.category_id = any (v_cats))
  order by random()
  limit 1;

  if v_word_id is null then
    raise exception 'No hay palabras con esos filtros';
  end if;

  select array_agg(seat) into v_seats
  from (
    select seat from public.game_players
    where game_id = p_game_id
    order by random()
    limit v_n
  ) picked;

  insert into public.impostor_secrets (game_id, word_id, word, emoji, category_name, impostor_seats)
  values (p_game_id, v_word_id, v_word, v_emoji, v_category, v_seats);

  update public.games
  set status = 'playing',
      config = config || jsonb_build_object('impostor_count', v_n)
  where id = p_game_id;

  return jsonb_build_object('ok', true, 'players', private.players_json(p_game_id));
end;
$$;

create or replace function private.reveal_role(p_game_id uuid, p_seat integer)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  g public.games;
  s public.impostor_secrets;
  v_name text;
  v_impostor boolean;
begin
  g := private.load_game(p_game_id);
  if g.status not in ('playing', 'voting', 'guessing') then
    raise exception 'Todavía no se han repartido los papeles';
  end if;
  select * into s from public.impostor_secrets where game_id = p_game_id;
  if not found then
    raise exception 'Todavía no se han repartido los papeles';
  end if;
  select display_name into v_name
  from public.game_players
  where game_id = p_game_id and seat = p_seat;
  if v_name is null then
    raise exception 'Jugador no encontrado';
  end if;
  v_impostor := p_seat = any (s.impostor_seats);
  return jsonb_build_object(
    'seat', p_seat,
    'name', v_name,
    'is_impostor', v_impostor,
    'word', case when v_impostor then null else s.word end,
    'emoji', case when v_impostor then null else s.emoji end,
    'category', case when v_impostor then null else s.category_name end
  );
end;
$$;

create or replace function private.start_voting(p_game_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  g public.games;
begin
  g := private.load_game(p_game_id);
  if g.game_type <> 'impostor' or g.status not in ('playing', 'voting') then
    raise exception 'Ahora no toca votar';
  end if;
  update public.games set status = 'voting' where id = p_game_id and status = 'playing';
  return jsonb_build_object('ok', true, 'players', private.players_json(p_game_id));
end;
$$;

create or replace function private.cast_vote(
  p_game_id uuid,
  p_voter_seat integer,
  p_target_seat integer
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  g public.games;
  v_players integer;
  v_votes integer;
begin
  g := private.load_game(p_game_id);
  if g.status <> 'voting' then
    raise exception 'La votación no está abierta';
  end if;
  if p_voter_seat = p_target_seat then
    raise exception 'No puedes votarte a ti mismo';
  end if;
  if not exists (select 1 from public.game_players where game_id = p_game_id and seat = p_voter_seat)
     or not exists (select 1 from public.game_players where game_id = p_game_id and seat = p_target_seat) then
    raise exception 'Voto no válido';
  end if;
  if exists (
    select 1 from public.impostor_votes
    where game_id = p_game_id and voter_seat = p_voter_seat
  ) then
    raise exception 'Ese jugador ya ha votado';
  end if;

  insert into public.impostor_votes (game_id, voter_seat, target_seat)
  values (p_game_id, p_voter_seat, p_target_seat);

  select count(*) into v_players from public.game_players where game_id = p_game_id;
  select count(*) into v_votes from public.impostor_votes where game_id = p_game_id;
  return jsonb_build_object('ok', true, 'votes', v_votes, 'players', v_players, 'complete', v_votes >= v_players);
end;
$$;

create or replace function private.finish_impostor(p_game_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  g public.games;
  s public.impostor_secrets;
  v_host_seat integer;
  v_was boolean;
  v_host_won boolean;
  v_results jsonb;
  v_votes jsonb;
  v_names text;
begin
  select * into g from public.games where id = p_game_id;
  select * into s from public.impostor_secrets where game_id = p_game_id;
  if s.winner_side is null then
    raise exception 'La partida todavía no tiene resultado';
  end if;

  select seat into v_host_seat from public.game_players where game_id = p_game_id and is_host;
  v_was := v_host_seat = any (s.impostor_seats);
  v_host_won := (v_was and s.winner_side = 'impostors') or (not v_was and s.winner_side = 'citizens');

  select string_agg(display_name, ', ' order by seat) into v_names
  from public.game_players
  where game_id = p_game_id and seat = any (s.impostor_seats);

  select coalesce(jsonb_agg(jsonb_build_object(
    'voter', vp.display_name,
    'target', tp.display_name
  ) order by v.voter_seat), '[]'::jsonb)
  into v_votes
  from public.impostor_votes v
  join public.game_players vp on vp.game_id = v.game_id and vp.seat = v.voter_seat
  join public.game_players tp on tp.game_id = v.game_id and tp.seat = v.target_seat
  where v.game_id = p_game_id;

  select coalesce(jsonb_agg(jsonb_build_object(
    'player_id', gp.id,
    'score', case
      when (gp.seat = any (s.impostor_seats) and s.winner_side = 'impostors')
        or (not (gp.seat = any (s.impostor_seats)) and s.winner_side = 'citizens')
      then 1 else 0 end,
    'won', (gp.seat = any (s.impostor_seats) and s.winner_side = 'impostors')
        or (not (gp.seat = any (s.impostor_seats)) and s.winner_side = 'citizens'),
    'details', jsonb_build_object(
      'name', gp.display_name,
      'impostor', gp.seat = any (s.impostor_seats)
    )
  )), '[]'::jsonb)
  into v_results
  from public.game_players gp
  where gp.game_id = p_game_id;

  return private.apply_progress(
    p_game_id,
    v_host_won,
    0,
    jsonb_build_object(
      'impostor_played', 1,
      'impostor_times', case when v_was then 1 else 0 end,
      'impostor_wins', case when v_was and s.winner_side = 'impostors' then 1 else 0 end,
      'impostor_caught', case when v_was and s.winner_side = 'citizens' then 1 else 0 end,
      'impostor_catches', case when not v_was and s.winner_side = 'citizens' then 1 else 0 end,
      'impostor_word_guesses', case when v_host_seat = s.accused_seat and s.guess_ok then 1 else 0 end
    ),
    v_results,
    jsonb_build_object(
      'game_type', 'impostor',
      'winner_label', case when s.winner_side = 'impostors' then 'Ganan los impostores' else 'Ganan los jugadores' end,
      'winner_side', s.winner_side,
      'word', s.word,
      'emoji', s.emoji,
      'category', s.category_name,
      'impostors', v_names,
      'votes', v_votes,
      'guess', s.guess,
      'guess_ok', s.guess_ok,
      'discovered', s.accused_seat is not null
    )
  );
end;
$$;

create or replace function private.resolve_impostor(p_game_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  g public.games;
  s public.impostor_secrets;
  v_players integer;
  v_top integer;
  v_top_count integer;
  v_second integer;
  v_name text;
  v_tie boolean := false;
begin
  g := private.load_game(p_game_id);
  if g.status = 'finished' then
    return g.summary;
  end if;
  if g.status = 'guessing' then
    raise exception 'El impostor todavía puede adivinar la palabra';
  end if;
  if g.status <> 'voting' then
    raise exception 'Todavía no estáis votando';
  end if;

  select count(*) into v_players from public.game_players where game_id = p_game_id;
  if (select count(*) from public.impostor_votes where game_id = p_game_id) < v_players then
    raise exception 'Faltan votos';
  end if;

  select * into s from public.impostor_secrets where game_id = p_game_id;

  select target_seat, votes into v_top, v_top_count
  from (
    select target_seat, count(*) as votes
    from public.impostor_votes
    where game_id = p_game_id
    group by target_seat
    order by count(*) desc, target_seat
    limit 1
  ) top;

  select target_seat into v_second
  from (
    select target_seat, count(*) as votes
    from public.impostor_votes
    where game_id = p_game_id
    group by target_seat
    order by count(*) desc, target_seat
    offset 1 limit 1
  ) second;

  if v_second is not null and (
    select count(*) from public.impostor_votes where game_id = p_game_id and target_seat = v_second
  ) = v_top_count then
    v_tie := true;
  end if;

  if not v_tie and v_top = any (s.impostor_seats) then
    select display_name into v_name from public.game_players where game_id = p_game_id and seat = v_top;
    update public.impostor_secrets set accused_seat = v_top where game_id = p_game_id;
    update public.games set status = 'guessing' where id = p_game_id;
    return jsonb_build_object('phase', 'guess', 'accused_seat', v_top, 'accused_name', v_name);
  end if;

  update public.impostor_secrets set winner_side = 'impostors' where game_id = p_game_id;
  return private.finish_impostor(p_game_id);
end;
$$;

create or replace function private.impostor_guess(p_game_id uuid, p_guess text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  g public.games;
  s public.impostor_secrets;
  v_ok boolean;
begin
  g := private.load_game(p_game_id);
  if g.status = 'finished' then
    return g.summary;
  end if;
  if g.status <> 'guessing' then
    raise exception 'Ahora no toca adivinar';
  end if;
  select * into s from public.impostor_secrets where game_id = p_game_id;
  v_ok := private.fold(p_guess) = private.fold(s.word) and length(private.fold(p_guess)) > 0;
  update public.impostor_secrets
  set guess = left(trim(p_guess), 80),
      guess_ok = v_ok,
      winner_side = case when v_ok then 'impostors' else 'citizens' end
  where game_id = p_game_id;
  return private.finish_impostor(p_game_id);
end;
$$;
