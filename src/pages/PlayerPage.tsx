import { useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { friendCard, removeFriend } from '../lib/api'
import { LEAGUE_MARK } from '../lib/leagues'
import { RankBoard } from '../components/Ranks'
import { Banner, Button } from '../components/ui'
import type { PlayerCard } from '../types'

export function PlayerPage() {
  const { username = '' } = useParams()
  const navigate = useNavigate()
  const [player, setPlayer] = useState<PlayerCard | null>(null)
  const [error, setError] = useState('')

  useEffect(() => {
    friendCard(username).then(setPlayer).catch((caught) => setError(caught instanceof Error ? caught.message : 'No se pudo abrir'))
  }, [username])

  if (error) return <Banner text={error} />
  if (!player) return <p>Cargando perfil…</p>

  const rate = player.games ? Math.round((player.wins / player.games) * 100) : 0
  return (
    <div className="mx-auto grid w-full max-w-lg gap-4">
      <Link to="/social" className="text-sm font-bold text-quick">Volver a Social</Link>
      <section className="card shine p-5">
        <p className="text-6xl">{player.avatar}</p>
        <h1 className="font-display text-4xl font-extrabold">{player.name}</h1>
        <p className="text-muted">@{player.username}</p>
        <p className="mt-3 font-display text-3xl font-extrabold">Nivel {player.level}</p>
        <p className="text-sm text-muted">{player.xp} XP</p>
        <p className="mt-2 font-bold" style={{ color: player.rank.color }}>{LEAGUE_MARK[player.rank.slug]} {player.rank.name}</p>
      </section>
      <RankBoard rating={player.rating} detailed own={false} />
      <div className="grid grid-cols-3 gap-2">
        <Stat label="Victorias" value={player.wins} />
        <Stat label="Partidas" value={player.games} />
        <Stat label="Ratio" value={`${rate}%`} />
      </div>
      <Stat label="Mejor racha" value={player.best_streak} />
      <Button type="button" tone="ghost" onClick={() => removeFriend(player.id).then(() => navigate('/social'))}>Eliminar amigo</Button>
    </div>
  )
}

function Stat({ label, value }: { label: string; value: number | string }) {
  return (
    <div className="card p-3 text-center">
      <p className="font-display text-2xl font-extrabold">{value}</p>
      <p className="text-xs text-muted">{label}</p>
    </div>
  )
}
