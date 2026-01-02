import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  User, Mail, Lock, Eye, EyeOff, Github, Chrome, ArrowRight,
  CheckCircle, AlertCircle, Loader2, Sparkles, Shield
} from 'lucide-react'

function FloatingShape({ className, delay = 0 }) {
  return (
    <motion.div
      className={`absolute rounded-full blur-3xl opacity-30 ${className}`}
      animate={{
        x: [0, 30, 0],
        y: [0, -30, 0],
        scale: [1, 1.1, 1],
      }}
      transition={{
        duration: 8,
        delay,
        repeat: Infinity,
        ease: "easeInOut"
      }}
    />
  )
}

function InputField({
  icon: Icon,
  label,
  type = 'text',
  placeholder,
  value,
  onChange,
  error,
  success
}) {
  const [focused, setFocused] = useState(false)
  const [showPassword, setShowPassword] = useState(false)

  const isPassword = type === 'password'
  const inputType = isPassword ? (showPassword ? 'text' : 'password') : type

  return (
    <div className="space-y-2">
      <label className="text-sm font-medium">{label}</label>
      <div className="relative">
        <Icon className={`absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 transition-colors ${
          focused ? 'text-primary' : 'text-muted-foreground'
        }`} />
        <motion.input
          type={inputType}
          placeholder={placeholder}
          value={value}
          onChange={onChange}
          onFocus={() => setFocused(true)}
          onBlur={() => setFocused(false)}
          whileFocus={{ scale: 1.01 }}
          className={`w-full pl-10 pr-10 py-3 rounded-xl border bg-background transition-all outline-none ${
            error 
              ? 'border-red-500 focus:ring-2 focus:ring-red-500/20' 
              : success
                ? 'border-green-500 focus:ring-2 focus:ring-green-500/20'
                : 'focus:border-primary focus:ring-2 focus:ring-primary/20'
          }`}
        />
        {isPassword && (
          <button
            type="button"
            onClick={() => setShowPassword(!showPassword)}
            className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground transition-colors"
          >
            {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
          </button>
        )}
        {success && !isPassword && (
          <CheckCircle className="absolute right-3 top-1/2 -translate-y-1/2 w-5 h-5 text-green-500" />
        )}
        {error && !isPassword && (
          <AlertCircle className="absolute right-3 top-1/2 -translate-y-1/2 w-5 h-5 text-red-500" />
        )}
      </div>
      <AnimatePresence>
        {error && (
          <motion.p
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            className="text-sm text-red-500"
          >
            {error}
          </motion.p>
        )}
      </AnimatePresence>
    </div>
  )
}

function PasswordStrength({ password }) {
  const getStrength = () => {
    let strength = 0
    if (password.length >= 8) strength++
    if (/[A-Z]/.test(password)) strength++
    if (/[0-9]/.test(password)) strength++
    if (/[^A-Za-z0-9]/.test(password)) strength++
    return strength
  }

  const strength = getStrength()
  const labels = ['Très faible', 'Faible', 'Moyen', 'Fort', 'Très fort']
  const colors = ['bg-red-500', 'bg-orange-500', 'bg-yellow-500', 'bg-green-500', 'bg-emerald-500']

  if (!password) return null

  return (
    <motion.div
      initial={{ opacity: 0, height: 0 }}
      animate={{ opacity: 1, height: 'auto' }}
      className="space-y-2"
    >
      <div className="flex gap-1">
        {[...Array(4)].map((_, i) => (
          <motion.div
            key={i}
            initial={{ scaleX: 0 }}
            animate={{ scaleX: 1 }}
            transition={{ delay: i * 0.1 }}
            className={`h-1.5 flex-1 rounded-full ${
              i < strength ? colors[strength] : 'bg-muted'
            }`}
          />
        ))}
      </div>
      <p className={`text-xs ${colors[strength].replace('bg-', 'text-')}`}>
        {labels[strength]}
      </p>
    </motion.div>
  )
}

function SocialButton({ icon: Icon, label, onClick }) {
  return (
    <motion.button
      whileHover={{ scale: 1.02 }}
      whileTap={{ scale: 0.98 }}
      onClick={onClick}
      className="flex-1 flex items-center justify-center gap-2 py-3 rounded-xl border hover:bg-muted transition-colors"
    >
      <Icon className="w-5 h-5" />
      <span className="text-sm font-medium">{label}</span>
    </motion.button>
  )
}

export default function AuthDemo() {
  const [mode, setMode] = useState('login') // 'login', 'register', 'forgot'
  const [loading, setLoading] = useState(false)
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [name, setName] = useState('')
  const [emailError, setEmailError] = useState('')
  const [success, setSuccess] = useState(false)

  const validateEmail = (email) => {
    const isValid = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
    setEmailError(email && !isValid ? 'Email invalide' : '')
    return isValid
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!validateEmail(email)) return

    setLoading(true)
    await new Promise(resolve => setTimeout(resolve, 2000))
    setLoading(false)
    setSuccess(true)

    setTimeout(() => setSuccess(false), 3000)
  }

  return (
    <div className="min-h-[80vh] flex items-center justify-center p-4">
      <div className="w-full max-w-6xl grid lg:grid-cols-2 gap-8 items-center">
        {/* Left Side - Decorative */}
        <motion.div
          initial={{ opacity: 0, x: -50 }}
          animate={{ opacity: 1, x: 0 }}
          className="hidden lg:block relative"
        >
          <div className="relative bg-gradient-to-br from-primary/20 via-purple-500/20 to-pink-500/20 rounded-3xl p-12 overflow-hidden min-h-[600px]">
            <FloatingShape className="w-64 h-64 bg-primary -top-20 -left-20" delay={0} />
            <FloatingShape className="w-48 h-48 bg-purple-500 bottom-10 right-10" delay={2} />
            <FloatingShape className="w-32 h-32 bg-pink-500 top-1/2 left-1/2" delay={4} />

            <div className="relative z-10 h-full flex flex-col justify-center">
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.3 }}
              >
                <Sparkles className="w-12 h-12 text-primary mb-6" />
                <h2 className="text-4xl font-bold mb-4">
                  Bienvenue sur <br />
                  <span className="bg-gradient-to-r from-primary to-purple-600 bg-clip-text text-transparent">
                    ToolsApps
                  </span>
                </h2>
                <p className="text-muted-foreground text-lg mb-8">
                  Rejoignez notre communauté et découvrez une nouvelle façon de travailler.
                </p>
              </motion.div>

              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.5 }}
                className="space-y-4"
              >
                {[
                  'Accès à toutes les fonctionnalités premium',
                  'Support prioritaire 24/7',
                  'Mises à jour exclusives'
                ].map((feature, i) => (
                  <div key={i} className="flex items-center gap-3">
                    <div className="w-6 h-6 rounded-full bg-primary/20 flex items-center justify-center">
                      <CheckCircle className="w-4 h-4 text-primary" />
                    </div>
                    <span className="text-sm">{feature}</span>
                  </div>
                ))}
              </motion.div>
            </div>
          </div>
        </motion.div>

        {/* Right Side - Form */}
        <motion.div
          initial={{ opacity: 0, x: 50 }}
          animate={{ opacity: 1, x: 0 }}
          className="w-full max-w-md mx-auto"
        >
          <div className="bg-card rounded-2xl border shadow-xl p-8">
            {/* Tabs */}
            <div className="flex gap-2 p-1 bg-muted rounded-xl mb-8">
              {[
                { id: 'login', label: 'Connexion' },
                { id: 'register', label: 'Inscription' }
              ].map((tab) => (
                <button
                  key={tab.id}
                  onClick={() => {
                    setMode(tab.id)
                    setSuccess(false)
                  }}
                  className={`flex-1 py-2.5 rounded-lg text-sm font-medium transition-all ${
                    mode === tab.id
                      ? 'bg-background shadow-sm'
                      : 'text-muted-foreground hover:text-foreground'
                  }`}
                >
                  {tab.label}
                </button>
              ))}
            </div>

            <AnimatePresence mode="wait">
              {success ? (
                <motion.div
                  key="success"
                  initial={{ opacity: 0, scale: 0.9 }}
                  animate={{ opacity: 1, scale: 1 }}
                  exit={{ opacity: 0, scale: 0.9 }}
                  className="text-center py-12"
                >
                  <motion.div
                    initial={{ scale: 0 }}
                    animate={{ scale: 1 }}
                    transition={{ type: "spring", duration: 0.5 }}
                    className="w-20 h-20 rounded-full bg-green-500/10 flex items-center justify-center mx-auto mb-6"
                  >
                    <CheckCircle className="w-10 h-10 text-green-500" />
                  </motion.div>
                  <h3 className="text-xl font-semibold mb-2">
                    {mode === 'login' ? 'Connexion réussie !' : 'Inscription réussie !'}
                  </h3>
                  <p className="text-muted-foreground">
                    {mode === 'login'
                      ? 'Vous allez être redirigé...'
                      : 'Vérifiez votre email pour confirmer.'}
                  </p>
                </motion.div>
              ) : (
                <motion.form
                  key={mode}
                  initial={{ opacity: 0, x: 20 }}
                  animate={{ opacity: 1, x: 0 }}
                  exit={{ opacity: 0, x: -20 }}
                  onSubmit={handleSubmit}
                  className="space-y-6"
                >
                  {mode === 'register' && (
                    <InputField
                      icon={User}
                      label="Nom complet"
                      placeholder="Jean Dupont"
                      value={name}
                      onChange={(e) => setName(e.target.value)}
                    />
                  )}

                  <InputField
                    icon={Mail}
                    label="Email"
                    type="email"
                    placeholder="vous@exemple.com"
                    value={email}
                    onChange={(e) => {
                      setEmail(e.target.value)
                      if (e.target.value) validateEmail(e.target.value)
                    }}
                    error={emailError}
                    success={email && !emailError}
                  />

                  {mode !== 'forgot' && (
                    <>
                      <InputField
                        icon={Lock}
                        label="Mot de passe"
                        type="password"
                        placeholder="••••••••"
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                      />

                      {mode === 'register' && (
                        <PasswordStrength password={password} />
                      )}
                    </>
                  )}

                  {mode === 'login' && (
                    <div className="flex items-center justify-between text-sm">
                      <label className="flex items-center gap-2 cursor-pointer">
                        <input type="checkbox" className="rounded border-muted" />
                        <span className="text-muted-foreground">Se souvenir de moi</span>
                      </label>
                      <button
                        type="button"
                        onClick={() => setMode('forgot')}
                        className="text-primary hover:underline"
                      >
                        Mot de passe oublié ?
                      </button>
                    </div>
                  )}

                  <motion.button
                    type="submit"
                    disabled={loading}
                    whileHover={{ scale: loading ? 1 : 1.02 }}
                    whileTap={{ scale: loading ? 1 : 0.98 }}
                    className="w-full py-3 rounded-xl bg-primary text-primary-foreground font-semibold shadow-lg shadow-primary/25 flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {loading ? (
                      <>
                        <Loader2 className="w-5 h-5 animate-spin" />
                        Chargement...
                      </>
                    ) : (
                      <>
                        {mode === 'login' ? 'Se connecter' : mode === 'register' ? 'Créer un compte' : 'Réinitialiser'}
                        <ArrowRight className="w-5 h-5" />
                      </>
                    )}
                  </motion.button>
                </motion.form>
              )}
            </AnimatePresence>

            {!success && mode !== 'forgot' && (
              <>
                <div className="relative my-8">
                  <div className="absolute inset-0 flex items-center">
                    <div className="w-full border-t" />
                  </div>
                  <div className="relative flex justify-center text-xs uppercase">
                    <span className="bg-card px-2 text-muted-foreground">Ou continuer avec</span>
                  </div>
                </div>

                <div className="flex gap-4">
                  <SocialButton icon={Github} label="GitHub" />
                  <SocialButton icon={Chrome} label="Google" />
                </div>
              </>
            )}

            {mode === 'forgot' && !success && (
              <button
                type="button"
                onClick={() => setMode('login')}
                className="w-full mt-6 text-sm text-muted-foreground hover:text-foreground transition-colors"
              >
                ← Retour à la connexion
              </button>
            )}
          </div>

          <p className="text-center text-xs text-muted-foreground mt-6">
            En continuant, vous acceptez nos{' '}
            <a href="#" className="text-primary hover:underline">Conditions d'utilisation</a>{' '}
            et notre{' '}
            <a href="#" className="text-primary hover:underline">Politique de confidentialité</a>
          </p>
        </motion.div>
      </div>
    </div>
  )
}

