import { useState, useEffect, useMemo } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  CheckCircle, XCircle, Eye, EyeOff, Shuffle, Trophy,
  RotateCcw, Sparkles, BookOpen, Target, Zap, Medal,
  ChevronDown, ChevronUp, Volume2, Lightbulb, Timer, Star
} from 'lucide-react'

// Données des verbes irréguliers
const verbsData = [
  { infinitif: "To be", preterit: "I was/You were", participe: "been", traduction: "être" },
  { infinitif: "To have", preterit: "I had", participe: "had", traduction: "avoir" },
  { infinitif: "To make", preterit: "I made", participe: "made", traduction: "faire (son lit, un gâteau), fabriquer" },
  { infinitif: "To do", preterit: "I did", participe: "done", traduction: "faire (ses devoirs)" },
  { infinitif: "To go", preterit: "I went", participe: "gone", traduction: "aller" },
  { infinitif: "To get", preterit: "I got", participe: "got", traduction: "obtenir devenir (vieux, riche)" },
  { infinitif: "To bet", preterit: "I bet", participe: "bet", traduction: "parier" },
  { infinitif: "To cost", preterit: "I cost", participe: "cost", traduction: "coûter" },
  { infinitif: "To cut", preterit: "I cut", participe: "cut", traduction: "couper" },
  { infinitif: "To hit", preterit: "I hit", participe: "hit", traduction: "frapper" },
  { infinitif: "To hurt", preterit: "I hurt", participe: "hurt", traduction: "blesser, faire mal, avoir mal" },
  { infinitif: "To let", preterit: "I let", participe: "let", traduction: "laisser, permettre, louer un bien" },
  { infinitif: "To put", preterit: "I put", participe: "put", traduction: "mettre" },
  { infinitif: "To read", preterit: "I read", participe: "read", traduction: "lire" },
  { infinitif: "To set (the table)", preterit: "I set", participe: "set", traduction: "mettre (la table)" },
  { infinitif: "To spread", preterit: "I spread", participe: "spread", traduction: "étaler, répandre" },
  { infinitif: "To shut", preterit: "I shut", participe: "shut", traduction: "fermer" },
  { infinitif: "To build", preterit: "I built", participe: "built", traduction: "construire" },
  { infinitif: "To burn", preterit: "I burnt", participe: "burnt", traduction: "brûler" },
  { infinitif: "To lose", preterit: "I lost", participe: "lost", traduction: "perdre" },
  { infinitif: "To sit", preterit: "I sat", participe: "sat", traduction: "s'asseoir" },
  { infinitif: "To lend", preterit: "I lent", participe: "lent", traduction: "prêter" },
  { infinitif: "To send", preterit: "I sent", participe: "sent", traduction: "envoyer" },
  { infinitif: "To spend", preterit: "I spent", participe: "spent", traduction: "dépenser de l'argent, passer du tps" },
  { infinitif: "To bleed", preterit: "I bled", participe: "bled", traduction: "saigner" },
  { infinitif: "To deal", preterit: "I dealt", participe: "dealt", traduction: "distribuer, traiter" },
  { infinitif: "To dream", preterit: "I dreamt", participe: "dreamt", traduction: "rêver" },
  { infinitif: "To feed", preterit: "I fed", participe: "fed", traduction: "nourrir" },
  { infinitif: "To feel", preterit: "I felt", participe: "felt", traduction: "se sentir (bien, mal…)" },
  { infinitif: "To keep", preterit: "I kept", participe: "kept", traduction: "garder" },
  { infinitif: "To lead", preterit: "I led", participe: "led", traduction: "mener, diriger" },
  { infinitif: "To leave", preterit: "I left", participe: "left", traduction: "quitter, partir" },
  { infinitif: "To mean", preterit: "I meant", participe: "meant", traduction: "signifier, vouloir dire" },
  { infinitif: "To meet", preterit: "I met", participe: "met", traduction: "rencontrer" },
  { infinitif: "To sleep", preterit: "I slept", participe: "slept", traduction: "dormir" },
  { infinitif: "To sweep", preterit: "I swept", participe: "swept", traduction: "balayer" },
  { infinitif: "To smell", preterit: "I smelt", participe: "smelt", traduction: "sentir, flairer" },
  { infinitif: "To spell", preterit: "I spelt", participe: "spelt", traduction: "épeler, orthographier" },
  { infinitif: "To hear", preterit: "I heard", participe: "heard", traduction: "entendre" },
  { infinitif: "To learn", preterit: "I learnt", participe: "learnt", traduction: "apprendre" },
  { infinitif: "To bring", preterit: "I brought", participe: "brought", traduction: "apporter" },
  { infinitif: "To buy", preterit: "I bought", participe: "bought", traduction: "acheter" },
  { infinitif: "To catch", preterit: "I caught", participe: "caught", traduction: "attraper" },
  { infinitif: "To fight", preterit: "I fought", participe: "fought", traduction: "combattre" },
  { infinitif: "To teach", preterit: "I taught", participe: "taught", traduction: "enseigner" },
  { infinitif: "To think", preterit: "I thought", participe: "thought", traduction: "réfléchir, penser" },
  { infinitif: "To shoot", preterit: "I shot", participe: "shot", traduction: "tirer une balle, tuer par balle, filmer" },
  { infinitif: "To sell", preterit: "I sold", participe: "sold", traduction: "vendre" },
  { infinitif: "To tell", preterit: "I told", participe: "told", traduction: "dire, raconter" },
  { infinitif: "To pay", preterit: "I paid", participe: "paid", traduction: "payer" },
  { infinitif: "To say", preterit: "I said", participe: "said", traduction: "dire" },
  { infinitif: "To find", preterit: "I found", participe: "found", traduction: "trouver" },
  { infinitif: "To stand", preterit: "I stood", participe: "stood", traduction: "être debout" },
  { infinitif: "To understand", preterit: "I understood", participe: "understood", traduction: "comprendre" },
  { infinitif: "To become", preterit: "I became", participe: "become", traduction: "devenir" },
  { infinitif: "To come", preterit: "I came", participe: "come", traduction: "venir" },
  { infinitif: "To overcome", preterit: "I overcame", participe: "overcome", traduction: "vaincre, surmonter" },
  { infinitif: "To begin", preterit: "I began", participe: "begun", traduction: "commencer" },
  { infinitif: "To drink", preterit: "I drank", participe: "drunk", traduction: "boire" },
  { infinitif: "To ring", preterit: "I rang", participe: "rung", traduction: "sonner" },
  { infinitif: "To sing", preterit: "I sang", participe: "sung", traduction: "chanter" },
  { infinitif: "To swim", preterit: "I swam", participe: "swum", traduction: "nager" },
  { infinitif: "To tear", preterit: "I tore", participe: "torn", traduction: "déchirer" },
  { infinitif: "To wear", preterit: "I wore", participe: "worn", traduction: "porter des vêtements, user" },
  { infinitif: "To blow", preterit: "I blew", participe: "blown", traduction: "souffler" },
  { infinitif: "To fly", preterit: "I flew", participe: "flown", traduction: "voler, prendre l'avion" },
  { infinitif: "To grow", preterit: "I grew", participe: "grown", traduction: "cultiver, (faire) pousser, grandir" },
  { infinitif: "To know", preterit: "I knew", participe: "known", traduction: "connaître, savoir" },
  { infinitif: "To throw", preterit: "I threw", participe: "thrown", traduction: "jeter" },
  { infinitif: "To draw", preterit: "I drew", participe: "drawn", traduction: "dessiner" },
  { infinitif: "To break", preterit: "I broke", participe: "broken", traduction: "casser" },
  { infinitif: "To choose", preterit: "I chose", participe: "chosen", traduction: "choisir" },
  { infinitif: "To drive", preterit: "I drove", participe: "driven", traduction: "conduire" },
  { infinitif: "To eat", preterit: "I ate", participe: "eaten", traduction: "manger" },
  { infinitif: "To fall", preterit: "I fell", participe: "fallen", traduction: "tomber" },
  { infinitif: "To forbid", preterit: "I forbade", participe: "forbidden", traduction: "interdire" },
  { infinitif: "To forgive", preterit: "I forgave", participe: "forgiven", traduction: "pardonner" },
  { infinitif: "To give", preterit: "I gave", participe: "given", traduction: "donner" },
  { infinitif: "To hide", preterit: "I hid", participe: "hidden", traduction: "cacher" },
  { infinitif: "To ride", preterit: "I rode", participe: "ridden", traduction: "monter (à cheval) faire du vélo…" },
  { infinitif: "To rise", preterit: "I rose", participe: "risen", traduction: "augmenter, s'élever" },
  { infinitif: "To run", preterit: "I ran", participe: "run", traduction: "courir" },
  { infinitif: "To see", preterit: "I saw", participe: "seen", traduction: "Voir" },
  { infinitif: "To speak", preterit: "I spoke", participe: "spoken", traduction: "parler" },
  { infinitif: "To steal", preterit: "I stole", participe: "stolen", traduction: "voler, dérober" },
  { infinitif: "To take", preterit: "I took", participe: "taken", traduction: "prendre" },
  { infinitif: "To wake", preterit: "I woke", participe: "woken", traduction: "se réveiller" },
  { infinitif: "To win", preterit: "I won", participe: "won", traduction: "gagner" },
  { infinitif: "To write", preterit: "I wrote", participe: "written", traduction: "écrire" }
]

// Fonction pour mélanger un tableau
function shuffleArray(array) {
  const shuffled = [...array]
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]]
  }
  return shuffled
}

// Normalisation pour la comparaison
function normalizeAnswer(str) {
  return str
    .toLowerCase()
    .trim()
    .replace(/\s+/g, ' ')
    .replace(/[']/g, "'")
}

// Vérification si une réponse est correcte
function isCorrect(userAnswer, correctAnswer) {
  const normalized = normalizeAnswer(userAnswer)
  const correct = normalizeAnswer(correctAnswer)

  // Vérification exacte
  if (normalized === correct) return true

  // Pour l'infinitif, on accepte avec ou sans "To "
  if (correct.startsWith('to ') && normalized === correct.slice(3)) return true
  if (!normalized.startsWith('to ') && `to ${normalized}` === correct) return true

  // Pour le prétérit, on accepte avec ou sans "I "
  if (correct.startsWith('i ') && normalized === correct.slice(2)) return true
  if (!normalized.startsWith('i ') && `i ${normalized}` === correct) return true

  // Accepter les alternatives (was/were)
  if (correct.includes('/')) {
    const alternatives = correct.split('/').map(a => a.trim())
    if (alternatives.some(alt => normalizeAnswer(alt) === normalized)) return true
    // Sans "I " pour les alternatives du prétérit
    if (alternatives.some(alt => normalizeAnswer(alt).replace('i ', '') === normalized)) return true
    // Sans "To " pour les alternatives de l'infinitif
    if (alternatives.some(alt => normalizeAnswer(alt).replace('to ', '') === normalized)) return true
  }

  return false
}

// Composant pour une ligne de verbe
function VerbRow({ verb, index, userAnswers, setUserAnswers, verified, showSolution, setHintsUsed, quizMode, visibleColumn }) {
  const rowStatus = useMemo(() => {
    if (!verified) return null
    const infinitifOk = visibleColumn === 'infinitif' || isCorrect(userAnswers[index]?.infinitif || '', verb.infinitif)
    const preteritOk = visibleColumn === 'preterit' || isCorrect(userAnswers[index]?.preterit || '', verb.preterit)
    const participeOk = visibleColumn === 'participe' || isCorrect(userAnswers[index]?.participe || '', verb.participe)
    const traductionOk = visibleColumn === 'traduction' || normalizeAnswer(userAnswers[index]?.traduction || '') === normalizeAnswer(verb.traduction)
    return { infinitifOk, preteritOk, participeOk, traductionOk, allCorrect: infinitifOk && preteritOk && participeOk && traductionOk }
  }, [verified, userAnswers, index, verb, visibleColumn])

  const handleChange = (field, value) => {
    setUserAnswers(prev => ({
      ...prev,
      [index]: {
        ...prev[index],
        [field]: value
      }
    }))
  }

  const getHint = (field) => {
    const answer = verb[field]
    const firstLetter = answer.replace(/^(I |To )/i, '')[0]
    setHintsUsed(prev => prev + 1)
    handleChange(field, firstLetter + '...')
  }

  const getInputClass = (field) => {
    let baseClass = "w-full px-3 py-2.5 rounded-lg border text-base font-semibold transition-all duration-200 focus:ring-2 focus:ring-primary/50 focus:border-primary"

    if (showSolution) {
      return `${baseClass} bg-emerald-200 dark:bg-emerald-800 border-emerald-500 dark:border-emerald-500 text-emerald-950 dark:text-white`
    }

    if (verified && rowStatus) {
      const isOk = rowStatus[`${field}Ok`]
      if (isOk) {
        return `${baseClass} bg-emerald-200 dark:bg-emerald-800 border-emerald-600 text-emerald-950 dark:text-white`
      } else {
        return `${baseClass} bg-red-200 dark:bg-red-800 border-red-600 text-red-950 dark:text-white`
      }
    }

    return `${baseClass} bg-background border-input text-foreground hover:border-primary/50`
  }

  return (
    <motion.tr
      initial={{ opacity: 0, x: -20 }}
      animate={{ opacity: 1, x: 0 }}
      transition={{ delay: index * 0.02 }}
      className={`group ${verified ? (rowStatus?.allCorrect ? 'bg-emerald-50/50 dark:bg-emerald-900/10' : 'bg-red-50/50 dark:bg-red-900/10') : 'hover:bg-muted/50'}`}
    >
      {/* Numéro */}
      <td className="px-2 py-3 text-center">
        <span className="inline-flex items-center justify-center w-7 h-7 rounded-full bg-primary/10 text-primary text-sm font-medium">
          {index + 1}
        </span>
      </td>

      {/* Traduction */}
      <td className="px-3 py-3">
        {visibleColumn === 'traduction' ? (
          <div className="flex items-center gap-2">
            <span className="font-semibold text-foreground text-base">{verb.traduction}</span>
            <motion.button
              whileHover={{ scale: 1.1 }}
              whileTap={{ scale: 0.9 }}
              onClick={() => {
                const utterance = new SpeechSynthesisUtterance(verb.infinitif)
                utterance.lang = 'en-US'
                speechSynthesis.speak(utterance)
              }}
              className="opacity-0 group-hover:opacity-100 p-1 rounded-full hover:bg-primary/10 text-muted-foreground hover:text-primary transition-all"
              title="Écouter la prononciation"
            >
              <Volume2 className="w-4 h-4" />
            </motion.button>
          </div>
        ) : (
          <div className="relative">
            <input
              type="text"
              value={showSolution ? verb.traduction : (userAnswers[index]?.traduction || '')}
              onChange={(e) => handleChange('traduction', e.target.value)}
              disabled={showSolution}
              placeholder="Traduction..."
              className={getInputClass('traduction')}
            />
          </div>
        )}
      </td>

      {/* Infinitif */}
      <td className="px-2 py-3">
        {visibleColumn === 'infinitif' ? (
          <span className="font-semibold text-foreground text-base px-3">{verb.infinitif}</span>
        ) : (
          <div className="relative">
            <input
              type="text"
              value={showSolution ? verb.infinitif : (userAnswers[index]?.infinitif || '')}
              onChange={(e) => handleChange('infinitif', e.target.value)}
              disabled={showSolution}
              placeholder="To..."
              className={getInputClass('infinitif')}
            />
            {!verified && !showSolution && (
              <motion.button
                whileHover={{ scale: 1.1 }}
                whileTap={{ scale: 0.9 }}
                onClick={() => getHint('infinitif')}
                className="absolute right-2 top-1/2 -translate-y-1/2 opacity-0 group-hover:opacity-100 p-1 rounded-full hover:bg-yellow-100 dark:hover:bg-yellow-900/30 text-yellow-600"
                title="Obtenir un indice"
              >
                <Lightbulb className="w-3 h-3" />
              </motion.button>
            )}
          </div>
        )}
      </td>

      {/* Prétérit */}
      <td className="px-2 py-3">
        {visibleColumn === 'preterit' ? (
          <span className="font-semibold text-foreground text-base px-3">{verb.preterit}</span>
        ) : (
          <div className="relative">
            <input
              type="text"
              value={showSolution ? verb.preterit : (userAnswers[index]?.preterit || '')}
              onChange={(e) => handleChange('preterit', e.target.value)}
              disabled={showSolution}
              placeholder="I..."
              className={getInputClass('preterit')}
            />
            {!verified && !showSolution && (
              <motion.button
                whileHover={{ scale: 1.1 }}
                whileTap={{ scale: 0.9 }}
                onClick={() => getHint('preterit')}
                className="absolute right-2 top-1/2 -translate-y-1/2 opacity-0 group-hover:opacity-100 p-1 rounded-full hover:bg-yellow-100 dark:hover:bg-yellow-900/30 text-yellow-600"
                title="Obtenir un indice"
              >
                <Lightbulb className="w-3 h-3" />
              </motion.button>
            )}
          </div>
        )}
      </td>

      {/* Participe passé */}
      <td className="px-2 py-3">
        {visibleColumn === 'participe' ? (
          <span className="font-semibold text-foreground text-base px-3">{verb.participe}</span>
        ) : (
          <div className="relative">
            <input
              type="text"
              value={showSolution ? verb.participe : (userAnswers[index]?.participe || '')}
              onChange={(e) => handleChange('participe', e.target.value)}
              disabled={showSolution}
              placeholder="..."
              className={getInputClass('participe')}
            />
            {!verified && !showSolution && (
              <motion.button
                whileHover={{ scale: 1.1 }}
                whileTap={{ scale: 0.9 }}
                onClick={() => getHint('participe')}
                className="absolute right-2 top-1/2 -translate-y-1/2 opacity-0 group-hover:opacity-100 p-1 rounded-full hover:bg-yellow-100 dark:hover:bg-yellow-900/30 text-yellow-600"
                title="Obtenir un indice"
              >
                <Lightbulb className="w-3 h-3" />
              </motion.button>
            )}
          </div>
        )}
      </td>

      {/* Statut */}
      <td className="px-2 py-3 text-center">
        <AnimatePresence mode="wait">
          {verified && rowStatus && (
            <motion.div
              initial={{ scale: 0, rotate: -180 }}
              animate={{ scale: 1, rotate: 0 }}
              exit={{ scale: 0 }}
              className="inline-flex"
            >
              {rowStatus.allCorrect ? (
                <CheckCircle className="w-6 h-6 text-emerald-500" />
              ) : (
                <XCircle className="w-6 h-6 text-red-500" />
              )}
            </motion.div>
          )}
        </AnimatePresence>
      </td>
    </motion.tr>
  )
}

export default function IrregularVerbsDemo() {
  const [verbCount, setVerbCount] = useState(20)
  const [selectedVerbs, setSelectedVerbs] = useState([])
  const [userAnswers, setUserAnswers] = useState({})
  const [verified, setVerified] = useState(false)
  const [showSolution, setShowSolution] = useState(false)
  const [hintsUsed, setHintsUsed] = useState(0)
  const [startTime, setStartTime] = useState(null)
  const [elapsedTime, setElapsedTime] = useState(0)
  const [isTimerRunning, setIsTimerRunning] = useState(false)
  const [showStats, setShowStats] = useState(false)
  const [quizMode, setQuizMode] = useState('traduction') // 'traduction' ou 'random'
  const [visibleColumns, setVisibleColumns] = useState({}) // Pour le mode random: {index: 'infinitif'|'preterit'|'participe'|'traduction'}

  // Sélectionner des verbes aléatoires au démarrage
  useEffect(() => {
    initializeQuiz()
  }, [])

  // Timer
  useEffect(() => {
    let interval
    if (isTimerRunning && startTime) {
      interval = setInterval(() => {
        setElapsedTime(Math.floor((Date.now() - startTime) / 1000))
      }, 1000)
    }
    return () => clearInterval(interval)
  }, [isTimerRunning, startTime])

  const initializeQuiz = (count = verbCount, mode = quizMode) => {
    const shuffled = shuffleArray(verbsData)
    const selected = shuffled.slice(0, count)
    setSelectedVerbs(selected)
    setUserAnswers({})
    setVerified(false)
    setShowSolution(false)
    setHintsUsed(0)
    setStartTime(Date.now())
    setIsTimerRunning(true)
    setElapsedTime(0)
    setShowStats(false)

    // Générer les colonnes visibles pour le mode random
    if (mode === 'random') {
      const columns = ['infinitif', 'preterit', 'participe', 'traduction']
      const newVisibleColumns = {}
      selected.forEach((_, index) => {
        newVisibleColumns[index] = columns[Math.floor(Math.random() * columns.length)]
      })
      setVisibleColumns(newVisibleColumns)
    } else {
      setVisibleColumns({})
    }
  }

  const handleVerify = () => {
    setVerified(true)
    setIsTimerRunning(false)
    setShowStats(true)
  }

  const handleShowSolution = () => {
    setShowSolution(true)
    setVerified(true)
    setIsTimerRunning(false)
  }

  const handleNewQuiz = () => {
    initializeQuiz(verbCount, quizMode)
  }

  const handleVerbCountChange = (count) => {
    setVerbCount(count)
    initializeQuiz(count, quizMode)
  }

  const handleModeChange = (mode) => {
    setQuizMode(mode)
    initializeQuiz(verbCount, mode)
  }

  // Calcul des statistiques
  const stats = useMemo(() => {
    if (!verified) return null

    let correct = 0
    let total = selectedVerbs.length
    let details = { infinitif: 0, preterit: 0, participe: 0, traduction: 0 }

    selectedVerbs.forEach((verb, index) => {
      const answer = userAnswers[index] || {}
      const visibleCol = quizMode === 'random' ? visibleColumns[index] : 'traduction'

      const infinitifOk = visibleCol === 'infinitif' || isCorrect(answer.infinitif || '', verb.infinitif)
      const preteritOk = visibleCol === 'preterit' || isCorrect(answer.preterit || '', verb.preterit)
      const participeOk = visibleCol === 'participe' || isCorrect(answer.participe || '', verb.participe)
      const traductionOk = visibleCol === 'traduction' || normalizeAnswer(answer.traduction || '') === normalizeAnswer(verb.traduction)

      if (visibleCol !== 'infinitif' && infinitifOk) details.infinitif++
      if (visibleCol !== 'preterit' && preteritOk) details.preterit++
      if (visibleCol !== 'participe' && participeOk) details.participe++
      if (visibleCol !== 'traduction' && traductionOk) details.traduction++

      if (infinitifOk && preteritOk && participeOk && traductionOk) correct++
    })

    return {
      correct,
      total,
      percentage: Math.round((correct / total) * 100),
      details,
      time: elapsedTime
    }
  }, [verified, selectedVerbs, userAnswers, elapsedTime, quizMode, visibleColumns])

  const formatTime = (seconds) => {
    const mins = Math.floor(seconds / 60)
    const secs = seconds % 60
    return `${mins}:${secs.toString().padStart(2, '0')}`
  }

  const getGrade = (percentage) => {
    if (percentage >= 90) return { label: 'Excellent !', emoji: '🏆', color: 'text-yellow-500' }
    if (percentage >= 75) return { label: 'Très bien !', emoji: '⭐', color: 'text-emerald-500' }
    if (percentage >= 60) return { label: 'Bien', emoji: '👍', color: 'text-blue-500' }
    if (percentage >= 40) return { label: 'Peut mieux faire', emoji: '📚', color: 'text-orange-500' }
    return { label: 'Continue à t\'entraîner !', emoji: '💪', color: 'text-red-500' }
  }

  return (
    <div className="space-y-6 pb-12">
      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        className="text-center space-y-4"
      >
        <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-gradient-to-r from-blue-500/10 via-purple-500/10 to-pink-500/10 text-sm font-medium">
          <BookOpen className="w-4 h-4 text-primary" />
          <span>Exercice interactif</span>
        </div>
        <h1 className="text-3xl font-bold tracking-tight">
          Verbes Irréguliers Anglais
        </h1>
        <p className="text-muted-foreground max-w-2xl mx-auto">
          {quizMode === 'traduction'
            ? "Complète les colonnes Infinitif, Prétérit et Participe Passé. La traduction française est donnée comme indice."
            : "Mode aléatoire : une colonne est affichée au hasard, complète les autres !"}
        </p>
      </motion.div>

      {/* Controls */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.1 }}
        className="flex flex-wrap items-center justify-between gap-4 p-4 rounded-xl bg-card border shadow-sm"
      >
        <div className="flex flex-wrap items-center gap-4">
          {/* Mode de quiz */}
          <div className="flex items-center gap-2">
            <span className="text-sm text-muted-foreground">Mode :</span>
            <div className="flex gap-1">
              <motion.button
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                onClick={() => handleModeChange('traduction')}
                className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                  quizMode === 'traduction'
                    ? 'bg-emerald-600 text-white'
                    : 'bg-secondary hover:bg-secondary/80'
                }`}
                title="Seule la traduction est affichée"
              >
                🇫🇷 Traduction
              </motion.button>
              <motion.button
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                onClick={() => handleModeChange('random')}
                className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                  quizMode === 'random'
                    ? 'bg-purple-600 text-white'
                    : 'bg-secondary hover:bg-secondary/80'
                }`}
                title="Une colonne aléatoire est affichée par ligne"
              >
                🎲 Aléatoire
              </motion.button>
            </div>
          </div>

          {/* Nombre de verbes */}
          <div className="flex items-center gap-2">
            <span className="text-sm text-muted-foreground">Verbes :</span>
            <div className="flex gap-1">
              {[10, 20, 30, 40].map((count) => (
                <motion.button
                  key={count}
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                  onClick={() => handleVerbCountChange(count)}
                  className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                    verbCount === count
                      ? 'bg-primary text-primary-foreground'
                      : 'bg-secondary hover:bg-secondary/80'
                  }`}
                >
                  {count}
                </motion.button>
              ))}
            </div>
          </div>

          {/* Timer */}
          <div className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-secondary">
            <Timer className="w-4 h-4 text-muted-foreground" />
            <span className="font-mono text-sm font-medium">{formatTime(elapsedTime)}</span>
          </div>

          {/* Indices utilisés */}
          {hintsUsed > 0 && (
            <div className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-yellow-100 dark:bg-yellow-900/30 text-yellow-700 dark:text-yellow-300">
              <Lightbulb className="w-4 h-4" />
              <span className="text-sm font-medium">{hintsUsed} indices</span>
            </div>
          )}
        </div>

        {/* Action buttons */}
        <div className="flex items-center gap-2">
          <motion.button
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            onClick={handleNewQuiz}
            className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-secondary hover:bg-secondary/80 text-sm font-medium transition-colors"
          >
            <Shuffle className="w-4 h-4" />
            Nouveau quiz
          </motion.button>

          <motion.button
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            onClick={handleShowSolution}
            disabled={showSolution}
            className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-orange-500 hover:bg-orange-600 text-white text-sm font-medium transition-colors disabled:opacity-50"
          >
            {showSolution ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
            {showSolution ? 'Solutions affichées' : 'Voir les solutions'}
          </motion.button>

          <motion.button
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            onClick={handleVerify}
            disabled={verified}
            className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-gradient-to-r from-primary to-purple-600 hover:opacity-90 text-white text-sm font-medium transition-all disabled:opacity-50"
          >
            <CheckCircle className="w-4 h-4" />
            {verified ? 'Vérifié' : 'Vérifier'}
          </motion.button>
        </div>
      </motion.div>

      {/* Stats panel */}
      <AnimatePresence>
        {showStats && stats && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            className="overflow-hidden"
          >
            <div className="p-6 rounded-xl bg-gradient-to-br from-primary/5 via-purple-500/5 to-pink-500/5 border shadow-lg">
              <div className="flex flex-col md:flex-row items-center justify-between gap-6">
                {/* Score principal */}
                <div className="text-center md:text-left">
                  <div className="flex items-center gap-3">
                    <div className={`text-5xl ${getGrade(stats.percentage).color}`}>
                      {getGrade(stats.percentage).emoji}
                    </div>
                    <div>
                      <div className="text-3xl font-bold">
                        {stats.correct} / {stats.total}
                      </div>
                      <div className={`text-lg font-medium ${getGrade(stats.percentage).color}`}>
                        {getGrade(stats.percentage).label}
                      </div>
                    </div>
                  </div>
                </div>

                {/* Barre de progression */}
                <div className="flex-1 max-w-md w-full">
                  <div className="h-4 rounded-full bg-secondary overflow-hidden">
                    <motion.div
                      initial={{ width: 0 }}
                      animate={{ width: `${stats.percentage}%` }}
                      transition={{ duration: 1, ease: "easeOut" }}
                      className={`h-full rounded-full ${
                        stats.percentage >= 75 ? 'bg-gradient-to-r from-emerald-500 to-green-500' :
                        stats.percentage >= 50 ? 'bg-gradient-to-r from-yellow-500 to-orange-500' :
                        'bg-gradient-to-r from-red-500 to-pink-500'
                      }`}
                    />
                  </div>
                  <div className="flex justify-between mt-2 text-sm text-muted-foreground">
                    <span>{stats.percentage}% de réussite</span>
                    <span>Temps : {formatTime(stats.time)}</span>
                  </div>
                </div>

                {/* Détails par colonne */}
                <div className="flex flex-wrap gap-3">
                  {quizMode === 'random' && (
                    <div className="text-center px-4 py-2 rounded-lg bg-card border">
                      <div className="text-xl font-bold text-emerald-500">{stats.details.traduction}</div>
                      <div className="text-xs text-muted-foreground">Traductions</div>
                    </div>
                  )}
                  <div className="text-center px-4 py-2 rounded-lg bg-card border">
                    <div className="text-xl font-bold text-blue-500">{stats.details.infinitif}</div>
                    <div className="text-xs text-muted-foreground">Infinitifs</div>
                  </div>
                  <div className="text-center px-4 py-2 rounded-lg bg-card border">
                    <div className="text-xl font-bold text-purple-500">{stats.details.preterit}</div>
                    <div className="text-xs text-muted-foreground">Prétérits</div>
                  </div>
                  <div className="text-center px-4 py-2 rounded-lg bg-card border">
                    <div className="text-xl font-bold text-pink-500">{stats.details.participe}</div>
                    <div className="text-xs text-muted-foreground">Participes</div>
                  </div>
                </div>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Table */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.2 }}
        className="overflow-x-auto rounded-xl border bg-card shadow-lg"
      >
        <table className="w-full">
          <thead>
            <tr className="border-b bg-muted/50">
              <th className="px-2 py-4 text-center text-xs font-medium text-muted-foreground uppercase tracking-wider w-12">
                #
              </th>
              <th className="px-3 py-4 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider">
                <div className="flex items-center gap-2">
                  <span className="w-2 h-2 rounded-full bg-emerald-500" />
                  Traduction
                </div>
              </th>
              <th className="px-2 py-4 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider">
                <div className="flex items-center gap-2">
                  <span className="w-2 h-2 rounded-full bg-blue-500" />
                  Infinitif
                </div>
              </th>
              <th className="px-2 py-4 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider">
                <div className="flex items-center gap-2">
                  <span className="w-2 h-2 rounded-full bg-purple-500" />
                  Prétérit
                </div>
              </th>
              <th className="px-2 py-4 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider">
                <div className="flex items-center gap-2">
                  <span className="w-2 h-2 rounded-full bg-pink-500" />
                  Participe Passé
                </div>
              </th>
              <th className="px-2 py-4 text-center text-xs font-medium text-muted-foreground uppercase tracking-wider w-16">
                Statut
              </th>
            </tr>
          </thead>
          <tbody className="divide-y">
            {selectedVerbs.map((verb, index) => (
              <VerbRow
                key={`${verb.infinitif}-${index}`}
                verb={verb}
                index={index}
                userAnswers={userAnswers}
                setUserAnswers={setUserAnswers}
                verified={verified}
                showSolution={showSolution}
                setHintsUsed={setHintsUsed}
                quizMode={quizMode}
                visibleColumn={quizMode === 'random' ? visibleColumns[index] : 'traduction'}
              />
            ))}
          </tbody>
        </table>
      </motion.div>

      {/* Tips Section */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.3 }}
        className="p-4 rounded-xl bg-gradient-to-r from-blue-500/10 to-purple-500/10 border"
      >
        <div className="flex items-start gap-3">
          <div className="p-2 rounded-lg bg-primary/10">
            <Sparkles className="w-5 h-5 text-primary" />
          </div>
          <div className="space-y-1">
            <h3 className="font-medium">Astuces</h3>
            <ul className="text-sm text-muted-foreground space-y-1">
              <li>• <strong>Mode Traduction 🇫🇷</strong> : seule la traduction est affichée, trouve les 3 formes anglaises</li>
              <li>• <strong>Mode Aléatoire 🎲</strong> : une colonne au hasard est affichée par ligne (peut être la traduction !)</li>
              <li>• Survole une ligne pour afficher l'icône d'indice 💡 et écouter la prononciation 🔊</li>
              <li>• L'infinitif commence par "To" et le prétérit par "I" (acceptés avec ou sans)</li>
              <li>• Tu peux changer le nombre de verbes et le mode à tout moment</li>
            </ul>
          </div>
        </div>
      </motion.div>
    </div>
  )
}

