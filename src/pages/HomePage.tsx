import { Link } from 'react-router-dom'
import { useAuth } from '../auth/AuthProvider'
import { GAMES } from '../lib/games'
import type { GameType } from '../types'

const order: GameType[] = ['quiz', 'impostor', 'taboo', 'quick']

export function HomePage() {
  const { profile } = useAuth()
  return (
    <div className="mx-auto w-full max-w-lg animate-pop">
      <div className="flex items-center gap-3">
        <img src="/logo.png" alt="" className="h-16 w-16 rounded-2xl" />
        <div>
          <p className="text-sm font-semibold uppercase tracking-[0.2em] text-quick">La quedada</p>
          <h1 className="font-display text-5xl font-extrabold leading-none">PlayLeague</h1>
        </div>
      </div>
      <p className="mt-2 text-lg text-muted">
        Hola {profile?.profile.display_name ?? 'anfitrión'}. Elige un juego y pasa el móvil.
      </p>
      <div className="mt-6 grid gap-3">
        {order.map((id) => {
          const game = GAMES[id]
          return (
            <Link
              key={id}
              to={`/nueva/${id}`}
              className="card flex items-center gap-4 p-4"
              style={{ boxShadow: `inset 6px 0 0 ${game.tint}` }}
            >
              <span className="grid h-16 w-16 place-items-center rounded-2xl text-4xl" style={{ background: `${game.tint}22` }}>
                {game.emoji}
              </span>
              <span>
                <span className="block font-display text-2xl font-extrabold">{game.name}</span>
                <span className="text-muted">{game.blurb}</span>
              </span>
            </Link>
          )
        })}
      </div>
    </div>
  )
}
