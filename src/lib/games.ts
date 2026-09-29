import type { GameType, Player, Team } from '../types'

export const GAMES: Record<GameType, { name: string; emoji: string; blurb: string; tint: string }> = {
  quiz: { name: 'Quiz', emoji: '🧠', blurb: 'Preguntas por equipos. El que más sepa, gana.', tint: '#a78bfa' },
  impostor: { name: 'Impostor', emoji: '🕵️', blurb: 'Todos ven la palabra. Alguien no.', tint: '#ff5d73' },
  taboo: { name: 'Tabú', emoji: '🗣️', blurb: 'Descríbela sin decir lo prohibido.', tint: '#2ee6a6' },
  quick: { name: 'Responde rápido', emoji: '⚡', blurb: 'Nombra tres cosas antes de que suene.', tint: '#ffc53d' },
}

export const TEAM_PRESETS: Team[] = [
  { key: 'red', name: 'Los Máquina', color: '#ff5d73' },
  { key: 'blue', name: 'Los Cracks', color: '#60a5fa' },
  { key: 'green', name: 'Los Fenómenos', color: '#2ee6a6' },
  { key: 'amber', name: 'La Banda', color: '#ffc53d' },
]

export const AVATARS = ['😎', '🦊', '🐸', '🐼', '🦁', '🐙', '🦄', '🤠', '👽', '🤖', '👻', '🐯', '🐧', '🐵', '🐲', '🐨']

export const DIFFICULTIES = [
  { id: 'easy', label: 'Fácil', emoji: '🟢' },
  { id: 'normal', label: 'Normal', emoji: '🟡' },
  { id: 'hard', label: 'Difícil', emoji: '🔴' },
  { id: 'expert', label: 'Experto', emoji: '💀' },
  { id: '', label: 'Aleatorio', emoji: '🎲' },
]

export function maxTeams(playerCount: number) {
  return Math.min(4, playerCount)
}

export function dealTeams(players: { name: string; isHost: boolean }[], teamCount: number): { name: string; isHost: boolean; teamKey: string }[] {
  const teams = TEAM_PRESETS.slice(0, teamCount)
  const order = players.map((_, index) => index)
  for (let i = order.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1))
    ;[order[i], order[j]] = [order[j], order[i]]
  }
  return order.map((playerIndex, dealIndex) => ({
    ...players[playerIndex],
    teamKey: teams[dealIndex % teamCount].key,
  })).sort((a, b) => players.findIndex((p) => p.name === a.name) - players.findIndex((p) => p.name === b.name))
}

export function turnOf(players: Player[], teams: Team[], position: number) {
  const team = teams[position % teams.length]
  const members = players.filter((player) => player.team_key === team.key).sort((a, b) => a.seat - b.seat)
  const player = members[Math.floor(position / teams.length) % members.length]
  return { team, player }
}

export function balanceOk(assignments: string[]) {
  const counts = new Map<string, number>()
  for (const key of assignments) counts.set(key, (counts.get(key) ?? 0) + 1)
  const values = [...counts.values()]
  return values.length > 0 && Math.max(...values) - Math.min(...values) <= 1
}
