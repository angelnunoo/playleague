import { useEffect, useState } from 'react'
import { endTabooTurn, finishMatch, nextTabooCard, startTabooTurn, tabooMark } from '../lib/api'
import type { MatchState, Summary } from '../types'
import { Banner, Button, PassPhone, Timer } from '../components/ui'

type Card = { word: string; emoji: string; forbidden: string[]; category: string }
type Turn = { player_name: string; team_name: string; seconds: number; total: number; turn_index: number }

export function TabooPlay({ match, onDone }: { match: MatchState; onDone: (summary: Summary) => void }) {
  const [turn, setTurn] = useState<Turn | null>(null)
  const [card, setCard] = useState<Card | null>(null)
  const [phase, setPhase] = useState<'cover' | 'play'>('cover')
  const [running, setRunning] = useState(false)
  const [scores, setScores] = useState(match.taboo?.scores ?? [])
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)

  async function begin() {
    setError('')
    try {
      const next = await startTabooTurn(match.id)
      setTurn({
        player_name: next.player_name,
        team_name: next.team_name,
        seconds: next.seconds,
        total: next.total,
        turn_index: next.turn_index,
      })
      setScores(next.scores ?? [])
      setPhase('cover')
      setCard(null)
    } catch (caught) {
      const message = caught instanceof Error ? caught.message : 'No se ha podido empezar el turno'
      if (message.includes('Ya no quedan turnos')) {
        const summary = await finishMatch(match.id)
        onDone(summary)
        return
      }
      setError(message)
    }
  }

  useEffect(() => {
    if (!match.taboo?.open_turn) begin().catch(() => undefined)
    // The first turn is dealt once when the match opens.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [match.id])

  async function deal() {
    setBusy(true)
    try {
      const next = await nextTabooCard(match.id)
      if (next.empty || !next.card) {
        await closeTurn()
        return
      }
      setCard(next.card)
      setPhase('play')
      setRunning(true)
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'No hay tarjeta')
    } finally {
      setBusy(false)
    }
  }

  async function mark(result: 'correct' | 'forbidden' | 'pass') {
    setBusy(true)
    try {
      const marked = await tabooMark(match.id, result)
      setScores(marked.scores ?? [])
      setCard(null)
      await deal()
    } catch (caught) {
      const message = caught instanceof Error ? caught.message : 'No se ha podido anotar'
      if (message.includes('tiempo')) await closeTurn()
      else setError(message)
    } finally {
      setBusy(false)
    }
  }

  async function closeTurn() {
    setRunning(false)
    const ended = await endTabooTurn(match.id)
    setScores(ended.scores ?? [])
    setCard(null)
    if (ended.finished_rounds) {
      onDone(await finishMatch(match.id))
      return
    }
    await begin()
  }

  return (
    <div className="mx-auto grid w-full max-w-lg gap-4">
      {error ? <Banner text={error} /> : null}
      <div className="flex flex-wrap gap-2">
        {(scores ?? []).map((score) => (
          <span key={score.team_key} className="rounded-full bg-white/10 px-3 py-1 text-sm font-bold">{score.name} {score.score}</span>
        ))}
      </div>
      {!turn ? <p>Preparando turno…</p> : null}
      {turn && phase === 'cover' ? (
        <PassPhone name={turn.player_name} hint={`${turn.team_name} describe. Turno ${turn.turn_index + 1}/${turn.total}.`} onReady={deal} />
      ) : null}
      {turn && phase === 'play' ? (
        <section className="grid gap-4 text-center animate-pop">
          <Timer seconds={turn.seconds} running={running} resetKey={turn.turn_index} onExpire={() => closeTurn().catch((caught: Error) => setError(caught.message))} />
          {!card ? <p>Siguiente palabra…</p> : null}
          {card ? <>
          <p className="text-sm text-muted">{card.category}</p>
          <h2 className="font-display text-5xl font-extrabold">{card.emoji} {card.word}</h2>
          <ul className="grid gap-2">
            {card.forbidden.map((word) => (
              <li key={word} className="rounded-2xl bg-impostor/20 px-3 py-2 font-bold">❌ {word}</li>
            ))}
          </ul>
          <div className="grid grid-cols-3 gap-2">
            <Button type="button" tone="taboo" disabled={busy} onClick={() => mark('correct')}>✅</Button>
            <Button type="button" tone="danger" disabled={busy} onClick={() => mark('forbidden')}>🚫</Button>
            <Button type="button" tone="ghost" disabled={busy} onClick={() => mark('pass')}>⏭️</Button>
          </div>
          </> : null}
        </section>
      ) : null}
    </div>
  )
}
