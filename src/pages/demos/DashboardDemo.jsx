import { useState } from 'react'
import { motion } from 'framer-motion'
import {
  TrendingUp, TrendingDown, Users, DollarSign, ShoppingCart,
  Activity, BarChart3, PieChart, ArrowUpRight, ArrowDownRight,
  Bell, Search, Settings, ChevronDown, MoreHorizontal
} from 'lucide-react'

const stats = [
  {
    name: 'Revenus',
    value: '€45,231',
    change: '+20.1%',
    trend: 'up',
    icon: DollarSign,
    color: 'from-emerald-500 to-teal-600'
  },
  {
    name: 'Utilisateurs',
    value: '2,350',
    change: '+15.3%',
    trend: 'up',
    icon: Users,
    color: 'from-blue-500 to-indigo-600'
  },
  {
    name: 'Commandes',
    value: '1,247',
    change: '-5.4%',
    trend: 'down',
    icon: ShoppingCart,
    color: 'from-purple-500 to-pink-600'
  },
  {
    name: 'Taux de conversion',
    value: '3.2%',
    change: '+2.1%',
    trend: 'up',
    icon: Activity,
    color: 'from-orange-500 to-red-600'
  },
]

const recentActivities = [
  { id: 1, user: 'Marie Dupont', action: 'a passé une commande', amount: '€250', time: 'il y a 2 min', avatar: 'MD' },
  { id: 2, user: 'Pierre Martin', action: 's\'est inscrit', amount: null, time: 'il y a 5 min', avatar: 'PM' },
  { id: 3, user: 'Sophie Bernard', action: 'a passé une commande', amount: '€180', time: 'il y a 12 min', avatar: 'SB' },
  { id: 4, user: 'Lucas Petit', action: 'a laissé un avis', amount: '⭐⭐⭐⭐⭐', time: 'il y a 25 min', avatar: 'LP' },
  { id: 5, user: 'Emma Richard', action: 'a passé une commande', amount: '€420', time: 'il y a 1h', avatar: 'ER' },
]

const chartData = [40, 55, 45, 70, 65, 80, 75, 90, 85, 95, 88, 100]
const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc']

function AnimatedChart() {
  const maxValue = Math.max(...chartData)

  return (
    <div className="flex items-end justify-between h-48 gap-2 px-2">
      {chartData.map((value, index) => (
        <motion.div
          key={index}
          className="flex-1 flex flex-col items-center gap-2"
          initial={{ height: 0 }}
          animate={{ height: 'auto' }}
          transition={{ delay: index * 0.1 }}
        >
          <motion.div
            className="w-full bg-gradient-to-t from-primary to-blue-400 rounded-t-md relative group cursor-pointer"
            initial={{ height: 0 }}
            animate={{ height: `${(value / maxValue) * 100}%` }}
            transition={{ delay: index * 0.1, duration: 0.5, ease: "easeOut" }}
            whileHover={{ scale: 1.05 }}
          >
            <div className="absolute -top-8 left-1/2 -translate-x-1/2 bg-foreground text-background px-2 py-1 rounded text-xs opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap">
              {value}%
            </div>
          </motion.div>
          <span className="text-xs text-muted-foreground">{months[index]}</span>
        </motion.div>
      ))}
    </div>
  )
}

function StatCard({ stat, index }) {
  const Icon = stat.icon

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.1 }}
      whileHover={{ y: -5, transition: { duration: 0.2 } }}
      className="relative overflow-hidden rounded-2xl bg-card border p-6 shadow-lg hover:shadow-xl transition-shadow"
    >
      <div className="flex items-start justify-between">
        <div className="space-y-2">
          <p className="text-sm font-medium text-muted-foreground">{stat.name}</p>
          <p className="text-3xl font-bold tracking-tight">{stat.value}</p>
          <div className={`flex items-center gap-1 text-sm font-medium ${
            stat.trend === 'up' ? 'text-emerald-600' : 'text-red-600'
          }`}>
            {stat.trend === 'up' ? <ArrowUpRight className="w-4 h-4" /> : <ArrowDownRight className="w-4 h-4" />}
            {stat.change}
            <span className="text-muted-foreground font-normal">vs mois dernier</span>
          </div>
        </div>
        <div className={`p-3 rounded-xl bg-gradient-to-br ${stat.color}`}>
          <Icon className="w-6 h-6 text-white" />
        </div>
      </div>

      {/* Decorative gradient */}
      <div className={`absolute -bottom-4 -right-4 w-24 h-24 rounded-full bg-gradient-to-br ${stat.color} opacity-10 blur-2xl`} />
    </motion.div>
  )
}

export default function DashboardDemo() {
  const [searchQuery, setSearchQuery] = useState('')

  return (
    <div className="space-y-8">
      {/* Header */}
      <motion.div
        className="flex flex-col md:flex-row md:items-center justify-between gap-4"
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
      >
        <div>
          <h1 className="text-3xl font-bold">Tableau de bord</h1>
          <p className="text-muted-foreground">Bienvenue ! Voici un aperçu de vos métriques.</p>
        </div>

        <div className="flex items-center gap-3">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <input
              type="text"
              placeholder="Rechercher..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-10 pr-4 py-2 rounded-lg border bg-background focus:ring-2 focus:ring-primary/20 outline-none transition-all w-64"
            />
          </div>
          <motion.button
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            className="p-2 rounded-lg border hover:bg-muted transition-colors relative"
          >
            <Bell className="w-5 h-5" />
            <span className="absolute -top-1 -right-1 w-4 h-4 bg-red-500 rounded-full text-[10px] text-white flex items-center justify-center">3</span>
          </motion.button>
          <motion.button
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            className="p-2 rounded-lg border hover:bg-muted transition-colors"
          >
            <Settings className="w-5 h-5" />
          </motion.button>
        </div>
      </motion.div>

      {/* Stats Grid */}
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
        {stats.map((stat, index) => (
          <StatCard key={stat.name} stat={stat} index={index} />
        ))}
      </div>

      {/* Charts Section */}
      <div className="grid gap-6 lg:grid-cols-3">
        {/* Main Chart */}
        <motion.div
          className="lg:col-span-2 rounded-2xl bg-card border p-6 shadow-lg"
          initial={{ opacity: 0, x: -20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.4 }}
        >
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="text-lg font-semibold">Évolution des ventes</h3>
              <p className="text-sm text-muted-foreground">Performance mensuelle 2024</p>
            </div>
            <div className="flex items-center gap-2">
              <button className="px-3 py-1.5 text-sm rounded-lg bg-primary text-primary-foreground">Année</button>
              <button className="px-3 py-1.5 text-sm rounded-lg hover:bg-muted transition-colors">Mois</button>
              <button className="px-3 py-1.5 text-sm rounded-lg hover:bg-muted transition-colors">Semaine</button>
            </div>
          </div>
          <AnimatedChart />
        </motion.div>

        {/* Activity Feed */}
        <motion.div
          className="rounded-2xl bg-card border p-6 shadow-lg"
          initial={{ opacity: 0, x: 20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.5 }}
        >
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-lg font-semibold">Activité récente</h3>
            <button className="text-sm text-primary hover:underline">Voir tout</button>
          </div>

          <div className="space-y-4">
            {recentActivities.map((activity, index) => (
              <motion.div
                key={activity.id}
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 0.6 + index * 0.1 }}
                className="flex items-center gap-3 p-3 rounded-lg hover:bg-muted/50 transition-colors cursor-pointer"
              >
                <div className="w-10 h-10 rounded-full bg-gradient-to-br from-primary to-purple-600 flex items-center justify-center text-white text-sm font-medium">
                  {activity.avatar}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium truncate">
                    <span className="font-semibold">{activity.user}</span>{' '}
                    <span className="text-muted-foreground">{activity.action}</span>
                  </p>
                  <p className="text-xs text-muted-foreground">{activity.time}</p>
                </div>
                {activity.amount && (
                  <span className="text-sm font-semibold text-primary">{activity.amount}</span>
                )}
              </motion.div>
            ))}
          </div>
        </motion.div>
      </div>
    </div>
  )
}

