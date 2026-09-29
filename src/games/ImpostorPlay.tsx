import { useState } from 'react'
import { castVote, impostorGuess, resolveImpostor, revealRole, startVoting } from '../lib/api'
import type { MatchState, Player, Summary } from '../types'
import { Banner, Button, PassPhone, Timer } from '../components/ui'

type Role = { name: string; is_impostor: boolean; word: string | null; emoji: string | null }

export function ImpostorPlay({ match, onDone }: { match: MatchState; onDone: (summary: Summary) => void }) {
  const players = [...match.players].sort((a, b) => a.seat - b.seat)
  const discuss = Number(match.config.discuss_seconds ?? 60)
  const [index, setIndex] = useState(0)
  const [phase, setPhase] = useState<'cover' | 'blank' | 'role' | 'talk' | 'vote-cover' | 'vote' | 'guess-cover' | 'guess'>(
    match.status === 'guessing' ? 'guess-cover' : match.status === 'voting' ? 'vote-cover' : 'cover',
  )
  const [role, setRole] = useState<Role | null>(null)
  const [voteIndex, setVoteIndex] = useState(0)
  const [error, setError] = useState('')
  const [guess, setGuess] = useState('')
  const [accused, setAccused] = useState(match.impostor?.accused_name ?? '')
  const player = players[index]
  const voter = players[voteIndex]

  async function showRole(seat: number) {
    setError('')
    try {
      const data = await revealRole(match.id, seat)
      setRole(data)
      setPhase('role')
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'No se ha podido mostrar el papel')
    }
  }

  function hideRole() {
    setPhase('blank')
    setRole(null)
    window.setTimeout(() => {
      if (index + 1 >= players.length) setPhase('talk')
      else {
        setIndex(index + 1)
        setPhase('cover')
      }
    }, 350)
  }

  async function vote(target: Player) {
    if (!voter) return
    try {
      const result = await castVote(match.id, voter.seat, target.seat)
      setPhase('blank')
      window.setTimeout(() => {
        if (result.complete) {
          resolveImpostor(match.id).then((payload) => {
            if ('phase' in payload && payload.phase === 'guess') {
              setAccused(payload.accused_name)
              setPhase('guess-cover')
            } else {
              onDone(payload as Summary)
            }
          }).catch((caught: Error) => setError(caught.message))
        } else {
          setVoteIndex(voteIndex + 1)
          setPhase('vote-cover')
        }
      }, 350)
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'No se ha podido votar')
    }
  }

  return (
    <div className="mx-auto grid w-full max-w-lg gap-4">
      {error ? <Banner text={error} /> : null}
      {phase === 'blank' ? <div className="min-h-[70vh] rounded-[1.5rem] bg-black" /> : null}
      {phase === 'cover' && player ? (
        <PassPhone name={player.name} hint="Toca solo cuando tenga el móvil. Nadie más debe mirar." onReady={() => showRole(player.seat)} />
      ) : null}
      {phase === 'role' && role ? (
        <section className="card grid min-h-[70vh] place-items-center gap-3 p-6 text-center animate-pop">
          {role.is_impostor ? (
            <>
              <p className="font-display text-4xl font-extrabold text-impostor">Eres el impostor</p>
              <p>No debes conocer la palabra. Improvisa.</p>
            </>
          ) : (
            <>
              <p className="text-muted">Palabra</p>
              <p className="font-display text-5xl font-extrabold">{role.emoji} {role.word}</p>
              <p>No eres el impostor.</p>
            </>
          )}
          <Button type="button" tone="impostor" onClick={hideRole}>Ocultar y pasar</Button>
        </section>
      ) : null}
      {phase === 'talk' ? (
        <section className="grid gap-4 text-center">
          <p className="text-muted">Cada uno da una pista, en este orden.</p>
          <ol className="grid gap-2 text-left">
            {players.map((item, order) => (
              <li key={item.id} className="card px-4 py-3 font-bold">{order + 1}. {item.name}</li>
            ))}
          </ol>
          <Timer seconds={discuss} running onExpire={() => undefined} />
          <Button type="button" tone="impostor" onClick={() => startVoting(match.id).then(() => setPhase('vote-cover')).catch((caught: Error) => setError(caught.message))}>
            🗳️ Votar
          </Button>
        </section>
      ) : null}
      {phase === 'vote-cover' && voter ? (
        <PassPhone name={voter.name} hint="Toca para votar en secreto." onReady={() => setPhase('vote')} />
      ) : null}
      {phase === 'vote' && voter ? (
        <section className="grid gap-2">
          <h2 className="font-display text-3xl font-extrabold">{voter.name}, ¿quién es?</h2>
          {players.filter((item) => item.seat !== voter.seat).map((item) => (
            <Button key={item.id} type="button" tone="ghost" onClick={() => vote(item)}>{item.name}</Button>
          ))}
        </section>
      ) : null}
      {phase === 'guess-cover' ? (
        <PassPhone name={accused || 'el acusado'} hint="Te han descubierto. Toca para intentar adivinar la palabra." onReady={() => setPhase('guess')} />
      ) : null}
      {phase === 'guess' ? (
        <form
          className="grid gap-3"
          onSubmit={(event) => {
            event.preventDefault()
            impostorGuess(match.id, guess).then(onDone).catch((caught: Error) => setError(caught.message))
          }}
        >
          <h2 className="font-display text-3xl font-extrabold">¿Cuál era la palabra?</h2>
          <input value={guess} onChange={(event) => setGuess(event.target.value)} className="min-h-14 rounded-2xl bg-white/10 px-4 text-2xl" autoFocus />
          <Button type="submit" tone="impostor">Probar</Button>
        </form>
      ) : null}
    </div>
  )
}
