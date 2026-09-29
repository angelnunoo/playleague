import { useEffect, useState } from 'react'
import { Link, Navigate, useParams } from 'react-router-dom'
import { useAuth } from '../auth/AuthProvider'
import { respondFriendRequest, searchPlayers, sendFriendRequest, socialHome } from '../lib/api'
import { LEAGUE_MARK } from '../lib/leagues'
import { Banner, Button } from '../components/ui'
import type { PlayerCard } from '../types'

export function InvitePage() {
  const { username = '' } = useParams()
  const clean = username.trim().toLowerCase()
  const { session, loading, profile } = useAuth()
  const [player, setPlayer] = useState<PlayerCard | null>(null)
  const [relation, setRelation] = useState<'none' | 'incoming' | 'outgoing' | 'friends'>('none')
  const [message, setMessage] = useState('')
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)

  useEffect(() => {
    if (session) sessionStorage.removeItem('playleague-invite')
  }, [session])

  useEffect(() => {
    if (!session || !clean) return
    let stop = false
    Promise.all([searchPlayers(clean), socialHome()])
      .then(([found, home]) => {
        if (stop) return
        const match = found.find((item) => item.username === clean) ?? null
        setPlayer(match)
        if (home.friends.some((item) => item.username === clean)) setRelation('friends')
        else if (home.incoming.some((item) => item.username === clean)) setRelation('incoming')
        else if (home.outgoing.some((item) => item.username === clean)) setRelation('outgoing')
        else setRelation('none')
      })
      .catch((caught) => {
        if (!stop) setError(caught instanceof Error ? caught.message : 'No se pudo abrir la invitación')
      })
    return () => {
      stop = true
    }
  }, [session, clean])

  if (loading) return <p>Cargando…</p>
  if (!session) {
    if (clean) sessionStorage.setItem('playleague-invite', clean)
    return <Navigate to="/entrar" replace />
  }
  if (profile?.profile.username === clean) {
    return (
      <div className="mx-auto grid w-full max-w-lg gap-3">
        <h1 className="font-display text-4xl font-extrabold">Este enlace es el tuyo</h1>
        <p className="text-muted">Compártelo por WhatsApp desde Social para que te envíen la solicitud.</p>
        <Link to="/social" className="touch grid place-items-center bg-white text-center text-ink">Ir a Social</Link>
      </div>
    )
  }

  async function send() {
    setBusy(true)
    setError('')
    try {
      const result = await sendFriendRequest(clean)
      setRelation(result === 'accepted' ? 'friends' : 'outgoing')
      setMessage(result === 'accepted' ? 'Ya sois amigos.' : 'Solicitud enviada.')
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'No se pudo enviar')
    } finally {
      setBusy(false)
    }
  }

  async function accept() {
    if (!player) return
    setBusy(true)
    setError('')
    try {
      await respondFriendRequest(player.id, true)
      setRelation('friends')
      setMessage('Solicitud aceptada.')
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'No se pudo aceptar')
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="mx-auto grid w-full max-w-lg gap-4">
      <h1 className="font-display text-4xl font-extrabold">Solicitud de amistad</h1>
      {error ? <Banner text={error} /> : null}
      {message ? <p className="rounded-2xl bg-taboo/20 px-4 py-3 text-sm">{message}</p> : null}
      {!player && !error ? <p className="text-muted">Buscando a @{clean}…</p> : null}
      {player ? (
        <article className="card grid gap-3 p-4">
          <div className="flex items-center gap-3">
            <span className="text-4xl">{player.avatar}</span>
            <span>
              <span className="block font-display text-2xl font-extrabold">{player.name}</span>
              <span className="text-sm text-muted">@{player.username} · Nivel {player.level}</span>
            </span>
            <span className="ml-auto text-sm font-bold" style={{ color: player.rank.color }}>{LEAGUE_MARK[player.rank.slug]} {player.rank.name}</span>
          </div>
          {relation === 'friends' ? <p className="font-bold text-taboo">Ya sois amigos.</p> : null}
          {relation === 'outgoing' ? <p className="text-muted">Solicitud enviada. Cuando la acepte, aparecerá en tus amigos.</p> : null}
          {relation === 'incoming' ? <Button type="button" tone="quick" disabled={busy} onClick={accept}>Aceptar solicitud</Button> : null}
          {relation === 'none' ? <Button type="button" tone="quick" disabled={busy} onClick={send}>Enviar solicitud</Button> : null}
        </article>
      ) : null}
      <Link to="/social" className="text-sm font-bold text-quick">Volver a Social</Link>
    </div>
  )
}

export function whatsappInvite(username: string, name: string) {
  const link = `${window.location.origin}/invitar/${encodeURIComponent(username)}`
  const text = `¡Hola! Soy ${name} en PlayLeague (@${username}). Entra en este enlace y envíame la solicitud de amistad:\n${link}`
  return `https://wa.me/?text=${encodeURIComponent(text)}`
}
