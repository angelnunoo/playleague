import { useState, type FormEvent } from 'react'
import { supabase } from '../lib/supabase'
import { Banner, Button, Choice } from '../components/ui'

type Mode = 'login' | 'signup' | 'forgot'

const rememberedEmail = () => localStorage.getItem('keda-email') ?? ''

export function AuthPage() {
  const [mode, setMode] = useState<Mode>('login')
  const [email, setEmail] = useState(rememberedEmail)
  const [password, setPassword] = useState('')
  const [name, setName] = useState('')
  const [username, setUsername] = useState('')
  const [message, setMessage] = useState('')
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)

  async function onSubmit(event: FormEvent) {
    event.preventDefault()
    setBusy(true)
    setError('')
    setMessage('')
    try {
      localStorage.setItem('keda-email', email.trim())
      if (mode === 'login') {
        const { error: authError } = await supabase.auth.signInWithPassword({ email, password })
        if (authError) throw authError
      } else if (mode === 'signup') {
        const { error: authError } = await supabase.auth.signUp({
          email,
          password,
          options: {
            emailRedirectTo: window.location.origin,
            data: { display_name: name.trim(), username: username.trim().toLowerCase() },
          },
        })
        if (authError) throw authError
        setMessage('Cuenta creada. Si te pide confirmar el email, ábrelo y vuelve a entrar.')
      } else {
        const { error: authError } = await supabase.auth.resetPasswordForEmail(email, {
          redirectTo: `${window.location.origin}/restablecer`,
        })
        if (authError) throw authError
        setMessage('Te hemos enviado un enlace para elegir una contraseña nueva.')
      }
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'No se ha podido entrar')
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="mx-auto w-full max-w-lg animate-pop">
      <p className="font-display text-5xl font-extrabold">PlayLeague</p>
      <p className="mt-1 text-muted">Entra con tu cuenta para jugar. La primera vez te lo pedimos; después sigues dentro.</p>
      <div className="mt-5 grid grid-cols-3 gap-2">
        <Choice selected={mode === 'login'} onClick={() => setMode('login')}>Entrar</Choice>
        <Choice selected={mode === 'signup'} onClick={() => setMode('signup')}>Crear</Choice>
        <Choice selected={mode === 'forgot'} onClick={() => setMode('forgot')}>Olvidé</Choice>
      </div>
      <form onSubmit={onSubmit} className="mt-4 grid gap-3">
        {mode === 'signup' ? (
          <>
            <Field label="Nombre" value={name} onChange={setName} autoComplete="name" />
            <Field label="Usuario" value={username} onChange={setUsername} autoComplete="username" />
          </>
        ) : null}
        <Field label="Email" type="email" value={email} onChange={setEmail} autoComplete="email" />
        {mode === 'forgot' ? null : (
          <Field label="Contraseña" type="password" value={password} onChange={setPassword} autoComplete={mode === 'login' ? 'current-password' : 'new-password'} />
        )}
        {error ? <Banner text={error} /> : null}
        {message ? <p className="rounded-2xl bg-taboo/20 px-4 py-3 text-sm">{message}</p> : null}
        <Button type="submit" tone="quick" disabled={busy}>{busy ? 'Un momento…' : mode === 'login' ? 'Entrar' : mode === 'signup' ? 'Crear cuenta' : 'Enviar enlace'}</Button>
      </form>
    </div>
  )
}

function Field({
  label,
  value,
  onChange,
  type = 'text',
  autoComplete,
}: {
  label: string
  value: string
  onChange: (value: string) => void
  type?: string
  autoComplete?: string
}) {
  return (
    <label className="grid gap-1 text-sm font-semibold">
      {label}
      <input
        required
        type={type}
        value={value}
        autoComplete={autoComplete}
        onChange={(event) => onChange(event.target.value)}
        className="min-h-14 rounded-2xl border border-white/10 bg-white/10 px-4 text-lg"
      />
    </label>
  )
}
