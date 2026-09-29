export type GameType = 'quiz' | 'impostor' | 'taboo' | 'quick'

export type Player = {
  id: string
  name: string
  is_host: boolean
  seat: number
  team_key: string | null
}

export type Team = {
  key: string
  name: string
  color: string
}

export type Category = {
  id: string
  slug: string
  name: string
  emoji: string
  sort: number
}

export type DraftPlayer = {
  name: string
  isHost: boolean
}

export type League = {
  slug: string
  name: string
  floor: number
  ceil: number
  color: string
}

export type ProfileBundle = {
  profile: {
    id: string
    username: string
    display_name: string
    avatar_emoji: string
    title: string
    xp: number
    level: number
    role: string
    rating?: number
    banner?: string
    frame?: string
  }
  league?: League
  stats: Record<string, number>
  progress: { level: number; xp: number; floor: number; ceil: number }
  best_category: string | null
  admin: boolean
}

export type OnlineMode = 'battle' | 'quick' | 'duel'

export type OnlinePlayer = {
  user_id: string
  name: string
  avatar: string
  ready: boolean
  connected: boolean
  score: number
  xp: number
  answered: boolean
}

export type OnlineState = {
  room: {
    id: string
    code: string
    mode: OnlineMode
    status: 'lobby' | 'countdown' | 'playing' | 'reveal' | 'round_result' | 'finished'
    host_id: string
    question_index: number
    round_index: number
    seconds: number
    phase_ends: string | null
    opened_at: string | null
    rematch_id: string | null
    ranked: boolean
  }
  server_now: string
  total: number
  you: { ready: boolean; score: number; xp: number; answered: boolean }
  players: OnlinePlayer[]
  question: {
    position: number
    round_no: number
    prompt: string
    emoji: string | null
    category: string | null
    answers: { id: string; text: string }[]
  } | null
  reveal: { correct_id?: string | null; correct_text?: string; prompt?: string } | null
  round: {
    round: number
    players: { user_id: string; name: string; avatar: string; round_points: number; correct: number }[]
  } | null
  summary: {
    mode: OnlineMode
    tie: boolean
    ranking: { user_id: string; name: string; avatar: string; score: number; correct: number; xp: number; round_wins: number }[]
  } | null
  answers: { user_id: string; correct: boolean; points: number; elapsed_ms: number; answer_id: string | null }[]
}

export type RecentMatch = {
  kind: 'local' | 'online'
  mode: string
  finished_at: string
  won: boolean
  result: 'win' | 'loss' | 'tie'
  xp: number
}

export type PlayerCard = {
  id: string
  username: string
  name: string
  avatar: string
  level: number
  xp: number
  rating: number
  rank: League
  last_seen: string
  wins: number
  games: number
  losses: number
  best_streak: number
  place?: number
}

export type SocialHome = {
  incoming: PlayerCard[]
  outgoing: PlayerCard[]
  friends: PlayerCard[]
}

export type FriendRanking = {
  sort: 'xp' | 'level' | 'wins'
  delta: number
  rows: PlayerCard[]
}

export type XpLine = { label: string; xp: number }

export type Summary = {
  game_type: GameType
  winner_label: string | null
  host_won: boolean
  xp: number
  xp_breakdown: XpLine[]
  achievements: { slug: string; name: string; emoji: string; xp: number }[]
  level: {
    before: number
    after: number
    xp_before: number
    xp: number
    floor: number
    ceil: number
    title: string
  }
  teams?: { team_key: string; name: string; color?: string; score: number; correct?: number; wrong?: number; forbidden?: number; passed?: number }[]
  quiz?: { correct: number; wrong: number; accuracy: number; best_player: string; best_category: string | null; questions: number }
  taboo?: { correct: number; failed: number; forbidden: number; best_player: string }
  quick?: { correct: number; wrong: number; best_streak: number; best_player: string; avg_ms: number }
  word?: string
  emoji?: string
  category?: string
  impostors?: string
  votes?: { voter: string; target: string }[]
  guess?: string | null
  guess_ok?: boolean | null
  discovered?: boolean
  winner_side?: string
  players?: { player_id: string; score: number; won: boolean; details: { name?: string } }[]
}

export type MatchState = {
  id: string
  game_type: GameType
  status: 'setup' | 'playing' | 'voting' | 'guessing' | 'finished'
  config: Record<string, unknown>
  xp_awarded: number
  summary: Summary | null
  players: Player[]
  quiz?: {
    questions: QuizQuestion[]
    responses: QuizResponse[]
    scores: { team_key: string; name: string; color: string; score: number }[]
    seconds: number
  }
  impostor?: {
    ready: boolean
    votes: number[]
    accused_seat: number | null
    accused_name: string | null
  }
  taboo?: {
    scores: Summary['teams']
    open_turn: { turn_index: number; player_id: string; player_name: string; team_key: string; started_at: string } | null
  }
  quick?: {
    alive: number[]
    events: { player_id: string; success: boolean; points: number; streak: number }[]
  }
}

export type QuizQuestion = {
  id: string
  position: number
  prompt: string
  difficulty: string
  category: string
  emoji: string
  answers: { id: string; text: string }[]
  opened: boolean
}

export type QuizResponse = {
  question_id: string
  player_id: string
  correct: boolean
  points: number
  correct_text: string
  answer_id: string | null
}

export type GameConfig = {
  teams?: Team[]
  question_count?: number
  seconds?: number
  difficulty?: string
  category_ids?: string[]
  rounds?: number
  impostor_count?: number
  discuss_seconds?: number
  mode?: 'individual' | 'elimination'
  questions_per_player?: number
}
