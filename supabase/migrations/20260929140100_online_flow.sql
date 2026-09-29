-- Online match flow. Clients send an answer id or a lock-in. Points are computed here.

create or replace function private.room_code()
returns text
language plpgsql
volatile
set search_path = ''
as $$
declare
  alphabet text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_code text := '';
  i integer;
begin
  for i in 1..4 loop
    v_code := v_code || substr(alphabet, 1 + floor(pg_catalog.random() * length(alphabet))::integer, 1);
  end loop;
  return v_code;
end;
$$;

create or replace function private.member_room(p_room uuid)
returns public.online_rooms
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  r public.online_rooms;
begin
  if auth.uid() is null then
    raise exception 'Necesitas iniciar sesión';
  end if;
  select * into r from public.online_rooms where id = p_room;
  if not found then
    raise exception 'La sala no existe';
  end if;
  if not exists (
    select 1 from public.online_players
    where room_id = p_room and user_id = auth.uid()
  ) then
    raise exception 'No estás en esta sala';
  end if;
  return r;
end;
$$;

create or replace function private.deal_online(p_room uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.online_rooms;
  v_limit integer;
  v_mode text;
begin
  select * into r from public.online_rooms where id = p_room;
  v_mode := r.mode;
  if exists (select 1 from public.online_cards where room_id = p_room) then
    return;
  end if;
  v_limit := case v_mode when 'duel' then 10 when 'quick' then 6 else 8 end;

  if v_mode = 'quick' then
    insert into public.online_cards (room_id, position, round_no, prompt, emoji, category, answers)
    select p_room, row_number() over (order by q.shuffle) - 1, 1, q.prompt, q.emoji, q.category, '[]'::jsonb
    from (
      select qq.prompt, c.emoji, c.name as category, pg_catalog.random() as shuffle
      from public.quick_questions qq
      join public.quick_categories c on c.id = qq.category_id
      where qq.active and c.active
      order by pg_catalog.random()
      limit v_limit
    ) q;
  else
    insert into public.online_cards (room_id, position, round_no, prompt, emoji, category, answers, correct_id)
    select p_room,
           row_number() over (order by q.shuffle) - 1,
           case
             when v_mode <> 'duel' then 1
             when row_number() over (order by q.shuffle) <= 4 then 1
             when row_number() over (order by q.shuffle) <= 7 then 2
             else 3
           end,
           q.prompt, q.emoji, q.category, q.answers, q.correct_id
    from (
      select qq.prompt, c.emoji, c.name as category, pg_catalog.random() as shuffle,
        (
          select a.id from public.quiz_answers a
          where a.question_id = qq.id and a.is_correct
          limit 1
        ) as correct_id,
        (
          select jsonb_agg(jsonb_build_object('id', a.id, 'text', a.text) order by a.ord)
          from (
            select id, text, pg_catalog.random() as ord
            from public.quiz_answers
            where question_id = qq.id
          ) a
        ) as answers
      from public.quiz_questions qq
      join public.quiz_categories c on c.id = qq.category_id
      where qq.active and c.active
      order by pg_catalog.random()
      limit v_limit
    ) q
    where q.correct_id is not null and jsonb_array_length(q.answers) >= 2;
  end if;

  if (select count(*) from public.online_cards where room_id = p_room) < 3 then
    raise exception 'No hay preguntas suficientes para empezar';
  end if;
end;
$$;

create or replace function private.open_online(p_room uuid, p_position integer)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_seconds integer;
begin
  select seconds into v_seconds from public.online_rooms where id = p_room;
  update public.online_rooms
  set status = 'playing',
      question_index = p_position,
      opened_at = pg_catalog.now(),
      phase_ends = pg_catalog.now() + make_interval(secs => v_seconds),
      public_state = '{}'::jsonb
  where id = p_room;
end;
$$;

create or replace function private.refresh_scores(p_room uuid)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.online_players p
  set score = coalesce((
    select sum(a.points)::integer from public.online_answers a
    where a.room_id = p.room_id and a.user_id = p.user_id
  ), 0)
  where p.room_id = p_room;
$$;

create or replace function private.grant_online(
  p_user uuid,
  p_mode text,
  p_result text,
  p_correct integer
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_xp_before integer;
  v_rating integer;
  v_match integer;
  v_bonus integer := 0;
  v_new integer;
  v_delta integer;
  v_old_streak integer;
  v_ranked boolean := false;
  v_parts jsonb;
  v_title text;
  ach public.achievements;
  v_value integer;
  v_already timestamptz;
  v_unlocked jsonb := '[]'::jsonb;
begin
  select xp, rating into v_xp_before, v_rating from public.profiles where id = p_user;
  select current_streak into v_old_streak from public.user_stats where user_id = p_user;
  select r.ranked into v_ranked
  from public.online_rooms r
  join public.online_players op on op.room_id = r.id
  where op.user_id = p_user and r.status <> 'finished'
  order by r.created_at desc
  limit 1;
  v_parts := private.progress_parts(p_result = 'win', v_old_streak, p_correct);
  v_match := (v_parts ->> 'total')::integer;
  v_delta := case
    when not coalesce(v_ranked, false) then 0
    when p_result = 'win' and p_mode = 'duel' then 32
    when p_result = 'win' then 25
    when p_result = 'tie' then 5
    else -20
  end;

  update public.user_stats s set
    games_played = s.games_played + 1,
    wins = s.wins + case when p_result = 'win' then 1 else 0 end,
    losses = s.losses + case when p_result = 'loss' then 1 else 0 end,
    current_streak = case when p_result = 'win' then s.current_streak + 1 else 0 end,
    best_streak = greatest(s.best_streak, case when p_result = 'win' then s.current_streak + 1 else s.best_streak end),
    quiz_played = s.quiz_played + case when p_mode in ('battle', 'duel') then 1 else 0 end,
    quiz_wins = s.quiz_wins + case when p_mode in ('battle', 'duel') and p_result = 'win' then 1 else 0 end,
    quiz_correct = s.quiz_correct + case when p_mode in ('battle', 'duel') then p_correct else 0 end,
    quick_played = s.quick_played + case when p_mode = 'quick' then 1 else 0 end,
    quick_wins = s.quick_wins + case when p_mode = 'quick' and p_result = 'win' then 1 else 0 end,
    quick_correct = s.quick_correct + case when p_mode = 'quick' then p_correct else 0 end,
    updated_at = pg_catalog.now()
  where s.user_id = p_user;

  for ach in select * from public.achievements where active order by sort loop
    v_value := private.metric_of(p_user, ach.metric);
    select unlocked_at into v_already
    from public.user_achievements
    where user_id = p_user and achievement_id = ach.id;
    if v_already is null then
      insert into public.user_achievements as ua (user_id, achievement_id, progress, unlocked_at)
      values (p_user, ach.id, v_value, case when v_value >= ach.threshold then pg_catalog.now() else null end)
      on conflict (user_id, achievement_id) do update
        set progress = excluded.progress,
            unlocked_at = coalesce(ua.unlocked_at, excluded.unlocked_at);
      if v_value >= ach.threshold then
        v_bonus := v_bonus + ach.xp_reward;
        v_unlocked := v_unlocked || jsonb_build_array(jsonb_build_object(
          'slug', ach.slug, 'name', ach.name, 'emoji', ach.emoji, 'xp', ach.xp_reward
        ));
      end if;
    else
      update public.user_achievements set progress = v_value
      where user_id = p_user and achievement_id = ach.id;
    end if;
  end loop;

  v_new := v_xp_before + v_match + v_bonus;
  select t.name into v_title
  from public.titles t
  left join public.achievements a on a.slug = t.achievement_slug
  left join public.user_achievements ua
    on ua.achievement_id = a.id and ua.user_id = p_user and ua.unlocked_at is not null
  where (t.achievement_slug is null and coalesce(t.min_level, 1) <= private.level_for_xp(v_new))
     or ua.user_id is not null
  order by t.sort desc
  limit 1;

  perform set_config('keda.trusted', '1', true);
  update public.profiles
  set xp = v_new,
      level = private.level_for_xp(v_new),
      title = coalesce(v_title, title),
      rating = greatest(0, rating + v_delta),
      updated_at = pg_catalog.now()
  where id = p_user;

  return jsonb_build_object(
    'xp', v_match + v_bonus,
    'rating_delta', v_delta,
    'achievements', v_unlocked,
    'level', private.level_for_xp(v_new),
    'league', private.league_for_rating(greatest(0, v_rating + v_delta))
  );
end;
$$;

create or replace function private.close_online(p_room uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.online_rooms;
  c public.online_cards;
  v_player record;
  v_elapsed integer;
  v_points integer;
  v_correct boolean;
begin
  select * into r from public.online_rooms where id = p_room;
  select * into c from public.online_cards where room_id = p_room and position = r.question_index;
  v_elapsed := greatest(0, floor(extract(epoch from (pg_catalog.now() - r.opened_at)) * 1000)::integer);

  for v_player in
    select user_id from public.online_players
    where room_id = p_room and connected
      and not exists (
        select 1 from public.online_answers a
        where a.room_id = p_room and a.user_id = online_players.user_id and a.position = r.question_index
      )
  loop
    insert into public.online_answers (room_id, user_id, position, correct, points, elapsed_ms)
    values (p_room, v_player.user_id, r.question_index, false, 0, v_elapsed)
    on conflict do nothing;
  end loop;

  perform private.refresh_scores(p_room);

  update public.online_rooms
  set status = 'reveal',
      phase_ends = pg_catalog.now() + interval '2.4 seconds',
      public_state = jsonb_build_object(
        'correct_id', c.correct_id,
        'correct_text', coalesce(
          (select a.text from public.quiz_answers a where a.id = c.correct_id),
          c.prompt
        ),
        'prompt', c.prompt
      )
  where id = p_room;
end;
$$;

create or replace function private.advance_online(p_room uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.online_rooms;
  v_next integer;
  v_round integer;
  v_compare jsonb;
begin
  select * into r from public.online_rooms where id = p_room;
  v_next := r.question_index + 1;
  select round_no into v_round from public.online_cards where room_id = p_room and position = v_next;

  if v_round is null then
    perform private.finish_online(p_room);
    return;
  end if;

  if r.mode = 'duel' and v_round > r.round_index then
    select coalesce(jsonb_agg(jsonb_build_object(
      'user_id', p.user_id,
      'name', p.display_name,
      'avatar', p.avatar_emoji,
      'round_points', coalesce(s.points, 0),
      'correct', coalesce(s.correct, 0)
    ) order by coalesce(s.points, 0) desc), '[]'::jsonb)
    into v_compare
    from public.online_players p
    left join (
      select a.user_id, sum(a.points)::integer as points, count(*) filter (where a.correct)::integer as correct
      from public.online_answers a
      join public.online_cards c on c.room_id = a.room_id and c.position = a.position
      where a.room_id = p_room and c.round_no = r.round_index
      group by a.user_id
    ) s on s.user_id = p.user_id
    where p.room_id = p_room;

    update public.online_rooms
    set status = 'round_result',
        phase_ends = pg_catalog.now() + interval '4 seconds',
        public_state = jsonb_build_object('round', r.round_index, 'players', v_compare)
    where id = p_room;
    return;
  end if;

  perform private.open_online(p_room, v_next);
end;
$$;

create or replace function private.finish_online(p_room uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.online_rooms;
  v_best integer;
  v_winners integer;
  v_player record;
  v_result text;
  v_correct integer;
  v_grant jsonb;
  v_ranking jsonb;
  v_round_wins jsonb := '{}'::jsonb;
  v_rw integer;
begin
  select * into r from public.online_rooms where id = p_room;
  if r.status = 'finished' then
    return;
  end if;
  perform private.refresh_scores(p_room);

  if r.mode = 'duel' then
    select coalesce(jsonb_object_agg(user_id::text, wins), '{}'::jsonb)
    into v_round_wins
    from (
      select p.user_id, count(w.round_no)::integer as wins
      from public.online_players p
      left join (
        select rp.round_no, rp.user_id
        from (
          select c.round_no, a.user_id, sum(a.points)::integer as points
          from public.online_answers a
          join public.online_cards c on c.room_id = a.room_id and c.position = a.position
          where a.room_id = p_room
          group by c.round_no, a.user_id
        ) rp
        where rp.points > 0
          and rp.points = (
            select max(rp2.points)
            from (
              select c2.round_no, sum(a2.points)::integer as points
              from public.online_answers a2
              join public.online_cards c2 on c2.room_id = a2.room_id and c2.position = a2.position
              where a2.room_id = p_room
              group by c2.round_no, a2.user_id
            ) rp2
            where rp2.round_no = rp.round_no
          )
          and (
            select count(*)
            from (
              select sum(a3.points)::integer as points
              from public.online_answers a3
              join public.online_cards c3 on c3.room_id = a3.room_id and c3.position = a3.position
              where a3.room_id = p_room and c3.round_no = rp.round_no
              group by a3.user_id
            ) rp3
            where rp3.points = rp.points
          ) = 1
      ) w on w.user_id = p.user_id
      where p.room_id = p_room
      group by p.user_id
    ) s;
    select coalesce(max((value)::integer), 0) into v_best
    from jsonb_each_text(v_round_wins);
    select count(*) into v_winners
    from jsonb_each_text(v_round_wins)
    where value::integer = v_best and v_best > 0;
  else
    select max(score) into v_best from public.online_players where room_id = p_room;
    select count(*) into v_winners
    from public.online_players
    where room_id = p_room and score = v_best and v_best > 0;
  end if;

  for v_player in select * from public.online_players where room_id = p_room loop
    v_rw := coalesce((v_round_wins ->> v_player.user_id::text)::integer, 0);
    if r.mode = 'duel' and v_best > 0 then
      if v_rw = v_best and v_winners = 1 then
        v_result := 'win';
      elsif v_rw = v_best and v_winners > 1 then
        v_result := 'tie';
      else
        v_result := 'loss';
      end if;
    elsif v_winners > 1 and v_player.score = v_best then
      v_result := 'tie';
    elsif v_player.score = v_best and v_best > 0 then
      v_result := 'win';
    else
      v_result := 'loss';
    end if;
    select count(*) into v_correct
    from public.online_answers
    where room_id = p_room and user_id = v_player.user_id and correct;
    v_grant := private.grant_online(v_player.user_id, r.mode, v_result, coalesce(v_correct, 0));
    update public.online_players
    set xp_awarded = coalesce((v_grant ->> 'xp')::integer, 0)
    where room_id = p_room and user_id = v_player.user_id;
  end loop;

  select coalesce(jsonb_agg(jsonb_build_object(
    'user_id', p.user_id,
    'name', p.display_name,
    'avatar', p.avatar_emoji,
    'score', p.score,
    'correct', coalesce(a.correct, 0),
    'xp', p.xp_awarded,
    'round_wins', coalesce((v_round_wins ->> p.user_id::text)::integer, 0)
  ) order by coalesce((v_round_wins ->> p.user_id::text)::integer, 0) desc, p.score desc, p.display_name), '[]'::jsonb)
  into v_ranking
  from public.online_players p
  left join (
    select user_id, count(*) filter (where correct)::integer as correct
    from public.online_answers where room_id = p_room group by user_id
  ) a on a.user_id = p.user_id
  where p.room_id = p_room;

  update public.online_rooms
  set status = 'finished',
      summary = jsonb_build_object(
        'mode', r.mode,
        'ranking', v_ranking,
        'tie', v_winners > 1
      ),
      public_state = '{}'::jsonb,
      phase_ends = pg_catalog.now()
  where id = p_room;
end;
$$;

create or replace function private.pump_room(p_room uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.online_rooms;
  v_players integer;
  v_ready integer;
  v_connected integer;
  v_answered integer;
  v_next integer;
begin
  select * into r from public.online_rooms where id = p_room for update;
  if not found or r.status = 'finished' then
    return;
  end if;

  select count(*), count(*) filter (where ready), count(*) filter (where connected)
  into v_players, v_ready, v_connected
  from public.online_players where room_id = p_room;

  if r.status = 'lobby' then
    if v_players >= 2 and v_ready = v_players and v_players <= 20
       and (r.mode <> 'duel' or v_players = 2) then
      update public.online_rooms
      set status = 'countdown', phase_ends = pg_catalog.now() + interval '3 seconds'
      where id = p_room;
    end if;
    return;
  end if;

  if r.status = 'countdown' and pg_catalog.now() >= r.phase_ends then
    perform private.deal_online(p_room);
    perform private.open_online(p_room, 0);
    return;
  end if;

  if r.status = 'playing' then
    select count(*) into v_answered
    from public.online_answers
    where room_id = p_room and position = r.question_index;
    if pg_catalog.now() >= r.phase_ends or v_answered >= v_connected then
      perform private.close_online(p_room);
    end if;
    return;
  end if;

  if r.status = 'reveal' and pg_catalog.now() >= r.phase_ends then
    perform private.advance_online(p_room);
    return;
  end if;

  if r.status = 'round_result' and pg_catalog.now() >= r.phase_ends then
    select min(position) into v_next
    from public.online_cards
    where room_id = p_room and round_no = r.round_index + 1;
    if v_next is null then
      perform private.finish_online(p_room);
    else
      update public.online_rooms set round_index = round_index + 1 where id = p_room;
      perform private.open_online(p_room, v_next);
    end if;
  end if;
end;
$$;
