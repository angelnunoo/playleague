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

export default function App() {
  const { session, loading } = useAuth()
  if (loading) {
    return <div className="grid min-h-dvh place-items-center font-display text-2xl">PlayLeague</div>
  }
  return (
    <Shell wide>
      <Routes>
        <Route path="/entrar" element={session ? <Navigate to="/" replace /> : <AuthPage />} />
        <Route path="/restablecer" element={<ResetPage />} />
        <Route path="*" element={session ? <PrivateRoutes /> : <Navigate to="/entrar" replace />} />
      </Routes>
    </Shell>
  )
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
