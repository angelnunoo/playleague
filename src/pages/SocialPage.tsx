import { useEffect, useState, type ReactNode } from 'react'
import { Link } from 'react-router-dom'
import { useAuth } from '../auth/AuthProvider'
import { whatsappInvite } from './InvitePage'
import { friendsRanking, removeFriend, respondFriendRequest, searchPlayers, sendFriendRequest, socialHome } from '../lib/api'
import { LEAGUE_MARK } from '../lib/leagues'
import { RankBoard } from '../components/Ranks'
import { Banner, Button } from '../components/ui'
import type { FriendRanking, PlayerCard, SocialHome } from '../types'

type Tab = 'amigos' | 'clasificacion'

export function SocialPage() {
  const [tab, setTab] = useState<Tab>('amigos')
  return (
    <div className="mx-auto grid w-full max-w-lg gap-4">
      <div>
        <p className="text-sm font-semibold uppercase tracking-[0.2em] text-quick">Comunidad</p>
        <h1 className="font-display text-5xl font-extrabold leading-none">Social</h1>
      </div>
      <div className="grid grid-cols-2 gap-2">
        <button type="button" onClick={() => setTab('amigos')} className={`touch ${tab === 'amigos' ? 'bg-white text-ink' : 'bg-white/10'}`}>Amigos</button>
        <button type="button" onClick={() => setTab('clasificacion')} className={`touch ${tab === 'clasificacion' ? 'bg-white text-ink' : 'bg-white/10'}`}>Clasificación</button>
      </div>
      {tab === 'amigos' ? <Friends /> : <Ranking />}
    </div>
  )
}

function Friends() {
  const { profile } = useAuth()
  const [home, setHome] = useState<SocialHome | null>(null)
  const [query, setQuery] = useState('')
  const [found, setFound] = useState<PlayerCard[]>([])
  const [error, setError] = useState('')

  async function load() {
    setHome(await socialHome())
  }

  useEffect(() => {
    load().catch((caught) => setError(caught instanceof Error ? caught.message : 'No se pudo cargar'))
  }, [])

  useEffect(() => {
    if (query.trim().length < 2) {
      setFound([])
      return
    }
    const timer = window.setTimeout(() => {
      searchPlayers(query).then(setFound).catch(() => setFound([]))
    }, 250)
    return () => window.clearTimeout(timer)
  }, [query])

  async function add(username: string) {
    setError('')
    try {
      await sendFriendRequest(username)
      setQuery('')
      setFound([])
      await load()
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'No se pudo enviar')
    }
  }

  const me = profile?.profile
  const inviteHref = me ? whatsappInvite(me.username, me.display_name) : ''

  return (
    <div className="grid gap-4">
      <section className="card grid gap-3 p-4">
        <h2 className="font-display text-2xl font-extrabold">Invitar por WhatsApp</h2>
        <p className="text-sm text-muted">Le llega tu enlace. Cuando entre, te envía la solicitud y la aceptas aquí.</p>
        <a
          href={inviteHref || undefined}
          target="_blank"
          rel="noopener noreferrer"
          aria-disabled={!inviteHref}
          className={`touch grid place-items-center bg-[#25D366] text-center text-ink ${inviteHref ? '' : 'pointer-events-none opacity-50'}`}
        >
          Enviar solicitud por WhatsApp
        </a>
      </section>
      <input
        value={query}
        onChange={(event) => setQuery(event.target.value)}
        placeholder="Busca por usuario o nombre"
        className="min-h-14 rounded-2xl bg-white/10 px-4"
      />
      {error ? <Banner text={error} /> : null}
      {found.length > 0 ? (
        <section className="grid gap-2">
          {found.map((player) => (
            <Card key={player.id} player={player} action={<Button type="button" tone="quick" onClick={() => add(player.username)}>Añadir</Button>} />
          ))}
        </section>
      ) : null}
      {home && home.incoming.length > 0 ? (
        <section className="grid gap-2">
          <h2 className="font-display text-2xl font-extrabold">Solicitudes</h2>
          {home.incoming.map((player) => (
            <Card
              key={player.id}
              player={player}
              action={
                <div className="grid grid-cols-2 gap-2">
                  <Button type="button" tone="quick" onClick={() => respondFriendRequest(player.id, true).then(load)}>Aceptar</Button>
                  <Button type="button" tone="ghost" onClick={() => respondFriendRequest(player.id, false).then(load)}>Rechazar</Button>
                </div>
              }
            />
          ))}
        </section>
      ) : null}
      <section className="grid gap-2">
        <h2 className="font-display text-2xl font-extrabold">Tus amigos</h2>
        {home && home.friends.length === 0 ? <p className="text-muted">Todavía no tienes amigos. Busca un usuario y envíale una solicitud.</p> : null}
        {home?.friends.map((player) => (
          <Card
            key={player.id}
            player={player}
            action={
              <div className="grid grid-cols-2 gap-2">
                <Link to={`/jugador/${player.username}`} className="touch grid place-items-center bg-white text-center text-ink">Ver perfil</Link>
                <Button type="button" tone="ghost" onClick={() => removeFriend(player.id).then(load)}>Eliminar</Button>
              </div>
            }
          />
        ))}
        {home && home.outgoing.length > 0 ? <p className="text-sm text-muted">Pendientes: {home.outgoing.map((player) => player.name).join(', ')}</p> : null}
      </section>
    </div>
  )
}

function Ranking() {
  const { profile } = useAuth()
  const [sort, setSort] = useState<FriendRanking['sort']>('xp')
  const [board, setBoard] = useState<FriendRanking | null>(null)
  const [error, setError] = useState('')

  useEffect(() => {
    let stop = false
    async function load() {
      try {
        const next = await friendsRanking(sort)
        if (!stop) setBoard(next)
      } catch (caught) {
        if (!stop) setError(caught instanceof Error ? caught.message : 'No se pudo cargar')
      }
    }
    load()
    const timer = window.setInterval(load, 15000)
    return () => {
      stop = true
      window.clearInterval(timer)
    }
  }, [sort])

  const medals = ['🥇', '🥈', '🥉']
  return (
    <div className="grid gap-3">
      <RankBoard rating={profile?.profile.rating ?? 0} detailed />
      <div className="grid grid-cols-3 gap-2">
        {([['xp', 'XP'], ['level', 'Nivel'], ['wins', 'Victorias']] as const).map(([id, label]) => (
          <button key={id} type="button" onClick={() => setSort(id)} className={`rounded-2xl px-3 py-3 text-sm font-bold ${sort === id ? 'bg-white text-ink' : 'bg-white/10'}`}>{label}</button>
        ))}
      </div>
      {error ? <Banner text={error} /> : null}
      {board && board.delta !== 0 ? (
        <p className={`text-center font-bold ${board.delta > 0 ? 'text-taboo' : 'text-impostor'}`}>
          {board.delta > 0 ? `↑ Subes ${board.delta}` : `↓ Bajas ${Math.abs(board.delta)}`}
        </p>
      ) : null}
      {board?.rows.map((player) => (
        <Link key={player.id} to={`/jugador/${player.username}`} className="card flex items-center gap-3 px-4 py-3">
          <span className="w-8 text-center text-2xl">{player.place && player.place <= 3 ? medals[player.place - 1] : player.place}</span>
          <span className="text-3xl">{player.avatar}</span>
          <span className="flex-1">
            <span className="block font-bold">{player.name}</span>
            <span className="text-sm text-muted">Nivel {player.level} · {player.wins} victorias</span>
          </span>
          <span className="text-right">
            <span className="block font-display text-xl font-extrabold">{sort === 'wins' ? player.wins : sort === 'level' ? player.level : player.xp}</span>
            <span className="text-xs" style={{ color: player.rank.color }}>{LEAGUE_MARK[player.rank.slug]} {player.rank.name}</span>
          </span>
        </Link>
      ))}
    </div>
  )
}

function Card({ player, action }: { player: PlayerCard; action: ReactNode }) {
  return (
    <article className="card grid gap-3 p-4">
      <div className="flex items-center gap-3">
        <span className="text-4xl">{player.avatar}</span>
        <span className="flex-1">
          <span className="block font-display text-xl font-extrabold">{player.name}</span>
          <span className="text-sm text-muted">@{player.username} · Nivel {player.level}</span>
        </span>
        <span className="text-right text-sm font-bold" style={{ color: player.rank.color }}>{LEAGUE_MARK[player.rank.slug]} {player.rank.name}</span>
      </div>
      <p className="text-sm text-muted">{player.wins} victorias · {player.games} partidas · {seen(player.last_seen)}</p>
      {action}
    </article>
  )
}

function seen(iso: string) {
  const mins = Math.round((Date.now() - new Date(iso).getTime()) / 60000)
  if (mins < 2) return 'En línea'
  if (mins < 60) return `Hace ${mins} min`
  const hours = Math.round(mins / 60)
  if (hours < 24) return `Hace ${hours} h`
  return `Hace ${Math.round(hours / 24)} d`
}
