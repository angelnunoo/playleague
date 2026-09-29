-- Only angelnuunoo@gmail.com can use the admin panel.

create or replace function private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from auth.users
    where id = auth.uid()
      and lower(email) = 'angelnuunoo@gmail.com'
  );
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
  if not private.is_admin() then
    raise exception 'El panel de administración no está disponible para esta cuenta';
  end if;
  perform set_config('keda.trusted', '1', true);
  update public.profiles set role = 'admin' where id = auth.uid();
  return true;
end;
$$;

create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_name text;
  v_base text;
  v_candidate text;
  n integer := 0;
  v_role text := 'user';
begin
  v_name := coalesce(nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''), 'Jugador');
  if char_length(v_name) > 32 then
    v_name := left(v_name, 32);
  end if;

  v_base := lower(coalesce(nullif(trim(new.raw_user_meta_data ->> 'username'), ''), 'jugador'));
  v_base := regexp_replace(v_base, '[^a-z0-9_]', '', 'g');
  if char_length(v_base) < 3 then
    v_base := 'jugador';
  end if;
  v_base := left(v_base, 16);
  v_candidate := v_base;

  while exists (select 1 from public.profiles where username = v_candidate) loop
    n := n + 1;
    v_candidate := left(v_base, 16) || n::text;
  end loop;

  if lower(new.email) = 'angelnuunoo@gmail.com' then
    v_role := 'admin';
  end if;

  insert into public.profiles (id, display_name, username, avatar_emoji, title, role)
  values (
    new.id,
    v_name,
    v_candidate,
    coalesce(nullif(new.raw_user_meta_data ->> 'avatar_emoji', ''), '😎'),
    'Novato',
    v_role
  );

  insert into public.user_stats (user_id) values (new.id);
  return new;
end;
$$;

grant execute on function private.handle_new_user() to supabase_auth_admin;

do $$
declare
  src text;
begin
  src := pg_get_functiondef('private.my_profile()'::regprocedure);
  src := replace(src, 'p.role = ''admin''', 'private.is_admin()');
  execute src;
end $$;

select set_config('keda.trusted', '1', true);

update public.profiles
set role = 'user'
where role = 'admin'
  and id not in (
    select id from auth.users where lower(email) = 'angelnuunoo@gmail.com'
  );

update public.profiles
set role = 'admin'
where id in (
  select id from auth.users where lower(email) = 'angelnuunoo@gmail.com'
);
