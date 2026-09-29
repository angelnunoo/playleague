import { Link } from 'react-router-dom'
import { useAuth } from '../auth/AuthProvider'

export function StatsPage() {
  const { profile } = useAuth()
  if (!profile) return null
  const stats = profile.stats
  const accuracy = stats.quiz_correct + stats.quiz_wrong === 0
    ? 0
    : Math.round((100 * stats.quiz_correct) / (stats.quiz_correct + stats.quiz_wrong))
  const avg = stats.quick_time_count ? Math.round(stats.quick_time_total_ms / stats.quick_time_count) : 0

  return (
    <div className="mx-auto grid w-full max-w-lg gap-4">
      <Link to="/perfil" className="text-sm text-muted">← Perfil</Link>
      <h1 className="font-display text-4xl font-extrabold">Estadísticas</h1>
      <Block title="General" rows={[
        ['Partidas', stats.games_played],
        ['Victorias', stats.wins],
        ['Derrotas', stats.losses],
        ['Racha actual', stats.current_streak],
        ['Mejor racha', stats.best_streak],
        ['Nivel', profile.profile.level],
        ['XP', profile.profile.xp],
      ]} />
      <Block title="🧠 Quiz" rows={[
        ['Partidas', stats.quiz_played],
        ['Victorias', stats.quiz_wins],
        ['Aciertos', stats.quiz_correct],
        ['Fallos', stats.quiz_wrong],
        ['Porcentaje', `${accuracy}%`],
        ['Mejor racha', stats.quiz_best_streak],
        ['Mejor categoría', profile.best_category ?? '—'],
      ]} />
      <Block title="🕵️ Impostor" rows={[
        ['Partidas', stats.impostor_played],
        ['Veces impostor', stats.impostor_times],
        ['Victorias como impostor', stats.impostor_wins],
        ['Veces descubierto', stats.impostor_caught],
        ['Veces descubriendo', stats.impostor_catches],
      ]} />
      <Block title="🗣️ Tabú" rows={[
        ['Partidas', stats.taboo_played],
        ['Victorias', stats.taboo_wins],
        ['Palabras acertadas', stats.taboo_correct],
        ['Pasadas', stats.taboo_failed],
        ['Prohibidas', stats.taboo_forbidden],
      ]} />
      <Block title="⚡ Responde rápido" rows={[
        ['Partidas', stats.quick_played],
        ['Victorias', stats.quick_wins],
        ['Correctas', stats.quick_correct],
        ['Mejor racha', stats.quick_best_streak],
        ['Tiempo medio', avg ? `${(avg / 1000).toFixed(1)} s` : '—'],
      ]} />
    </div>
  )
}

function Block({ title, rows }: { title: string; rows: [string, string | number | null][] }) {
  return (
    <section className="card p-4">
      <h2 className="font-display text-2xl font-extrabold">{title}</h2>
      <dl className="mt-2 grid gap-2">
        {rows.map(([label, value]) => (
          <div key={label} className="flex justify-between gap-4 text-sm">
            <dt className="text-muted">{label}</dt>
            <dd className="font-bold">{value ?? 0}</dd>
          </div>
        ))}
      </dl>
    </section>
  )
}
