import { supabase } from './supabase'
import type { Category, FriendRanking, GameConfig, GameType, MatchState, OnlineMode, OnlineState, PlayerCard, ProfileBundle, RecentMatch, SocialHome, Summary } from '../types'

export class ApiError extends Error {}

export async function rpc<T>(fn: string, args?: Record<string, unknown>): Promise<T> {
  const { data, error } = await supabase.rpc(fn, args)
  if (error) throw new ApiError(error.message)
  return data as T
}

export async function categories(table: 'quiz_categories' | 'impostor_categories' | 'taboo_categories' | 'quick_categories') {
  const { data, error } = await supabase.from(table).select('id, slug, name, emoji, sort').eq('active', true).order('sort')
  if (error) throw new ApiError(error.message)
  return (data ?? []) as Category[]
}

export const createMatch = (game: GameType, config: GameConfig, players: { name: string; is_host: boolean; team_key?: string }[]) =>
  rpc<string>('create_match', { p_game_type: game, p_config: config, p_players: players })

export const getMatch = (id: string) => rpc<MatchState>('get_match', { p_game_id: id })
export const myProfile = () => rpc<ProfileBundle>('my_profile')
export const drawQuiz = (id: string) => rpc<MatchState['quiz']>('draw_quiz', { p_game_id: id })
export const focusQuiz = (id: string, questionId: string) =>
  rpc<{ ok: boolean; player_id: string }>('focus_quiz', { p_game_id: id, p_question_id: questionId })
export const answerQuiz = (id: string, questionId: string, answerId: string | null) =>
  rpc<{ correct: boolean; points: number; correct_answer_id: string; correct_text: string; player_id: string; quiz: MatchState['quiz'] }>(
    'answer_quiz',
    { p_game_id: id, p_question_id: questionId, p_answer_id: answerId },
  )
export const finishMatch = (id: string) => rpc<Summary>('finish_match', { p_game_id: id })
export const prepareImpostor = (id: string) => rpc<{ ok: boolean }>('prepare_impostor', { p_game_id: id })
export const revealRole = (id: string, seat: number) =>
  rpc<{ seat: number; name: string; is_impostor: boolean; word: string | null; emoji: string | null; category: string | null }>(
    'reveal_role',
    { p_game_id: id, p_seat: seat },
  )
export const startVoting = (id: string) => rpc<{ ok: boolean }>('start_voting', { p_game_id: id })
export const castVote = (id: string, voter: number, target: number) =>
  rpc<{ complete: boolean; votes: number; players: number }>('cast_vote', { p_game_id: id, p_voter_seat: voter, p_target_seat: target })
export const resolveImpostor = (id: string) =>
  rpc<Summary | { phase: 'guess'; accused_seat: number; accused_name: string }>('resolve_impostor', { p_game_id: id })
export const impostorGuess = (id: string, guess: string) => rpc<Summary>('impostor_guess', { p_game_id: id, p_guess: guess })
export const startTabooTurn = (id: string) =>
  rpc<{ turn_index: number; total: number; seconds: number; player_id: string; player_name: string; team_key: string; team_name: string; scores: Summary['teams'] }>(
    'start_taboo_turn',
    { p_game_id: id },
  )
export const nextTabooCard = (id: string) =>
  rpc<{ empty: boolean; card_id?: string; card?: { word: string; emoji: string; forbidden: string[]; category: string }; player_id?: string }>(
    'next_taboo_card',
    { p_game_id: id },
  )
export const tabooMark = (id: string, result: 'correct' | 'forbidden' | 'pass') =>
  rpc<{ points: number; scores: Summary['teams'] }>('taboo_mark', { p_game_id: id, p_result: result })
export const endTabooTurn = (id: string) =>
  rpc<{ finished_rounds: boolean; scores: Summary['teams'] }>('end_taboo_turn', { p_game_id: id })
export const nextQuick = (id: string) =>
  rpc<{ prompt_id: string; prompt: string; emoji: string; category: string; player_id: string; player_name: string; seat: number; seconds: number }>(
    'next_quick',
    { p_game_id: id },
  )
export const quickMark = (id: string, success: boolean) =>
  rpc<{ success: boolean; points: number; streak: number; elapsed_ms: number; done: boolean; alive: number[] }>(
    'quick_mark',
    { p_game_id: id, p_success: success },
  )

export const createOnlineRoom = (mode: OnlineMode) => rpc<string>('create_online_room', { p_mode: mode })
export const joinOnlineRoom = (code: string) => rpc<string>('join_online_room', { p_code: code })
export const setOnlineReady = (id: string, ready: boolean) => rpc<OnlineState>('set_online_ready', { p_room: id, p_ready: ready })
export const onlineSync = (id: string) => rpc<OnlineState>('online_sync', { p_room: id })
export const onlineAnswer = (id: string, answerId: string | null) => rpc<OnlineState>('online_answer', { p_room: id, p_answer: answerId })
export const onlineRematch = (id: string) => rpc<string>('online_rematch', { p_room: id })
export const leaveOnlineRoom = (id: string) => rpc<void>('leave_online_room', { p_room: id })
export const myRecent = () => rpc<RecentMatch[]>('my_recent')
export const touchPresence = () => rpc<void>('touch_presence')
export const searchPlayers = (query: string) => rpc<PlayerCard[]>('search_players', { p_query: query })
export const sendFriendRequest = (username: string) => rpc<string>('send_friend_request', { p_username: username })
export const respondFriendRequest = (userId: string, accept: boolean) => rpc<void>('respond_friend_request', { p_user: userId, p_accept: accept })
export const removeFriend = (userId: string) => rpc<void>('remove_friend', { p_user: userId })
export const socialHome = () => rpc<SocialHome>('social_home')
export const friendCard = (username: string) => rpc<PlayerCard>('friend_card', { p_username: username })
export const friendsRanking = (sort: FriendRanking['sort']) => rpc<FriendRanking>('friends_ranking', { p_sort: sort })
export const findRankedMatch = (mode: OnlineMode) => rpc<{ room_id: string; players: number; matched: boolean }>('find_ranked_match', { p_mode: mode })

export const claimAdmin = () => rpc<boolean>('claim_admin')
export const adminExists = () => rpc<boolean>('admin_exists')
export const adminOverview = () => rpc<Record<string, number>>('admin_overview')
export const importQuiz = (rows: unknown[]) => rpc<number>('import_quiz', { p_rows: rows })
export const importImpostor = (rows: unknown[]) => rpc<number>('import_impostor', { p_rows: rows })
export const importTaboo = (rows: unknown[]) => rpc<number>('import_taboo', { p_rows: rows })
export const importQuick = (rows: unknown[]) => rpc<number>('import_quick', { p_rows: rows })
export const reviewSubmission = (id: string, status: 'approved' | 'rejected') =>
  rpc<{ ok: boolean; imported: number }>('review_submission', { p_id: id, p_status: status })
