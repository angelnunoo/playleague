-- Gameplay RPCs. XP, stats and achievements are computed here, never from the client.

create or replace function private.load_game(p_game_id uuid)
returns public.games
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  g public.games;
begin
  if auth.uid() is null then
    raise exception 'Necesitas iniciar sesión';
  end if;
  select * into g from public.games where id = p_game_id;
  if not found then
    raise exception 'Partida no encontrada';
  end if;
  if g.host_id <> auth.uid() then
    raise exception 'No eres el anfitrión de esta partida';
  end if;
  return g;
end;
$$;

create or replace function private.uuid_list(p_value jsonb)
returns uuid[]
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_ids uuid[] := '{}'::uuid[];
  v_text text;
begin
  if p_value is null or jsonb_typeof(p_value) <> 'array' then
    return v_ids;
  end if;
  for v_text in select value from jsonb_array_elements_text(p_value) loop
    v_ids := v_ids || v_text::uuid;
  end loop;
  return v_ids;
exception when invalid_text_representation then
  raise exception 'Hay una categoría que no es válida';
end;
$$;

create or replace function private.clean_difficulty(p_value text)
returns text
language sql
immutable
set search_path = ''
as $$
  select case
    when p_value in ('easy', 'normal', 'hard', 'expert') then p_value
    else null
  end;
$$;

create or replace function private.players_json(p_game_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', p.id,
    'name', p.display_name,
    'is_host', p.is_host,
    'seat', p.seat,
    'team_key', p.team_key
  ) order by p.seat), '[]'::jsonb)
  from public.game_players p
  where p.game_id = p_game_id;
$$;

create or replace function private.quiz_answerer(p_game_id uuid, p_position integer)
returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_teams jsonb;
  v_team_count integer;
  v_team_key text;
  v_members integer;
  v_nth integer;
  v_player uuid;
begin
  select config -> 'teams' into v_teams from public.games where id = p_game_id;
  v_team_count := jsonb_array_length(v_teams);
  v_team_key := v_teams -> (p_position % v_team_count) ->> 'key';
  select count(*) into v_members
  from public.game_players
  where game_id = p_game_id and team_key = v_team_key;
  v_nth := (p_position / v_team_count) % v_members;
  select id into v_player
  from (
    select id, row_number() over (order by seat) - 1 as rn
    from public.game_players
    where game_id = p_game_id and team_key = v_team_key
  ) s
  where rn = v_nth;
  return v_player;
end;
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
    else 0
  end;
end;
$$;

-- ---------------------------------------------------------------------------
-- Progression
-- ---------------------------------------------------------------------------

create or replace function private.apply_progress(
  p_game_id uuid,
  p_host_won boolean,
  p_answer_streak integer,
  p_patch jsonb,
  p_results jsonb,
  p_display jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  g public.games;
  v_user uuid;
  v_xp_before integer;
  v_level_before integer;
  v_match_xp integer;
  v_win integer;
  v_mvp integer;
  v_answer_xp integer;
  v_old_streak integer;
  v_parts jsonb;
  v_streak_bonus integer;
  v_bonus integer := 0;
  v_new_xp integer;
  v_title text;
  v_break jsonb;
  v_unlocked jsonb := '[]'::jsonb;
  v_summary jsonb;
  ach public.achievements;
  v_value integer;
  v_already timestamptz;
begin
  if auth.uid() is null then
    raise exception 'Necesitas iniciar sesión';
  end if;

  select * into g from public.games where id = p_game_id for update;
  if not found then
    raise exception 'Partida no encontrada';
  end if;
  if g.host_id <> auth.uid() then
    raise exception 'No eres el anfitrión de esta partida';
  end if;
  if g.status = 'finished' then
    return g.summary;
  end if;

  v_user := g.host_id;
  select xp, level into v_xp_before, v_level_before
  from public.profiles where id = v_user;

  select current_streak into v_old_streak from public.user_stats where user_id = v_user;
  v_parts := private.progress_parts(
    p_host_won,
    v_old_streak,
    coalesce((p_patch ->> 'quiz_correct')::integer, 0)
      + coalesce((p_patch ->> 'quick_correct')::integer, 0)
      + coalesce((p_patch ->> 'taboo_correct')::integer, 0)
  );
  v_win := (v_parts ->> 'win')::integer;
  v_mvp := (v_parts ->> 'mvp')::integer;
  v_streak_bonus := (v_parts ->> 'streak')::integer;
  v_answer_xp := (v_parts ->> 'answers')::integer;
  v_match_xp := (v_parts ->> 'total')::integer;

  update public.user_stats s set
    games_played = s.games_played + 1,
    wins = s.wins + (case when p_host_won then 1 else 0 end),
    losses = s.losses + (case when p_host_won then 0 else 1 end),
    current_streak = case when p_host_won then s.current_streak + 1 else 0 end,
    best_streak = greatest(s.best_streak, case when p_host_won then s.current_streak + 1 else 0 end),
    quiz_played = s.quiz_played + coalesce((p_patch ->> 'quiz_played')::integer, 0),
    quiz_wins = s.quiz_wins + coalesce((p_patch ->> 'quiz_wins')::integer, 0),
    quiz_correct = s.quiz_correct + coalesce((p_patch ->> 'quiz_correct')::integer, 0),
    quiz_wrong = s.quiz_wrong + coalesce((p_patch ->> 'quiz_wrong')::integer, 0),
    quiz_best_streak = greatest(s.quiz_best_streak, coalesce((p_patch ->> 'quiz_best_streak')::integer, 0)),
    quiz_expert_correct = s.quiz_expert_correct + coalesce((p_patch ->> 'quiz_expert_correct')::integer, 0),
    quiz_perfect = s.quiz_perfect + coalesce((p_patch ->> 'quiz_perfect')::integer, 0),
    impostor_played = s.impostor_played + coalesce((p_patch ->> 'impostor_played')::integer, 0),
    impostor_times = s.impostor_times + coalesce((p_patch ->> 'impostor_times')::integer, 0),
    impostor_wins = s.impostor_wins + coalesce((p_patch ->> 'impostor_wins')::integer, 0),
    impostor_caught = s.impostor_caught + coalesce((p_patch ->> 'impostor_caught')::integer, 0),
    impostor_catches = s.impostor_catches + coalesce((p_patch ->> 'impostor_catches')::integer, 0),
    impostor_word_guesses = s.impostor_word_guesses + coalesce((p_patch ->> 'impostor_word_guesses')::integer, 0),
    taboo_played = s.taboo_played + coalesce((p_patch ->> 'taboo_played')::integer, 0),
    taboo_correct = s.taboo_correct + coalesce((p_patch ->> 'taboo_correct')::integer, 0),
    taboo_failed = s.taboo_failed + coalesce((p_patch ->> 'taboo_failed')::integer, 0),
    taboo_forbidden = s.taboo_forbidden + coalesce((p_patch ->> 'taboo_forbidden')::integer, 0),
    taboo_wins = s.taboo_wins + coalesce((p_patch ->> 'taboo_wins')::integer, 0),
    taboo_clean = s.taboo_clean + coalesce((p_patch ->> 'taboo_clean')::integer, 0),
    quick_played = s.quick_played + coalesce((p_patch ->> 'quick_played')::integer, 0),
    quick_correct = s.quick_correct + coalesce((p_patch ->> 'quick_correct')::integer, 0),
    quick_wrong = s.quick_wrong + coalesce((p_patch ->> 'quick_wrong')::integer, 0),
    quick_best_streak = greatest(s.quick_best_streak, coalesce((p_patch ->> 'quick_best_streak')::integer, 0)),
    quick_wins = s.quick_wins + coalesce((p_patch ->> 'quick_wins')::integer, 0),
    quick_time_total_ms = s.quick_time_total_ms + coalesce((p_patch ->> 'quick_time_ms')::bigint, 0),
    quick_time_count = s.quick_time_count + coalesce((p_patch ->> 'quick_time_count')::integer, 0),
    updated_at = now()
  where s.user_id = v_user;

  for ach in select * from public.achievements where active order by sort loop
    v_value := private.metric_of(v_user, ach.metric);
    select unlocked_at into v_already
    from public.user_achievements
    where user_id = v_user and achievement_id = ach.id;

    if v_already is null then
      insert into public.user_achievements as ua (user_id, achievement_id, progress, unlocked_at)
      values (
        v_user,
        ach.id,
        v_value,
        case when v_value >= ach.threshold then now() else null end
      )
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
      update public.user_achievements
      set progress = v_value
      where user_id = v_user and achievement_id = ach.id;
    end if;
  end loop;

  v_new_xp := v_xp_before + v_match_xp + v_bonus;

  select t.name into v_title
  from public.titles t
  left join public.achievements a on a.slug = t.achievement_slug
  left join public.user_achievements ua
    on ua.achievement_id = a.id
   and ua.user_id = v_user
   and ua.unlocked_at is not null
  where (
    t.achievement_slug is null
    and coalesce(t.min_level, 1) <= private.level_for_xp(v_new_xp)
  ) or ua.user_id is not null
  order by t.sort desc
  limit 1;

  perform set_config('keda.trusted', '1', true);
  update public.profiles
  set xp = v_new_xp,
      level = private.level_for_xp(v_new_xp),
      title = coalesce(v_title, title),
      updated_at = now()
  where id = v_user;

  insert into public.game_results (game_id, player_id, score, won, details)
  select p_game_id,
         (item ->> 'player_id')::uuid,
         coalesce((item ->> 'score')::integer, 0),
         coalesce((item ->> 'won')::boolean, false),
         coalesce(item -> 'details', '{}'::jsonb)
  from jsonb_array_elements(coalesce(p_results, '[]'::jsonb)) item;

  v_break := jsonb_build_array(jsonb_build_object('label', 'Participar', 'xp', 10));
  if v_win > 0 then
    v_break := v_break || jsonb_build_array(jsonb_build_object('label', 'Victoria', 'xp', v_win));
  end if;
  if v_mvp > 0 then
    v_break := v_break || jsonb_build_array(jsonb_build_object('label', 'MVP', 'xp', v_mvp));
  end if;
  if v_streak_bonus > 0 then
    v_break := v_break || jsonb_build_array(jsonb_build_object('label', 'Racha de victorias', 'xp', v_streak_bonus));
  end if;
  if v_answer_xp > 0 then
    v_break := v_break || jsonb_build_array(jsonb_build_object('label', 'Aciertos', 'xp', v_answer_xp));
  end if;
  if jsonb_array_length(v_unlocked) > 0 then
    v_break := v_break || (
      select jsonb_agg(jsonb_build_object('label', item ->> 'name', 'xp', (item ->> 'xp')::integer))
      from jsonb_array_elements(v_unlocked) item
    );
  end if;

  v_summary := coalesce(p_display, '{}'::jsonb) || jsonb_build_object(
    'host_won', p_host_won,
    'xp', v_match_xp + v_bonus,
    'xp_breakdown', v_break,
    'achievements', v_unlocked,
    'level', jsonb_build_object(
      'before', v_level_before,
      'after', private.level_for_xp(v_new_xp),
      'xp_before', v_xp_before,
      'xp', v_new_xp,
      'floor', private.xp_to_reach(private.level_for_xp(v_new_xp)),
      'ceil', private.xp_to_reach(private.level_for_xp(v_new_xp) + 1),
      'title', coalesce(v_title, 'Novato')
    )
  );

  update public.games
  set status = 'finished',
      summary = v_summary,
      xp_awarded = v_match_xp + v_bonus,
      finished_at = now()
  where id = p_game_id;

  return v_summary;
end;
$$;
