-- Shared progression, competitive ranks and friends.
-- XP and rank only change inside private functions.

alter table public.profiles
  add column if not exists last_seen timestamptz not null default now();

alter table public.online_rooms
  add column if not exists ranked boolean not null default false;

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
     or new.last_seen is distinct from old.last_seen
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

create or replace function private.league_for_rating(p_rating integer)
returns jsonb
language sql
immutable
set search_path = ''
as $$
  select case
    when p_rating >= 3200 then jsonb_build_object('slug', 'desafiante', 'name', 'Desafiante', 'floor', 3200, 'ceil', 3200, 'color', '#f5d76e')
    when p_rating >= 2500 then jsonb_build_object('slug', 'gran_maestro', 'name', 'Gran Maestro', 'floor', 2500, 'ceil', 3200, 'color', '#f0abfc')
    when p_rating >= 1900 then jsonb_build_object('slug', 'maestro', 'name', 'Maestro', 'floor', 1900, 'ceil', 2500, 'color', '#c4b5fd')
    when p_rating >= 1400 then jsonb_build_object('slug', 'diamante', 'name', 'Diamante', 'floor', 1400, 'ceil', 1900, 'color', '#7ee0ff')
    when p_rating >= 1000 then jsonb_build_object('slug', 'esmeralda', 'name', 'Esmeralda', 'floor', 1000, 'ceil', 1400, 'color', '#34d399')
    when p_rating >= 700 then jsonb_build_object('slug', 'platino', 'name', 'Platino', 'floor', 700, 'ceil', 1000, 'color', '#5eead4')
    when p_rating >= 450 then jsonb_build_object('slug', 'oro', 'name', 'Oro', 'floor', 450, 'ceil', 700, 'color', '#ffc53d')
    when p_rating >= 250 then jsonb_build_object('slug', 'plata', 'name', 'Plata', 'floor', 250, 'ceil', 450, 'color', '#d7deea')
    when p_rating >= 100 then jsonb_build_object('slug', 'bronce', 'name', 'Bronce', 'floor', 100, 'ceil', 250, 'color', '#e09756')
    else jsonb_build_object('slug', 'hierro', 'name', 'Hierro', 'floor', 0, 'ceil', 100, 'color', '#8d8d97')
  end;
$$;

create or replace function private.progress_parts(p_won boolean, p_old_streak integer, p_correct integer)
returns jsonb
language sql
immutable
set search_path = ''
as $$
  select jsonb_build_object(
    'participate', 10,
    'win', case when p_won then 100 else 0 end,
    'mvp', case when p_won then 50 else 0 end,
    'streak', case when p_won and coalesce(p_old_streak, 0) >= 2 then 25 else 0 end,
    'answers', least(greatest(coalesce(p_correct, 0), 0) * 2, 40),
    'total', least(
      10
      + case when p_won then 150 else 0 end
      + case when p_won and coalesce(p_old_streak, 0) >= 2 then 25 else 0 end
      + least(greatest(coalesce(p_correct, 0), 0) * 2, 40),
      280
    )
  );
$$;

create or replace function private.metric_of(p_user uuid, p_metric text)
returns integer
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  s public.user_stats;
begin
  select * into s from public.user_stats where user_id = p_user;
  if p_metric = 'level' then
    return coalesce((select level from public.profiles where id = p_user), 1);
  end if;
  if not found then
    return 0;
  end if;
  return case p_metric
    when 'games_played' then s.games_played
    when 'wins' then s.wins
    when 'best_streak' then s.best_streak
    when 'quiz_correct' then s.quiz_correct
    when 'quiz_played' then s.quiz_played
    when 'quiz_wins' then s.quiz_wins
    when 'quiz_expert_correct' then s.quiz_expert_correct
    when 'quiz_perfect' then s.quiz_perfect
    when 'answer_streak' then greatest(s.quiz_best_streak, s.quick_best_streak)
    when 'impostor_catches' then s.impostor_catches
    when 'impostor_wins' then s.impostor_wins
    when 'impostor_times' then s.impostor_times
    when 'impostor_word_guesses' then s.impostor_word_guesses
    when 'taboo_correct' then s.taboo_correct
    when 'taboo_wins' then s.taboo_wins
    when 'taboo_clean' then s.taboo_clean
    when 'quick_correct' then s.quick_correct
    when 'quick_best_streak' then s.quick_best_streak
    when 'quick_wins' then s.quick_wins
    when 'quick_played' then s.quick_played
    when 'correct_total' then s.quiz_correct + s.quick_correct + s.taboo_correct
    else 0
  end;
end;
$$;

create table if not exists public.friendships (
  requester uuid not null references public.profiles (id) on delete cascade,
  addressee uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted')),
  created_at timestamptz not null default now(),
  primary key (requester, addressee),
  check (requester <> addressee)
);

create table if not exists public.rank_marks (
  user_id uuid not null references public.profiles (id) on delete cascade,
  sort_key text not null,
  position integer not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, sort_key)
);

alter table public.friendships enable row level security;
alter table public.rank_marks enable row level security;
revoke all on public.friendships from anon, authenticated;
revoke all on public.rank_marks from anon, authenticated;
grant select on public.friendships to authenticated;

drop policy if exists friendships_select on public.friendships;
create policy friendships_select on public.friendships
  for select to authenticated
  using (requester = auth.uid() or addressee = auth.uid());

update public.achievements set name = 'Primer paso', description = 'Juega tu primera partida.' where slug = 'primera_quedada';

insert into public.achievements (slug, name, description, emoji, metric, threshold, xp_reward, game_type, sort) values
  ('primer_nivel', 'Primer nivel', 'Alcanza el nivel 2.', '⬆️', 'level', 2, 20, null, 15),
  ('centenaria', '100 victorias', 'Gana 100 partidas.', '💯', 'wins', 100, 150, null, 65),
  ('mil_respuestas', '1000 respuestas correctas', 'Acierta 1000 preguntas entre todos los juegos.', '📚', 'correct_total', 1000, 200, null, 95),
  ('campeon_quiz', 'Campeón del Quiz', 'Gana 25 quizzes.', '🧠', 'quiz_wins', 25, 80, 'quiz', 115),
  ('maestro_tabu', 'Maestro del Tabú', 'Gana 25 partidas de Tabú.', '🗣️', 'taboo_wins', 25, 80, 'taboo', 205)
on conflict (slug) do nothing;
