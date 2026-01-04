import { Link } from 'react-router-dom'
import { motion } from 'framer-motion'
import Card, { CardHeader, CardTitle, CardDescription, CardContent } from '../components/Card'
import Button from '../components/Button'

const APP_VERSION = import.meta.env.VITE_APP_VERSION || 'dev'

export default function Home() {
  return (
    <div className="space-y-12">
      {/* Hero Section */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="text-center space-y-6 py-12"
      >
        <motion.div
          initial={{ scale: 0.9 }}
          animate={{ scale: 1 }}
          transition={{ delay: 0.1 }}
          className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-primary/10 text-primary text-sm font-medium"
        >
          ✨ Nouveau : Découvrez nos démos UI modernes
        </motion.div>

        <h1 className="text-4xl font-bold tracking-tight sm:text-5xl md:text-6xl">
          Bienvenue sur{' '}
          <span className="bg-gradient-to-r from-primary via-purple-500 to-pink-500 bg-clip-text text-transparent">
            ToolsApps
          </span>
        </h1>
        <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
          Une application moderne construite avec React 19, Vite, TailwindCSS et déployée sur Kubernetes
        </p>
        
        {/* Version Badge */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.2 }}
          className="flex items-center justify-center gap-2"
        >
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-muted text-xs font-mono">
            <span className="w-1.5 h-1.5 rounded-full bg-green-500 animate-pulse" />
            v{APP_VERSION}
          </span>
        </motion.div>
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.3 }}
          className="flex gap-4 justify-center pt-4"
        >
          <Link to="/demos">
            <Button size="lg" className="bg-gradient-to-r from-primary to-purple-600 hover:opacity-90">
              🚀 Explorer les Démos
            </Button>
          </Link>
          <Link to="/about">
            <Button variant="outline" size="lg">
              En savoir plus
            </Button>
          </Link>
        </motion.div>
      </motion.div>

      {/* Demo Showcase */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.2 }}
        className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-primary/5 via-purple-500/5 to-pink-500/5 border p-8"
      >
        <div className="text-center mb-8">
          <h2 className="text-2xl font-bold mb-2">Galerie de Démos UI</h2>
          <p className="text-muted-foreground">Interfaces modernes avec animations Framer Motion</p>
        </div>

        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
          {[
            { icon: '📊', name: 'Dashboard', path: '/demos/dashboard' },
            { icon: '🚀', name: 'Landing', path: '/demos/landing' },
            { icon: '🔐', name: 'Auth', path: '/demos/auth' },
            { icon: '✅', name: 'Tasks', path: '/demos/tasks' },
            { icon: '💬', name: 'Social', path: '/demos/social' },
            { icon: '🛒', name: 'E-commerce', path: '/demos/ecommerce' },
          ].map((demo, i) => (
            <Link key={demo.path} to={demo.path}>
              <motion.div
                initial={{ opacity: 0, scale: 0.8 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: 0.3 + i * 0.1 }}
                whileHover={{ y: -5, scale: 1.05 }}
                className="p-4 rounded-xl bg-card border shadow-sm hover:shadow-lg transition-all text-center cursor-pointer"
              >
                <span className="text-3xl block mb-2">{demo.icon}</span>
                <span className="text-sm font-medium">{demo.name}</span>
              </motion.div>
            </Link>
          ))}
        </div>

        <div className="text-center mt-6">
          <Link to="/demos" className="text-primary hover:underline text-sm font-medium">
            Voir toutes les démos →
          </Link>
        </div>
      </motion.div>

      {/* Features Grid */}
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        {[
          { icon: '⚡', title: 'Performant', desc: 'Construit avec Vite pour un développement ultra-rapide', content: 'Hot Module Replacement instantané et build optimisé pour la production.' },
          { icon: '🎨', title: 'Design Moderne', desc: 'Interface élégante avec TailwindCSS', content: 'Design system cohérent avec des composants réutilisables.' },
          { icon: '☸️', title: 'Kubernetes', desc: 'Déployé sur K3s avec Helm Charts', content: 'Infrastructure professionnelle avec SSL automatique via Let\'s Encrypt.' },
          { icon: '🔐', title: 'Sécurisé', desc: 'HTTPS par défaut avec Traefik', content: 'Certificats SSL automatiques et renouvellement transparent.' },
          { icon: '🚀', title: 'Scalable', desc: 'Architecture cloud-native', content: 'Prêt pour passer à l\'échelle avec des réplicas Kubernetes.' },
          { icon: '📦', title: 'Helm Charts', desc: 'Déploiement professionnel SRE', content: 'Gestion de configuration avec values.yaml et ConfigMaps.' },
        ].map((feature, i) => (
          <motion.div
            key={feature.title}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.4 + i * 0.1 }}
          >
            <Card className="h-full hover:shadow-lg transition-shadow">
              <CardHeader>
                <CardTitle className="text-xl">{feature.icon} {feature.title}</CardTitle>
                <CardDescription>{feature.desc}</CardDescription>
              </CardHeader>
              <CardContent>
                <p className="text-sm">{feature.content}</p>
              </CardContent>
            </Card>
          </motion.div>
        ))}
      </div>

      {/* Tech Stack */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.6 }}
      >
        <Card>
          <CardHeader>
            <CardTitle>Stack Technologique</CardTitle>
            <CardDescription>
              Technologies modernes utilisées dans ce projet
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
              {[
                { emoji: '⚛️', name: 'React 19', desc: 'UI Library' },
                { emoji: '⚡', name: 'Vite 7', desc: 'Build Tool' },
                { emoji: '🎨', name: 'TailwindCSS', desc: 'Styling' },
                { emoji: '🎬', name: 'Framer Motion', desc: 'Animations' },
                { emoji: '☸️', name: 'Kubernetes', desc: 'Orchestration' },
                { emoji: '📦', name: 'Helm', desc: 'Deployment' },
              ].map((tech, i) => (
                <motion.div
                  key={tech.name}
                  initial={{ opacity: 0, scale: 0.8 }}
                  animate={{ opacity: 1, scale: 1 }}
                  transition={{ delay: 0.7 + i * 0.05 }}
                  whileHover={{ y: -3 }}
                  className="text-center p-4 border rounded-lg hover:shadow-md transition-all"
                >
                  <div className="text-3xl mb-2">{tech.emoji}</div>
                  <div className="font-semibold">{tech.name}</div>
                  <div className="text-xs text-muted-foreground">{tech.desc}</div>
                </motion.div>
              ))}
            </div>
          </CardContent>
        </Card>
      </motion.div>
    </div>
  )
}

