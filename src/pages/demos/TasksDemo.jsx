import { useState } from 'react'
import { motion, AnimatePresence, Reorder } from 'framer-motion'
import {
  Plus, Trash2, GripVertical, Check, Circle, Clock,
  AlertCircle, Star, Calendar, Tag, Filter, Search,
  ChevronDown, MoreHorizontal, Sparkles
} from 'lucide-react'

const initialTasks = [
  { id: 1, title: 'Finaliser le design du dashboard', completed: false, priority: 'high', category: 'Design', dueDate: 'Aujourd\'hui' },
  { id: 2, title: 'Revoir les animations Framer Motion', completed: false, priority: 'medium', category: 'Dev', dueDate: 'Demain' },
  { id: 3, title: 'Préparer la présentation client', completed: true, priority: 'high', category: 'Business', dueDate: 'Hier' },
  { id: 4, title: 'Optimiser les performances', completed: false, priority: 'low', category: 'Dev', dueDate: 'Cette semaine' },
  { id: 5, title: 'Mettre à jour la documentation', completed: false, priority: 'medium', category: 'Docs', dueDate: 'Cette semaine' },
]

const priorityColors = {
  high: 'text-red-500 bg-red-500/10',
  medium: 'text-yellow-500 bg-yellow-500/10',
  low: 'text-green-500 bg-green-500/10'
}

const priorityLabels = {
  high: 'Haute',
  medium: 'Moyenne',
  low: 'Basse'
}

const categoryColors = {
  Design: 'bg-purple-500',
  Dev: 'bg-blue-500',
  Business: 'bg-emerald-500',
  Docs: 'bg-orange-500'
}

function TaskItem({ task, onToggle, onDelete, onStar }) {
  const [isStarred, setIsStarred] = useState(false)

  return (
    <Reorder.Item
      value={task}
      id={task.id}
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, x: -100 }}
      whileHover={{ scale: 1.01 }}
      className={`group flex items-center gap-4 p-4 rounded-xl border bg-card shadow-sm hover:shadow-md transition-all ${
        task.completed ? 'opacity-60' : ''
      }`}
    >
      <motion.div
        className="cursor-grab active:cursor-grabbing text-muted-foreground hover:text-foreground"
        whileHover={{ scale: 1.1 }}
      >
        <GripVertical className="w-5 h-5" />
      </motion.div>

      <motion.button
        onClick={() => onToggle(task.id)}
        whileHover={{ scale: 1.1 }}
        whileTap={{ scale: 0.9 }}
        className={`w-6 h-6 rounded-full border-2 flex items-center justify-center transition-colors ${
          task.completed 
            ? 'bg-primary border-primary' 
            : 'border-muted-foreground hover:border-primary'
        }`}
      >
        <AnimatePresence>
          {task.completed && (
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              exit={{ scale: 0 }}
            >
              <Check className="w-4 h-4 text-primary-foreground" />
            </motion.div>
          )}
        </AnimatePresence>
      </motion.button>

      <div className="flex-1 min-w-0">
        <p className={`font-medium truncate ${task.completed ? 'line-through text-muted-foreground' : ''}`}>
          {task.title}
        </p>
        <div className="flex items-center gap-3 mt-1">
          <span className={`text-xs px-2 py-0.5 rounded-full ${priorityColors[task.priority]}`}>
            {priorityLabels[task.priority]}
          </span>
          <span className="flex items-center gap-1 text-xs text-muted-foreground">
            <div className={`w-2 h-2 rounded-full ${categoryColors[task.category]}`} />
            {task.category}
          </span>
          <span className="flex items-center gap-1 text-xs text-muted-foreground">
            <Clock className="w-3 h-3" />
            {task.dueDate}
          </span>
        </div>
      </div>

      <div className="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
        <motion.button
          whileHover={{ scale: 1.1 }}
          whileTap={{ scale: 0.9 }}
          onClick={() => setIsStarred(!isStarred)}
          className="p-2 rounded-lg hover:bg-muted transition-colors"
        >
          <Star className={`w-4 h-4 ${isStarred ? 'fill-yellow-400 text-yellow-400' : 'text-muted-foreground'}`} />
        </motion.button>
        <motion.button
          whileHover={{ scale: 1.1 }}
          whileTap={{ scale: 0.9 }}
          onClick={() => onDelete(task.id)}
          className="p-2 rounded-lg hover:bg-red-500/10 text-muted-foreground hover:text-red-500 transition-colors"
        >
          <Trash2 className="w-4 h-4" />
        </motion.button>
      </div>
    </Reorder.Item>
  )
}

function AddTaskForm({ onAdd }) {
  const [isOpen, setIsOpen] = useState(false)
  const [title, setTitle] = useState('')
  const [priority, setPriority] = useState('medium')
  const [category, setCategory] = useState('Dev')

  const handleSubmit = (e) => {
    e.preventDefault()
    if (!title.trim()) return

    onAdd({
      id: Date.now(),
      title,
      priority,
      category,
      completed: false,
      dueDate: 'Aujourd\'hui'
    })

    setTitle('')
    setIsOpen(false)
  }

  return (
    <div className="mb-6">
      <AnimatePresence>
        {isOpen ? (
          <motion.form
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            onSubmit={handleSubmit}
            className="p-4 rounded-xl border bg-card shadow-lg space-y-4"
          >
            <input
              type="text"
              placeholder="Nom de la tâche..."
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              autoFocus
              className="w-full px-4 py-3 rounded-lg border bg-background focus:ring-2 focus:ring-primary/20 outline-none"
            />

            <div className="flex flex-wrap items-center gap-4">
              <div className="flex items-center gap-2">
                <span className="text-sm text-muted-foreground">Priorité:</span>
                <div className="flex gap-1">
                  {['low', 'medium', 'high'].map((p) => (
                    <button
                      key={p}
                      type="button"
                      onClick={() => setPriority(p)}
                      className={`px-3 py-1 text-xs rounded-full transition-colors ${
                        priority === p 
                          ? priorityColors[p] 
                          : 'bg-muted text-muted-foreground hover:bg-muted/80'
                      }`}
                    >
                      {priorityLabels[p]}
                    </button>
                  ))}
                </div>
              </div>

              <div className="flex items-center gap-2">
                <span className="text-sm text-muted-foreground">Catégorie:</span>
                <div className="flex gap-1">
                  {Object.keys(categoryColors).map((cat) => (
                    <button
                      key={cat}
                      type="button"
                      onClick={() => setCategory(cat)}
                      className={`px-3 py-1 text-xs rounded-full transition-colors ${
                        category === cat 
                          ? 'bg-primary text-primary-foreground' 
                          : 'bg-muted text-muted-foreground hover:bg-muted/80'
                      }`}
                    >
                      {cat}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            <div className="flex justify-end gap-2">
              <button
                type="button"
                onClick={() => setIsOpen(false)}
                className="px-4 py-2 rounded-lg hover:bg-muted transition-colors"
              >
                Annuler
              </button>
              <motion.button
                type="submit"
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                className="px-4 py-2 rounded-lg bg-primary text-primary-foreground font-medium"
              >
                Ajouter
              </motion.button>
            </div>
          </motion.form>
        ) : (
          <motion.button
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            whileHover={{ scale: 1.01 }}
            whileTap={{ scale: 0.99 }}
            onClick={() => setIsOpen(true)}
            className="w-full p-4 rounded-xl border-2 border-dashed hover:border-primary hover:bg-primary/5 transition-all flex items-center justify-center gap-2 text-muted-foreground hover:text-primary"
          >
            <Plus className="w-5 h-5" />
            Ajouter une tâche
          </motion.button>
        )}
      </AnimatePresence>
    </div>
  )
}

export default function TasksDemo() {
  const [tasks, setTasks] = useState(initialTasks)
  const [filter, setFilter] = useState('all') // 'all', 'active', 'completed'
  const [searchQuery, setSearchQuery] = useState('')

  const filteredTasks = tasks
    .filter(task => {
      if (filter === 'active') return !task.completed
      if (filter === 'completed') return task.completed
      return true
    })
    .filter(task =>
      task.title.toLowerCase().includes(searchQuery.toLowerCase())
    )

  const stats = {
    total: tasks.length,
    completed: tasks.filter(t => t.completed).length,
    active: tasks.filter(t => !t.completed).length,
    highPriority: tasks.filter(t => t.priority === 'high' && !t.completed).length
  }

  const handleToggle = (id) => {
    setTasks(tasks.map(task =>
      task.id === id ? { ...task, completed: !task.completed } : task
    ))
  }

  const handleDelete = (id) => {
    setTasks(tasks.filter(task => task.id !== id))
  }

  const handleAdd = (newTask) => {
    setTasks([newTask, ...tasks])
  }

  return (
    <div className="max-w-4xl mx-auto space-y-8">
      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        className="flex flex-col md:flex-row md:items-center justify-between gap-4"
      >
        <div>
          <h1 className="text-3xl font-bold flex items-center gap-2">
            <Sparkles className="w-8 h-8 text-primary" />
            Mes Tâches
          </h1>
          <p className="text-muted-foreground mt-1">
            Gérez vos tâches avec style
          </p>
        </div>

        <div className="flex items-center gap-3">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <input
              type="text"
              placeholder="Rechercher..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-10 pr-4 py-2 rounded-lg border bg-background focus:ring-2 focus:ring-primary/20 outline-none w-48"
            />
          </div>
        </div>
      </motion.div>

      {/* Stats */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.1 }}
        className="grid grid-cols-2 md:grid-cols-4 gap-4"
      >
        {[
          { label: 'Total', value: stats.total, icon: Circle, color: 'text-blue-500' },
          { label: 'Actives', value: stats.active, icon: Clock, color: 'text-yellow-500' },
          { label: 'Terminées', value: stats.completed, icon: Check, color: 'text-green-500' },
          { label: 'Urgentes', value: stats.highPriority, icon: AlertCircle, color: 'text-red-500' },
        ].map((stat, i) => (
          <motion.div
            key={stat.label}
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 0.1 + i * 0.05 }}
            whileHover={{ y: -2 }}
            className="p-4 rounded-xl bg-card border shadow-sm"
          >
            <div className="flex items-center gap-3">
              <div className={`p-2 rounded-lg bg-muted ${stat.color}`}>
                <stat.icon className="w-5 h-5" />
              </div>
              <div>
                <p className="text-2xl font-bold">{stat.value}</p>
                <p className="text-xs text-muted-foreground">{stat.label}</p>
              </div>
            </div>
          </motion.div>
        ))}
      </motion.div>

      {/* Filters */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.2 }}
        className="flex items-center gap-2"
      >
        {[
          { id: 'all', label: 'Toutes' },
          { id: 'active', label: 'Actives' },
          { id: 'completed', label: 'Terminées' },
        ].map((f) => (
          <button
            key={f.id}
            onClick={() => setFilter(f.id)}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
              filter === f.id
                ? 'bg-primary text-primary-foreground'
                : 'bg-muted text-muted-foreground hover:bg-muted/80'
            }`}
          >
            {f.label}
          </button>
        ))}
      </motion.div>

      {/* Add Task Form */}
      <AddTaskForm onAdd={handleAdd} />

      {/* Task List */}
      <Reorder.Group
        axis="y"
        values={filteredTasks}
        onReorder={setTasks}
        className="space-y-3"
      >
        <AnimatePresence>
          {filteredTasks.map((task) => (
            <TaskItem
              key={task.id}
              task={task}
              onToggle={handleToggle}
              onDelete={handleDelete}
            />
          ))}
        </AnimatePresence>
      </Reorder.Group>

      {filteredTasks.length === 0 && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="text-center py-12"
        >
          <div className="w-16 h-16 rounded-full bg-muted flex items-center justify-center mx-auto mb-4">
            <Check className="w-8 h-8 text-muted-foreground" />
          </div>
          <h3 className="text-lg font-semibold mb-1">Aucune tâche</h3>
          <p className="text-muted-foreground">
            {filter === 'completed'
              ? 'Vous n\'avez pas encore terminé de tâche'
              : filter === 'active'
                ? 'Toutes vos tâches sont terminées !'
                : 'Ajoutez votre première tâche'}
          </p>
        </motion.div>
      )}
    </div>
  )
}

