import { Routes, Route } from 'react-router-dom'
import Layout from './components/Layout'
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

function App() {
  return (
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
      </Routes>
    </Layout>
  )
}

export default App

