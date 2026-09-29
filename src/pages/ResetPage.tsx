import { useState, type FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import { supabase } from '../lib/supabase'
import { Banner, Button } from '../components/ui'

export function ResetPage() {
  const navigate = useNavigate()
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)

  async function onSubmit(event: FormEvent) {
    event.preventDefault()
    setBusy(true)
    setError('')
    const { error: updateError } = await supabase.auth.updateUser({ password })
    setBusy(false)
    if (updateError) {
      setError(updateError.message)
      return
    }
    navigate('/')
  }

  return (
    <form onSubmit={onSubmit} className="mx-auto grid w-full max-w-lg gap-4">
      <h1 className="font-display text-4xl font-extrabold">Nueva contraseña</h1>
      <input
        required
        minLength={6}
        type="password"
        value={password}
        onChange={(event) => setPassword(event.target.value)}
        className="min-h-14 rounded-2xl bg-white/10 px-4 text-lg"
        placeholder="Mínimo 6 caracteres"
      />
      {error ? <Banner text={error} /> : null}
      <Button type="submit" tone="quick" disabled={busy}>Guardar</Button>
    </form>
  )
}
