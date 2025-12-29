import { Link, useLocation } from 'react-router-dom'

export default function Layout({ children }) {
  const location = useLocation()

  const isActive = (path) => {
    return location.pathname === path ? 'text-primary' : 'text-muted-foreground hover:text-foreground'
  }

  return (
    <div className="min-h-screen flex flex-col">
      {/* Header */}
      <header className="border-b">
        <div className="container mx-auto px-4 py-4">
          <nav className="flex items-center justify-between">
            <Link to="/" className="text-2xl font-bold text-primary">
              ToolsApps
            </Link>
            <ul className="flex gap-6">
              <li>
                <Link to="/" className={`transition-colors ${isActive('/')}`}>
                  Accueil
                </Link>
              </li>
              <li>
                <Link to="/about" className={`transition-colors ${isActive('/about')}`}>
                  À propos
                </Link>
              </li>
              <li>
                <Link to="/api-test" className={`transition-colors ${isActive('/api-test')}`}>
                  Test API
                </Link>
              </li>
            </ul>
          </nav>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 container mx-auto px-4 py-8">
        {children}
      </main>

      {/* Footer */}
      <footer className="border-t mt-auto">
        <div className="container mx-auto px-4 py-6">
          <div className="flex items-center justify-between text-sm text-muted-foreground">
            <p>© 2024 ToolsApps - Tous droits réservés</p>
            <div className="flex gap-4">
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

