import { Navigate, Route, Routes } from 'react-router-dom'
import { useAuth } from './auth/AuthProvider'
import { Shell } from './components/Shell'
import { HomePage } from './pages/HomePage'
import { AuthPage } from './pages/AuthPage'
import { ResetPage } from './pages/ResetPage'
import { SetupPage } from './pages/SetupPage'
import { MatchPage } from './pages/MatchPage'
import { ProfilePage } from './pages/ProfilePage'
import { StatsPage } from './pages/StatsPage'
import { AchievementsPage } from './pages/AchievementsPage'
import { HistoryPage } from './pages/HistoryPage'
import { AdminPage } from './pages/AdminPage'
import { OnlinePage } from './pages/OnlinePage'
import { RoomPage } from './pages/RoomPage'
import { SocialPage } from './pages/SocialPage'
import { PlayerPage } from './pages/PlayerPage'
import { InvitePage } from './pages/InvitePage'

export default function App() {
  const { session, loading } = useAuth()
  if (loading) {
    return (
    <div className="grid min-h-dvh place-items-center gap-3">
      <img src="/logo.png" alt="" className="h-24 w-24 rounded-[1.6rem]" />
      <div className="font-display text-2xl">PlayLeague</div>
    </div>
  )
  }
  return (
    <Shell wide>
      <Routes>
        <Route path="/entrar" element={session ? <Navigate to={afterLogin()} replace /> : <AuthPage />} />
        <Route path="/restablecer" element={<ResetPage />} />
        <Route path="/invitar/:username" element={<InvitePage />} />
        <Route path="*" element={session ? <PrivateRoutes /> : <Navigate to="/entrar" replace />} />
      </Routes>
    </Shell>
  )
}

function afterLogin() {
  const invite = sessionStorage.getItem('playleague-invite')
  return invite ? `/invitar/${invite}` : '/'
}

function PrivateRoutes() {
  return (
    <Routes>
      <Route path="/" element={<HomePage />} />
      <Route path="/online" element={<OnlinePage />} />
      <Route path="/sala/:id" element={<RoomPage />} />
      <Route path="/social" element={<SocialPage />} />
      <Route path="/jugador/:username" element={<PlayerPage />} />
      <Route path="/nueva/:game" element={<SetupPage />} />
      <Route path="/partida/:id" element={<MatchPage />} />
      <Route path="/perfil" element={<ProfilePage />} />
      <Route path="/estadisticas" element={<StatsPage />} />
      <Route path="/logros" element={<AchievementsPage />} />
      <Route path="/historial" element={<HistoryPage />} />
      <Route path="/historial/:id" element={<HistoryPage />} />
      <Route path="/admin" element={<AdminPage />} />
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}
