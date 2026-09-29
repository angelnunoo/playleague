-- Friends, ranked matchmaking and presence.

create or replace function private.touch_presence()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    return;
  end if;
  perform set_config('keda.trusted', '1', true);
  update public.profiles set last_seen = pg_catalog.now() where id = auth.uid();
end;
$$;

create or replace function private.player_card(p_user uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'id', p.id,
    'username', p.username,
    'name', p.display_name,
    'avatar', p.avatar_emoji,
    'level', p.level,
    'xp', p.xp,
    'rating', p.rating,
    'rank', private.league_for_rating(p.rating),
    'last_seen', p.last_seen,
    'wins', coalesce(s.wins, 0),
    'games', coalesce(s.games_played, 0),
    'losses', coalesce(s.losses, 0),
    'best_streak', coalesce(s.best_streak, 0)
  )
  from public.profiles p
  left join public.user_stats s on s.user_id = p.id
  where p.id = p_user;
$$;

create or replace function private.search_players(p_query text)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_q text := lower(trim(p_query));
begin
  if auth.uid() is null then
    raise exception 'Necesitas iniciar sesión';
  end if;
  if char_length(v_q) < 2 then
    return '[]'::jsonb;
  end if;
  return coalesce((
    select jsonb_agg(private.player_card(p.id))
    from (
      select id
      from public.profiles
      where id <> auth.uid()
        and (username ilike '%' || v_q || '%' or lower(display_name) ilike '%' || v_q || '%')
      order by username
      limit 12
    ) p
  ), '[]'::jsonb);
end;
$$;

create or replace function private.send_friend_request(p_username text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_other uuid;
begin
  if auth.uid() is null then
    raise exception 'Necesitas iniciar sesión';
  end if;
  select id into v_other from public.profiles where username = lower(trim(p_username));
  if v_other is null then
    raise exception 'No hay ningún jugador con ese usuario';
  end if;
  if v_other = auth.uid() then
    raise exception 'No puedes añadirte a ti mismo';
  end if;
  if exists (
    select 1 from public.friendships
    where status = 'accepted'
      and ((requester = auth.uid() and addressee = v_other) or (requester = v_other and addressee = auth.uid()))
  ) then
    return 'accepted';
  end if;
  if exists (
    select 1 from public.friendships
    where requester = v_other and addressee = auth.uid() and status = 'pending'
  ) then
    update public.friendships set status = 'accepted'
    where requester = v_other and addressee = auth.uid();
    return 'accepted';
  end if;
  insert into public.friendships (requester, addressee, status)
  values (auth.uid(), v_other, 'pending')
  on conflict (requester, addressee) do nothing;
  return 'pending';
end;
$$;

create or replace function private.respond_friend_request(p_user uuid, p_accept boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Necesitas iniciar sesión';
  end if;
  if p_accept then
    update public.friendships set status = 'accepted'
    where requester = p_user and addressee = auth.uid() and status = 'pending';
  else
    delete from public.friendships
    where requester = p_user and addressee = auth.uid() and status = 'pending';
  end if;
end;
$$;

create or replace function private.remove_friend(p_user uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Necesitas iniciar sesión';
  end if;
  delete from public.friendships
  where (requester = auth.uid() and addressee = p_user)
     or (requester = p_user and addressee = auth.uid());
end;
$$;

create or replace function private.social_home()
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
  return jsonb_build_object(
    'incoming', coalesce((
      select jsonb_agg(private.player_card(requester) order by created_at desc)
      from public.friendships where addressee = auth.uid() and status = 'pending'
    ), '[]'::jsonb),
    'outgoing', coalesce((
      select jsonb_agg(private.player_card(addressee) order by created_at desc)
      from public.friendships where requester = auth.uid() and status = 'pending'
    ), '[]'::jsonb),
    'friends', coalesce((
      select jsonb_agg(card order by card ->> 'name')
      from (
        select private.player_card(case when requester = auth.uid() then addressee else requester end) as card
        from public.friendships
        where status = 'accepted' and (requester = auth.uid() or addressee = auth.uid())
      ) f
    ), '[]'::jsonb)
  );
end;
$$;

create or replace function private.friend_card(p_username text)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_other uuid;
begin
  if auth.uid() is null then
    raise exception 'Necesitas iniciar sesión';
  end if;
  select id into v_other from public.profiles where username = lower(trim(p_username));
  if v_other is null then
    raise exception 'Ese jugador no existe';
  end if;
  if v_other <> auth.uid() and not exists (
    select 1 from public.friendships
    where status = 'accepted'
      and ((requester = auth.uid() and addressee = v_other) or (requester = v_other and addressee = auth.uid()))
  ) then
    raise exception 'Solo puedes ver el perfil de tus amigos';
  end if;
  return private.player_card(v_other);
end;
$$;

create or replace function private.friends_ranking(p_sort text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_sort text := case when p_sort in ('xp', 'level', 'wins') then p_sort else 'xp' end;
  v_rows jsonb;
  v_me integer;
  v_prev integer;
  v_anchor timestamptz;
begin
  if auth.uid() is null then
    raise exception 'Necesitas iniciar sesión';
  end if;

  with circle as (
    select auth.uid() as id
    union
    select case when requester = auth.uid() then addressee else requester end
    from public.friendships
    where status = 'accepted' and (requester = auth.uid() or addressee = auth.uid())
  ),
  ranked as (
    select c.id,
           row_number() over (
             order by case v_sort
               when 'wins' then coalesce(s.wins, 0)
               when 'level' then p.level
               else p.xp
             end desc, p.xp desc, p.display_name
           )::integer as place
    from circle c
    join public.profiles p on p.id = c.id
    left join public.user_stats s on s.user_id = p.id
  )
  select coalesce(jsonb_agg(
    private.player_card(r.id) || jsonb_build_object('place', r.place)
    order by r.place
  ), '[]'::jsonb),
  min(r.place) filter (where r.id = auth.uid())
  into v_rows, v_me
  from ranked r;

  select position, updated_at into v_prev, v_anchor
  from public.rank_marks
  where user_id = auth.uid() and sort_key = v_sort;

  if v_prev is null or v_anchor < pg_catalog.now() - interval '12 hours' then
    insert into public.rank_marks (user_id, sort_key, position, updated_at)
    values (auth.uid(), v_sort, coalesce(v_me, 1), pg_catalog.now())
    on conflict (user_id, sort_key) do update
      set position = excluded.position, updated_at = excluded.updated_at;
    v_prev := coalesce(v_me, 1);
  end if;

  return jsonb_build_object(
    'sort', v_sort,
    'delta', coalesce(v_prev, v_me) - coalesce(v_me, 1),
    'rows', v_rows
  );
end;
$$;

create or replace function private.find_ranked_match(p_mode text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_rating integer;
  v_room uuid;
  v_code text;
  v_try integer := 0;
  v_profile public.profiles;
begin
  if auth.uid() is null then
    raise exception 'Necesitas iniciar sesión';
  end if;
  if p_mode not in ('battle', 'quick', 'duel') then
    raise exception 'Modo no válido';
  end if;
  select rating into v_rating from public.profiles where id = auth.uid();

  select r.id into v_room
  from public.online_rooms r
  join public.profiles h on h.id = r.host_id
  where r.ranked
    and r.status = 'lobby'
    and r.mode = p_mode
    and abs(h.rating - v_rating) <= 250
    and (select count(*) from public.online_players p where p.room_id = r.id) < case when p_mode = 'duel' then 2 else 12 end
    and not exists (
      select 1 from public.online_players p where p.room_id = r.id and p.user_id = auth.uid()
    )
  order by abs(h.rating - v_rating), r.created_at
  limit 1
  for update skip locked;

  if v_room is not null then
    select * into v_profile from public.profiles where id = auth.uid();
    insert into public.online_players (room_id, user_id, display_name, avatar_emoji)
    values (v_room, auth.uid(), v_profile.display_name, v_profile.avatar_emoji);
    return v_room;
  end if;

  select * into v_profile from public.profiles where id = auth.uid();
  loop
    v_try := v_try + 1;
    v_code := private.room_code();
    exit when not exists (select 1 from public.online_rooms where code = v_code) or v_try > 8;
  end loop;
  insert into public.online_rooms (code, host_id, mode, seconds, ranked)
  values (v_code, auth.uid(), p_mode, case when p_mode = 'quick' then 8 else 12 end, true)
  returning id into v_room;
  insert into public.online_players (room_id, user_id, display_name, avatar_emoji)
  values (v_room, auth.uid(), v_profile.display_name, v_profile.avatar_emoji);
  return v_room;
end;
$$;

create or replace function public.touch_presence()
returns void language sql security invoker set search_path = '' as $$ select private.touch_presence(); $$;
create or replace function public.search_players(p_query text)
returns jsonb language sql security invoker set search_path = '' as $$ select private.search_players(p_query); $$;
create or replace function public.send_friend_request(p_username text)
returns text language sql security invoker set search_path = '' as $$ select private.send_friend_request(p_username); $$;
create or replace function public.respond_friend_request(p_user uuid, p_accept boolean)
returns void language sql security invoker set search_path = '' as $$ select private.respond_friend_request(p_user, p_accept); $$;
create or replace function public.remove_friend(p_user uuid)
returns void language sql security invoker set search_path = '' as $$ select private.remove_friend(p_user); $$;
create or replace function public.social_home()
returns jsonb language sql security invoker set search_path = '' as $$ select private.social_home(); $$;
create or replace function public.friend_card(p_username text)
returns jsonb language sql security invoker set search_path = '' as $$ select private.friend_card(p_username); $$;
create or replace function public.friends_ranking(p_sort text)
returns jsonb language sql security invoker set search_path = '' as $$ select private.friends_ranking(p_sort); $$;
create or replace function public.find_ranked_match(p_mode text)
returns uuid language sql security invoker set search_path = '' as $$ select private.find_ranked_match(p_mode); $$;

do $$
declare r record;
begin
  for r in
    select format('%I.%I(%s)', n.nspname, p.proname, pg_get_function_identity_arguments(p.oid)) as sig,
           n.nspname
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where (n.nspname = 'public' and p.proname in (
        'touch_presence', 'search_players', 'send_friend_request', 'respond_friend_request',
        'remove_friend', 'social_home', 'friend_card', 'friends_ranking', 'find_ranked_match'
      ))
       or (n.nspname = 'private' and p.proname in (
        'touch_presence', 'search_players', 'send_friend_request', 'respond_friend_request',
        'remove_friend', 'social_home', 'friend_card', 'friends_ranking', 'find_ranked_match', 'player_card'
      ))
  loop
    execute format('revoke all on function %s from public, anon', r.sig);
    execute format('grant execute on function %s to authenticated', r.sig);
  end loop;
end $$;

notify pgrst, 'reload schema';
