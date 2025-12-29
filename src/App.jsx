import { Routes, Route } from 'react-router-dom'
import Layout from './components/Layout'
import Home from './pages/Home'
import About from './pages/About'
import ApiTest from './pages/ApiTest'

function App() {
  return (
    <Layout>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/about" element={<About />} />
        <Route path="/api-test" element={<ApiTest />} />
      </Routes>
    </Layout>
  )
}

export default App

