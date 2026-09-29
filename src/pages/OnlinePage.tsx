import { useEffect, useState, type FormEvent } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { useAuth } from '../auth/AuthProvider'
import { createOnlineRoom, findRankedMatch, joinOnlineRoom, leaveOnlineRoom } from '../lib/api'
import { RankBoard } from '../components/Ranks'
import { Banner, Button } from '../components/ui'
import type { OnlineMode } from '../types'

const modes: { id: OnlineMode; name: string; emoji: string; blurb: string; tint: string }[] = [
  { id: 'battle', name: 'Quiz Battle', emoji: '⚔️', blurb: 'Todos respondéis a la vez. El más rápido suma más.', tint: '#a78bfa' },
  { id: 'quick', name: 'Responde rápido', emoji: '⚡', blurb: 'La misma prueba para todos. Pulsa cuando la tengas.', tint: '#ffc53d' },
  { id: 'duel', name: 'Duelo 1 vs 1', emoji: '🥊', blurb: '10 preguntas contra un rival. Mejor de tres rondas.', tint: '#ff5d73' },
]

function isMode(value: string | null): value is OnlineMode {
  return value === 'battle' || value === 'quick' || value === 'duel'
}

export function OnlinePage() {
  const { profile } = useAuth()
  const navigate = useNavigate()
  const [params, setParams] = useSearchParams()
  const searching = isMode(params.get('cola')) ? params.get('cola') : null
  const [code, setCode] = useState('')
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)
  const [waiting, setWaiting] = useState(1)

  useEffect(() => {
    if (!isMode(searching)) return
    const mode = searching
    let stop = false
    let roomId: string | null = null
    const matched = { current: false }

    async function tick() {
      try {
        const result = await findRankedMatch(mode)
        if (stop) {
          if (!matched.current) leaveOnlineRoom(result.room_id).catch(() => undefined)
          return
        }
        roomId = result.room_id
        setWaiting(result.players)
        if (result.matched) {
          matched.current = true
          navigate(`/sala/${result.room_id}`)
        }
      } catch (caught) {
        if (!stop) setError(caught instanceof Error ? caught.message : 'No se pudo buscar partida')
      }
    }

    tick()
    const timer = window.setInterval(tick, 1200)
    return () => {
      stop = true
      window.clearInterval(timer)
      if (!matched.current && roomId) leaveOnlineRoom(roomId).catch(() => undefined)
    }
  }, [navigate, searching])

  async function create(mode: OnlineMode) {
    setBusy(true)
    setError('')
    try {
      const id = await createOnlineRoom(mode)
      navigate(`/sala/${id}`)
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'No se pudo crear la sala')
      setBusy(false)
    }
  }

  async function join(event: FormEvent) {
    event.preventDefault()
    setBusy(true)
    setError('')
    try {
      const id = await joinOnlineRoom(code)
      navigate(`/sala/${id}`)
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'No se pudo entrar')
      setBusy(false)
    }
  }

  const current = modes.find((mode) => mode.id === searching)

  if (current) {
    return (
      <div className="mx-auto grid w-full max-w-lg gap-4 text-center">
        <p className="text-sm font-semibold uppercase tracking-[0.2em] text-quick">En línea</p>
        <h1 className="font-display text-5xl font-extrabold leading-none">{current.emoji} {current.name}</h1>
        <div className="card shine grid gap-3 p-6">
          <p className="text-5xl animate-pulse">🌐</p>
          <p className="font-display text-3xl font-extrabold">Buscando rivales</p>
          <p className="text-muted">Tiene que haber otra persona buscando esta partida ahora mismo. En cuanto entre, empezáis.</p>
          <p className="text-sm font-bold text-quick">{waiting} en la cola</p>
        </div>
        {error ? <Banner text={error} /> : null}
        <Button type="button" tone="ghost" onClick={() => setParams({})}>Cancelar búsqueda</Button>
      </div>
    )
  }

  return (
    <div className="mx-auto w-full max-w-lg">
      <p className="text-sm font-semibold uppercase tracking-[0.2em] text-quick">Competición</p>
      <h1 className="font-display text-5xl font-extrabold leading-none">Online</h1>
      <p className="mt-2 text-muted">Juega contra gente que esté buscando partida en este momento.</p>
      <div className="mt-4">
        <RankBoard rating={profile?.profile.rating ?? 0} />
      </div>
      <div className="mt-5 grid gap-3">
        {modes.map((mode) => (
          <button
            key={mode.id}
            type="button"
            disabled={busy}
            onClick={() => {
              setError('')
              setWaiting(1)
              setParams({ cola: mode.id })
            }}
            className="card shine flex items-center gap-4 p-4 text-left disabled:opacity-50"
            style={{ boxShadow: `inset 6px 0 0 ${mode.tint}` }}
          >
            <span className="grid h-16 w-16 place-items-center rounded-2xl text-4xl" style={{ background: `${mode.tint}22` }}>
              {mode.emoji}
            </span>
            <span>
              <span className="block font-display text-2xl font-extrabold">{mode.name}</span>
              <span className="text-muted">{mode.blurb}</span>
            </span>
          </button>
        ))}
      </div>
      <section className="mt-6 grid gap-3">
        <div>
          <p className="font-display text-2xl font-extrabold">Partida privada</p>
          <p className="text-sm text-muted">Crea tu sala y comparte el código con quien tú elijas.</p>
        </div>
        <div className="grid grid-cols-3 gap-2">
          {modes.map((mode) => (
            <button key={`private-${mode.id}`} type="button" disabled={busy} onClick={() => create(mode.id)} className="touch bg-white/10 text-sm disabled:opacity-50">
              {mode.emoji} {mode.name}
            </button>
          ))}
        </div>
        <form onSubmit={join} className="card grid gap-3 p-4">
          <p className="font-display text-xl font-extrabold">Unirse con código</p>
          <input
            value={code}
            onChange={(event) => setCode(event.target.value.toUpperCase())}
            maxLength={4}
            placeholder="CÓDIGO"
            className="min-h-14 rounded-2xl bg-white/10 px-4 text-center font-display text-3xl font-extrabold tracking-[0.4em] uppercase"
          />
          {error ? <Banner text={error} /> : null}
          <Button type="submit" tone="quick" disabled={busy || code.trim().length < 4}>Entrar a la sala</Button>
        </form>
      </section>
    </div>
  )
}
