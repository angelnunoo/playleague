import { useEffect, useState, type FormEvent } from 'react'
import { Link, Navigate } from 'react-router-dom'
import { useAuth } from '../auth/AuthProvider'
import { supabase } from '../lib/supabase'
import { adminOverview, importImpostor, importQuick, importQuiz, importTaboo, reviewSubmission } from '../lib/api'
import { Banner, Button } from '../components/ui'

type Tab = 'resumen' | 'quiz' | 'importar' | 'moderacion' | 'usuarios' | 'partidas'

export function AdminPage() {
  const { profile } = useAuth()
  const [tab, setTab] = useState<Tab>('resumen')
  const [overview, setOverview] = useState<Record<string, number> | null>(null)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')

  useEffect(() => {
    if (!profile?.admin) return
    adminOverview().then(setOverview).catch((caught: Error) => setError(caught.message))
  }, [profile?.admin])

  if (!profile?.admin) return <Navigate to="/perfil" replace />

  return (
    <div className="mx-auto grid w-full max-w-3xl gap-4">
      <Link to="/perfil" className="text-sm text-muted">← Perfil</Link>
      <h1 className="font-display text-4xl font-extrabold">Administración</h1>
      <div className="flex gap-2 overflow-auto">
        {(['resumen', 'quiz', 'importar', 'moderacion', 'usuarios', 'partidas'] as Tab[]).map((item) => (
          <button key={item} type="button" onClick={() => setTab(item)} className={`rounded-full px-3 py-2 text-sm font-bold ${tab === item ? 'bg-white text-ink' : 'bg-white/10'}`}>{item}</button>
        ))}
      </div>
      {error ? <Banner text={error} /> : null}
      {message ? <p className="text-taboo">{message}</p> : null}
      {tab === 'resumen' && overview ? (
        <div className="grid grid-cols-2 gap-2">
          {Object.entries(overview).map(([key, value]) => (
            <div key={key} className="card p-4"><p className="text-xs text-muted">{key}</p><p className="text-2xl font-bold">{value}</p></div>
          ))}
        </div>
      ) : null}
      {tab === 'quiz' ? <QuizEditor onMessage={setMessage} onError={setError} /> : null}
      {tab === 'importar' ? <Importer onMessage={setMessage} onError={setError} /> : null}
      {tab === 'moderacion' ? <Moderation onMessage={setMessage} onError={setError} /> : null}
      {tab === 'usuarios' ? <Users /> : null}
      {tab === 'partidas' ? <Matches /> : null}
    </div>
  )
}

function QuizEditor({ onMessage, onError }: { onMessage: (text: string) => void; onError: (text: string) => void }) {
  const [categories, setCategories] = useState<{ id: string; name: string }[]>([])
  const [categoryId, setCategoryId] = useState('')
  const [difficulty, setDifficulty] = useState('normal')
  const [prompt, setPrompt] = useState('')
  const [answers, setAnswers] = useState(['', '', '', ''])
  const [correct, setCorrect] = useState(0)

  useEffect(() => {
    supabase.from('quiz_categories').select('id, name').order('sort').then(({ data }) => {
      const rows = (data ?? []) as { id: string; name: string }[]
      setCategories(rows)
      if (rows[0]) setCategoryId(rows[0].id)
    })
  }, [])

  async function save(event: FormEvent) {
    event.preventDefault()
    const { data, error } = await supabase.from('quiz_questions').insert({
      category_id: categoryId,
      difficulty,
      prompt: prompt.trim(),
    }).select('id').single()
    if (error || !data) {
      onError(error?.message ?? 'No se ha podido crear')
      return
    }
    const { error: answerError } = await supabase.from('quiz_answers').insert(
      answers.map((text, index) => ({ question_id: data.id, text: text.trim(), is_correct: index === correct, sort_order: index })),
    )
    if (answerError) onError(answerError.message)
    else {
      onMessage('Pregunta creada')
      setPrompt('')
      setAnswers(['', '', '', ''])
    }
  }

  return (
    <form onSubmit={save} className="grid gap-3">
      <select value={categoryId} onChange={(event) => setCategoryId(event.target.value)} className="min-h-12 rounded-2xl bg-white/10 px-3">
        {categories.map((category) => <option key={category.id} value={category.id}>{category.name}</option>)}
      </select>
      <select value={difficulty} onChange={(event) => setDifficulty(event.target.value)} className="min-h-12 rounded-2xl bg-white/10 px-3">
        <option value="easy">Fácil</option>
        <option value="normal">Normal</option>
        <option value="hard">Difícil</option>
        <option value="expert">Experto</option>
      </select>
      <textarea required minLength={8} value={prompt} onChange={(event) => setPrompt(event.target.value)} placeholder="Pregunta" className="min-h-24 rounded-2xl bg-white/10 p-3" />
      {answers.map((answer, index) => (
        <label key={index} className="flex items-center gap-2">
          <input type="radio" name="correct" checked={correct === index} onChange={() => setCorrect(index)} />
          <input required value={answer} onChange={(event) => setAnswers(answers.map((item, itemIndex) => itemIndex === index ? event.target.value : item))} className="min-h-12 flex-1 rounded-2xl bg-white/10 px-3" placeholder={`Respuesta ${index + 1}`} />
        </label>
      ))}
      <Button type="submit" tone="quick">Crear pregunta</Button>
      <p className="text-sm text-muted">Para desactivar una pregunta, márcala como inactiva desde la tabla en Supabase o importa un CSV nuevo. Las preguntas inactivas dejan de salir en las partidas.</p>
    </form>
  )
}

function Importer({ onMessage, onError }: { onMessage: (text: string) => void; onError: (text: string) => void }) {
  const [kind, setKind] = useState<'quiz' | 'impostor' | 'taboo' | 'quick'>('quiz')
  const [text, setText] = useState('category_slug,difficulty,prompt,a,b,c,d,correct\nfutbol,easy,¿En qué año ganó España el Mundial?,2006,2010,2014,2018,B\n')

  async function run() {
    try {
      const rows = parseCsv(text)
      const header = rows[0]?.map((cell) => cell.trim()) ?? []
      const body = rows.slice(1).filter((row) => row.some(Boolean))
      let count = 0
      const chunks = chunk(body, 200)
      for (const part of chunks) {
        if (kind === 'quiz') {
          count += await importQuiz(part.map((row) => record(header, row)).map(quizRow))
        } else if (kind === 'impostor') {
          count += await importImpostor(part.map((row) => record(header, row)))
        } else if (kind === 'taboo') {
          count += await importTaboo(part.map((row) => {
            const item = record(header, row)
            return { ...item, forbidden: String(item.forbidden ?? '').split('|').map((word) => word.trim()).filter(Boolean) }
          }))
        } else {
          count += await importQuick(part.map((row) => record(header, row)))
        }
      }
      onMessage(`Importadas ${count} filas`)
    } catch (caught) {
      onError(caught instanceof Error ? caught.message : 'CSV no válido')
    }
  }

  return (
    <div className="grid gap-3">
      <select value={kind} onChange={(event) => setKind(event.target.value as typeof kind)} className="min-h-12 rounded-2xl bg-white/10 px-3">
        <option value="quiz">Quiz</option>
        <option value="impostor">Impostor</option>
        <option value="taboo">Tabú</option>
        <option value="quick">Responde rápido</option>
      </select>
      <textarea value={text} onChange={(event) => setText(event.target.value)} className="min-h-64 rounded-2xl bg-black/30 p-3 font-mono text-sm" />
      <p className="text-sm text-muted">Quiz: category_slug,difficulty,prompt,a,b,c,d,correct. Tabú: category_slug,word,emoji,forbidden con palabras separadas por |. Impostor: category_slug,word,emoji,difficulty. Rápido: category_slug,prompt,difficulty. Puedes pegar cientos de filas; se envían de 200 en 200.</p>
      <Button type="button" tone="quick" onClick={run}>Importar CSV</Button>
    </div>
  )
}

function Moderation({ onMessage, onError }: { onMessage: (text: string) => void; onError: (text: string) => void }) {
  const [rows, setRows] = useState<{ id: string; kind: string; payload: unknown; status: string }[]>([])
  useEffect(() => {
    supabase.from('content_submissions').select('id, kind, payload, status').eq('status', 'pending').then(({ data }) => setRows((data ?? []) as typeof rows))
  }, [])
  return (
    <div className="grid gap-2">
      {rows.length === 0 ? <p className="text-muted">No hay envíos pendientes.</p> : null}
      {rows.map((row) => (
        <article key={row.id} className="card p-3 text-left">
          <p className="text-sm text-muted">{row.kind}</p>
          <pre className="overflow-auto text-xs">{JSON.stringify(row.payload, null, 2)}</pre>
          <div className="mt-2 grid grid-cols-2 gap-2">
            <Button type="button" tone="taboo" onClick={() => reviewSubmission(row.id, 'approved').then(() => onMessage('Aprobado')).catch((caught: Error) => onError(caught.message))}>Aprobar</Button>
            <Button type="button" tone="ghost" onClick={() => reviewSubmission(row.id, 'rejected').then(() => onMessage('Rechazado')).catch((caught: Error) => onError(caught.message))}>Rechazar</Button>
          </div>
        </article>
      ))}
    </div>
  )
}

function Users() {
  const [rows, setRows] = useState<{ username: string; display_name: string; level: number; xp: number; role: string }[]>([])
  useEffect(() => {
    supabase.from('profiles').select('username, display_name, level, xp, role').order('xp', { ascending: false }).limit(50).then(({ data }) => setRows((data ?? []) as typeof rows))
  }, [])
  return (
    <div className="grid gap-2">
      {rows.map((row) => (
        <div key={row.username} className="card flex justify-between px-4 py-3 text-sm">
          <span>{row.display_name} @{row.username}</span>
          <span>Nv {row.level} · {row.xp} XP · {row.role}</span>
        </div>
      ))}
    </div>
  )
}

function Matches() {
  const [rows, setRows] = useState<{ id: string; game_type: string; status: string; created_at: string }[]>([])
  useEffect(() => {
    supabase.from('games').select('id, game_type, status, created_at').order('created_at', { ascending: false }).limit(30).then(({ data }) => setRows((data ?? []) as typeof rows))
  }, [])
  return (
    <div className="grid gap-2">
      {rows.map((row) => (
        <div key={row.id} className="card flex justify-between px-4 py-3 text-sm">
          <span>{row.game_type}</span>
          <span>{row.status}</span>
        </div>
      ))}
    </div>
  )
}

function quizRow(row: Record<string, string>) {
  const letter = (row.correct ?? 'A').trim().toUpperCase()
  const index = 'ABCD'.indexOf(letter)
  return {
    category_slug: row.category_slug,
    difficulty: row.difficulty,
    prompt: row.prompt,
    answers: [row.a, row.b, row.c, row.d],
    correct_index: index >= 0 ? index : Number(row.correct ?? 0),
  }
}

function record(header: string[], row: string[]) {
  return Object.fromEntries(header.map((key, index) => [key, row[index] ?? '']))
}

function chunk<T>(items: T[], size: number) {
  const parts: T[][] = []
  for (let index = 0; index < items.length; index += size) parts.push(items.slice(index, index + size))
  return parts
}

function parseCsv(text: string) {
  return text.trim().split(/\r?\n/).map((line) => {
    const cells: string[] = []
    let current = ''
    let quoted = false
    for (const char of line) {
      if (char === '"') quoted = !quoted
      else if (char === ',' && !quoted) {
        cells.push(current)
        current = ''
      } else current += char
    }
    cells.push(current)
    return cells
  })
}
