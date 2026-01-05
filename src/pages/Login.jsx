import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { useNavigate, useLocation } from 'react-router-dom'
import { useAuth } from '../contexts/AuthContext'
import {
  Mail, Lock, Eye, EyeOff, ArrowRight,
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

export default function Login() {
  const navigate = useNavigate()
  const location = useLocation()
  const { login } = useAuth()

  const [loading, setLoading] = useState(false)
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [emailError, setEmailError] = useState('')
  const [loginError, setLoginError] = useState('')
  const [rememberMe, setRememberMe] = useState(false)

  const from = location.state?.from?.pathname || '/'

  const validateEmail = (email) => {
    const isValid = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
    setEmailError(email && !isValid ? 'Email invalide' : '')
    return isValid
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    
    if (!validateEmail(email)) {
      return
    }

    if (!password) {
      setLoginError('Veuillez entrer votre mot de passe')
      return
    }

    setLoading(true)
    setLoginError('')

    const result = await login(email, password)

    if (result.success) {
      // Rediriger vers la page d'origine ou l'accueil
      setTimeout(() => {
        navigate(from, { replace: true })
      }, 500)
    } else {
      setLoginError(result.error)
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center p-4 bg-gradient-to-br from-background via-background to-muted">
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
                <Shield className="w-12 h-12 text-primary mb-6" />
                <h2 className="text-4xl font-bold mb-4">
                  Accès sécurisé à <br />
                  <span className="bg-gradient-to-r from-primary to-purple-600 bg-clip-text text-transparent">
                    ToolsApps
                  </span>
                </h2>
                <p className="text-muted-foreground text-lg mb-8">
                  Connectez-vous pour accéder à toutes les fonctionnalités de la plateforme.
                </p>
              </motion.div>

              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.5 }}
                className="space-y-4"
              >
                {[
                  'Accès à toutes les pages et démos',
                  'Interface sécurisée et moderne',
                  'Session persistante'
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

        {/* Right Side - Login Form */}
        <motion.div
          initial={{ opacity: 0, x: 50 }}
          animate={{ opacity: 1, x: 0 }}
          className="w-full max-w-md mx-auto"
        >
          <div className="bg-card rounded-2xl border shadow-xl p-8">
            <div className="mb-8">
              <h1 className="text-3xl font-bold mb-2">Connexion</h1>
              <p className="text-muted-foreground">
                Entrez vos identifiants pour accéder à l'application
              </p>
            </div>

            <form onSubmit={handleSubmit} className="space-y-6">
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

              <InputField
                icon={Lock}
                label="Mot de passe"
                type="password"
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />

              <div className="flex items-center justify-between text-sm">
                <label className="flex items-center gap-2 cursor-pointer">
                  <input 
                    type="checkbox" 
                    className="rounded border-muted"
                    checked={rememberMe}
                    onChange={(e) => setRememberMe(e.target.checked)}
                  />
                  <span className="text-muted-foreground">Se souvenir de moi</span>
                </label>
              </div>

              {loginError && (
                <motion.div
                  initial={{ opacity: 0, y: -10 }}
                  animate={{ opacity: 1, y: 0 }}
                  className="p-3 rounded-lg bg-red-50 border border-red-200"
                >
                  <p className="text-sm text-red-600 flex items-center gap-2">
                    <AlertCircle className="w-4 h-4" />
                    {loginError}
                  </p>
                </motion.div>
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
                    Connexion en cours...
                  </>
                ) : (
                  <>
                    Se connecter
                    <ArrowRight className="w-5 h-5" />
                  </>
                )}
              </motion.button>
            </form>
          </div>

          <p className="text-center text-xs text-muted-foreground mt-6">
            Authentification sécurisée • ToolsApps {new Date().getFullYear()}
          </p>
        </motion.div>
      </div>
    </div>
  )
}
