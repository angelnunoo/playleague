import { Link } from 'react-router-dom'
import type { Summary } from '../types'
import { Button, Progress } from '../components/ui'
import { Confetti } from '../components/Fx'
import { GAMES } from '../lib/games'

export function Results({ summary }: { summary: Summary }) {
  const meta = GAMES[summary.game_type]
  const leveled = summary.level.after > summary.level.before
  return (
    <div className="mx-auto grid w-full max-w-lg gap-4 animate-pop text-center">
      {leveled ? <Confetti show /> : null}
      <p className="text-sm uppercase tracking-[0.2em] text-muted">{meta.emoji} {meta.name}</p>
      <p className="text-6xl">🏆</p>
      <h1 className="font-display text-4xl font-extrabold">{summary.winner_label || 'Partida terminada'}</h1>
      {leveled ? (
        <div className="card shine p-4">
          <p className="text-sm font-bold uppercase tracking-[0.2em] text-quick">Subes de nivel</p>
          <p className="font-display text-4xl font-extrabold">Nivel {summary.level.after}</p>
        </div>
      ) : null}
      <p className="font-display text-3xl font-extrabold text-quick">Has conseguido +{summary.xp} XP</p>
      <div className="card p-4 text-left">
        <Progress xp={summary.level.xp} floor={summary.level.floor} ceil={summary.level.ceil} level={summary.level.after} />
        <p className="mt-3 text-sm text-muted">Nivel {summary.level.before} → {summary.level.after} · {summary.level.title}</p>
        <ul className="mt-3 grid gap-1 text-sm">
          {summary.xp_breakdown.map((line) => (
            <li key={line.label} className="flex justify-between"><span>{line.label}</span><span>+{line.xp}</span></li>
          ))}
        </ul>
      </div>
      {summary.quiz ? (
        <StatGrid items={[
          ['Aciertos', summary.quiz.correct],
          ['Fallos', summary.quiz.wrong],
          ['Acierto', `${summary.quiz.accuracy}%`],
          ['Mejor jugador', summary.quiz.best_player],
          ['Mejor categoría', summary.quiz.best_category ?? '—'],
        ]} />
      ) : null}
      {summary.taboo ? (
        <StatGrid items={[
          ['Acertadas', summary.taboo.correct],
          ['Pasadas', summary.taboo.failed],
          ['Prohibidas', summary.taboo.forbidden],
          ['Mejor jugador', summary.taboo.best_player],
        ]} />
      ) : null}
      {summary.quick ? (
        <StatGrid items={[
          ['Correctas', summary.quick.correct],
          ['Fallos', summary.quick.wrong],
          ['Mejor racha', summary.quick.best_streak],
          ['Mejor jugador', summary.quick.best_player],
        ]} />
      ) : null}
      {summary.word ? (
        <div className="card p-4">
          <p className="text-muted">La palabra era</p>
          <p className="font-display text-3xl font-extrabold">{summary.emoji} {summary.word}</p>
          <p className="mt-2">Impostor: {summary.impostors}</p>
          {summary.guess ? <p>Intento: {summary.guess} {summary.guess_ok ? '✓' : '✗'}</p> : null}
          <ul className="mt-3 text-left text-sm">
            {(summary.votes ?? []).map((vote) => (
              <li key={`${vote.voter}-${vote.target}`}>{vote.voter} → {vote.target}</li>
            ))}
          </ul>
        </div>
      ) : null}
      {summary.teams ? (
        <div className="grid gap-2">
          {summary.teams.map((team) => (
            <div key={team.team_key} className="card flex items-center justify-between px-4 py-3">
              <span className="font-bold">{team.name}</span>
              <span>{team.score} pts</span>
            </div>
          ))}
        </div>
      ) : null}
      {summary.achievements.length ? (
        <div className="grid gap-2">
          {summary.achievements.map((item) => (
            <p key={item.slug} className="card px-4 py-3">{item.emoji} {item.name} +{item.xp} XP</p>
          ))}
        </div>
      ) : null}
      <Link to="/perfil"><Button type="button" tone="quick">Ver mi perfil</Button></Link>
      <Link to="/"><Button type="button" tone="ghost">Otra partida</Button></Link>
    </div>
  )
}

function StatGrid({ items }: { items: [string, string | number][] }) {
  return (
    <div className="grid grid-cols-2 gap-2 text-left">
      {items.map(([label, value]) => (
        <div key={label} className="card p-3">
          <p className="text-xs text-muted">{label}</p>
          <p className="text-xl font-bold">{value}</p>
        </div>
      ))}
    </div>
  )
}
