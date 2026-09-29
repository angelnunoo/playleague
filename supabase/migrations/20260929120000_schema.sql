-- KEDA: party games schema. Sensitive writes go through private functions.

create extension if not exists unaccent with schema extensions;
create schema if not exists private;

revoke all on schema private from public;
grant usage on schema private to authenticated, service_role, supabase_auth_admin;

-- ---------------------------------------------------------------------------
-- Profiles and progression
-- ---------------------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text not null unique,
  display_name text not null,
  avatar_emoji text not null default '😎',
  title text not null default 'Novato',
  xp integer not null default 0,
  level integer not null default 1,
  role text not null default 'user' check (role in ('user', 'admin')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_username_format check (username ~ '^[a-z0-9_]{3,20}$'),
  constraint profiles_display_name_len check (char_length(display_name) between 1 and 32),
  constraint profiles_xp_nonnegative check (xp >= 0),
  constraint profiles_level_positive check (level >= 1)
);

create table public.user_stats (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  games_played integer not null default 0,
  wins integer not null default 0,
  losses integer not null default 0,
  current_streak integer not null default 0,
  best_streak integer not null default 0,
  quiz_played integer not null default 0,
  quiz_wins integer not null default 0,
  quiz_correct integer not null default 0,
  quiz_wrong integer not null default 0,
  quiz_best_streak integer not null default 0,
  quiz_expert_correct integer not null default 0,
  quiz_perfect integer not null default 0,
  impostor_played integer not null default 0,
  impostor_times integer not null default 0,
  impostor_wins integer not null default 0,
  impostor_caught integer not null default 0,
  impostor_catches integer not null default 0,
  impostor_word_guesses integer not null default 0,
  taboo_played integer not null default 0,
  taboo_correct integer not null default 0,
  taboo_failed integer not null default 0,
  taboo_forbidden integer not null default 0,
  taboo_wins integer not null default 0,
  taboo_clean integer not null default 0,
  quick_played integer not null default 0,
  quick_correct integer not null default 0,
  quick_wrong integer not null default 0,
  quick_best_streak integer not null default 0,
  quick_wins integer not null default 0,
  quick_time_total_ms bigint not null default 0,
  quick_time_count integer not null default 0,
  updated_at timestamptz not null default now()
);

create table public.titles (
  slug text primary key,
  name text not null,
  min_level integer,
  min_wins integer,
  achievement_slug text,
  sort integer not null unique
);

create table public.achievements (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  description text not null,
  emoji text not null,
  metric text not null,
  threshold integer not null check (threshold > 0),
  xp_reward integer not null default 25 check (xp_reward >= 0),
  game_type text,
  active boolean not null default true,
  sort integer not null default 0
);

create table public.user_achievements (
  user_id uuid not null references public.profiles (id) on delete cascade,
  achievement_id uuid not null references public.achievements (id) on delete cascade,
  progress integer not null default 0,
  unlocked_at timestamptz,
  primary key (user_id, achievement_id)
);

create table public.saved_configs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  game_type text not null check (game_type in ('quiz', 'impostor', 'taboo', 'quick')),
  name text not null check (char_length(name) between 1 and 40),
  config jsonb not null,
  created_at timestamptz not null default now()
);

create table public.content_submissions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  kind text not null check (kind in ('quiz', 'impostor', 'taboo', 'quick')),
  payload jsonb not null,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Matches
-- ---------------------------------------------------------------------------

create table public.games (
  id uuid primary key default gen_random_uuid(),
  host_id uuid not null references public.profiles (id) on delete cascade,
  game_type text not null check (game_type in ('quiz', 'impostor', 'taboo', 'quick')),
  status text not null default 'setup' check (status in ('setup', 'playing', 'voting', 'guessing', 'finished')),
  config jsonb not null default '{}'::jsonb,
  summary jsonb,
  xp_awarded integer not null default 0,
  created_at timestamptz not null default now(),
  finished_at timestamptz
);

create index games_host_created_idx on public.games (host_id, created_at desc);
create index games_status_idx on public.games (status);

create table public.game_players (
  id uuid primary key default gen_random_uuid(),
  game_id uuid not null references public.games (id) on delete cascade,
  user_id uuid references public.profiles (id) on delete set null,
  display_name text not null check (char_length(display_name) between 1 and 24),
  is_host boolean not null default false,
  seat integer not null check (seat >= 0),
  team_key text,
  unique (game_id, seat)
);

create index game_players_game_idx on public.game_players (game_id);

create table public.game_results (
  id uuid primary key default gen_random_uuid(),
  game_id uuid not null references public.games (id) on delete cascade,
  player_id uuid not null references public.game_players (id) on delete cascade,
  score integer not null default 0,
  won boolean not null default false,
  details jsonb not null default '{}'::jsonb,
  unique (game_id, player_id)
);

create index game_results_game_idx on public.game_results (game_id);

-- Cards dealt for one match. source_id points at the content row for that game.
create table public.match_cards (
  id uuid primary key default gen_random_uuid(),
  game_id uuid not null references public.games (id) on delete cascade,
  position integer not null check (position >= 0),
  source_id uuid not null,
  payload jsonb not null default '{}'::jsonb,
  assigned_player uuid references public.game_players (id) on delete set null,
  consumed boolean not null default false,
  opened_at timestamptz,
  unique (game_id, position)
);

create index match_cards_game_idx on public.match_cards (game_id, position);
create index match_cards_source_idx on public.match_cards (game_id, source_id);

-- ---------------------------------------------------------------------------
-- Quiz
-- ---------------------------------------------------------------------------

create table public.quiz_categories (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  emoji text not null,
  sort integer not null default 0,
  active boolean not null default true
);

create table public.quiz_questions (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.quiz_categories (id) on delete cascade,
  difficulty text not null check (difficulty in ('easy', 'normal', 'hard', 'expert')),
  prompt text not null check (char_length(prompt) between 8 and 300),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (category_id, prompt)
);

create index quiz_questions_filter_idx
  on public.quiz_questions (category_id, difficulty)
  where active;

create table public.quiz_answers (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.quiz_questions (id) on delete cascade,
  text text not null check (char_length(text) between 1 and 160),
  is_correct boolean not null default false,
  sort_order integer not null default 0
);

create index quiz_answers_question_idx on public.quiz_answers (question_id);

create table public.quiz_responses (
  id uuid primary key default gen_random_uuid(),
  game_id uuid not null references public.games (id) on delete cascade,
  question_id uuid not null,
  player_id uuid not null references public.game_players (id) on delete cascade,
  answer_id uuid,
  correct boolean not null,
  points integer not null default 0,
  elapsed_ms integer not null default 0,
  correct_text text,
  created_at timestamptz not null default now(),
  unique (game_id, question_id)
);

create index quiz_responses_game_idx on public.quiz_responses (game_id);

create table public.quiz_category_stats (
  user_id uuid not null references public.profiles (id) on delete cascade,
  category_id uuid not null references public.quiz_categories (id) on delete cascade,
  correct integer not null default 0,
  wrong integer not null default 0,
  primary key (user_id, category_id)
);

-- ---------------------------------------------------------------------------
-- Impostor
-- ---------------------------------------------------------------------------

create table public.impostor_categories (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  emoji text not null,
  sort integer not null default 0,
  active boolean not null default true
);

create table public.impostor_words (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.impostor_categories (id) on delete cascade,
  word text not null,
  emoji text not null default '🕵️',
  difficulty text not null default 'normal' check (difficulty in ('easy', 'normal', 'hard', 'expert')),
  active boolean not null default true,
  unique (category_id, word)
);

create index impostor_words_filter_idx
  on public.impostor_words (category_id, difficulty)
  where active;

create table public.impostor_secrets (
  game_id uuid primary key references public.games (id) on delete cascade,
  word_id uuid not null,
  word text not null,
  emoji text,
  category_name text,
  impostor_seats integer[] not null,
  accused_seat integer,
  guess text,
  guess_ok boolean,
  winner_side text check (winner_side is null or winner_side in ('impostors', 'citizens'))
);

create table public.impostor_votes (
  game_id uuid not null references public.games (id) on delete cascade,
  voter_seat integer not null,
  target_seat integer not null,
  primary key (game_id, voter_seat)
);

-- ---------------------------------------------------------------------------
-- Taboo
-- ---------------------------------------------------------------------------

create table public.taboo_categories (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  emoji text not null,
  sort integer not null default 0,
  active boolean not null default true
);

create table public.taboo_cards (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.taboo_categories (id) on delete cascade,
  word text not null,
  emoji text not null default '🗣️',
  forbidden text[] not null check (cardinality(forbidden) >= 3),
  difficulty text not null default 'normal' check (difficulty in ('easy', 'normal', 'hard', 'expert')),
  active boolean not null default true,
  unique (category_id, word)
);

create index taboo_cards_filter_idx
  on public.taboo_cards (category_id)
  where active;

create table public.taboo_turns (
  id uuid primary key default gen_random_uuid(),
  game_id uuid not null references public.games (id) on delete cascade,
  turn_index integer not null,
  player_id uuid not null references public.game_players (id) on delete cascade,
  team_key text not null,
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  unique (game_id, turn_index)
);

create table public.taboo_events (
  id uuid primary key default gen_random_uuid(),
  game_id uuid not null references public.games (id) on delete cascade,
  card_id uuid not null,
  player_id uuid not null references public.game_players (id) on delete cascade,
  team_key text not null,
  result text not null check (result in ('correct', 'forbidden', 'pass')),
  points integer not null,
  created_at timestamptz not null default now(),
  unique (game_id, card_id)
);

create index taboo_events_game_idx on public.taboo_events (game_id);

-- ---------------------------------------------------------------------------
-- Quick answers
-- ---------------------------------------------------------------------------

create table public.quick_categories (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  emoji text not null,
  sort integer not null default 0,
  active boolean not null default true
);

create table public.quick_questions (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.quick_categories (id) on delete cascade,
  prompt text not null check (char_length(prompt) between 8 and 200),
  difficulty text not null default 'normal' check (difficulty in ('easy', 'normal', 'hard', 'expert')),
  active boolean not null default true,
  unique (category_id, prompt)
);

create index quick_questions_filter_idx
  on public.quick_questions (category_id)
  where active;

create table public.quick_events (
  id uuid primary key default gen_random_uuid(),
  game_id uuid not null references public.games (id) on delete cascade,
  prompt_id uuid not null,
  player_id uuid not null references public.game_players (id) on delete cascade,
  success boolean not null,
  points integer not null default 0,
  streak integer not null default 0,
  elapsed_ms integer not null default 0,
  created_at timestamptz not null default now(),
  unique (game_id, prompt_id)
);

create index quick_events_game_idx on public.quick_events (game_id, created_at);

-- ---------------------------------------------------------------------------
-- Progression helpers
-- ---------------------------------------------------------------------------

create or replace function private.level_for_xp(p_xp integer)
returns integer
language sql
immutable
set search_path = ''
as $$
  select greatest(1, floor(
    (-1 + sqrt(1 + 4 * ((greatest(p_xp, 0) + 50)::numeric / 25))) / 2
  )::integer);
$$;

create or replace function private.xp_to_reach(p_level integer)
returns integer
language sql
immutable
set search_path = ''
as $$
  select case
    when p_level <= 1 then 0
    else (25 * p_level * (p_level + 1) - 50)
  end;
$$;

create or replace function private.fold(p_text text)
returns text
language sql
stable
set search_path = ''
as $$
  select regexp_replace(
    regexp_replace(
      lower(trim(extensions.unaccent(coalesce(p_text, '')))),
      '^(el|la|los|las|un|una|unos|unas)\s+',
      ''
    ),
    '[^a-z0-9]',
    '',
    'g'
  );
$$;

create or replace function private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'admin'
  );
$$;

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

  new.updated_at := now();
  return new;
end;
$$;

create trigger profiles_protect
  before update on public.profiles
  for each row execute function private.protect_profile();

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

  insert into public.profiles (id, display_name, username, avatar_emoji, title)
  values (
    new.id,
    v_name,
    v_candidate,
    coalesce(nullif(new.raw_user_meta_data ->> 'avatar_emoji', ''), '😎'),
    'Novato'
  );

  insert into public.user_stats (user_id) values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_user();

grant execute on function private.handle_new_user() to supabase_auth_admin;

create or replace function private.limit_saved_configs()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if (select count(*) from public.saved_configs where user_id = new.user_id) >= 20 then
    raise exception 'Solo puedes guardar 20 configuraciones';
  end if;
  return new;
end;
$$;

create trigger saved_configs_limit
  before insert on public.saved_configs
  for each row execute function private.limit_saved_configs();

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.user_stats enable row level security;
alter table public.titles enable row level security;
alter table public.achievements enable row level security;
alter table public.user_achievements enable row level security;
alter table public.saved_configs enable row level security;
alter table public.content_submissions enable row level security;
alter table public.games enable row level security;
alter table public.game_players enable row level security;
alter table public.game_results enable row level security;
alter table public.match_cards enable row level security;
alter table public.quiz_categories enable row level security;
alter table public.quiz_questions enable row level security;
alter table public.quiz_answers enable row level security;
alter table public.quiz_responses enable row level security;
alter table public.quiz_category_stats enable row level security;
alter table public.impostor_categories enable row level security;
alter table public.impostor_words enable row level security;
alter table public.impostor_secrets enable row level security;
alter table public.impostor_votes enable row level security;
alter table public.taboo_categories enable row level security;
alter table public.taboo_cards enable row level security;
alter table public.taboo_turns enable row level security;
alter table public.taboo_events enable row level security;
alter table public.quick_categories enable row level security;
alter table public.quick_questions enable row level security;
alter table public.quick_events enable row level security;

alter table public.profiles force row level security;
alter table public.user_stats force row level security;
alter table public.games force row level security;
alter table public.quiz_questions force row level security;
alter table public.quiz_answers force row level security;
alter table public.impostor_secrets force row level security;

create policy profiles_select on public.profiles
  for select to authenticated
  using (true);

create policy profiles_update on public.profiles
  for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

create policy stats_select on public.user_stats
  for select to authenticated
  using (user_id = auth.uid() or private.is_admin());

create policy titles_select on public.titles
  for select to authenticated
  using (true);

create policy achievements_select on public.achievements
  for select to authenticated
  using (active or private.is_admin());

create policy achievements_admin on public.achievements
  for all to authenticated
  using (private.is_admin())
  with check (private.is_admin());

create policy user_achievements_select on public.user_achievements
  for select to authenticated
  using (user_id = auth.uid() or private.is_admin());

create policy saved_configs_all on public.saved_configs
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy submissions_insert on public.content_submissions
  for insert to authenticated
  with check (user_id = auth.uid() and status = 'pending');

create policy submissions_select on public.content_submissions
  for select to authenticated
  using (user_id = auth.uid() or private.is_admin());

create policy submissions_admin on public.content_submissions
  for update to authenticated
  using (private.is_admin())
  with check (private.is_admin());

create policy games_select on public.games
  for select to authenticated
  using (host_id = auth.uid() or private.is_admin());

create policy game_players_select on public.game_players
  for select to authenticated
  using (
    exists (
      select 1 from public.games g
      where g.id = game_id
        and (g.host_id = auth.uid() or private.is_admin())
    )
  );

create policy game_results_select on public.game_results
  for select to authenticated
  using (
    exists (
      select 1 from public.games g
      where g.id = game_id
        and (g.host_id = auth.uid() or private.is_admin())
    )
  );

create policy category_stats_select on public.quiz_category_stats
  for select to authenticated
  using (user_id = auth.uid() or private.is_admin());

-- Content catalogs: players read active rows. Admins manage everything.
create policy quiz_categories_read on public.quiz_categories
  for select to authenticated using (active or private.is_admin());
create policy quiz_categories_admin on public.quiz_categories
  for all to authenticated using (private.is_admin()) with check (private.is_admin());

create policy quiz_questions_admin on public.quiz_questions
  for all to authenticated using (private.is_admin()) with check (private.is_admin());

create policy quiz_answers_admin on public.quiz_answers
  for all to authenticated using (private.is_admin()) with check (private.is_admin());

create policy impostor_categories_read on public.impostor_categories
  for select to authenticated using (active or private.is_admin());
create policy impostor_categories_admin on public.impostor_categories
  for all to authenticated using (private.is_admin()) with check (private.is_admin());

create policy impostor_words_admin on public.impostor_words
  for all to authenticated using (private.is_admin()) with check (private.is_admin());

create policy taboo_categories_read on public.taboo_categories
  for select to authenticated using (active or private.is_admin());
create policy taboo_categories_admin on public.taboo_categories
  for all to authenticated using (private.is_admin()) with check (private.is_admin());

create policy taboo_cards_admin on public.taboo_cards
  for all to authenticated using (private.is_admin()) with check (private.is_admin());

create policy quick_categories_read on public.quick_categories
  for select to authenticated using (active or private.is_admin());
create policy quick_categories_admin on public.quick_categories
  for all to authenticated using (private.is_admin()) with check (private.is_admin());

create policy quick_questions_admin on public.quick_questions
  for all to authenticated using (private.is_admin()) with check (private.is_admin());

revoke all on public.profiles from anon, authenticated;
grant select on public.profiles to authenticated;
grant update (display_name, username, avatar_emoji) on public.profiles to authenticated;

revoke insert, update, delete on public.user_stats from anon, authenticated;
revoke insert, update, delete on public.games from anon, authenticated;
revoke insert, update, delete on public.game_players from anon, authenticated;
revoke insert, update, delete on public.game_results from anon, authenticated;
revoke insert, update, delete on public.user_achievements from anon, authenticated;
revoke insert, update, delete on public.quiz_responses from anon, authenticated;
revoke insert, update, delete on public.quiz_category_stats from anon, authenticated;

-- ---------------------------------------------------------------------------
-- Catalog, titles, achievements
-- ---------------------------------------------------------------------------

insert into public.titles (slug, name, min_level, sort) values
  ('novato', 'Novato', 1, 10),
  ('de_la_mesa', 'De la mesa', 3, 20),
  ('anfitrion', 'Anfitrión', 5, 30),
  ('imparable', 'Imparable', 8, 40),
  ('leyenda', 'Leyenda', 12, 50),
  ('mito', 'Mito', 16, 60),
  ('inmortal', 'Inmortal', 20, 70);

insert into public.titles (slug, name, achievement_slug, sort) values
  ('titulo_sherlock', 'Sherlock', 'sherlock', 80),
  ('titulo_engano', 'Maestro del engaño', 'maestro_engano', 90),
  ('titulo_campeon', 'Campeón', 'campeon', 100);

insert into public.achievements (slug, name, description, emoji, metric, threshold, xp_reward, game_type, sort) values
  ('primera_quedada', 'Primera quedada', 'Juega tu primera partida.', '🎮', 'games_played', 1, 10, null, 10),
  ('anfitrion_fiel', 'Anfitrión fiel', 'Juega 10 partidas.', '👑', 'games_played', 10, 30, null, 20),
  ('veterano', 'Veterano', 'Juega 100 partidas.', '🎮', 'games_played', 100, 100, null, 30),
  ('primera_victoria', 'Primera victoria', 'Gana tu primera partida.', '🏅', 'wins', 1, 15, null, 40),
  ('campeon', 'Campeón', 'Gana 25 partidas.', '🏆', 'wins', 25, 80, null, 50),
  ('leyenda_mesa', 'Leyenda de la mesa', 'Gana 50 partidas.', '👑', 'wins', 50, 120, null, 60),
  ('en_racha', 'En racha', 'Consigue 5 victorias seguidas.', '🔥', 'best_streak', 5, 40, null, 70),
  ('racha_victorias', 'Dinastía', 'Consigue 10 victorias seguidas.', '🔥', 'best_streak', 10, 80, null, 80),
  ('cerebrito', 'Cerebrito', 'Acierta 100 preguntas de quiz.', '🧠', 'quiz_correct', 100, 70, 'quiz', 90),
  ('raton_quiz', 'Ratón de biblioteca', 'Juega 10 quizzes.', '📚', 'quiz_played', 10, 30, 'quiz', 100),
  ('quiz_winner', 'Cerebro del grupo', 'Gana 5 quizzes.', '🧠', 'quiz_wins', 5, 40, 'quiz', 110),
  ('experto', 'Modo experto', 'Acierta 25 preguntas de dificultad experto.', '💀', 'quiz_expert_correct', 25, 50, 'quiz', 120),
  ('perfeccion', 'Sin fallo', 'Termina un quiz de 10 o más preguntas sin fallos.', '✨', 'quiz_perfect', 1, 60, 'quiz', 130),
  ('imparable', 'Imparable', 'Consigue una racha de 10 respuestas correctas.', '🔥', 'answer_streak', 10, 70, null, 140),
  ('sherlock', 'Sherlock', 'Descubre al impostor 10 veces.', '🕵️', 'impostor_catches', 10, 70, 'impostor', 150),
  ('maestro_engano', 'Maestro del engaño', 'Gana 10 partidas como impostor.', '😈', 'impostor_wins', 10, 80, 'impostor', 160),
  ('infiltrado', 'Infiltrado', 'Sé el impostor 5 veces.', '🎭', 'impostor_times', 5, 25, 'impostor', 170),
  ('palabra_magica', 'Palabra mágica', 'Adivina la palabra secreta 3 veces.', '🔮', 'impostor_word_guesses', 3, 40, 'impostor', 180),
  ('hablador', 'Hablador', 'Consigue 100 palabras en Tabú.', '🗣️', 'taboo_correct', 100, 70, 'taboo', 190),
  ('lengua_suelta', 'Lengua suelta', 'Gana 10 partidas de Tabú.', '🗣️', 'taboo_wins', 10, 50, 'taboo', 200),
  ('boca_limpia', 'Boca limpia', 'Termina un Tabú con 5 aciertos y ninguna palabra prohibida.', '🧼', 'taboo_clean', 1, 40, 'taboo', 210),
  ('rapido', 'Rápido', 'Completa 20 respuestas rápidas.', '⚡', 'quick_correct', 20, 40, 'quick', 220),
  ('relampago', 'Relámpago', 'Consigue una racha de 10 en Responde rápido.', '⚡', 'quick_best_streak', 10, 70, 'quick', 230),
  ('superviviente', 'Superviviente', 'Gana 5 partidas de Responde rápido.', '🏁', 'quick_wins', 5, 40, 'quick', 240),
  ('maraton', 'Maratón', 'Juega 15 partidas de Responde rápido.', '⏱️', 'quick_played', 15, 30, 'quick', 250);

insert into public.quiz_categories (slug, name, emoji, sort) values
  ('futbol', 'Fútbol', '⚽', 10),
  ('videojuegos', 'Videojuegos', '🎮', 20),
  ('cine', 'Cine y series', '🎬', 30),
  ('musica', 'Música', '🎵', 40),
  ('geografia', 'Geografía', '🌎', 50),
  ('historia', 'Historia', '📚', 60),
  ('ciencia', 'Ciencia', '🔬', 70),
  ('cultura', 'Cultura general', '🧠', 80),
  ('tecnologia', 'Tecnología', '💻', 90),
  ('marvel', 'Marvel', '🦸', 100),
  ('f1', 'Fórmula 1', '🏎️', 110),
  ('deportes', 'Deportes', '🏀', 120),
  ('espana', 'España', '🇪🇸', 130),
  ('internet', 'Internet', '😂', 140);

insert into public.impostor_categories (slug, name, emoji, sort) values
  ('comida', 'Comida', '🍕', 10),
  ('animales', 'Animales', '🐶', 20),
  ('objetos', 'Objetos', '📦', 30),
  ('lugares', 'Lugares', '📍', 40),
  ('profesiones', 'Profesiones', '👷', 50),
  ('famosos', 'Famosos', '🌟', 60),
  ('deportes', 'Deportes', '🏀', 70),
  ('marcas', 'Marcas', '🏷️', 80);

insert into public.taboo_categories (slug, name, emoji, sort) values
  ('comida', 'Comida', '🍕', 10),
  ('animales', 'Animales', '🐶', 20),
  ('objetos', 'Objetos', '📦', 30),
  ('lugares', 'Lugares', '📍', 40),
  ('deportes', 'Deportes', '🏅', 50),
  ('famosos', 'Famosos', '🌟', 60),
  ('casa', 'En casa', '🏠', 70),
  ('ciudad', 'Por la ciudad', '🏙️', 80);

insert into public.quick_categories (slug, name, emoji, sort) values
  ('paises', 'Países', '🌍', 10),
  ('futbolistas', 'Futbolistas', '⚽', 20),
  ('coches', 'Marcas de coches', '🚗', 30),
  ('videojuegos', 'Videojuegos', '🎮', 40),
  ('marvel', 'Marvel', '🦸', 50),
  ('animales', 'Animales', '🐾', 60),
  ('ciudades', 'Ciudades de España', '🇪🇸', 70),
  ('comidas', 'Comidas', '🍜', 80),
  ('profesiones', 'Profesiones', '🧑‍🔧', 90),
  ('musica', 'Música', '🎵', 100);
