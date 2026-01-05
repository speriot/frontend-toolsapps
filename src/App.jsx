import { Routes, Route, Navigate } from 'react-router-dom'
import Layout from './components/Layout'
import ProtectedRoute from './components/ProtectedRoute'
import Login from './pages/Login'
import Home from './pages/Home'
import About from './pages/About'
import ApiTest from './pages/ApiTest'

// Demo pages
import DemosIndex from './pages/demos/DemosIndex'
import DashboardDemo from './pages/demos/DashboardDemo'
import LandingDemo from './pages/demos/LandingDemo'
import AuthDemo from './pages/demos/AuthDemo'
import TasksDemo from './pages/demos/TasksDemo'
import SocialDemo from './pages/demos/SocialDemo'
import EcommerceDemo from './pages/demos/EcommerceDemo'
import ComponentsDemo from './pages/demos/ComponentsDemo'
import TablesDemo from './pages/demos/TablesDemo'
import IrregularVerbsDemo from './pages/demos/IrregularVerbsDemo'
import PortalDashboard from './pages/demos/PortalDashboard'

function App() {
  return (
    <Routes>
      {/* Route publique de connexion */}
      <Route path="/login" element={<Login />} />

      {/* Routes protégées avec Layout */}
      <Route
        path="/*"
        element={
          <ProtectedRoute>
            <Layout>
              <Routes>
                <Route path="/" element={<Home />} />
                <Route path="/about" element={<About />} />
                <Route path="/api-test" element={<ApiTest />} />

                {/* Demo Routes */}
                <Route path="/demos" element={<DemosIndex />} />
                <Route path="/demos/dashboard" element={<DashboardDemo />} />
                <Route path="/demos/landing" element={<LandingDemo />} />
                <Route path="/demos/auth" element={<AuthDemo />} />
                <Route path="/demos/tasks" element={<TasksDemo />} />
                <Route path="/demos/social" element={<SocialDemo />} />
                <Route path="/demos/ecommerce" element={<EcommerceDemo />} />
                <Route path="/demos/components" element={<ComponentsDemo />} />
                <Route path="/demos/tables" element={<TablesDemo />} />
                <Route path="/demos/irregular-verbs" element={<IrregularVerbsDemo />} />
                <Route path="/demos/portal" element={<PortalDashboard />} />

                {/* Redirection par défaut */}
                <Route path="*" element={<Navigate to="/" replace />} />
              </Routes>
            </Layout>
          </ProtectedRoute>
        }
      />
    </Routes>
  )
}

export default App

