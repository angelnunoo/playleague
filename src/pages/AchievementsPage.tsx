import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { supabase } from '../lib/supabase'

type Achievement = {
  id: string
  slug: string
  name: string
  description: string
  emoji: string
  threshold: number
  xp_reward: number
  user_achievements: { progress: number; unlocked_at: string | null }[]
}

export function AchievementsPage() {
  const [items, setItems] = useState<Achievement[]>([])
  const [error, setError] = useState('')

  useEffect(() => {
    supabase
      .from('achievements')
      .select('id, slug, name, description, emoji, threshold, xp_reward, user_achievements(progress, unlocked_at)')
      .order('sort')
      .then(({ data, error: queryError }) => {
        if (queryError) setError(queryError.message)
        else setItems((data ?? []) as Achievement[])
      })
  }, [])

  const unlocked = items.filter((item) => item.user_achievements[0]?.unlocked_at)
  const locked = items.filter((item) => !item.user_achievements[0]?.unlocked_at)

  return (
    <div className="mx-auto grid w-full max-w-lg gap-4">
      <Link to="/perfil" className="text-sm text-muted">← Perfil</Link>
      <h1 className="font-display text-4xl font-extrabold">Logros</h1>
      {error ? <p>{error}</p> : null}
      <h2 className="font-bold">Desbloqueados · {unlocked.length}</h2>
      {unlocked.map((item) => <Card key={item.id} item={item} />)}
      <h2 className="font-bold">Bloqueados · {locked.length}</h2>
      {locked.map((item) => <Card key={item.id} item={item} />)}
    </div>
  )
}

function Card({ item }: { item: Achievement }) {
  const progress = item.user_achievements[0]?.progress ?? 0
  const open = Boolean(item.user_achievements[0]?.unlocked_at)
  const ratio = Math.min(1, progress / item.threshold)
  return (
    <article className={`card p-4 ${open ? '' : 'opacity-70'}`}>
      <p className="text-2xl">{item.emoji} {item.name}</p>
      <p className="text-sm text-muted">{item.description}</p>
      <div className="mt-2 h-2 overflow-hidden rounded-full bg-white/10">
        <div className="h-full bg-quick" style={{ width: `${ratio * 100}%` }} />
      </div>
      <p className="mt-1 text-xs text-muted">{Math.min(progress, item.threshold)} / {item.threshold} · +{item.xp_reward} XP</p>
    </article>
  )
}
