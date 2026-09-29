import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { getMatch } from '../lib/api'
import type { MatchState, Summary } from '../types'
import { Banner } from '../components/ui'
import { QuizPlay } from '../games/QuizPlay'
import { ImpostorPlay } from '../games/ImpostorPlay'
import { TabooPlay } from '../games/TabooPlay'
import { QuickPlay } from '../games/QuickPlay'
import { Results } from '../games/Results'

export function MatchPage() {
  const { id } = useParams()
  const [match, setMatch] = useState<MatchState | null>(null)
  const [summary, setSummary] = useState<Summary | null>(null)
  const [error, setError] = useState('')

  useEffect(() => {
    if (!id) return
    getMatch(id).then((data) => {
      setMatch(data)
      if (data.summary) setSummary(data.summary)
    }).catch((caught: Error) => setError(caught.message))
  }, [id])

  if (error) return <Banner text={error} />
  if (!match) return <p className="text-center font-display text-2xl">Cargando partida…</p>
  if (summary || match.status === 'finished') {
    return summary || match.summary ? <Results summary={(summary ?? match.summary)!} /> : <Link to="/">Volver</Link>
  }
  if (match.game_type === 'quiz' && match.quiz) return <QuizPlay match={match} onDone={setSummary} />
  if (match.game_type === 'impostor') return <ImpostorPlay match={match} onDone={setSummary} />
  if (match.game_type === 'taboo') return <TabooPlay match={match} onDone={setSummary} />
  if (match.game_type === 'quick') return <QuickPlay match={match} onDone={setSummary} />
  return <Banner text="No se ha podido abrir la partida." />
}
