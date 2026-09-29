let audio: AudioContext | null = null

export function soundEnabled() {
  return localStorage.getItem('keda-sound') === '1'
}

export function setSoundEnabled(on: boolean) {
  localStorage.setItem('keda-sound', on ? '1' : '0')
}

function tone(freq: number, duration: number, type: OscillatorType, when = 0) {
  if (!soundEnabled()) return
  const ctx = audio ?? new AudioContext()
  audio = ctx
  const osc = ctx.createOscillator()
  const gain = ctx.createGain()
  osc.type = type
  osc.frequency.value = freq
  gain.gain.value = 0.045
  osc.connect(gain)
  gain.connect(ctx.destination)
  const start = ctx.currentTime + when
  osc.start(start)
  gain.gain.exponentialRampToValueAtTime(0.001, start + duration)
  osc.stop(start + duration)
}

export function playTap() {
  tone(740, 0.04, 'square')
}

export function playWin() {
  tone(523, 0.1, 'sine')
  tone(659, 0.12, 'sine', 0.09)
  tone(784, 0.2, 'sine', 0.18)
}

export function playLose() {
  tone(196, 0.22, 'triangle')
}
