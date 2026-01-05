// Script pour générer un hash de mot de passe
const bcrypt = require('bcryptjs')

const password = process.argv[2] || 'admin123'
const saltRounds = 10

bcrypt.hash(password, saltRounds, (err, hash) => {
  if (err) {
    console.error('Error:', err)
    return
  }
  console.log('Password:', password)
  console.log('Hash:', hash)
})
