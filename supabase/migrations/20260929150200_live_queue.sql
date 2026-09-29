-- Online matchmaking only pairs people who are searching right now.
-- Private rooms stay on create_online_room and are not joinable from the queue.

alter table public.online_players
  add column if not exists seen_at timestamptz not null default now();

update public.online_players set seen_at = joined_at;

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
      'rematch_id', r.rematch_id,
      'ranked', r.ranked
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
  if r.ranked then
    raise exception 'Esta sala es una partida online. Busca rival desde Online.';
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

create or replace function private.online_sync(p_room uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.member_room(p_room);
  update public.online_players
  set seen_at = pg_catalog.now()
  where room_id = p_room and user_id = auth.uid();
  perform private.pump_room(p_room);
  return private.online_view(p_room);
end;
$$;

drop function if exists public.find_ranked_match(text);
drop function if exists private.find_ranked_match(text);

create or replace function private.find_ranked_match(p_mode text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_rating integer;
  v_profile public.profiles;
  v_mine uuid;
  v_status text;
  v_live integer;
  v_room uuid;
  v_code text;
  v_try integer := 0;
  v_cap integer;
begin
  if auth.uid() is null then
    raise exception 'Necesitas iniciar sesión';
  end if;
  if p_mode not in ('battle', 'quick', 'duel') then
    raise exception 'Modo no válido';
  end if;

  v_cap := case when p_mode = 'duel' then 2 else 12 end;
  select * into v_profile from public.profiles where id = auth.uid();
  v_rating := v_profile.rating;

  delete from public.online_rooms r
  where r.ranked
    and r.status = 'lobby'
    and not exists (
      select 1 from public.online_players p
      where p.room_id = r.id
        and p.user_id = auth.uid()
    )
    and not exists (
      select 1 from public.online_players p
      where p.room_id = r.id
        and p.connected
        and p.seen_at > pg_catalog.now() - interval '20 seconds'
    );

  select r.id, r.status
  into v_mine, v_status
  from public.online_rooms r
  join public.online_players p on p.room_id = r.id
  where p.user_id = auth.uid()
    and p.connected
    and r.ranked
    and r.mode = p_mode
    and r.status <> 'finished'
  order by r.created_at desc
  limit 1;

  if v_mine is not null and v_status <> 'lobby' then
    update public.online_players set seen_at = pg_catalog.now()
    where room_id = v_mine and user_id = auth.uid();
    return jsonb_build_object('room_id', v_mine, 'players', (
      select count(*) from public.online_players where room_id = v_mine and connected
    ), 'matched', true);
  end if;

  if v_mine is not null then
    perform 1 from public.online_rooms where id = v_mine for update;
    update public.online_players set seen_at = pg_catalog.now(), connected = true
    where room_id = v_mine and user_id = auth.uid();
    select count(*) into v_live
    from public.online_players
    where room_id = v_mine and connected and seen_at > pg_catalog.now() - interval '20 seconds';
    if v_live >= 2 then
      update public.online_players set ready = true where room_id = v_mine and connected;
      perform private.pump_room(v_mine);
      return jsonb_build_object('room_id', v_mine, 'players', v_live, 'matched', true);
    end if;
  end if;

  select r.id into v_room
  from public.online_rooms r
  join public.profiles h on h.id = r.host_id
  where r.ranked
    and r.status = 'lobby'
    and r.mode = p_mode
    and r.id is distinct from v_mine
    and exists (
      select 1 from public.online_players p
      where p.room_id = r.id
        and p.user_id <> auth.uid()
        and p.connected
        and p.seen_at > pg_catalog.now() - interval '20 seconds'
    )
    and (select count(*) from public.online_players p where p.room_id = r.id and p.connected) < v_cap
    and not exists (
      select 1 from public.online_players p where p.room_id = r.id and p.user_id = auth.uid()
    )
  order by case when abs(h.rating - v_rating) <= 250 then 0 else 1 end,
           abs(h.rating - v_rating),
           r.created_at
  limit 1
  for update of r skip locked;

  if v_room is not null then
    if v_mine is not null then
      delete from public.online_players where room_id = v_mine and user_id = auth.uid();
      delete from public.online_rooms r
      where r.id = v_mine
        and not exists (select 1 from public.online_players p where p.room_id = r.id);
    end if;
    insert into public.online_players (room_id, user_id, display_name, avatar_emoji, ready, seen_at)
    values (v_room, auth.uid(), v_profile.display_name, v_profile.avatar_emoji, true, pg_catalog.now());
    update public.online_players set ready = true
    where room_id = v_room and connected;
    perform private.pump_room(v_room);
    return jsonb_build_object(
      'room_id', v_room,
      'players', (select count(*) from public.online_players where room_id = v_room and connected),
      'matched', true
    );
  end if;

  if v_mine is not null then
    return jsonb_build_object('room_id', v_mine, 'players', 1, 'matched', false);
  end if;

  loop
    v_try := v_try + 1;
    v_code := private.room_code();
    exit when not exists (select 1 from public.online_rooms where code = v_code) or v_try > 8;
  end loop;

  insert into public.online_rooms (code, host_id, mode, seconds, ranked)
  values (v_code, auth.uid(), p_mode, case when p_mode = 'quick' then 8 else 12 end, true)
  returning id into v_room;

  insert into public.online_players (room_id, user_id, display_name, avatar_emoji, seen_at)
  values (v_room, auth.uid(), v_profile.display_name, v_profile.avatar_emoji, pg_catalog.now());

  return jsonb_build_object('room_id', v_room, 'players', 1, 'matched', false);
end;
$$;

create or replace function public.find_ranked_match(p_mode text)
returns jsonb
language sql
security invoker
set search_path = ''
as $$ select private.find_ranked_match(p_mode); $$;

revoke all on function public.find_ranked_match(text) from public, anon;
revoke all on function private.find_ranked_match(text) from public, anon;
grant execute on function public.find_ranked_match(text) to authenticated;
grant execute on function private.find_ranked_match(text) to authenticated;

notify pgrst, 'reload schema';
