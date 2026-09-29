import { LEAGUE_MARK, RANKS, rankProgress } from '../lib/leagues'

export function RankBoard({ rating, detailed = false, own = true }: { rating: number; detailed?: boolean; own?: boolean }) {
  const { current, next, index, total, left, ratio, points } = rankProgress(rating)

  return (
    <section className="card grid gap-3 p-4">
      <div className="flex items-end justify-between gap-3">
        <div>
          <p className="text-xs font-bold uppercase tracking-[0.16em] text-muted">Competitivo · {index + 1} de {total}</p>
          <p className="font-display text-2xl font-extrabold" style={{ color: current.color }}>
            {LEAGUE_MARK[current.slug]} {current.name}
          </p>
        </div>
        <p className="text-right text-sm font-bold">{points} pts</p>
      </div>
      <div className="h-2 overflow-hidden rounded-full bg-white/10">
        <div className="h-full rounded-full" style={{ width: `${ratio * 100}%`, background: current.color }} />
      </div>
      <p className="text-sm font-semibold">
        {next
          ? `${own ? 'Te faltan' : 'Le faltan'} ${left} puntos para ${next.name}`
          : own ? 'Estás en el último rango' : 'Está en el último rango'}
      </p>
      {detailed ? (
        <ol className="grid gap-1">
          {RANKS.map((rank, position) => {
            const here = rank.slug === current.slug
            const reached = points >= rank.floor
            return (
              <li
                key={rank.slug}
                className={`flex items-center gap-2 rounded-xl px-2 py-1.5 text-sm ${here ? 'bg-white/10' : ''}`}
                style={{ opacity: reached || here ? 1 : 0.45 }}
              >
                <span className="w-5 text-center text-xs font-bold text-muted">{position + 1}</span>
                <span>{LEAGUE_MARK[rank.slug]}</span>
                <span className="flex-1 font-bold" style={{ color: here ? rank.color : undefined }}>{rank.name}</span>
                <span className="text-xs text-muted">{rank.floor} pts</span>
                <span className="w-8 text-right text-xs font-bold">{here ? (own ? 'Tú' : 'Aquí') : reached ? '✓' : ''}</span>
              </li>
            )
          })}
        </ol>
      ) : (
        <div className="flex justify-between text-lg" aria-label={`${total} rangos`}>
          {RANKS.map((rank) => (
            <span key={rank.slug} title={`${rank.name} · ${rank.floor} pts`} style={{ opacity: points >= rank.floor ? 1 : 0.35 }}>
              {LEAGUE_MARK[rank.slug]}
            </span>
          ))}
        </div>
      )}
      <p className="text-xs text-muted">Hay {total} rangos. Los puntos solo cambian en partidas online contra otra gente.</p>
    </section>
  )
}
