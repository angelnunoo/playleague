import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react'
import type { Session } from '@supabase/supabase-js'
import { supabase } from '../lib/supabase'
import { myProfile, touchPresence } from '../lib/api'
import type { ProfileBundle } from '../types'

type AuthValue = {
  session: Session | null
  profile: ProfileBundle | null
  loading: boolean
  refresh: () => Promise<void>
}

const AuthContext = createContext<AuthValue | null>(null)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null)
  const [profile, setProfile] = useState<ProfileBundle | null>(null)
  const [loading, setLoading] = useState(true)

  const refresh = useCallback(async () => {
    const { data } = await supabase.auth.getSession()
    setSession(data.session)
    if (!data.session) {
      setProfile(null)
      return
    }
    try {
      setProfile(await myProfile())
    } catch {
      setProfile(null)
    }
  }, [])

  useEffect(() => {
    let active = true
    supabase.auth.getSession().then(async ({ data }) => {
      if (!active) return
      setSession(data.session)
      if (data.session) {
        try {
          setProfile(await myProfile())
        } catch {
          setProfile(null)
        }
      }
      setLoading(false)
    })
    const presence = window.setInterval(() => {
      touchPresence().catch(() => undefined)
    }, 60000)
    touchPresence().catch(() => undefined)
    const { data: sub } = supabase.auth.onAuthStateChange((_event, next) => {
      setSession(next)
      if (!next) {
        setProfile(null)
        setLoading(false)
        return
      }
      myProfile().then(setProfile).catch(() => setProfile(null)).finally(() => setLoading(false))
    })
    return () => {
      active = false
      sub.subscription.unsubscribe()
      window.clearInterval(presence)
    }
  }, [])

  const value = useMemo(() => ({ session, profile, loading, refresh }), [session, profile, loading, refresh])
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const value = useContext(AuthContext)
  if (!value) throw new Error('useAuth fuera del proveedor')
  return value
}
