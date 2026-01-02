import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  Sparkles, Zap, Shield, Globe, ArrowRight, Play, Star,
  CheckCircle2, ChevronRight, Rocket, Heart, Users, Award
} from 'lucide-react'

const features = [
  {
    icon: Zap,
    title: 'Ultra Rapide',
    description: 'Performance optimisée pour une expérience utilisateur fluide et instantanée.',
    color: 'from-yellow-400 to-orange-500'
  },
  {
    icon: Shield,
    title: 'Sécurisé',
    description: 'Protection de niveau entreprise avec chiffrement de bout en bout.',
    color: 'from-green-400 to-emerald-600'
  },
  {
    icon: Globe,
    title: 'Global',
    description: 'Disponible partout dans le monde avec une latence minimale.',
    color: 'from-blue-400 to-indigo-600'
  },
  {
    icon: Sparkles,
    title: 'Innovant',
    description: 'Technologies de pointe et mises à jour régulières avec les dernières fonctionnalités.',
    color: 'from-purple-400 to-pink-600'
  },
]

const testimonials = [
  {
    name: 'Sophie Martin',
    role: 'CEO, TechStart',
    content: 'Cette solution a révolutionné notre façon de travailler. L\'interface est incroyablement intuitive.',
    avatar: 'SM',
    rating: 5
  },
  {
    name: 'Thomas Dubois',
    role: 'CTO, InnovateCorp',
    content: 'La meilleure décision que nous ayons prise cette année. Performance et fiabilité au rendez-vous.',
    avatar: 'TD',
    rating: 5
  },
  {
    name: 'Léa Bernard',
    role: 'Product Manager',
    content: 'Un outil indispensable pour notre équipe. Le support client est exceptionnel.',
    avatar: 'LB',
    rating: 5
  },
]

const pricingPlans = [
  {
    name: 'Starter',
    price: '0',
    description: 'Parfait pour démarrer',
    features: ['5 projets', '10 Go stockage', 'Support email', 'API basique'],
    cta: 'Commencer gratuitement',
    popular: false
  },
  {
    name: 'Pro',
    price: '29',
    description: 'Pour les équipes en croissance',
    features: ['Projets illimités', '100 Go stockage', 'Support prioritaire', 'API avancée', 'Analytics', 'Intégrations'],
    cta: 'Essai gratuit 14 jours',
    popular: true
  },
  {
    name: 'Enterprise',
    price: '99',
    description: 'Pour les grandes organisations',
    features: ['Tout de Pro', '1 To stockage', 'Support 24/7', 'SSO/SAML', 'Audit logs', 'SLA garanti'],
    cta: 'Contacter les ventes',
    popular: false
  },
]

function FloatingParticle({ delay }) {
  return (
    <motion.div
      className="absolute w-2 h-2 rounded-full bg-primary/30"
      initial={{ y: 0, opacity: 0 }}
      animate={{
        y: [-20, 20, -20],
        opacity: [0, 1, 0],
        scale: [0.5, 1, 0.5]
      }}
      transition={{
        duration: 4,
        delay,
        repeat: Infinity,
        ease: "easeInOut"
      }}
      style={{
        left: `${Math.random() * 100}%`,
        top: `${Math.random() * 100}%`,
      }}
    />
  )
}

export default function LandingDemo() {
  const [hoveredFeature, setHoveredFeature] = useState(null)
  const [selectedPlan, setSelectedPlan] = useState('Pro')

  return (
    <div className="space-y-24 pb-12">
      {/* Hero Section */}
      <section className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-primary/10 via-purple-500/10 to-pink-500/10 p-8 md:p-16">
        {/* Animated background */}
        <div className="absolute inset-0 overflow-hidden">
          {[...Array(20)].map((_, i) => (
            <FloatingParticle key={i} delay={i * 0.2} />
          ))}
        </div>

        <div className="relative z-10 max-w-4xl mx-auto text-center space-y-8">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-primary/10 border border-primary/20 text-sm font-medium"
          >
            <Sparkles className="w-4 h-4 text-primary" />
            Nouveau : Découvrez la v2.0
            <ChevronRight className="w-4 h-4" />
          </motion.div>

          <motion.h1
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="text-4xl md:text-6xl lg:text-7xl font-bold tracking-tight"
          >
            Créez des expériences{' '}
            <span className="bg-gradient-to-r from-primary via-purple-500 to-pink-500 bg-clip-text text-transparent">
              extraordinaires
            </span>
          </motion.h1>

          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
            className="text-xl text-muted-foreground max-w-2xl mx-auto"
          >
            La plateforme tout-en-un pour concevoir, développer et déployer
            vos applications avec une simplicité déconcertante.
          </motion.p>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3 }}
            className="flex flex-col sm:flex-row gap-4 justify-center"
          >
            <motion.button
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              className="px-8 py-4 rounded-xl bg-gradient-to-r from-primary to-purple-600 text-white font-semibold shadow-lg shadow-primary/25 flex items-center justify-center gap-2"
            >
              <Rocket className="w-5 h-5" />
              Démarrer maintenant
            </motion.button>
            <motion.button
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              className="px-8 py-4 rounded-xl border-2 font-semibold flex items-center justify-center gap-2 hover:bg-muted transition-colors"
            >
              <Play className="w-5 h-5" />
              Voir la démo
            </motion.button>
          </motion.div>

          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.5 }}
            className="flex items-center justify-center gap-8 pt-8 text-sm text-muted-foreground"
          >
            <div className="flex items-center gap-2">
              <Users className="w-4 h-4" />
              <span>10k+ utilisateurs</span>
            </div>
            <div className="flex items-center gap-2">
              <Star className="w-4 h-4 fill-yellow-400 text-yellow-400" />
              <span>4.9/5 étoiles</span>
            </div>
            <div className="flex items-center gap-2">
              <Award className="w-4 h-4" />
              <span>Top Product 2024</span>
            </div>
          </motion.div>
        </div>
      </section>

      {/* Features Section */}
      <section className="space-y-12">
        <div className="text-center space-y-4">
          <motion.h2
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            viewport={{ once: true }}
            className="text-3xl md:text-4xl font-bold"
          >
            Tout ce dont vous avez besoin
          </motion.h2>
          <p className="text-muted-foreground max-w-2xl mx-auto">
            Des fonctionnalités puissantes pour propulser votre productivité
          </p>
        </div>

        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
          {features.map((feature, index) => {
            const Icon = feature.icon
            return (
              <motion.div
                key={feature.title}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: index * 0.1 }}
                onMouseEnter={() => setHoveredFeature(index)}
                onMouseLeave={() => setHoveredFeature(null)}
                className="relative group p-6 rounded-2xl bg-card border hover:shadow-xl transition-all duration-300 cursor-pointer overflow-hidden"
              >
                <motion.div
                  animate={{
                    scale: hoveredFeature === index ? 1.1 : 1,
                    rotate: hoveredFeature === index ? 5 : 0
                  }}
                  className={`w-12 h-12 rounded-xl bg-gradient-to-br ${feature.color} flex items-center justify-center mb-4`}
                >
                  <Icon className="w-6 h-6 text-white" />
                </motion.div>
                <h3 className="text-lg font-semibold mb-2">{feature.title}</h3>
                <p className="text-sm text-muted-foreground">{feature.description}</p>

                <motion.div
                  className={`absolute -bottom-2 -right-2 w-24 h-24 rounded-full bg-gradient-to-br ${feature.color} opacity-0 group-hover:opacity-10 blur-2xl transition-opacity`}
                />
              </motion.div>
            )
          })}
        </div>
      </section>

      {/* Testimonials */}
      <section className="space-y-12">
        <div className="text-center space-y-4">
          <motion.h2
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            viewport={{ once: true }}
            className="text-3xl md:text-4xl font-bold"
          >
            Ce que nos clients disent
          </motion.h2>
          <p className="text-muted-foreground">
            Rejoignez des milliers d'utilisateurs satisfaits
          </p>
        </div>

        <div className="grid md:grid-cols-3 gap-6">
          {testimonials.map((testimonial, index) => (
            <motion.div
              key={testimonial.name}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: index * 0.1 }}
              whileHover={{ y: -5 }}
              className="p-6 rounded-2xl bg-card border shadow-lg"
            >
              <div className="flex items-center gap-1 mb-4">
                {[...Array(testimonial.rating)].map((_, i) => (
                  <Star key={i} className="w-4 h-4 fill-yellow-400 text-yellow-400" />
                ))}
              </div>
              <p className="text-muted-foreground mb-6">"{testimonial.content}"</p>
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-gradient-to-br from-primary to-purple-600 flex items-center justify-center text-white text-sm font-medium">
                  {testimonial.avatar}
                </div>
                <div>
                  <p className="font-semibold">{testimonial.name}</p>
                  <p className="text-sm text-muted-foreground">{testimonial.role}</p>
                </div>
              </div>
            </motion.div>
          ))}
        </div>
      </section>

      {/* Pricing Section */}
      <section className="space-y-12">
        <div className="text-center space-y-4">
          <motion.h2
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            viewport={{ once: true }}
            className="text-3xl md:text-4xl font-bold"
          >
            Tarifs simples et transparents
          </motion.h2>
          <p className="text-muted-foreground">
            Choisissez le plan qui correspond à vos besoins
          </p>
        </div>

        <div className="grid md:grid-cols-3 gap-6 max-w-5xl mx-auto">
          {pricingPlans.map((plan, index) => (
            <motion.div
              key={plan.name}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: index * 0.1 }}
              whileHover={{ y: -5 }}
              className={`relative p-6 rounded-2xl border ${
                plan.popular 
                  ? 'bg-gradient-to-b from-primary/5 to-transparent border-primary shadow-xl shadow-primary/10' 
                  : 'bg-card'
              }`}
            >
              {plan.popular && (
                <div className="absolute -top-3 left-1/2 -translate-x-1/2 px-3 py-1 rounded-full bg-primary text-primary-foreground text-xs font-semibold">
                  Plus populaire
                </div>
              )}

              <div className="text-center mb-6">
                <h3 className="text-xl font-semibold mb-2">{plan.name}</h3>
                <p className="text-sm text-muted-foreground mb-4">{plan.description}</p>
                <div className="flex items-baseline justify-center gap-1">
                  <span className="text-4xl font-bold">€{plan.price}</span>
                  <span className="text-muted-foreground">/mois</span>
                </div>
              </div>

              <ul className="space-y-3 mb-6">
                {plan.features.map((feature) => (
                  <li key={feature} className="flex items-center gap-2 text-sm">
                    <CheckCircle2 className="w-4 h-4 text-primary flex-shrink-0" />
                    {feature}
                  </li>
                ))}
              </ul>

              <motion.button
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                className={`w-full py-3 rounded-xl font-semibold transition-colors ${
                  plan.popular
                    ? 'bg-primary text-primary-foreground hover:bg-primary/90'
                    : 'border hover:bg-muted'
                }`}
              >
                {plan.cta}
              </motion.button>
            </motion.div>
          ))}
        </div>
      </section>

      {/* CTA Section */}
      <motion.section
        initial={{ opacity: 0, scale: 0.95 }}
        whileInView={{ opacity: 1, scale: 1 }}
        viewport={{ once: true }}
        className="relative overflow-hidden rounded-3xl bg-gradient-to-r from-primary via-purple-600 to-pink-600 p-12 text-center text-white"
      >
        <div className="absolute inset-0 bg-[url('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNjAiIGhlaWdodD0iNjAiIHZpZXdCb3g9IjAgMCA2MCA2MCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48ZyBmaWxsPSJub25lIiBmaWxsLXJ1bGU9ImV2ZW5vZGQiPjxnIGZpbGw9IiNmZmZmZmYiIGZpbGwtb3BhY2l0eT0iMC4xIj48Y2lyY2xlIGN4PSIzMCIgY3k9IjMwIiByPSIyIi8+PC9nPjwvZz48L3N2Zz4=')] opacity-30" />

        <div className="relative z-10 max-w-2xl mx-auto space-y-6">
          <h2 className="text-3xl md:text-4xl font-bold">
            Prêt à transformer votre workflow ?
          </h2>
          <p className="text-white/80 text-lg">
            Rejoignez des milliers d'équipes qui utilisent déjà notre plateforme.
            Commencez gratuitement, sans carte de crédit.
          </p>
          <motion.button
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            className="px-8 py-4 rounded-xl bg-white text-primary font-semibold shadow-lg flex items-center gap-2 mx-auto"
          >
            Commencer maintenant
            <ArrowRight className="w-5 h-5" />
          </motion.button>
        </div>
      </motion.section>
    </div>
  )
}

