import { useEffect, useMemo, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useAuth } from '../auth/AuthProvider'
import { Banner, Button, Choice } from '../components/ui'
import { categories, createMatch } from '../lib/api'
import { supabase } from '../lib/supabase'
import { DIFFICULTIES, GAMES, TEAM_PRESETS, balanceOk, dealTeams, maxTeams } from '../lib/games'
import type { Category, DraftPlayer, GameConfig, GameType, Team } from '../types'

const tables = {
  quiz: 'quiz_categories',
  impostor: 'impostor_categories',
  taboo: 'taboo_categories',
  quick: 'quick_categories',
} as const

export function SetupPage() {
  const { game: gameParam } = useParams()
  const game = (gameParam ?? 'quiz') as GameType
  const meta = GAMES[game]
  const navigate = useNavigate()
  const { profile } = useAuth()
  const needsTeams = game === 'quiz' || game === 'taboo'
  const [step, setStep] = useState<'players' | 'teams' | 'config'>('players')
  const [players, setPlayers] = useState<DraftPlayer[]>([{ name: profile?.profile.display_name ?? 'Anfitrión', isHost: true }])
  const [draft, setDraft] = useState('')
  const [teamCount, setTeamCount] = useState(2)
  const [assigned, setAssigned] = useState<string[]>([])
  const [teams, setTeams] = useState<Team[]>(TEAM_PRESETS.slice(0, 2))
  const [picked, setPicked] = useState<number | null>(null)
  const [catalog, setCatalog] = useState<Category[]>([])
  const [categoryIds, setCategoryIds] = useState<string[]>([])
  const [allCategories, setAllCategories] = useState(true)
  const [difficulty, setDifficulty] = useState('normal')
  const [questionCount, setQuestionCount] = useState(10)
  const [seconds, setSeconds] = useState(game === 'quick' ? 10 : game === 'taboo' ? 60 : 15)
  const [rounds, setRounds] = useState(3)
  const [impostors, setImpostors] = useState(0)
  const [discuss, setDiscuss] = useState(60)
  const [mode, setMode] = useState<'individual' | 'elimination'>('individual')
  const [perPlayer, setPerPlayer] = useState(5)
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)
  const [configName, setConfigName] = useState('')

  useEffect(() => {
    if (!meta) return
    categories(tables[game]).then(setCatalog).catch((caught: Error) => setError(caught.message))
  }, [game, meta])

  const limit = maxTeams(players.length)
  const teamOptions = useMemo(() => Array.from({ length: Math.max(0, limit - 1) }, (_, index) => index + 2), [limit])

  if (!meta) return <Banner text="Ese juego no existe." />

  function addPlayer() {
    const name = draft.trim()
    if (!name) return
    if (players.some((player) => player.name.toLowerCase() === name.toLowerCase())) {
      setError('Ese nombre ya está')
      return
    }
    if (players.length >= (game === 'impostor' ? 12 : 16)) return
    setPlayers([...players, { name, isHost: false }])
    setDraft('')
    setError('')
  }

  function randomTeams() {
    const count = Math.min(teamCount, limit)
    const nextTeams = TEAM_PRESETS.slice(0, count)
    const dealt = dealTeams(players, count)
    setTeams(nextTeams)
    setAssigned(players.map((player) => dealt.find((item) => item.name === player.name)?.teamKey ?? nextTeams[0].key))
  }

  function moveTo(teamKey: string) {
    if (picked === null) return
    const next = [...assigned]
    next[picked] = teamKey
    setAssigned(next)
    setPicked(null)
  }

  async function saveConfig(config: GameConfig) {
    if (!configName.trim() || !profile) return
    await supabase.from('saved_configs').insert({
      user_id: profile.profile.id,
      game_type: game,
      name: configName.trim(),
      config,
    })
  }

  async function start() {
    setBusy(true)
    setError('')
    try {
      const config: GameConfig = {
        difficulty: difficulty || undefined,
        category_ids: allCategories ? [] : categoryIds,
      }
      if (needsTeams) {
        config.teams = teams
        if (!balanceOk(assigned) || assigned.length !== players.length) {
          throw new Error('Equilibra los equipos antes de empezar')
        }
      }
      if (game === 'quiz') {
        config.question_count = questionCount
        config.seconds = seconds
      }
      if (game === 'taboo') {
        config.rounds = rounds
        config.seconds = seconds
      }
      if (game === 'impostor') {
        config.impostor_count = impostors
        config.discuss_seconds = discuss
      }
      if (game === 'quick') {
        config.mode = mode
        config.seconds = seconds
        config.questions_per_player = perPlayer
      }
      if (configName.trim()) await saveConfig(config)
      const id = await createMatch(
        game,
        config,
        players.map((player, index) => ({
          name: player.name,
          is_host: player.isHost,
          team_key: needsTeams ? assigned[index] : undefined,
        })),
      )
      if (game === 'quiz') {
        const { drawQuiz } = await import('../lib/api')
        await drawQuiz(id)
      }
      if (game === 'impostor') {
        const { prepareImpostor } = await import('../lib/api')
        await prepareImpostor(id)
      }
      navigate(`/partida/${id}`)
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'No se ha podido crear la partida')
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="mx-auto grid w-full max-w-lg gap-4 animate-pop">
      <button type="button" className="text-left text-sm text-muted" onClick={() => navigate('/')}>← Juegos</button>
      <h1 className="font-display text-4xl font-extrabold">{meta.emoji} {meta.name}</h1>
      {error ? <Banner text={error} /> : null}

      {step === 'players' ? (
        <section className="grid gap-3">
          <p className="text-muted">Añade a quien esté en la mesa. Solo tú tienes cuenta.</p>
          <div className="grid gap-2">
            {players.map((player, index) => (
              <div key={`${player.name}-${index}`} className="card flex items-center justify-between px-4 py-3">
                <span className="text-lg font-bold">{player.name}</span>
                <span className="text-sm text-muted">{player.isHost ? '👑 Anfitrión' : 'Invitado'}</span>
                {player.isHost ? null : (
                  <button type="button" className="text-impostor" onClick={() => setPlayers(players.filter((_, item) => item !== index))}>Quitar</button>
                )}
              </div>
            ))}
          </div>
          <div className="flex gap-2">
            <input
              value={draft}
              maxLength={24}
              placeholder="+ Añadir jugador"
              onChange={(event) => setDraft(event.target.value)}
              onKeyDown={(event) => { if (event.key === 'Enter') { event.preventDefault(); addPlayer() } }}
              className="min-h-14 flex-1 rounded-2xl bg-white/10 px-4 text-lg"
            />
            <Button type="button" tone="light" className="w-auto px-5" onClick={addPlayer}>Añadir</Button>
          </div>
          <Button
            type="button"
            tone="quick"
            onClick={() => {
              if (game === 'impostor' && players.length < 3) return setError('Impostor necesita al menos 3 jugadores')
              if (needsTeams && players.length < 2) return setError('Hacen falta al menos 2 jugadores')
              setError('')
              if (needsTeams) {
                const count = Math.min(2, limit)
                setTeamCount(count)
                setTeams(TEAM_PRESETS.slice(0, count))
                setAssigned(players.map((_, index) => TEAM_PRESETS[index % count].key))
                setStep('teams')
              } else {
                setStep('config')
              }
            }}
          >
            Seguir
          </Button>
        </section>
      ) : null}

      {step === 'teams' ? (
        <section className="grid gap-3">
          <p className="text-muted">Toca a una persona y luego a su equipo. O repártelos al azar.</p>
          <div className="grid grid-cols-3 gap-2">
            {teamOptions.map((count) => (
              <Choice key={count} selected={teamCount === count} onClick={() => {
                setTeamCount(count)
                setTeams(TEAM_PRESETS.slice(0, count))
                setAssigned(players.map((_, index) => TEAM_PRESETS[index % count].key))
              }}>{count} equipos</Choice>
            ))}
          </div>
          <Button type="button" tone="ghost" onClick={randomTeams}>🎲 Equipos aleatorios</Button>
          <div className="grid gap-2">
            {players.map((player, index) => (
              <button
                key={player.name}
                type="button"
                onClick={() => setPicked(index)}
                className={`card flex items-center justify-between px-4 py-3 text-left ${picked === index ? 'ring-2 ring-quick' : ''}`}
              >
                <span className="font-bold">{player.name} {player.isHost ? '👑' : ''}</span>
                <span>{teams.find((team) => team.key === assigned[index])?.name ?? 'Sin equipo'}</span>
              </button>
            ))}
          </div>
          <div className="grid gap-2">
            {teams.map((team, index) => (
              <label key={team.key} className="grid gap-1">
                <span className="text-sm text-muted">Nombre del equipo</span>
                <div className="flex gap-2">
                  <input
                    value={team.name}
                    maxLength={24}
                    onChange={(event) => setTeams(teams.map((item, itemIndex) => itemIndex === index ? { ...item, name: event.target.value } : item))}
                    className="min-h-14 flex-1 rounded-2xl px-4 text-lg text-ink"
                    style={{ background: team.color }}
                  />
                  <Button type="button" tone="ghost" className="w-auto" onClick={() => moveTo(team.key)}>Mover aquí</Button>
                </div>
              </label>
            ))}
          </div>
          <Button type="button" tone="quick" onClick={() => balanceOk(assigned) ? setStep('config') : setError('Los equipos tienen que quedar equilibrados')}>Seguir</Button>
        </section>
      ) : null}

      {step === 'config' ? (
        <section className="grid gap-4">
          <CategoryPicker
            catalog={catalog}
            all={allCategories}
            selected={categoryIds}
            onAll={() => { setAllCategories(true); setCategoryIds([]) }}
            onToggle={(id) => {
              setAllCategories(false)
              setCategoryIds((current) => current.includes(id) ? current.filter((item) => item !== id) : [...current, id])
            }}
          />
          <div className="grid grid-cols-2 gap-2">
            {DIFFICULTIES.map((item) => (
              <Choice key={item.id || 'random'} selected={difficulty === item.id} onClick={() => setDifficulty(item.id)}>
                {item.emoji} {item.label}
              </Choice>
            ))}
          </div>
          {game === 'quiz' ? (
            <>
              <Picker label="Preguntas" values={[5, 10, 15, 20, 30]} value={questionCount} onChange={setQuestionCount} />
              <Picker label="Segundos" values={[10, 15, 20, 30]} value={seconds} onChange={setSeconds} />
            </>
          ) : null}
          {game === 'taboo' ? (
            <>
              <Picker label="Rondas" values={[1, 2, 3, 4, 5]} value={rounds} onChange={setRounds} />
              <Picker label="Segundos por turno" values={[30, 45, 60, 90]} value={seconds} onChange={setSeconds} />
            </>
          ) : null}
          {game === 'impostor' ? (
            <>
              <div className="grid grid-cols-3 gap-2">
                <Choice selected={impostors === 1} onClick={() => setImpostors(1)}>1 impostor</Choice>
                <Choice selected={impostors === 2} onClick={() => setImpostors(2)}>2 impostores</Choice>
                <Choice selected={impostors === 0} onClick={() => setImpostors(0)}>🎲 Azar</Choice>
              </div>
              <Picker label="Debate" values={[30, 60, 90, 120]} value={discuss} onChange={setDiscuss} />
            </>
          ) : null}
          {game === 'quick' ? (
            <>
              <div className="grid grid-cols-2 gap-2">
                <Choice selected={mode === 'individual'} onClick={() => setMode('individual')}>Individual</Choice>
                <Choice selected={mode === 'elimination'} onClick={() => setMode('elimination')}>Eliminación</Choice>
              </div>
              <Picker label="Segundos" values={[5, 10]} value={seconds} onChange={setSeconds} />
              {mode === 'individual' ? <Picker label="Retos por jugador" values={[3, 5, 8]} value={perPlayer} onChange={setPerPlayer} /> : null}
            </>
          ) : null}
          <label className="grid gap-1 text-sm">
            Guardar esta configuración (opcional)
            <input value={configName} maxLength={40} onChange={(event) => setConfigName(event.target.value)} placeholder="Viernes de quiz" className="min-h-14 rounded-2xl bg-white/10 px-4 text-lg" />
          </label>
          <Button type="button" tone="quick" disabled={busy} onClick={start}>{busy ? 'Preparando…' : 'Empezar a jugar'}</Button>
        </section>
      ) : null}
    </div>
  )
}

function Picker({ label, values, value, onChange }: { label: string; values: number[]; value: number; onChange: (value: number) => void }) {
  return (
    <div>
      <p className="mb-2 text-sm font-semibold">{label}</p>
      <div className="grid grid-cols-5 gap-2">
        {values.map((item) => (
          <Choice key={item} selected={value === item} onClick={() => onChange(item)}>{item}</Choice>
        ))}
      </div>
    </div>
  )
}

function CategoryPicker({
  catalog,
  all,
  selected,
  onAll,
  onToggle,
}: {
  catalog: Category[]
  all: boolean
  selected: string[]
  onAll: () => void
  onToggle: (id: string) => void
}) {
  return (
    <div>
      <p className="mb-2 text-sm font-semibold">Categorías</p>
      <div className="grid grid-cols-2 gap-2">
        <Choice selected={all} onClick={onAll}>🎲 Todas</Choice>
        {catalog.map((category) => (
          <Choice key={category.id} selected={!all && selected.includes(category.id)} onClick={() => onToggle(category.id)}>
            {category.emoji} {category.name}
          </Choice>
        ))}
      </div>
    </div>
  )
}
