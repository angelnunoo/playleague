-- Online rooms, leagues and cosmetic profile fields.
-- Scoring, XP and rating only change inside private functions.

alter table public.profiles
  add column if not exists rating integer not null default 0,
  add column if not exists banner text not null default 'royal',
  add column if not exists frame text not null default 'none';

alter table public.profiles drop constraint if exists profiles_rating_nonnegative;
alter table public.profiles add constraint profiles_rating_nonnegative check (rating >= 0);
alter table public.profiles drop constraint if exists profiles_banner_known;
alter table public.profiles add constraint profiles_banner_known check (banner in ('royal', 'neon', 'sunset', 'pitch', 'aurora'));
alter table public.profiles drop constraint if exists profiles_frame_known;
alter table public.profiles add constraint profiles_frame_known check (frame in ('none', 'gold', 'fire', 'ice', 'diamond'));

create or replace function private.protect_profile()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if current_setting('keda.trusted', true) = '1' then
    return new;
  end if;

  new.username := lower(trim(new.username));
  new.display_name := trim(new.display_name);

  if new.role is distinct from old.role
     or new.xp is distinct from old.xp
     or new.level is distinct from old.level
     or new.title is distinct from old.title
     or new.rating is distinct from old.rating
     or new.id is distinct from old.id then
    raise exception 'No puedes modificar la progresión del perfil';
  end if;

  if new.username !~ '^[a-z0-9_]{3,20}$' then
    raise exception 'El usuario debe tener 3-20 caracteres: letras, números o _';
  end if;
  if char_length(new.display_name) < 1 or char_length(new.display_name) > 32 then
    raise exception 'El nombre debe tener entre 1 y 32 caracteres';
  end if;
  if char_length(new.avatar_emoji) < 1 or char_length(new.avatar_emoji) > 8 then
    raise exception 'Elige un avatar';
  end if;
  if new.banner not in ('royal', 'neon', 'sunset', 'pitch', 'aurora')
     or new.frame not in ('none', 'gold', 'fire', 'ice', 'diamond') then
    raise exception 'Elige un banner y un marco válidos';
  end if;

  new.updated_at := now();
  return new;
end;
$$;

grant update (banner, frame) on public.profiles to authenticated;

create or replace function private.league_for_rating(p_rating integer)
returns jsonb
language sql
immutable
set search_path = ''
as $$
  select case
    when p_rating >= 1100 then jsonb_build_object('slug', 'maestro', 'name', 'Maestro', 'floor', 1100, 'ceil', 1100, 'color', '#f5d76e')
    when p_rating >= 700 then jsonb_build_object('slug', 'diamante', 'name', 'Diamante', 'floor', 700, 'ceil', 1100, 'color', '#7ee0ff')
    when p_rating >= 400 then jsonb_build_object('slug', 'platino', 'name', 'Platino', 'floor', 400, 'ceil', 700, 'color', '#5eead4')
    when p_rating >= 200 then jsonb_build_object('slug', 'oro', 'name', 'Oro', 'floor', 200, 'ceil', 400, 'color', '#ffc53d')
    when p_rating >= 80 then jsonb_build_object('slug', 'plata', 'name', 'Plata', 'floor', 80, 'ceil', 200, 'color', '#d7deea')
    else jsonb_build_object('slug', 'bronce', 'name', 'Bronce', 'floor', 0, 'ceil', 80, 'color', '#e09756')
  end;
$$;

create table if not exists public.online_rooms (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  host_id uuid not null references public.profiles (id) on delete cascade,
  mode text not null check (mode in ('battle', 'quick', 'duel')),
  status text not null default 'lobby' check (status in ('lobby', 'countdown', 'playing', 'reveal', 'round_result', 'finished')),
  question_index integer not null default 0,
  round_index integer not null default 1,
  seconds integer not null,
  phase_ends timestamptz,
  opened_at timestamptz,
  public_state jsonb not null default '{}'::jsonb,
  summary jsonb,
  rematch_id uuid,
  created_at timestamptz not null default now()
);

create table if not exists public.online_players (
  room_id uuid not null references public.online_rooms (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  display_name text not null,
  avatar_emoji text not null default '😎',
  ready boolean not null default false,
  connected boolean not null default true,
  score integer not null default 0,
  xp_awarded integer not null default 0,
  joined_at timestamptz not null default now(),
  primary key (room_id, user_id)
);

create table if not exists public.online_cards (
  room_id uuid not null references public.online_rooms (id) on delete cascade,
  position integer not null,
  round_no integer not null default 1,
  prompt text not null,
  emoji text,
  category text,
  answers jsonb not null default '[]'::jsonb,
  correct_id uuid,
  primary key (room_id, position)
);

create table if not exists public.online_answers (
  room_id uuid not null references public.online_rooms (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  position integer not null,
  answer_id uuid,
  correct boolean not null default false,
  points integer not null default 0,
  elapsed_ms integer not null default 0,
  created_at timestamptz not null default now(),
  primary key (room_id, user_id, position)
);

create index if not exists online_players_user_idx on public.online_players (user_id);
create index if not exists online_answers_room_idx on public.online_answers (room_id, position);

alter table public.online_rooms enable row level security;
alter table public.online_players enable row level security;
alter table public.online_cards enable row level security;
alter table public.online_answers enable row level security;

drop policy if exists online_rooms_select on public.online_rooms;
create policy online_rooms_select on public.online_rooms
  for select to authenticated
  using (exists (
    select 1 from public.online_players p
    where p.room_id = id and p.user_id = auth.uid()
  ));

drop policy if exists online_players_select on public.online_players;
create policy online_players_select on public.online_players
  for select to authenticated
  using (exists (
    select 1 from public.online_players me
    where me.room_id = online_players.room_id and me.user_id = auth.uid()
  ));

drop policy if exists online_answers_select on public.online_answers;
create policy online_answers_select on public.online_answers
  for select to authenticated
  using (exists (
    select 1 from public.online_players me
    where me.room_id = online_answers.room_id and me.user_id = auth.uid()
  ));

revoke all on public.online_rooms from anon, authenticated;
revoke all on public.online_players from anon, authenticated;
revoke all on public.online_cards from anon, authenticated;
revoke all on public.online_answers from anon, authenticated;
grant select on public.online_rooms to authenticated;
grant select on public.online_players to authenticated;
grant select on public.online_answers to authenticated;

do $$
begin
  begin
    alter publication supabase_realtime add table public.online_rooms;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table public.online_players;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table public.online_answers;
  exception when duplicate_object then null;
  end;
end $$;

alter table public.online_rooms replica identity full;
alter table public.online_players replica identity full;
alter table public.online_answers replica identity full;
