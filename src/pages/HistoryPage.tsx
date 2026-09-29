import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { supabase } from '../lib/supabase'
import { GAMES } from '../lib/games'
import type { GameType, Summary } from '../types'
import { Results } from '../games/Results'

type Row = {
  id: string
  game_type: GameType
  finished_at: string | null
  xp_awarded: number
  summary: Summary | null
}

export function HistoryPage() {
  const { id } = useParams()
  const [rows, setRows] = useState<Row[]>([])
  const [error, setError] = useState('')

  useEffect(() => {
    supabase
      .from('games')
      .select('id, game_type, finished_at, xp_awarded, summary')
      .eq('status', 'finished')
      .order('finished_at', { ascending: false })
      .limit(40)
      .then(({ data, error: queryError }) => {
        if (queryError) setError(queryError.message)
        else setRows((data ?? []) as Row[])
      })
  }, [])

  const selected = rows.find((row) => row.id === id)
  if (selected?.summary) {
    return (
      <div>
        <Link to="/historial" className="mb-3 block text-sm text-muted">← Historial</Link>
        <Results summary={selected.summary} />
      </div>
    )
  }

  return (
    <div className="mx-auto grid w-full max-w-lg gap-3">
      <h1 className="font-display text-4xl font-extrabold">Historial</h1>
      {error ? <p>{error}</p> : null}
      {rows.length === 0 ? <p className="text-muted">Todavía no hay partidas guardadas.</p> : null}
      {rows.map((row) => {
        const meta = GAMES[row.game_type]
        return (
          <Link key={row.id} to={`/historial/${row.id}`} className="card flex items-center justify-between p-4">
            <span>
              <span className="block font-bold">{meta.emoji} {meta.name}</span>
              <span className="text-sm text-muted">{row.summary?.winner_label ?? 'Terminada'}</span>
            </span>
            <span className="font-bold text-quick">+{row.xp_awarded} XP</span>
          </Link>
        )
      })}
    </div>
  )
}
