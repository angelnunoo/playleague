const colors = ['#ffc53d', '#ff5d73', '#2ee6a6', '#a78bfa', '#7ee0ff', '#ffffff']

export function Confetti({ show }: { show: boolean }) {
  if (!show) return null
  return (
    <div className="pointer-events-none fixed inset-0 z-40 overflow-hidden" aria-hidden>
      {Array.from({ length: 32 }, (_, index) => (
        <span
          key={index}
          className="confetti"
          style={{
            left: `${(index * 31) % 100}%`,
            animationDelay: `${(index % 8) * 0.07}s`,
            background: colors[index % colors.length],
          }}
        />
      ))}
    </div>
  )
}
