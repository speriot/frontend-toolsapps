import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  Check, X, AlertTriangle, Info, Bell, ChevronDown,
  Loader2, Copy, CheckCircle, ExternalLink, Moon, Sun,
  Volume2, VolumeX, Wifi, WifiOff, Battery, BatteryCharging
} from 'lucide-react'

// Toggle Component
function Toggle({ enabled, onChange, label }) {
  return (
    <label className="flex items-center gap-3 cursor-pointer">
      <motion.button
        onClick={() => onChange(!enabled)}
        className={`relative w-12 h-6 rounded-full transition-colors ${
          enabled ? 'bg-primary' : 'bg-muted'
        }`}
      >
        <motion.div
          animate={{ x: enabled ? 24 : 2 }}
          transition={{ type: 'spring', stiffness: 500, damping: 30 }}
          className="absolute top-1 w-4 h-4 rounded-full bg-white shadow-sm"
        />
      </motion.button>
      {label && <span className="text-sm">{label}</span>}
    </label>
  )
}

// Badge Component
function Badge({ children, variant = 'default' }) {
  const variants = {
    default: 'bg-primary/10 text-primary',
    success: 'bg-green-500/10 text-green-600',
    warning: 'bg-yellow-500/10 text-yellow-600',
    error: 'bg-red-500/10 text-red-600',
    info: 'bg-blue-500/10 text-blue-600',
  }

  return (
    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${variants[variant]}`}>
      {children}
    </span>
  )
}

// Alert Component
function Alert({ type = 'info', title, children, onClose }) {
  const styles = {
    info: { bg: 'bg-blue-500/10 border-blue-500/20', icon: Info, iconColor: 'text-blue-500' },
    success: { bg: 'bg-green-500/10 border-green-500/20', icon: CheckCircle, iconColor: 'text-green-500' },
    warning: { bg: 'bg-yellow-500/10 border-yellow-500/20', icon: AlertTriangle, iconColor: 'text-yellow-500' },
    error: { bg: 'bg-red-500/10 border-red-500/20', icon: X, iconColor: 'text-red-500' },
  }

  const { bg, icon: Icon, iconColor } = styles[type]

  return (
    <motion.div
      initial={{ opacity: 0, y: -10 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -10 }}
      className={`flex items-start gap-3 p-4 rounded-xl border ${bg}`}
    >
      <Icon className={`w-5 h-5 flex-shrink-0 ${iconColor}`} />
      <div className="flex-1 min-w-0">
        {title && <h4 className="font-medium mb-1">{title}</h4>}
        <p className="text-sm text-muted-foreground">{children}</p>
      </div>
      {onClose && (
        <button onClick={onClose} className="text-muted-foreground hover:text-foreground">
          <X className="w-4 h-4" />
        </button>
      )}
    </motion.div>
  )
}

// Tooltip Component
function Tooltip({ children, content }) {
  const [show, setShow] = useState(false)

  return (
    <div
      className="relative inline-block"
      onMouseEnter={() => setShow(true)}
      onMouseLeave={() => setShow(false)}
    >
      {children}
      <AnimatePresence>
        {show && (
          <motion.div
            initial={{ opacity: 0, y: 5 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: 5 }}
            className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 px-3 py-1.5 rounded-lg bg-foreground text-background text-xs whitespace-nowrap z-50"
          >
            {content}
            <div className="absolute top-full left-1/2 -translate-x-1/2 border-4 border-transparent border-t-foreground" />
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}

// Progress Bar
function ProgressBar({ value, max = 100, showLabel = true, color = 'primary' }) {
  const percentage = Math.min((value / max) * 100, 100)
  const colors = {
    primary: 'bg-primary',
    success: 'bg-green-500',
    warning: 'bg-yellow-500',
    error: 'bg-red-500',
  }

  return (
    <div className="space-y-1">
      <div className="h-2 rounded-full bg-muted overflow-hidden">
        <motion.div
          initial={{ width: 0 }}
          animate={{ width: `${percentage}%` }}
          transition={{ duration: 0.5, ease: 'easeOut' }}
          className={`h-full rounded-full ${colors[color]}`}
        />
      </div>
      {showLabel && (
        <p className="text-xs text-muted-foreground text-right">{Math.round(percentage)}%</p>
      )}
    </div>
  )
}

// Skeleton Loader
function Skeleton({ className }) {
  return (
    <div className={`animate-pulse bg-muted rounded ${className}`} />
  )
}

// Avatar Group
function AvatarGroup({ avatars, max = 4 }) {
  const visible = avatars.slice(0, max)
  const remaining = avatars.length - max

  return (
    <div className="flex -space-x-3">
      {visible.map((avatar, i) => (
        <motion.div
          key={i}
          initial={{ scale: 0, x: -10 }}
          animate={{ scale: 1, x: 0 }}
          transition={{ delay: i * 0.1 }}
          className="w-10 h-10 rounded-full bg-gradient-to-br from-primary to-purple-600 flex items-center justify-center text-white text-sm font-medium ring-2 ring-background"
        >
          {avatar}
        </motion.div>
      ))}
      {remaining > 0 && (
        <div className="w-10 h-10 rounded-full bg-muted flex items-center justify-center text-sm font-medium ring-2 ring-background">
          +{remaining}
        </div>
      )}
    </div>
  )
}

// Accordion
function Accordion({ items }) {
  const [openIndex, setOpenIndex] = useState(null)

  return (
    <div className="space-y-2">
      {items.map((item, i) => (
        <div key={i} className="border rounded-xl overflow-hidden">
          <button
            onClick={() => setOpenIndex(openIndex === i ? null : i)}
            className="w-full flex items-center justify-between p-4 hover:bg-muted/50 transition-colors"
          >
            <span className="font-medium">{item.title}</span>
            <motion.div
              animate={{ rotate: openIndex === i ? 180 : 0 }}
              transition={{ duration: 0.2 }}
            >
              <ChevronDown className="w-5 h-5 text-muted-foreground" />
            </motion.div>
          </button>
          <AnimatePresence>
            {openIndex === i && (
              <motion.div
                initial={{ height: 0 }}
                animate={{ height: 'auto' }}
                exit={{ height: 0 }}
                transition={{ duration: 0.2 }}
                className="overflow-hidden"
              >
                <div className="p-4 pt-0 text-sm text-muted-foreground">
                  {item.content}
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      ))}
    </div>
  )
}

// Tabs Component
function Tabs({ tabs }) {
  const [activeTab, setActiveTab] = useState(0)

  return (
    <div className="space-y-4">
      <div className="flex gap-1 p-1 bg-muted rounded-xl">
        {tabs.map((tab, i) => (
          <button
            key={i}
            onClick={() => setActiveTab(i)}
            className={`relative flex-1 py-2 px-4 text-sm font-medium rounded-lg transition-colors ${
              activeTab === i ? '' : 'text-muted-foreground hover:text-foreground'
            }`}
          >
            {activeTab === i && (
              <motion.div
                layoutId="activeTab"
                className="absolute inset-0 bg-background rounded-lg shadow-sm"
                transition={{ type: 'spring', bounce: 0.2, duration: 0.5 }}
              />
            )}
            <span className="relative z-10">{tab.label}</span>
          </button>
        ))}
      </div>
      <AnimatePresence mode="wait">
        <motion.div
          key={activeTab}
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -10 }}
          transition={{ duration: 0.2 }}
          className="p-4 border rounded-xl"
        >
          {tabs[activeTab].content}
        </motion.div>
      </AnimatePresence>
    </div>
  )
}

// Copy Button
function CopyButton({ text }) {
  const [copied, setCopied] = useState(false)

  const handleCopy = async () => {
    await navigator.clipboard.writeText(text)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  return (
    <motion.button
      whileHover={{ scale: 1.05 }}
      whileTap={{ scale: 0.95 }}
      onClick={handleCopy}
      className="p-2 rounded-lg border hover:bg-muted transition-colors"
    >
      <AnimatePresence mode="wait">
        {copied ? (
          <motion.div
            key="check"
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            exit={{ scale: 0 }}
          >
            <Check className="w-4 h-4 text-green-500" />
          </motion.div>
        ) : (
          <motion.div
            key="copy"
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            exit={{ scale: 0 }}
          >
            <Copy className="w-4 h-4" />
          </motion.div>
        )}
      </AnimatePresence>
    </motion.button>
  )
}

// Notification Toast
function Toast({ message, type = 'info', onClose }) {
  const icons = {
    info: Info,
    success: CheckCircle,
    warning: AlertTriangle,
    error: X,
  }
  const Icon = icons[type]

  const colors = {
    info: 'bg-blue-500',
    success: 'bg-green-500',
    warning: 'bg-yellow-500',
    error: 'bg-red-500',
  }

  return (
    <motion.div
      initial={{ opacity: 0, x: 50 }}
      animate={{ opacity: 1, x: 0 }}
      exit={{ opacity: 0, x: 50 }}
      className="flex items-center gap-3 px-4 py-3 rounded-xl bg-card border shadow-lg"
    >
      <div className={`p-1 rounded-full ${colors[type]}`}>
        <Icon className="w-4 h-4 text-white" />
      </div>
      <span className="text-sm">{message}</span>
      <button onClick={onClose} className="ml-2 text-muted-foreground hover:text-foreground">
        <X className="w-4 h-4" />
      </button>
    </motion.div>
  )
}

export default function ComponentsDemo() {
  const [toggle1, setToggle1] = useState(false)
  const [toggle2, setToggle2] = useState(true)
  const [showAlert, setShowAlert] = useState(true)
  const [toasts, setToasts] = useState([])
  const [loading, setLoading] = useState(false)

  const addToast = (message, type) => {
    const id = Date.now()
    setToasts([...toasts, { id, message, type }])
    setTimeout(() => {
      setToasts(prev => prev.filter(t => t.id !== id))
    }, 3000)
  }

  const simulateLoading = () => {
    setLoading(true)
    setTimeout(() => setLoading(false), 2000)
  }

  return (
    <div className="max-w-4xl mx-auto space-y-12">
      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="text-center space-y-4"
      >
        <h1 className="text-3xl font-bold">Bibliothèque de Composants</h1>
        <p className="text-muted-foreground">
          Une collection de composants UI modernes et réutilisables
        </p>
      </motion.div>

      {/* Toggles */}
      <section className="space-y-4">
        <h2 className="text-xl font-semibold">Toggles</h2>
        <div className="flex flex-wrap gap-6 p-6 border rounded-xl">
          <Toggle enabled={toggle1} onChange={setToggle1} label="Dark Mode" />
          <Toggle enabled={toggle2} onChange={setToggle2} label="Notifications" />
        </div>
      </section>

      {/* Badges */}
      <section className="space-y-4">
        <h2 className="text-xl font-semibold">Badges</h2>
        <div className="flex flex-wrap gap-3 p-6 border rounded-xl">
          <Badge>Default</Badge>
          <Badge variant="success">Succès</Badge>
          <Badge variant="warning">Attention</Badge>
          <Badge variant="error">Erreur</Badge>
          <Badge variant="info">Info</Badge>
        </div>
      </section>

      {/* Alerts */}
      <section className="space-y-4">
        <h2 className="text-xl font-semibold">Alertes</h2>
        <div className="space-y-3">
          <Alert type="info" title="Information">
            Ceci est un message d'information important pour l'utilisateur.
          </Alert>
          <Alert type="success" title="Succès">
            L'opération a été effectuée avec succès !
          </Alert>
          <Alert type="warning" title="Attention">
            Veuillez vérifier les informations avant de continuer.
          </Alert>
          <AnimatePresence>
            {showAlert && (
              <Alert type="error" title="Erreur" onClose={() => setShowAlert(false)}>
                Une erreur s'est produite. Cliquez sur X pour fermer.
              </Alert>
            )}
          </AnimatePresence>
        </div>
      </section>

      {/* Tooltips */}
      <section className="space-y-4">
        <h2 className="text-xl font-semibold">Tooltips</h2>
        <div className="flex gap-4 p-6 border rounded-xl">
          <Tooltip content="Ceci est un tooltip">
            <button className="px-4 py-2 bg-primary text-primary-foreground rounded-lg">
              Survolez-moi
            </button>
          </Tooltip>
          <Tooltip content="Information supplémentaire">
            <button className="p-2 border rounded-lg">
              <Info className="w-5 h-5" />
            </button>
          </Tooltip>
        </div>
      </section>

      {/* Progress Bars */}
      <section className="space-y-4">
        <h2 className="text-xl font-semibold">Barres de Progression</h2>
        <div className="space-y-4 p-6 border rounded-xl">
          <ProgressBar value={75} />
          <ProgressBar value={45} color="success" />
          <ProgressBar value={30} color="warning" />
          <ProgressBar value={15} color="error" />
        </div>
      </section>

      {/* Skeleton Loaders */}
      <section className="space-y-4">
        <h2 className="text-xl font-semibold">Skeleton Loaders</h2>
        <div className="flex items-center gap-4 p-6 border rounded-xl">
          <Skeleton className="w-12 h-12 rounded-full" />
          <div className="space-y-2 flex-1">
            <Skeleton className="h-4 w-1/3" />
            <Skeleton className="h-4 w-2/3" />
          </div>
        </div>
      </section>

      {/* Avatar Group */}
      <section className="space-y-4">
        <h2 className="text-xl font-semibold">Avatar Group</h2>
        <div className="p-6 border rounded-xl">
          <AvatarGroup avatars={['JD', 'SM', 'TD', 'LB', 'PM', 'ER']} max={4} />
        </div>
      </section>

      {/* Tabs */}
      <section className="space-y-4">
        <h2 className="text-xl font-semibold">Tabs</h2>
        <Tabs
          tabs={[
            { label: 'Aperçu', content: 'Contenu de l\'onglet Aperçu. Lorem ipsum dolor sit amet.' },
            { label: 'Fonctionnalités', content: 'Liste des fonctionnalités disponibles dans cette section.' },
            { label: 'Paramètres', content: 'Configurez vos préférences ici.' },
          ]}
        />
      </section>

      {/* Accordion */}
      <section className="space-y-4">
        <h2 className="text-xl font-semibold">Accordion</h2>
        <Accordion
          items={[
            { title: 'Comment ça fonctionne ?', content: 'Cliquez sur un élément pour l\'ouvrir ou le fermer. Les animations sont fluides grâce à Framer Motion.' },
            { title: 'Est-ce personnalisable ?', content: 'Oui, tous les composants sont facilement personnalisables avec TailwindCSS.' },
            { title: 'Puis-je les utiliser dans mon projet ?', content: 'Absolument ! Ces composants sont conçus pour être réutilisables.' },
          ]}
        />
      </section>

      {/* Buttons & Loading */}
      <section className="space-y-4">
        <h2 className="text-xl font-semibold">Boutons & Loading</h2>
        <div className="flex flex-wrap gap-4 p-6 border rounded-xl">
          <motion.button
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            onClick={simulateLoading}
            disabled={loading}
            className="px-6 py-2.5 bg-primary text-primary-foreground rounded-xl font-medium flex items-center gap-2 disabled:opacity-70"
          >
            {loading && <Loader2 className="w-4 h-4 animate-spin" />}
            {loading ? 'Chargement...' : 'Simuler chargement'}
          </motion.button>

          <CopyButton text="npm install frontend-toolsapps" />

          <motion.button
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            onClick={() => addToast('Action effectuée !', 'success')}
            className="px-6 py-2.5 border rounded-xl font-medium"
          >
            Afficher Toast
          </motion.button>
        </div>
      </section>

      {/* Toast Container */}
      <div className="fixed bottom-4 right-4 space-y-2 z-50">
        <AnimatePresence>
          {toasts.map(toast => (
            <Toast
              key={toast.id}
              message={toast.message}
              type={toast.type}
              onClose={() => setToasts(prev => prev.filter(t => t.id !== toast.id))}
            />
          ))}
        </AnimatePresence>
      </div>
    </div>
  )
}

