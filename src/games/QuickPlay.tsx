import { useState } from 'react'
import { finishMatch, nextQuick, quickMark } from '../lib/api'
import type { MatchState, Summary } from '../types'
import { Banner, Button, PassPhone, Timer } from '../components/ui'

type Prompt = { prompt: string; emoji: string; category: string; player_name: string; seconds: number }

export function QuickPlay({ match, onDone }: { match: MatchState; onDone: (summary: Summary) => void }) {
  const [prompt, setPrompt] = useState<Prompt | null>(null)
  const [phase, setPhase] = useState<'cover' | 'go' | 'flash'>('cover')
  const [running, setRunning] = useState(false)
  const [flash, setFlash] = useState('')
  const [streak, setStreak] = useState(0)
  const [error, setError] = useState('')

  async function deal() {
    setError('')
    try {
      const next = await nextQuick(match.id)
      setPrompt({ prompt: next.prompt, emoji: next.emoji, category: next.category, player_name: next.player_name, seconds: next.seconds })
      setPhase('cover')
    } catch (caught) {
      const message = caught instanceof Error ? caught.message : 'No hay más retos'
      if (message.includes('ganador') || message.includes('todas')) {
        onDone(await finishMatch(match.id))
        return
      }
      setError(message)
    }
  }

  async function mark(success: boolean) {
    setRunning(false)
    try {
      const result = await quickMark(match.id, success)
      setStreak(result.streak)
      setFlash(result.success ? `¡Bien! +${result.points}${result.streak ? ` · racha ${result.streak}` : ''}` : 'Fuera')
      setPhase('flash')
      window.setTimeout(() => {
        if (result.done) finishMatch(match.id).then(onDone).catch((caught: Error) => setError(caught.message))
        else deal()
      }, 700)
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'No se ha podido anotar')
    }
  }

  return (
    <div className="mx-auto grid w-full max-w-lg gap-4">
      {error ? <Banner text={error} /> : null}
      {!prompt && phase === 'cover' ? <Button type="button" tone="quick" onClick={deal}>Sacar reto</Button> : null}
      {prompt && phase === 'cover' ? (
        <PassPhone name={prompt.player_name} hint="Toca cuando estés listo. El tiempo corre al tocar." onReady={() => { setPhase('go'); setRunning(true) }} />
      ) : null}
      {prompt && phase === 'go' ? (
        <section className="grid gap-4 text-center animate-pop">
          <Timer seconds={prompt.seconds} running={running} onExpire={() => mark(false)} />
          <p className="text-sm text-muted">{prompt.emoji} {prompt.category}</p>
          <h2 className="font-display text-4xl font-extrabold">{prompt.prompt}</h2>
          {streak > 1 ? <p className="text-quick">🔥 Racha {streak}</p> : null}
          <div className="grid grid-cols-2 gap-2">
            <Button type="button" tone="taboo" onClick={() => mark(true)}>✅ Lo ha dicho</Button>
            <Button type="button" tone="danger" onClick={() => mark(false)}>❌ Fallo</Button>
          </div>
        </section>
      ) : null}
      {phase === 'flash' ? <p className="text-center font-display text-4xl font-extrabold">{flash}</p> : null}
    </div>
  )
}
