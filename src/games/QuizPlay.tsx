import { useEffect, useMemo, useRef, useState } from 'react'
import { answerQuiz, finishMatch, focusQuiz } from '../lib/api'
import { turnOf } from '../lib/games'
import type { MatchState, QuizQuestion, Summary, Team } from '../types'
import { Banner, Button, PassPhone, Timer } from '../components/ui'

export function QuizPlay({
  match,
  onDone,
}: {
  match: MatchState
  onDone: (summary: Summary) => void
}) {
  const quiz = match.quiz
  const teams = (match.config.teams as Team[] | undefined) ?? []
  const questions = quiz?.questions ?? []
  const responses = quiz?.responses ?? []
  const [askingId, setAskingId] = useState<string | null>(null)
  const [phase, setPhase] = useState<'ready' | 'ask' | 'reveal'>('ready')
  const [reveal, setReveal] = useState<{ correct: boolean; text: string; points: number; answerId: string | null } | null>(null)
  const [localResponses, setLocalResponses] = useState(responses)
  const [scores, setScores] = useState(quiz?.scores ?? [])
  const [error, setError] = useState('')
  const [running, setRunning] = useState(false)
  const [locked, setLocked] = useState(false)

  const pending = questions.find((question) => !localResponses.some((response) => response.question_id === question.id))
  const shown = questions.find((question) => question.id === (phase === 'ready' ? pending?.id : askingId)) ?? pending
  const active = useMemo(() => (shown ? turnOf(match.players, teams, shown.position) : null), [shown, match.players, teams])

  if (!quiz || !shown || !active) {
    return <Button type="button" tone="quiz" onClick={() => finishMatch(match.id).then(onDone).catch((caught: Error) => setError(caught.message))}>Ver resultado</Button>
  }

  async function openQuestion(question: QuizQuestion) {
    setError('')
    try {
      await focusQuiz(match.id, question.id)
      setAskingId(question.id)
      setPhase('ask')
      setRunning(true)
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'No se ha podido abrir la pregunta')
    }
  }

  async function choose(answerId: string | null) {
    if (locked || !shown) return
    setLocked(true)
    setRunning(false)
    try {
      const result = await answerQuiz(match.id, shown.id, answerId)
      setReveal({ correct: result.correct, text: result.correct_text, points: result.points, answerId })
      setScores(result.quiz?.scores ?? scores)
      setLocalResponses(result.quiz?.responses ?? localResponses)
      setPhase('reveal')
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'No se ha podido responder')
      setLocked(false)
    }
  }

  function next() {
    const upcoming = questions.find((question) => !localResponses.some((response) => response.question_id === question.id))
    setReveal(null)
    setLocked(false)
    setAskingId(null)
    if (!upcoming) {
      finishMatch(match.id).then(onDone).catch((caught: Error) => setError(caught.message))
      return
    }
    setPhase('ready')
  }

  return (
    <div className="mx-auto grid w-full max-w-lg gap-4">
      {error ? <Banner text={error} /> : null}
      <div className="flex flex-wrap gap-2">
        {scores.map((score) => (
          <span key={score.team_key} className="rounded-full px-3 py-1 text-sm font-bold text-ink" style={{ background: score.color }}>
            {score.name} {score.score}
          </span>
        ))}
      </div>
      {phase === 'ready' ? (
        <PassPhone
          name={active.player?.name ?? active.team.name}
          hint={`${active.team.name} · pregunta ${shown.position + 1}/${questions.length}. Tocad cuando estéis listos.`}
          onReady={() => openQuestion(shown)}
        />
      ) : null}
      {phase === 'ask' ? (
        <section className="grid gap-4 animate-pop">
          <div className="flex items-center justify-between">
            <p className="font-bold" style={{ color: active.team.color }}>{active.team.name}</p>
            <Timer seconds={quiz.seconds} running={running} onExpire={() => choose(null)} />
          </div>
          <p className="text-sm text-muted">{shown.emoji} {shown.category} · {shown.position + 1}/{questions.length}</p>
          <h2 className="font-display text-3xl font-extrabold">{shown.prompt}</h2>
          <div className="grid gap-2">
            {shown.answers.map((answer, index) => (
              <Button key={answer.id} type="button" tone="ghost" className="text-left" onClick={() => choose(answer.id)}>
                {String.fromCharCode(65 + index)}) {answer.text}
              </Button>
            ))}
          </div>
        </section>
      ) : null}
      {phase === 'reveal' && reveal ? (
        <section className={`card grid gap-3 p-5 ${reveal.correct ? '' : 'animate-shake'}`}>
          <p className="font-display text-4xl font-extrabold">{reveal.correct ? '¡Correcto!' : 'Fallado'}</p>
          <p>La respuesta era: <strong>{reveal.text}</strong></p>
          <p className="text-quick">{reveal.points > 0 ? `+${reveal.points} puntos` : '0 puntos'}</p>
          <Button type="button" tone="quiz" onClick={next}>Siguiente</Button>
          <AutoNext onNext={next} />
        </section>
      ) : null}
    </div>
  )
}

function AutoNext({ onNext }: { onNext: () => void }) {
  const onNextRef = useRef(onNext)
  onNextRef.current = onNext
  useEffect(() => {
    const id = window.setTimeout(() => onNextRef.current(), 1400)
    return () => window.clearTimeout(id)
  }, [])
  return null
}
