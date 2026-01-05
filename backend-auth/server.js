const express = require('express')
const cors = require('cors')
const bcrypt = require('bcryptjs')
const jwt = require('jsonwebtoken')
const fs = require('fs')
const path = require('path')

const app = express()
const PORT = process.env.PORT || 3001

// Secret pour JWT (à stocker dans Kubernetes Secret en production)
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production'

// Configuration CORS
app.use(cors())
app.use(express.json())

// Fonction pour charger les utilisateurs depuis les secrets Kubernetes
function loadUsers() {
  const usersPath = process.env.USERS_FILE || '/app/secrets/users.json'
  
  try {
    if (fs.existsSync(usersPath)) {
      const data = fs.readFileSync(usersPath, 'utf8')
      return JSON.parse(data)
    }
  } catch (error) {
    console.error('Error loading users:', error)
  }

  // Utilisateurs par défaut pour le développement
  return [
    {
      email: 'admin@toolsapps.eu',
      // Mot de passe hashé pour 'admin123' (à changer en production)
      passwordHash: '$2a$10$YourHashedPasswordHere',
      name: 'Admin',
      role: 'admin'
    }
  ]
}

// Route de santé
app.get('/frontend-auth/health', (req, res) => {
  res.json({ status: 'ok', service: 'auth-api' })
})

// Route de login
app.post('/frontend-auth/login', async (req, res) => {
  try {
    const { email, password } = req.body

    if (!email || !password) {
      return res.status(400).json({ 
        message: 'Email et mot de passe requis' 
      })
    }

    // Charger les utilisateurs
    const users = loadUsers()

    // Trouver l'utilisateur
    const user = users.find(u => u.email.toLowerCase() === email.toLowerCase())

    if (!user) {
      return res.status(401).json({ 
        message: 'Email ou mot de passe incorrect' 
      })
    }

    // Vérifier le mot de passe
    const isPasswordValid = await bcrypt.compare(password, user.passwordHash)

    if (!isPasswordValid) {
      return res.status(401).json({ 
        message: 'Email ou mot de passe incorrect' 
      })
    }

    // Générer le token JWT
    const token = jwt.sign(
      { 
        email: user.email, 
        name: user.name,
        role: user.role 
      },
      JWT_SECRET,
      { expiresIn: '24h' }
    )

    // Retourner les informations utilisateur (sans le hash du mot de passe)
    res.json({
      success: true,
      user: {
        email: user.email,
        name: user.name,
        role: user.role
      },
      token
    })

  } catch (error) {
    console.error('Login error:', error)
    res.status(500).json({ 
      message: 'Erreur serveur lors de la connexion' 
    })
  }
})

// Route de vérification du token
app.get('/api/auth/verify', (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '')

    if (!token) {
      return res.status(401).json({ message: 'Token manquant' })
    }

    const decoded = jwt.verify(token, JWT_SECRET)
    res.json({ valid: true, user: decoded })

  } catch (error) {
    res.status(401).json({ valid: false, message: 'Token invalide' })
  }
})

// Démarrer le serveur
app.listen(PORT, () => {
  console.log(`🚀 Auth API server running on port ${PORT}`)
  console.log(`📍 Health check: http://localhost:${PORT}/frontend-auth/health`)
  console.log(`🔐 Login endpoint: http://localhost:${PORT}/frontend-auth/login`)
})
