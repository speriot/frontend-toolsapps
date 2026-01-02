import { Link } from 'react-router-dom'
import { motion } from 'framer-motion'
import {
  LayoutDashboard, Rocket, UserCircle, ListTodo,
  MessageSquare, ShoppingBag, ArrowRight, Sparkles, Puzzle, Table, BookOpen
} from 'lucide-react'

const demos = [
  {
    id: 'dashboard',
    title: 'Dashboard Analytics',
    description: 'Tableau de bord moderne avec graphiques animés, statistiques et activités en temps réel.',
    icon: LayoutDashboard,
    color: 'from-blue-500 to-indigo-600',
    path: '/demos/dashboard',
    tags: ['Analytics', 'Charts', 'Stats']
  },
  {
    id: 'landing',
    title: 'Landing Page',
    description: 'Page d\'accueil moderne avec hero section, pricing, témoignages et animations fluides.',
    icon: Rocket,
    color: 'from-purple-500 to-pink-600',
    path: '/demos/landing',
    tags: ['Marketing', 'Pricing', 'CTA']
  },
  {
    id: 'auth',
    title: 'Authentification',
    description: 'Formulaires de connexion et inscription avec validation, animations et social login.',
    icon: UserCircle,
    color: 'from-emerald-500 to-teal-600',
    path: '/demos/auth',
    tags: ['Forms', 'Validation', 'OAuth']
  },
  {
    id: 'tasks',
    title: 'Gestionnaire de Tâches',
    description: 'Application de gestion de tâches avec drag & drop, filtres et animations fluides.',
    icon: ListTodo,
    color: 'from-orange-500 to-red-600',
    path: '/demos/tasks',
    tags: ['Todo', 'Drag & Drop', 'CRUD']
  },
  {
    id: 'social',
    title: 'Feed Social',
    description: 'Interface de réseau social avec stories, posts, likes et interactions.',
    icon: MessageSquare,
    color: 'from-pink-500 to-rose-600',
    path: '/demos/social',
    tags: ['Social', 'Feed', 'Interactions']
  },
  {
    id: 'ecommerce',
    title: 'E-commerce',
    description: 'Boutique en ligne avec catalogue produits, panier animé et checkout.',
    icon: ShoppingBag,
    color: 'from-cyan-500 to-blue-600',
    path: '/demos/ecommerce',
    tags: ['Shop', 'Cart', 'Products']
  },
  {
    id: 'tables',
    title: 'Tableaux de Données',
    description: 'Tableaux modernes avec tri, sélection, pagination, lignes extensibles et indicateurs.',
    icon: Table,
    color: 'from-slate-500 to-zinc-600',
    path: '/demos/tables',
    tags: ['Data', 'Sort', 'Pagination']
  },
  {
    id: 'components',
    title: 'Bibliothèque UI',
    description: 'Collection de composants réutilisables : toggles, badges, alerts, modals et plus.',
    icon: Puzzle,
    color: 'from-violet-500 to-purple-600',
    path: '/demos/components',
    tags: ['Components', 'Reusable', 'UI Kit']
  },
  {
    id: 'irregular-verbs',
    title: 'Verbes Irréguliers',
    description: 'Quiz interactif pour apprendre les verbes irréguliers anglais avec score et timer.',
    icon: BookOpen,
    color: 'from-emerald-500 to-teal-600',
    path: '/demos/irregular-verbs',
    tags: ['Éducation', 'Quiz', 'Anglais']
  },
]

function DemoCard({ demo, index }) {
  const Icon = demo.icon

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.1 }}
    >
      <Link to={demo.path}>
        <motion.div
          whileHover={{ y: -5, scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
          className="group relative overflow-hidden rounded-2xl bg-card border p-6 shadow-lg hover:shadow-xl transition-shadow h-full"
        >
          {/* Icon */}
          <div className={`w-14 h-14 rounded-xl bg-gradient-to-br ${demo.color} flex items-center justify-center mb-4 shadow-lg`}>
            <Icon className="w-7 h-7 text-white" />
          </div>

          {/* Content */}
          <h3 className="text-xl font-semibold mb-2 group-hover:text-primary transition-colors">
            {demo.title}
          </h3>
          <p className="text-muted-foreground text-sm mb-4">
            {demo.description}
          </p>

          {/* Tags */}
          <div className="flex flex-wrap gap-2 mb-4">
            {demo.tags.map(tag => (
              <span key={tag} className="px-2 py-1 text-xs rounded-full bg-muted">
                {tag}
              </span>
            ))}
          </div>

          {/* Arrow */}
          <div className="flex items-center gap-1 text-sm font-medium text-primary">
            Voir la démo
            <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
          </div>

          {/* Background decoration */}
          <div className={`absolute -bottom-4 -right-4 w-32 h-32 rounded-full bg-gradient-to-br ${demo.color} opacity-10 blur-2xl group-hover:opacity-20 transition-opacity`} />
        </motion.div>
      </Link>
    </motion.div>
  )
}

export default function DemosIndex() {
  return (
    <div className="space-y-12">
      {/* Hero */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="text-center space-y-4"
      >
        <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-primary/10 text-primary text-sm font-medium">
          <Sparkles className="w-4 h-4" />
          Galerie de Démos UI
        </div>
        <h1 className="text-4xl md:text-5xl font-bold tracking-tight">
          Explorez nos{' '}
          <span className="bg-gradient-to-r from-primary via-purple-500 to-pink-500 bg-clip-text text-transparent">
            composants modernes
          </span>
        </h1>
        <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
          Découvrez ce qui se fait de mieux en matière d'interfaces utilisateur web.
          Animations fluides, design system cohérent et expérience utilisateur optimale.
        </p>
      </motion.div>

      {/* Technologies */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.2 }}
        className="flex flex-wrap justify-center gap-3"
      >
        {['React 19', 'Framer Motion', 'TailwindCSS', 'Lucide Icons', 'HeadlessUI'].map((tech, i) => (
          <motion.span
            key={tech}
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 0.3 + i * 0.1 }}
            className="px-4 py-2 rounded-full border bg-card text-sm font-medium"
          >
            {tech}
          </motion.span>
        ))}
      </motion.div>

      {/* Demos Grid */}
      <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
        {demos.map((demo, index) => (
          <DemoCard key={demo.id} demo={demo} index={index} />
        ))}
      </div>

      {/* Footer Note */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.8 }}
        className="text-center py-8 text-muted-foreground"
      >
        <p>
          Toutes ces démos sont des exemples fonctionnels prêts à être utilisés dans vos projets.
        </p>
      </motion.div>
    </div>
  )
}

