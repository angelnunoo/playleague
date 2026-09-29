import { useEffect, useState, type FormEvent } from 'react'
import { Link } from 'react-router-dom'
import { useAuth } from '../auth/AuthProvider'
import { supabase } from '../lib/supabase'
import { myRecent } from '../lib/api'
import { AVATARS, GAMES } from '../lib/games'
import { BANNER_NAMES, BANNERS, FRAME_NAMES, FRAMES, LEAGUE_MARK, RANK_ORDER } from '../lib/leagues'
import { setSoundEnabled, soundEnabled } from '../lib/sound'
import { RankBoard } from '../components/Ranks'
import { Banner, Button, Progress } from '../components/ui'
import type { GameType, RecentMatch } from '../types'

const modeName: Record<string, string> = {
  quiz: 'Quiz',
  impostor: 'Impostor',
  taboo: 'Tabú',
  quick: 'Responde rápido',
  battle: 'Quiz Battle',
  duel: 'Duelo',
}

type Badge = { id: string; name: string; emoji: string; unlocked_at: string | null }

export function ProfilePage() {
  const { profile, refresh } = useAuth()
  const [name, setName] = useState(profile?.profile.display_name ?? '')
  const [username, setUsername] = useState(profile?.profile.username ?? '')
  const [avatar, setAvatar] = useState(profile?.profile.avatar_emoji ?? '😎')
  const [banner, setBanner] = useState(profile?.profile.banner ?? 'royal')
  const [frame, setFrame] = useState(profile?.profile.frame ?? 'none')
  const [message, setMessage] = useState('')
  const [error, setError] = useState('')
  const [suggestion, setSuggestion] = useState('')
  const [badges, setBadges] = useState<Badge[]>([])
  const [recent, setRecent] = useState<RecentMatch[]>([])
  const [levelFlash, setLevelFlash] = useState(false)
  const [rankFlash, setRankFlash] = useState('')
  const [sound, setSound] = useState(soundEnabled)

  useEffect(() => {
    supabase
      .from('achievements')
      .select('id, name, emoji, user_achievements(unlocked_at)')
      .order('sort')
      .then(({ data }) => {
        const rows = (data ?? []) as { id: string; name: string; emoji: string; user_achievements: { unlocked_at: string | null }[] }[]
        setBadges(rows.map((row) => ({
          id: row.id,
          name: row.name,
          emoji: row.emoji,
          unlocked_at: row.user_achievements?.[0]?.unlocked_at ?? null,
        })))
      })
    myRecent().then(setRecent).catch(() => setRecent([]))
  }, [])

  useEffect(() => {
    if (!profile) return
    const level = profile.profile.level
    const slug = profile.league?.slug ?? 'hierro'
    const previousLevel = Number(localStorage.getItem('playleague-level') ?? level)
    const previousSlug = localStorage.getItem('playleague-rank') ?? slug
    if (level > previousLevel) setLevelFlash(true)
    if (RANK_ORDER.indexOf(slug) > RANK_ORDER.indexOf(previousSlug)) setRankFlash(profile.league?.name ?? slug)
    localStorage.setItem('playleague-level', String(level))
    localStorage.setItem('playleague-rank', slug)
  }, [profile])

  if (!profile) return <p>Cargando perfil…</p>

  const stats = profile.stats
  const played = stats.games_played ?? 0
  const wins = stats.wins ?? 0
  const rate = played ? Math.round((wins / played) * 100) : 0
  const league = profile.league ?? { slug: 'hierro', name: 'Hierro', floor: 0, ceil: 100, color: '#8d8d97' }
  const rating = profile.profile.rating ?? 0
  const favorites = (['quiz', 'impostor', 'taboo', 'quick'] as GameType[])
    .map((id) => ({ id, played: stats[`${id}_played`] ?? 0 }))
    .filter((item) => item.played > 0)
    .sort((a, b) => b.played - a.played)
    .slice(0, 3)
  const unlocked = badges.filter((badge) => badge.unlocked_at)

  async function save(event: FormEvent) {
    event.preventDefault()
    setError('')
    setMessage('')
    const { error: updateError } = await supabase.from('profiles').update({
      display_name: name.trim(),
      username: username.trim().toLowerCase(),
      avatar_emoji: avatar,
      banner,
      frame,
    }).eq('id', profile!.profile.id)
    if (updateError) {
      setError(updateError.message)
      return
    }
    await refresh()
    setMessage('Perfil guardado')
  }

  async function suggest(event: FormEvent) {
    event.preventDefault()
    const { error: insertError } = await supabase.from('content_submissions').insert({
      user_id: profile!.profile.id,
      kind: 'quiz',
      payload: { note: suggestion.trim() },
    })
    if (insertError) setError(insertError.message)
    else {
      setSuggestion('')
      setMessage('Sugerencia enviada. Un administrador la revisará.')
    }
  }

  return (
    <div className="mx-auto grid w-full max-w-lg gap-4">
      {levelFlash ? (
        <button type="button" onClick={() => setLevelFlash(false)} className="card shine p-5 text-left">
          <p className="text-sm font-bold uppercase tracking-[0.2em] text-quick">Subes de nivel</p>
          <p className="font-display text-4xl font-extrabold">Nivel {profile.profile.level}</p>
        </button>
      ) : null}
      {rankFlash ? (
        <button type="button" onClick={() => setRankFlash('')} className="card shine p-5 text-left">
          <p className="text-sm font-bold uppercase tracking-[0.2em] text-quick">Ascenso de rango</p>
          <p className="font-display text-4xl font-extrabold">{rankFlash}</p>
        </button>
      ) : null}
      <section className="card shine overflow-hidden">
        <div className="h-28" style={{ background: BANNERS[banner] ?? BANNERS.royal }} />
        <div className="relative px-5 pb-5">
          <div className="-mt-12 grid h-24 w-24 place-items-center rounded-full bg-ink text-5xl" style={{ boxShadow: FRAMES[frame] ?? FRAMES.none }}>
            {profile.profile.avatar_emoji}
          </div>
          <div className="mt-3 flex items-start justify-between gap-3">
            <div>
              <h1 className="font-display text-4xl font-extrabold leading-none">{profile.profile.display_name}</h1>
              <p className="text-muted">@{profile.profile.username} · {profile.profile.title}</p>
            </div>
            <div className="rounded-2xl px-3 py-2 text-center" style={{ background: `${league.color}22`, color: league.color }}>
              <p className="text-[10px] font-bold uppercase tracking-wider">Rango</p>
              <p className="text-2xl leading-none">{LEAGUE_MARK[league.slug]}</p>
              <p className="text-xs font-bold">{league.name}</p>
            </div>
          </div>
          <div className="mt-4">
            <Progress xp={profile.progress.xp} floor={profile.progress.floor} ceil={profile.progress.ceil} level={profile.progress.level} />
          </div>
        </div>
      </section>
      <RankBoard rating={rating} detailed />

      <div className="grid grid-cols-3 gap-2">
        <Stat label="Partidas" value={played} />
        <Stat label="Victorias" value={wins} />
        <Stat label="Ratio" value={`${rate}%`} />
      </div>
      <div className="grid grid-cols-3 gap-2">
        <Stat label="Derrotas" value={stats.losses ?? 0} />
        <Stat label="Mejor racha" value={stats.best_streak ?? 0} />
        <Stat label="Aciertos" value={(stats.quiz_correct ?? 0) + (stats.quick_correct ?? 0) + (stats.taboo_correct ?? 0)} />
      </div>

      <section className="grid gap-2">
        <div className="flex items-center justify-between">
          <h2 className="font-display text-2xl font-extrabold">Logros</h2>
          <Link to="/logros" className="text-sm font-bold text-quick">Ver todos</Link>
        </div>
        <div className="flex gap-2 overflow-x-auto pb-1">
          {(unlocked.length ? unlocked : badges.slice(0, 4)).map((badge) => (
            <div key={badge.id} className={`card grid min-w-24 place-items-center px-3 py-3 text-center ${badge.unlocked_at ? 'shine' : 'opacity-40'}`}>
              <span className="text-3xl">{badge.emoji}</span>
              <span className="text-xs font-bold">{badge.name}</span>
            </div>
          ))}
        </div>
      </section>

      <section className="grid gap-2">
        <h2 className="font-display text-2xl font-extrabold">Reciente</h2>
        {recent.length === 0 ? <p className="text-muted">Todavía no hay partidas terminadas.</p> : recent.map((item, index) => (
          <div key={`${item.finished_at}-${index}`} className="card flex items-center justify-between px-4 py-3">
            <span>
              <span className="block font-bold">{modeName[item.mode] ?? item.mode}</span>
              <span className="text-sm text-muted">{item.kind === 'online' ? 'Online' : 'En la mesa'}</span>
            </span>
            <span className={`font-bold ${item.result === 'win' ? 'text-taboo' : item.result === 'tie' ? 'text-quick' : 'text-muted'}`}>
              {item.result === 'win' ? 'Victoria' : item.result === 'tie' ? 'Empate' : 'Derrota'} · +{item.xp}
            </span>
          </div>
        ))}
      </section>

      <section>
        <h2 className="font-display text-2xl font-extrabold">Favoritos</h2>
        <div className="mt-2 grid grid-cols-3 gap-2">
          {(favorites.length ? favorites : [{ id: 'quiz' as GameType, played: 0 }]).map((item) => (
            <div key={item.id} className="card p-3 text-center">
              <p className="text-3xl">{GAMES[item.id].emoji}</p>
              <p className="font-bold">{GAMES[item.id].name}</p>
              <p className="text-xs text-muted">{item.played} partidas</p>
            </div>
          ))}
        </div>
      </section>

      <div className="grid grid-cols-2 gap-2">
        <Link to="/estadisticas" className="card px-4 py-4 font-bold">Estadísticas</Link>
        <Link to="/logros" className="card px-4 py-4 font-bold">Logros</Link>
      </div>

      <form onSubmit={save} className="card grid gap-3 p-4">
        <h2 className="font-display text-2xl font-extrabold">Personalizar</h2>
        <input value={name} onChange={(event) => setName(event.target.value)} className="min-h-14 rounded-2xl bg-white/10 px-4" />
        <input value={username} onChange={(event) => setUsername(event.target.value)} className="min-h-14 rounded-2xl bg-white/10 px-4" />
        <div className="grid grid-cols-8 gap-2">
          {AVATARS.map((item) => (
            <button key={item} type="button" onClick={() => setAvatar(item)} className={`rounded-xl py-2 text-2xl ${avatar === item ? 'bg-white' : 'bg-white/10'}`}>{item}</button>
          ))}
        </div>
        <p className="text-sm font-semibold">Banner</p>
        <div className="grid grid-cols-5 gap-2">
          {Object.keys(BANNERS).map((id) => (
            <button key={id} type="button" aria-label={BANNER_NAMES[id]} onClick={() => setBanner(id)} className={`h-10 rounded-xl ${banner === id ? 'ring-2 ring-white' : ''}`} style={{ background: BANNERS[id] }} />
          ))}
        </div>
        <p className="text-sm font-semibold">Marco</p>
        <div className="grid grid-cols-5 gap-2">
          {Object.keys(FRAMES).map((id) => (
            <button key={id} type="button" onClick={() => setFrame(id)} className="grid h-12 place-items-center rounded-full bg-ink text-xl" style={{ boxShadow: FRAMES[id] }}>
              {FRAME_NAMES[id].slice(0, 1)}
            </button>
          ))}
        </div>
        <label className="flex items-center justify-between rounded-2xl bg-white/10 px-4 py-3 font-semibold">
          Sonidos
          <input
            type="checkbox"
            checked={sound}
            onChange={(event) => {
              setSound(event.target.checked)
              setSoundEnabled(event.target.checked)
            }}
          />
        </label>
        {error ? <Banner text={error} /> : null}
        {message ? <p className="text-sm text-taboo">{message}</p> : null}
        <Button type="submit" tone="quick">Guardar perfil</Button>
      </form>

      <form onSubmit={suggest} className="grid gap-2">
        <label className="text-sm font-semibold">Sugerir una pregunta</label>
        <textarea value={suggestion} required minLength={12} onChange={(event) => setSuggestion(event.target.value)} className="min-h-24 rounded-2xl bg-white/10 p-3" placeholder="Categoría, pregunta y respuesta correcta" />
        <Button type="submit" tone="ghost">Enviar a moderación</Button>
      </form>
      {profile.admin ? <Link to="/admin" className="text-center font-bold text-quick">Abrir administración</Link> : null}
      <Button type="button" tone="ghost" onClick={() => supabase.auth.signOut()}>Cerrar sesión</Button>
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
