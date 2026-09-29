import { NavLink, useLocation } from 'react-router-dom'
import type { ReactNode } from 'react'
import { useEffect, useState } from 'react'

const links = [
  { to: '/', label: 'Jugar', icon: '🎲' },
  { to: '/online', label: 'Online', icon: '🌐' },
  { to: '/social', label: 'Social', icon: '👥' },
  { to: '/historial', label: 'Historial', icon: '📜' },
  { to: '/perfil', label: 'Perfil', icon: '😎' },
]

export function Shell({ children, wide = false }: { children: ReactNode; wide?: boolean }) {
  const location = useLocation()
  const hideNav = location.pathname.startsWith('/partida') || location.pathname.startsWith('/sala') || location.pathname.startsWith('/entrar') || location.pathname.startsWith('/restablecer')
  return (
    <div>
      <main key={location.pathname} className={`stage animate-pop ${wide ? 'stage-wide' : ''} ${hideNav ? 'pb-[max(1.2rem,env(safe-area-inset-bottom))]' : ''}`}>
        {children}
      </main>
      {hideNav ? null : (
        <nav className="fixed inset-x-0 bottom-0 z-20 border-t border-white/10 bg-ink/90 backdrop-blur">
          <div className="mx-auto flex w-full max-w-lg justify-around px-2 pt-2 pb-[max(0.6rem,env(safe-area-inset-bottom))]">
            {links.map((link) => (
              <NavLink
                key={link.to}
                to={link.to}
                end={link.to === '/'}
                className={({ isActive }) => `flex min-h-12 min-w-0 flex-1 flex-col items-center justify-center rounded-2xl text-[11px] font-semibold ${isActive ? 'bg-white text-ink' : 'text-muted'}`}
              >
                <span className="text-lg">{link.icon}</span>
                {link.label}
              </NavLink>
            ))}
          </div>
        </nav>
      )}
      <InstallHint />
    </div>
  )
}

function InstallHint() {
  const [prompt, setPrompt] = useState<BeforeInstallPromptEvent | null>(null)
  const [hidden, setHidden] = useState(() => localStorage.getItem('keda-install-hide') === '1')

  useEffect(() => {
    const onPrompt = (event: Event) => {
      event.preventDefault()
      setPrompt(event as BeforeInstallPromptEvent)
    }
    window.addEventListener('beforeinstallprompt', onPrompt)
    return () => window.removeEventListener('beforeinstallprompt', onPrompt)
  }, [])

  if (hidden || !prompt) return null
  return (
    <div className="fixed inset-x-3 bottom-24 z-30 card flex items-center gap-3 p-3">
      <div className="flex-1 text-sm">
        <p className="font-bold">Instala PlayLeague</p>
        <p className="text-muted">Quedará en tu pantalla de inicio.</p>
      </div>
      <button
        type="button"
        className="rounded-xl bg-quick px-3 py-2 font-bold text-ink"
        onClick={async () => {
          await prompt.prompt()
          setPrompt(null)
        }}
      >
        Instalar
      </button>
      <button
        type="button"
        className="px-2 text-muted"
        onClick={() => {
          localStorage.setItem('keda-install-hide', '1')
          setHidden(true)
        }}
      >
        Ahora no
      </button>
    </div>
  )
}

type BeforeInstallPromptEvent = Event & {
  prompt: () => Promise<void>
}
