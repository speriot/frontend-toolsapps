import { Link, useLocation } from 'react-router-dom'
import { useState } from 'react'
import { useAuth } from '../contexts/AuthContext'
import { LogOut, User } from 'lucide-react'

export default function Layout({ children }) {
  const location = useLocation()
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)
  const { user, logout } = useAuth()

  const isActive = (path) => {
    if (path === '/demos') {
      return location.pathname.startsWith('/demos') ? 'text-primary font-medium' : 'text-muted-foreground hover:text-foreground'
    }
    return location.pathname === path ? 'text-primary font-medium' : 'text-muted-foreground hover:text-foreground'
  }

  const navLinks = [
    { path: '/', label: 'Accueil' },
    { path: '/demos', label: '✨ Démos' },
    { path: '/about', label: 'À propos' },
    { path: '/api-test', label: 'Test API' },
  ]

  return (
    <div className="min-h-screen flex flex-col bg-background">
      {/* Header */}
      <header className="sticky top-0 z-50 border-b bg-background/80 backdrop-blur-lg">
        <div className="container mx-auto px-4 py-4">
          <nav className="flex items-center justify-between">
            <Link to="/" className="text-2xl font-bold bg-gradient-to-r from-primary to-purple-600 bg-clip-text text-transparent">
              ToolsApps
            </Link>

            {/* Desktop Navigation */}
            <div className="hidden md:flex items-center gap-6">
              <ul className="flex gap-6">
                {navLinks.map(link => (
                  <li key={link.path}>
                    <Link
                      to={link.path}
                      className={`transition-colors ${isActive(link.path)}`}
                    >
                      {link.label}
                    </Link>
                  </li>
                ))}
              </ul>

              {/* User Info & Logout */}
              {user && (
                <div className="flex items-center gap-3 ml-4 pl-4 border-l">
                  <div className="flex items-center gap-2 text-sm">
                    <User className="w-4 h-4 text-muted-foreground" />
                    <span className="text-muted-foreground">{user.name || user.email}</span>
                  </div>
                  <button
                    onClick={logout}
                    className="flex items-center gap-2 px-3 py-1.5 rounded-lg text-sm hover:bg-muted transition-colors"
                    title="Déconnexion"
                  >
                    <LogOut className="w-4 h-4" />
                    <span>Déconnexion</span>
                  </button>
                </div>
              )}
            </div>

            {/* Mobile Menu Button */}
            <button
              className="md:hidden p-2"
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                {mobileMenuOpen ? (
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                ) : (
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
                )}
              </svg>
            </button>
          </nav>

          {/* Mobile Navigation */}
          {mobileMenuOpen && (
            <div className="md:hidden pt-4 pb-2 space-y-2">
              <ul className="space-y-2">
                {navLinks.map(link => (
                  <li key={link.path}>
                    <Link
                      to={link.path}
                      className={`block py-2 transition-colors ${isActive(link.path)}`}
                      onClick={() => setMobileMenuOpen(false)}
                    >
                      {link.label}
                    </Link>
                  </li>
                ))}
              </ul>
              
              {/* Mobile User Info & Logout */}
              {user && (
                <div className="pt-2 mt-2 border-t space-y-2">
                  <div className="flex items-center gap-2 text-sm py-2">
                    <User className="w-4 h-4 text-muted-foreground" />
                    <span className="text-muted-foreground">{user.name || user.email}</span>
                  </div>
                  <button
                    onClick={() => {
                      logout()
                      setMobileMenuOpen(false)
                    }}
                    className="flex items-center gap-2 px-3 py-2 rounded-lg text-sm hover:bg-muted transition-colors w-full"
                  >
                    <LogOut className="w-4 h-4" />
                    <span>Déconnexion</span>
                  </button>
                </div>
              )}
            </div>
          )}
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 container mx-auto px-4 py-8">
        {children}
      </main>

      {/* Footer */}
      <footer className="border-t mt-auto bg-muted/30">
        <div className="container mx-auto px-4 py-6">
          <div className="flex flex-col md:flex-row items-center justify-between gap-4 text-sm text-muted-foreground">
            <p>© 2025 ToolsApps - Tous droits réservés</p>
            <div className="flex gap-6">
              <Link to="/demos" className="hover:text-foreground transition-colors">
                Démos UI
              </Link>
              <a href="https://github.com" target="_blank" rel="noopener noreferrer" className="hover:text-foreground transition-colors">
                GitHub
              </a>
              <a href="https://api.toolsapps.eu" target="_blank" rel="noopener noreferrer" className="hover:text-foreground transition-colors">
                API
              </a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  )
}

