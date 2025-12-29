import React from 'react'
import ReactDOM from 'react-dom/client'

function MinimalApp() {
  return (
    <div style={{ padding: '2rem', fontFamily: 'Arial, sans-serif' }}>
      <h1>Test Minimal - Pas de rafraîchissement</h1>
      <p>Si cette page se rafraîchit en boucle, le problème vient de Vite ou du navigateur.</p>
      <p>Temps: {new Date().toLocaleTimeString()}</p>
    </div>
  )
}

ReactDOM.createRoot(document.getElementById('root')).render(<MinimalApp />)

