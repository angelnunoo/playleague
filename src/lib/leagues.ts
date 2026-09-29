export const BANNERS: Record<string, string> = {
  royal: 'linear-gradient(120deg, #3b0764 0%, #7c3aed 48%, #f59e0b 100%)',
  neon: 'linear-gradient(120deg, #042f2e 0%, #0f766e 42%, #a3e635 100%)',
  sunset: 'linear-gradient(120deg, #7f1d1d 0%, #fb7185 46%, #fdba74 100%)',
  pitch: 'linear-gradient(120deg, #052e16 0%, #16a34a 55%, #bbf7d0 100%)',
  aurora: 'linear-gradient(120deg, #0f172a 0%, #6366f1 42%, #22d3ee 100%)',
}

export const BANNER_NAMES: Record<string, string> = {
  royal: 'Real',
  neon: 'Neón',
  sunset: 'Atardecer',
  pitch: 'Césped',
  aurora: 'Aurora',
}

export const FRAMES: Record<string, string> = {
  none: '0 0 0 3px rgba(255,255,255,0.45)',
  gold: '0 0 0 4px #f5d76e, 0 0 22px rgba(245, 215, 110, 0.7)',
  fire: '0 0 0 4px #ff5d73, 0 0 22px rgba(255, 93, 115, 0.7)',
  ice: '0 0 0 4px #7ee0ff, 0 0 22px rgba(126, 224, 255, 0.7)',
  diamond: '0 0 0 4px #f5f3ff, 0 0 26px rgba(196, 181, 253, 0.85)',
}

export const FRAME_NAMES: Record<string, string> = {
  none: 'Clásico',
  gold: 'Oro',
  fire: 'Fuego',
  ice: 'Hielo',
  diamond: 'Diamante',
}

export const LEAGUE_MARK: Record<string, string> = {
  hierro: '⚙️',
  bronce: '🥉',
  plata: '🥈',
  oro: '🥇',
  platino: '💠',
  esmeralda: '💚',
  diamante: '💎',
  maestro: '👑',
  gran_maestro: '⚜️',
  desafiante: '🔥',
}

export const RANKS = [
  { slug: 'hierro', name: 'Hierro', floor: 0, color: '#8d8d97' },
  { slug: 'bronce', name: 'Bronce', floor: 100, color: '#e09756' },
  { slug: 'plata', name: 'Plata', floor: 250, color: '#d7deea' },
  { slug: 'oro', name: 'Oro', floor: 450, color: '#ffc53d' },
  { slug: 'platino', name: 'Platino', floor: 700, color: '#5eead4' },
  { slug: 'esmeralda', name: 'Esmeralda', floor: 1000, color: '#34d399' },
  { slug: 'diamante', name: 'Diamante', floor: 1400, color: '#7ee0ff' },
  { slug: 'maestro', name: 'Maestro', floor: 1900, color: '#c4b5fd' },
  { slug: 'gran_maestro', name: 'Gran Maestro', floor: 2500, color: '#f0abfc' },
  { slug: 'desafiante', name: 'Desafiante', floor: 3200, color: '#f5d76e' },
] as const

export const RANK_ORDER: string[] = RANKS.map((rank) => rank.slug)

export function rankProgress(rating: number) {
  const points = Math.max(0, rating)
  let index = 0
  for (let i = 0; i < RANKS.length; i += 1) {
    if (points >= RANKS[i].floor) index = i
  }
  const current = RANKS[index]
  const next = RANKS[index + 1]
  const span = next ? next.floor - current.floor : 1
  const ratio = next ? Math.min(1, Math.max(0, (points - current.floor) / span)) : 1
  return {
    current,
    next,
    index,
    total: RANKS.length,
    left: next ? next.floor - points : 0,
    ratio,
    points,
  }
}
