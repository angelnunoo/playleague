import { useEffect, useRef, useState, type ButtonHTMLAttributes, type ReactNode } from 'react'
import { GAMES } from '../lib/games'
import { playTap } from '../lib/sound'
import type { GameType } from '../types'

export function tap() {
  navigator.vibrate?.(12)
}

export function Button({
  tone = 'light',
  ...props
}: ButtonHTMLAttributes<HTMLButtonElement> & { tone?: 'light' | 'ghost' | 'quiz' | 'impostor' | 'taboo' | 'quick' | 'danger' }) {
  const tones: Record<string, string> = {
    light: 'bg-white text-ink',
    ghost: 'bg-white/10 text-white',
    quiz: 'bg-quiz text-ink',
    impostor: 'bg-impostor text-white',
    taboo: 'bg-taboo text-ink',
    quick: 'bg-quick text-ink',
    danger: 'bg-impostor text-white',
  }
  return (
    <button
      {...props}
      onClick={(event) => {
        tap()
        playTap()
        props.onClick?.(event)
      }}
      className={`touch w-full disabled:opacity-50 ${tones[tone]} ${props.className ?? ''}`}
    />
  )
}

export function Choice({
  selected,
  children,
  onClick,
}: {
  selected?: boolean
  children: ReactNode
  onClick: () => void
}) {
  return (
    <button
      type="button"
      onClick={() => {
        tap()
        onClick()
      }}
      className={`touch text-left ${selected ? 'bg-white text-ink' : 'bg-white/10'}`}
    >
      {children}
    </button>
  )
}

export function Progress({ xp, floor, ceil, level }: { xp: number; floor: number; ceil: number; level: number }) {
  const span = Math.max(1, ceil - floor)
  const into = Math.max(0, xp - floor)
  const ratio = Math.min(1, into / span)
  return (
    <div>
      <div className="mb-2 flex items-end justify-between">
        <p className="font-display text-3xl font-extrabold">Nivel {level}</p>
        <p className="text-sm text-muted">{xp} / {ceil} XP</p>
      </div>
      <div className="h-3 overflow-hidden rounded-full bg-white/10">
        <div className="h-full rounded-full bg-quick transition-[width] duration-700 ease-out" style={{ width: `${ratio * 100}%` }} />
      </div>
      <p className="mt-1 text-xs text-muted">{Math.max(0, ceil - xp)} XP para el nivel {level + 1}</p>
    </div>
  )
}

export function Timer({
  seconds,
  running,
  resetKey = 0,
  onExpire,
}: {
  seconds: number
  running: boolean
  resetKey?: string | number
  onExpire: () => void
}) {
  const [left, setLeft] = useState(seconds)
  const onExpireRef = useRef(onExpire)
  onExpireRef.current = onExpire

  useEffect(() => {
    setLeft(seconds)
    if (!running) return
    const started = Date.now()
    let fired = false
    const id = window.setInterval(() => {
      const remain = Math.max(0, seconds - (Date.now() - started) / 1000)
      setLeft(remain)
      if (remain <= 0 && !fired) {
        fired = true
        onExpireRef.current()
      }
    }, 80)
    return () => window.clearInterval(id)
  }, [seconds, running, resetKey])

  const shown = Math.ceil(left)
  return (
    <div className={`font-display text-7xl font-extrabold tabular-nums ${shown <= 5 ? 'text-impostor' : 'text-white'}`}>
      {shown}
    </div>
  )
}

export function PassPhone({ name, hint, onReady }: { name: string; hint: string; onReady: () => void }) {
  return (
    <button type="button" onClick={() => { tap(); onReady() }} className="card flex min-h-[70vh] w-full flex-col items-center justify-center gap-4 px-6 text-center">
      <p className="text-muted">Pasa el móvil a</p>
      <p className="font-display text-5xl font-extrabold">{name}</p>
      <p className="text-lg">{hint}</p>
    </button>
  )
}

export function GameBadge({ game }: { game: GameType }) {
  const meta = GAMES[game]
  return (
    <span className="inline-flex items-center gap-2 rounded-full bg-white/10 px-3 py-1 text-sm font-semibold">
      <span>{meta.emoji}</span> {meta.name}
    </span>
  )
}

export function Banner({ text }: { text: string }) {
  return <p className="rounded-2xl bg-impostor/20 px-4 py-3 text-sm text-white">{text}</p>
}
