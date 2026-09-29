import { useEffect, useRef, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useAuth } from '../auth/AuthProvider'
import { Confetti } from '../components/Fx'
import { Banner, Button } from '../components/ui'
import { createOnlineRoom, leaveOnlineRoom, onlineAnswer, onlineRematch, onlineSync, setOnlineReady } from '../lib/api'
import { supabase } from '../lib/supabase'
import { playLose, playWin } from '../lib/sound'
import type { OnlinePlayer, OnlineState } from '../types'

const titles = { battle: 'Quiz Battle', quick: 'Responde rápido', duel: 'Duelo' }

export function RoomPage() {
  const { id = '' } = useParams()
  const navigate = useNavigate()
  const { profile, refresh } = useAuth()
  const [state, setState] = useState<OnlineState | null>(null)
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)
  const celebrated = useRef(false)
  const ranks = useRef<Record<string, number>>({})
  const startLevel = useRef<number | null>(null)

  useEffect(() => {
    if (profile && startLevel.current === null) startLevel.current = profile.profile.level
  }, [profile])

  useEffect(() => {
    let stop = false
    async function pull() {
      try {
        const next = await onlineSync(id)
        if (!stop) setState(next)
      } catch (caught) {
        if (!stop) setError(caught instanceof Error ? caught.message : 'No se pudo sincronizar')
      }
    }
    pull()
    const timer = window.setInterval(pull, 900)
    const channel = supabase
      .channel(`room-${id}`)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'online_rooms', filter: `id=eq.${id}` }, pull)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'online_players', filter: `room_id=eq.${id}` }, pull)
      .subscribe()
    return () => {
      stop = true
      window.clearInterval(timer)
      supabase.removeChannel(channel)
    }
  }, [id])

  useEffect(() => {
    if (state?.room.status !== 'finished' || celebrated.current || !profile) return
    celebrated.current = true
    const mine = state.summary?.ranking.find((row) => row.user_id === profile.profile.id)
    const top = state.summary?.ranking[0]
    if (state.summary?.tie) return
    if (mine && top && mine.user_id === top.user_id && mine.score > 0) playWin()
    else playLose()
    refresh()
  }, [state?.room.status, state?.summary, profile, refresh])

  if (!state) {
    return error ? <Banner text={error} /> : <p className="font-display text-2xl">Entrando a la sala…</p>
  }

  const ranked = [...state.players].sort((a, b) => b.score - a.score || a.name.localeCompare(b.name))
  const movement: Record<string, boolean> = {}
  ranked.forEach((player, index) => {
    const previous = ranks.current[player.user_id]
    movement[player.user_id] = previous !== undefined && index < previous
  })
  ranks.current = Object.fromEntries(ranked.map((player, index) => [player.user_id, index]))

  async function ready() {
    setBusy(true)
    setError('')
    try {
      setState(await setOnlineReady(id, !state!.you.ready))
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'No se pudo marcar')
    } finally {
      setBusy(false)
    }
  }

  async function answer(answerId: string | null) {
    if (state?.you.answered) return
    setError('')
    try {
      setState(await onlineAnswer(id, answerId))
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'No se pudo enviar')
    }
  }

  async function again() {
    if (!state) return
    if (state.room.ranked) {
      navigate(`/online?cola=${state.room.mode}`)
      return
    }
    const next = await createOnlineRoom(state.room.mode)
    navigate(`/sala/${next}`)
  }

  async function rematch() {
    const next = await onlineRematch(id)
    navigate(`/sala/${next}`)
  }

  async function leave() {
    await leaveOnlineRoom(id).catch(() => undefined)
    navigate('/online')
  }

  const status = state.room.status
  const mine = state.answers.find((row) => row.user_id === profile?.profile.id)
  const won = Boolean(state.summary && !state.summary.tie && state.summary.ranking[0]?.user_id === profile?.profile.id && state.summary.ranking[0].score > 0)

  return (
    <div className="mx-auto grid w-full max-w-lg gap-4">
      <Confetti show={status === 'finished' && won} />
      <header className="flex items-center justify-between gap-3">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.18em] text-quick">{titles[state.room.mode]}</p>
          <p className="font-display text-3xl font-extrabold tracking-[0.28em]">{state.room.ranked ? 'En línea' : state.room.code}</p>
        </div>
        <button type="button" className="rounded-xl bg-white/10 px-3 py-2 text-sm font-bold" onClick={leave}>Salir</button>
      </header>
      {error ? <Banner text={error} /> : null}

      {status === 'lobby' ? (
        <Lobby state={state} busy={busy} onReady={ready} />
      ) : null}
      {status === 'countdown' ? <Countdown state={state} /> : null}
      {status === 'playing' || status === 'reveal' ? (
        <Question state={state} you={profile?.profile.id} mineCorrect={mine?.correct} minePoints={mine?.points} onAnswer={answer} />
      ) : null}
      {status === 'round_result' && state.round ? <RoundResult state={state} /> : null}
      {status === 'finished' && state.summary ? (
        <Final
          state={state}
          won={won}
          you={profile?.profile.id}
          leveled={startLevel.current !== null && (profile?.profile.level ?? 0) > startLevel.current}
          level={profile?.profile.level ?? 1}
          onAgain={again}
          onRematch={rematch}
        />
      ) : null}
      {status !== 'finished' ? <Ranking players={ranked} movement={movement} you={profile?.profile.id} /> : null}
    </div>
  )
}

function Lobby({ state, busy, onReady }: { state: OnlineState; busy: boolean; onReady: () => void }) {
  const readyCount = state.players.filter((player) => player.ready).length
  const live = state.players.filter((player) => player.connected)
  return (
    <section className="card grid gap-3 p-4">
      <p className="text-muted">
        {state.room.ranked
          ? 'Partida online. En cuanto hayáis entrado los rivales, empieza sola.'
          : 'Comparte el código. Cuando todos estén preparados, la partida arranca sola.'}
      </p>
      <ul className="grid gap-2">
        {live.map((player) => (
          <li key={player.user_id} className="flex items-center gap-3 rounded-2xl bg-white/8 px-3 py-2">
            <span className="text-3xl">{player.avatar}</span>
            <span className="flex-1 font-bold">{player.name}</span>
            <span className={`rounded-full px-3 py-1 text-xs font-bold ${player.ready ? 'bg-taboo text-ink' : 'bg-white/10 text-muted'}`}>
              {player.ready ? 'Preparado' : 'Esperando'}
            </span>
          </li>
        ))}
      </ul>
      {state.room.ranked ? (
        <p className="text-center text-sm text-muted">{live.length} jugadores conectados</p>
      ) : (
        <>
          <p className="text-center text-sm text-muted">{readyCount}/{state.players.length} listos · {state.room.mode === 'duel' ? 'hacen falta 2' : 'de 2 a 20'}</p>
          <Button type="button" tone={state.you.ready ? 'ghost' : 'quick'} disabled={busy} onClick={onReady}>
            {state.you.ready ? 'Quitar preparado' : 'Preparado'}
          </Button>
        </>
      )}
    </section>
  )
}

function Countdown({ state }: { state: OnlineState }) {
  const left = useLeft(state)
  return (
    <section className="card grid place-items-center gap-2 py-10">
      <p className="text-sm font-semibold uppercase tracking-[0.2em] text-muted">Empieza en</p>
      <p className="font-display text-8xl font-extrabold">{Math.max(1, Math.ceil(left / 1000))}</p>
    </section>
  )
}

function Question({
  state,
  you,
  mineCorrect,
  minePoints,
  onAnswer,
}: {
  state: OnlineState
  you?: string
  mineCorrect?: boolean
  minePoints?: number
  onAnswer: (id: string | null) => void
}) {
  const left = useLeft(state)
  const question = state.question
  const revealed = state.room.status === 'reveal'
  const ratio = Math.max(0, Math.min(1, left / (state.room.seconds * 1000)))
  return (
    <section className={`card grid gap-3 p-4 ${revealed && mineCorrect ? 'animate-pop' : ''} ${revealed && mineCorrect === false ? 'animate-shake' : ''}`}>
      <div className="flex items-center justify-between text-sm font-semibold">
        <span>{question?.category} {question?.emoji}</span>
        <span>{state.room.mode === 'duel' ? `Ronda ${state.room.round_index}/3 · ` : ''}{state.room.question_index + 1}/{Math.max(state.total, 1)}</span>
      </div>
      <div className="h-2 overflow-hidden rounded-full bg-white/10">
        <div className="h-full rounded-full bg-quick transition-[width] duration-100" style={{ width: `${ratio * 100}%` }} />
      </div>
      <p className="text-right font-display text-3xl font-extrabold">{(left / 1000).toFixed(1)}s</p>
      <h2 className="font-display text-3xl font-extrabold leading-tight">{question?.prompt}</h2>
      {state.room.mode === 'quick' ? (
        <Button type="button" tone="quick" disabled={state.you.answered || revealed} onClick={() => onAnswer(null)}>
          {state.you.answered ? 'Esperando al resto' : '¡Lo tengo!'}
        </Button>
      ) : (
        <div className="grid gap-2">
          {question?.answers.map((answer) => {
            const picked = state.answers.some((row) => row.user_id === you && row.answer_id === answer.id)
            const correct = revealed && state.reveal?.correct_id === answer.id
            return (
              <button
                key={answer.id}
                type="button"
                disabled={state.you.answered || revealed}
                onClick={() => onAnswer(answer.id)}
                className={`touch text-left ${correct ? 'bg-taboo text-ink' : picked ? 'bg-white text-ink' : 'bg-white/10'} disabled:opacity-80`}
              >
                {answer.text}
              </button>
            )
          })}
        </div>
      )}
      {revealed ? (
        <p className={`text-center font-display text-2xl font-extrabold ${mineCorrect ? 'text-taboo' : 'text-impostor'}`}>
          {mineCorrect ? `+${minePoints ?? 0}` : 'Fallaste'}
          {state.room.mode !== 'quick' && state.reveal?.correct_text ? ` · ${state.reveal.correct_text}` : ''}
        </p>
      ) : null}
    </section>
  )
}

function RoundResult({ state }: { state: OnlineState }) {
  const players = state.round?.players ?? []
  const best = Math.max(...players.map((player) => player.round_points), 0)
  return (
    <section className="card grid gap-3 p-4">
      <p className="text-center text-sm font-semibold uppercase tracking-[0.18em] text-quick">Fin de la ronda {state.round?.round}</p>
      {players.map((player) => (
        <div key={player.user_id} className={`flex items-center gap-3 rounded-2xl px-3 py-3 ${player.round_points === best && best > 0 ? 'bg-white text-ink' : 'bg-white/10'}`}>
          <span className="text-3xl">{player.avatar}</span>
          <span className="flex-1 font-bold">{player.name}</span>
          <span className="font-display text-2xl font-extrabold">{player.round_points}</span>
        </div>
      ))}
    </section>
  )
}

function Final({
  state,
  won,
  you,
  leveled,
  level,
  onAgain,
  onRematch,
}: {
  state: OnlineState
  won: boolean
  you?: string
  leveled: boolean
  level: number
  onAgain: () => void
  onRematch: () => void
}) {
  const ranking = state.summary?.ranking ?? []
  return (
    <section className="grid gap-3">
      <div className={`card shine p-5 text-center ${won ? 'bg-linear-to-b from-quick/30 to-transparent' : ''}`}>
        <p className="text-5xl">{state.summary?.tie ? '🤝' : won ? '🏆' : '😤'}</p>
        <h2 className="font-display text-4xl font-extrabold">{state.summary?.tie ? 'Empate' : won ? 'Victoria' : 'Derrota'}</h2>
        <p className="text-muted">+{ranking.find((row) => row.user_id === you)?.xp ?? 0} XP</p>
      </div>
      {leveled ? (
        <div className="card shine p-4 text-center">
          <p className="text-sm font-bold uppercase tracking-[0.2em] text-quick">Subes de nivel</p>
          <p className="font-display text-4xl font-extrabold">Nivel {level}</p>
        </div>
      ) : null}
      {ranking.map((row, index) => (
        <div key={row.user_id} className={`card flex items-center gap-3 px-4 py-3 ${index === 0 ? 'shine' : ''}`}>
          <span className="font-display text-2xl font-extrabold text-quick">{index + 1}</span>
          <span className="text-3xl">{row.avatar}</span>
          <span className="flex-1">
            <span className="block font-bold">{row.name}</span>
            <span className="text-sm text-muted">{row.correct} aciertos{state.room.mode === 'duel' ? ` · ${row.round_wins} rondas` : ''}</span>
          </span>
          <span className="font-display text-2xl font-extrabold">{row.score}</span>
        </div>
      ))}
      {state.room.rematch_id ? (
        <Button type="button" tone="impostor" onClick={() => onRematch()}>Entrar a la revancha</Button>
      ) : state.room.mode === 'duel' ? (
        <Button type="button" tone="impostor" onClick={onRematch}>Revancha</Button>
      ) : null}
      <Button type="button" tone="quick" onClick={onAgain}>{state.room.ranked ? 'Buscar otra partida' : 'Jugar otra partida'}</Button>
    </section>
  )
}

function Ranking({ players, movement, you }: { players: OnlinePlayer[]; movement: Record<string, boolean>; you?: string }) {
  return (
    <section className="grid gap-2">
      <p className="text-xs font-semibold uppercase tracking-[0.16em] text-muted">Ranking</p>
      {players.map((player, index) => (
        <div key={player.user_id} className={`flex items-center gap-3 rounded-2xl px-3 py-2 ${player.user_id === you ? 'bg-white text-ink' : 'bg-white/8'} ${movement[player.user_id] ? 'rank-up' : ''}`}>
          <span className="w-6 font-display text-lg font-extrabold">{index + 1}</span>
          <span className="text-2xl">{player.avatar}</span>
          <span className="flex-1 font-bold">{player.name}</span>
          <span className="font-display text-xl font-extrabold">{player.score}</span>
        </div>
      ))}
    </section>
  )
}

function useLeft(state: OnlineState) {
  const [left, setLeft] = useState(state.room.seconds * 1000)
  useEffect(() => {
    if (!state.room.phase_ends) return
    const offset = new Date(state.server_now).getTime() - Date.now()
    const end = new Date(state.room.phase_ends).getTime()
    const tick = () => setLeft(Math.max(0, end - (Date.now() + offset)))
    tick()
    const id = window.setInterval(tick, 80)
    return () => window.clearInterval(id)
  }, [state.server_now, state.room.phase_ends, state.room.status, state.room.question_index])
  return left
}
