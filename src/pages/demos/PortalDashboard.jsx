import { useState, useEffect, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  DoorOpen, DoorClosed, Wifi, WifiOff, AlertCircle, CheckCircle2,
  Clock, Activity, Signal, Zap, XCircle, Cpu, HardDrive, MemoryStick, Info,
  ChevronDown, ChevronUp
} from 'lucide-react'

// Configuration du backend SSE
const SSE_CONFIG = {
  // En développement local
  url: import.meta.env.VITE_MQTT_SSE_URL || 'http://localhost:3003/api/portal/events',
  // En production : 'https://votre-domaine.com/api/portal/events'
}

const TOPICS = {
  LED: 'portal/main/led',
  HEARTBEAT: 'portal/main/heartbeat',
  ALERT: 'portal/main/alert',
  SYSTEM_REPORT: 'portal/main/system_report',
}

function getSignalQuality(rssi) {
  if (rssi >= -50) return { label: 'Excellent', color: 'text-emerald-500', bars: 5 }
  if (rssi >= -60) return { label: 'Très bon', color: 'text-green-500', bars: 4 }
  if (rssi >= -70) return { label: 'Bon', color: 'text-blue-500', bars: 3 }
  if (rssi >= -80) return { label: 'Correct', color: 'text-yellow-500', bars: 2 }
  if (rssi >= -90) return { label: 'Faible', color: 'text-orange-500', bars: 1 }
  return { label: 'Très faible', color: 'text-red-500', bars: 1 }
}

function formatUptime(ms) {
  const seconds = Math.floor(ms / 1000)
  const days = Math.floor(seconds / 86400)
  const hours = Math.floor((seconds % 86400) / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)
  
  if (days > 0) return `${days}j ${hours}h`
  if (hours > 0) return `${hours}h ${minutes}m`
  return `${minutes}m`
}

function SignalBars({ bars, color }) {
  return (
    <div className="flex items-end gap-0.5 h-5">
      {[1, 2, 3, 4, 5].map((bar) => (
        <motion.div
          key={bar}
          initial={{ height: 0 }}
          animate={{ height: bar <= bars ? `${bar * 20}%` : '20%' }}
          className={`w-1 rounded-sm ${bar <= bars ? color.replace('text-', 'bg-') : 'bg-muted'}`}
        />
      ))}
    </div>
  )
}

export default function PortalDashboard() {
  const [portalState, setPortalState] = useState({
    state: 'UNKNOWN',
    color: 'gray',
    timestamp: null,
  })
  const [heartbeat, setHeartbeat] = useState({
    timestamp: null,
    uptime_ms: 0,
    ip: null,
    rssi: null,
    isAlive: false,
  })
  const [alert, setAlert] = useState({
    active: false,
    timestamp: null,
  })
  const [systemReport, setSystemReport] = useState(null)
  const [connectionStatus, setConnectionStatus] = useState('connecting')
  const [messagesByTopic, setMessagesByTopic] = useState({})
  const [openAccordions, setOpenAccordions] = useState({})
  
  const eventSourceRef = useRef(null)
  const heartbeatTimeoutRef = useRef(null)

  useEffect(() => {
    console.log('🔌 Connexion au backend SSE...')
    
    // Créer la connexion SSE
    const eventSource = new EventSource(SSE_CONFIG.url)
    eventSourceRef.current = eventSource

    eventSource.onopen = () => {
      console.log('✅ Connecté au backend SSE')
      setConnectionStatus('connected')
    }

    eventSource.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data)
        const { topic, payload, receivedAt } = data
        const timestamp = new Date(receivedAt)

        console.log('📨 Message SSE reçu:', topic)

        // Ajouter au log des messages groupés par topic
        setMessagesByTopic(prev => {
          const topicMessages = prev[topic] || []
          return {
            ...prev,
            [topic]: [{
              payload,
              receivedAt: timestamp
            }, ...topicMessages].slice(0, 10) // Garder les 10 derniers par topic
          }
        })

        // Traiter selon le topic
        switch (topic) {
          case TOPICS.LED:
            setPortalState({
              state: payload.state,
              color: payload.color,
              timestamp: new Date(payload.timestamp),
            })
            break

          case TOPICS.HEARTBEAT:
            setHeartbeat({
              timestamp: new Date(payload.timestamp),
              uptime_ms: payload.uptime_ms,
              ip: payload.ip,
              rssi: payload.rssi,
              isAlive: true,
            })
            
            // Réinitialiser le timeout de heartbeat
            if (heartbeatTimeoutRef.current) {
              clearTimeout(heartbeatTimeoutRef.current)
            }
            heartbeatTimeoutRef.current = setTimeout(() => {
              setHeartbeat(prev => ({ ...prev, isAlive: false }))
            }, 60000) // 60s sans heartbeat = offline
            break

          case TOPICS.ALERT:
            setAlert({
              active: payload.active,
              timestamp: new Date(payload.timestamp),
            })
            break

          case TOPICS.SYSTEM_REPORT:
            setSystemReport({
              ...payload,
              timestamp: new Date(payload.timestamp),
            })
            break
        }
      } catch (err) {
        console.error('❌ Erreur parsing message SSE:', err)
      }
    }

    eventSource.onerror = (err) => {
      console.error('❌ Erreur SSE:', err)
      setConnectionStatus('error')
      
      // EventSource reconnecte automatiquement, mais on peut améliorer ça
      if (eventSource.readyState === EventSource.CLOSED) {
        setConnectionStatus('offline')
      } else {
        setConnectionStatus('reconnecting')
      }
    }

    return () => {
      console.log('🔌 Fermeture connexion SSE')
      if (heartbeatTimeoutRef.current) {
        clearTimeout(heartbeatTimeoutRef.current)
      }
      eventSource.close()
    }
  }, [])

  const signalQuality = heartbeat.rssi ? getSignalQuality(heartbeat.rssi) : null

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Portail Principal</h1>
          <p className="text-muted-foreground">Surveillance en temps réel via SSE</p>
        </div>
        
        {/* Connection Status */}
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          className="flex items-center gap-2"
        >
          {connectionStatus === 'connected' ? (
            <>
              <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
              <span className="text-sm text-muted-foreground">Connecté</span>
            </>
          ) : connectionStatus === 'connecting' ? (
            <>
              <div className="w-2 h-2 rounded-full bg-yellow-500 animate-pulse" />
              <span className="text-sm text-muted-foreground">Connexion...</span>
            </>
          ) : (
            <>
              <div className="w-2 h-2 rounded-full bg-red-500" />
              <span className="text-sm text-muted-foreground">Déconnecté</span>
            </>
          )}
        </motion.div>
      </div>

      {/* Main Status Card */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="relative overflow-hidden rounded-2xl bg-card border shadow-xl"
      >
        <div className="p-8">
          <div className="flex items-center justify-between mb-6">
            <div className="flex items-center gap-4">
              <motion.div
                animate={{
                  scale: portalState.state === 'OPEN' ? [1, 1.1, 1] : 1,
                }}
                transition={{ repeat: portalState.state === 'OPEN' ? Infinity : 0, duration: 2 }}
                className={`w-20 h-20 rounded-2xl flex items-center justify-center shadow-lg ${
                  portalState.state === 'OPEN' 
                    ? 'bg-gradient-to-br from-red-500 to-orange-600' 
                    : portalState.state === 'CLOSED'
                    ? 'bg-gradient-to-br from-green-500 to-emerald-600'
                    : 'bg-gradient-to-br from-gray-400 to-gray-600'
                }`}
              >
                {portalState.state === 'OPEN' ? (
                  <DoorOpen className="w-10 h-10 text-white" />
                ) : portalState.state === 'CLOSED' ? (
                  <DoorClosed className="w-10 h-10 text-white" />
                ) : (
                  <DoorClosed className="w-10 h-10 text-white opacity-50" />
                )}
              </motion.div>

              <div>
                <h2 className="text-4xl font-bold">
                  {portalState.state === 'OPEN' ? 'OUVERT' : 
                   portalState.state === 'CLOSED' ? 'FERMÉ' : 
                   'EN ATTENTE'}
                </h2>
                {portalState.timestamp && (
                  <p className="text-muted-foreground">
                    {portalState.timestamp.toLocaleString('fr-FR')}
                  </p>
                )}
              </div>
            </div>

            {/* Alert Badge */}
            <AnimatePresence>
              {alert.active && (
                <motion.div
                  initial={{ opacity: 0, x: 20 }}
                  animate={{ opacity: 1, x: 0 }}
                  exit={{ opacity: 0, x: 20 }}
                  className="flex items-center gap-2 px-4 py-2 rounded-full bg-red-500/10 border border-red-500"
                >
                  <AlertCircle className="w-5 h-5 text-red-500 animate-pulse" />
                  <span className="text-red-500 font-semibold">Alerte active</span>
                </motion.div>
              )}
            </AnimatePresence>
          </div>

          {/* Background gradient */}
          <div className={`absolute inset-0 opacity-10 bg-gradient-to-br ${
            portalState.state === 'OPEN' 
              ? 'from-red-500 to-orange-600' 
              : 'from-green-500 to-emerald-600'
          }`} />
        </div>
      </motion.div>

      {/* Stats Grid */}
      <div className="grid md:grid-cols-3 gap-4">
        {/* Heartbeat Status */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="rounded-xl bg-card border p-6"
        >
          <div className="flex items-center gap-3 mb-4">
            {heartbeat.isAlive ? (
              <Activity className="w-6 h-6 text-green-500" />
            ) : (
              <XCircle className="w-6 h-6 text-red-500" />
            )}
            <h3 className="font-semibold">État du capteur</h3>
          </div>
          
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-sm text-muted-foreground">Statut</span>
              <span className={`text-sm font-medium ${heartbeat.isAlive ? 'text-green-500' : 'text-red-500'}`}>
                {heartbeat.isAlive ? 'En ligne' : 'Hors ligne'}
              </span>
            </div>
            
            {heartbeat.timestamp && (
              <div className="flex items-center justify-between">
                <span className="text-sm text-muted-foreground">Dernière MAJ</span>
                <span className="text-sm font-medium">
                  {heartbeat.timestamp.toLocaleString('fr-FR')}
                </span>
              </div>
            )}
            
            {heartbeat.uptime_ms > 0 && (
              <div className="flex items-center justify-between">
                <span className="text-sm text-muted-foreground">Uptime</span>
                <span className="text-sm font-medium flex items-center gap-1">
                  <Clock className="w-3 h-3" />
                  {formatUptime(heartbeat.uptime_ms)}
                </span>
              </div>
            )}
            
            {heartbeat.ip && (
              <div className="flex items-center justify-between">
                <span className="text-sm text-muted-foreground">IP</span>
                <span className="text-sm font-mono">{heartbeat.ip}</span>
              </div>
            )}
          </div>
        </motion.div>

        {/* Signal Quality */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="rounded-xl bg-card border p-6"
        >
          <div className="flex items-center gap-3 mb-4">
            {heartbeat.isAlive ? (
              <Wifi className={`w-6 h-6 ${signalQuality?.color || 'text-gray-500'}`} />
            ) : (
              <WifiOff className="w-6 h-6 text-muted-foreground" />
            )}
            <h3 className="font-semibold">Signal WiFi</h3>
          </div>

          {signalQuality ? (
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <SignalBars bars={signalQuality.bars} color={signalQuality.color} />
                <span className={`text-2xl font-bold ${signalQuality.color}`}>
                  {heartbeat.rssi} dBm
                </span>
              </div>
              
              <div className="flex items-center justify-between">
                <span className="text-sm text-muted-foreground">Qualité</span>
                <span className={`text-sm font-semibold ${signalQuality.color}`}>
                  {signalQuality.label}
                </span>
              </div>

              {/* Signal bar */}
              <div className="w-full h-2 bg-muted rounded-full overflow-hidden">
                <motion.div
                  initial={{ width: 0 }}
                  animate={{ width: `${(signalQuality.bars / 5) * 100}%` }}
                  className={`h-full ${signalQuality.color.replace('text-', 'bg-')}`}
                />
              </div>
            </div>
          ) : (
            <p className="text-sm text-muted-foreground">En attente de données...</p>
          )}
        </motion.div>

        {/* Alert Status */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className={`rounded-xl border p-6 ${
            alert.active 
              ? 'bg-red-500/10 border-red-500' 
              : 'bg-card'
          }`}
        >
          <div className="flex items-center gap-3 mb-4">
            {alert.active ? (
              <AlertCircle className="w-6 h-6 text-red-500" />
            ) : (
              <CheckCircle2 className="w-6 h-6 text-green-500" />
            )}
            <h3 className="font-semibold">Alertes</h3>
          </div>

          <div className="space-y-3">
            {alert.active ? (
              <>
                <p className="text-red-500 font-semibold">
                  ⚠️ Portail resté ouvert
                </p>
                {alert.timestamp && (
                  <p className="text-sm text-muted-foreground">
                    Depuis {alert.timestamp.toLocaleString('fr-FR')}
                  </p>
                )}
              </>
            ) : (
              <p className="text-green-500 font-semibold">
                ✓ Aucune alerte active
              </p>
            )}
          </div>
        </motion.div>
      </div>

      {/* System Report */}
      {systemReport && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
          className="rounded-xl bg-card border p-6"
        >
          <div className="flex items-center gap-2 mb-6">
            <Info className="w-5 h-5" />
            <h3 className="font-semibold">Rapport Système</h3>
            <span className="text-xs text-muted-foreground">
              {systemReport.timestamp.toLocaleString('fr-FR')}
            </span>
          </div>

          <div className="grid md:grid-cols-3 gap-6">
            {/* Network Info */}
            <div className="space-y-3">
              <div className="flex items-center gap-2 mb-3">
                <Wifi className="w-4 h-4 text-blue-500" />
                <h4 className="font-medium text-sm">Réseau</h4>
              </div>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <span className="text-muted-foreground">SSID</span>
                  <span className="font-mono font-medium">{systemReport.network.ssid}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">IP</span>
                  <span className="font-mono">{systemReport.network.ip}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">MAC</span>
                  <span className="font-mono text-xs">{systemReport.network.mac}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">RSSI</span>
                  <span className={getSignalQuality(systemReport.network.rssi).color}>
                    {systemReport.network.rssi} dBm
                  </span>
                </div>
              </div>
            </div>

            {/* System Info */}
            <div className="space-y-3">
              <div className="flex items-center gap-2 mb-3">
                <Cpu className="w-4 h-4 text-purple-500" />
                <h4 className="font-medium text-sm">Système</h4>
              </div>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Modèle</span>
                  <span className="font-mono text-xs">{systemReport.system.chip_model}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">CPU</span>
                  <span className="font-medium">{systemReport.system.cpu_freq_mhz} MHz</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Révision</span>
                  <span>{systemReport.system.chip_revision}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Uptime</span>
                  <span className="font-medium">{systemReport.uptime_days.toFixed(1)} jours</span>
                </div>
              </div>
            </div>

            {/* Memory Info */}
            <div className="space-y-3">
              <div className="flex items-center gap-2 mb-3">
                <MemoryStick className="w-4 h-4 text-green-500" />
                <h4 className="font-medium text-sm">Mémoire</h4>
              </div>
              <div className="space-y-2 text-sm">
                <div className="space-y-1">
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Heap libre</span>
                    <span className="font-medium">{(systemReport.system.free_heap / 1024).toFixed(1)} KB</span>
                  </div>
                  <div className="w-full h-1.5 bg-muted rounded-full overflow-hidden">
                    <div 
                      className="h-full bg-green-500"
                      style={{ width: `${(systemReport.system.free_heap / systemReport.system.heap_size) * 100}%` }}
                    />
                  </div>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Heap total</span>
                  <span>{(systemReport.system.heap_size / 1024).toFixed(1)} KB</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Flash libre</span>
                  <span>{(systemReport.system.free_sketch_space / 1024).toFixed(0)} KB</span>
                </div>
              </div>
            </div>
          </div>

          {/* MQTT Status */}
          <div className="mt-6 pt-6 border-t">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <div className={`w-2 h-2 rounded-full ${systemReport.mqtt.connected ? 'bg-green-500' : 'bg-red-500'}`} />
                <span className="text-sm font-medium">MQTT Broker</span>
              </div>
              <span className="text-xs font-mono text-muted-foreground">
                {systemReport.mqtt.broker}:{systemReport.mqtt.port}
              </span>
            </div>
          </div>
        </motion.div>
      )}

      {/* Message Log with Accordions */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.5 }}
        className="rounded-xl bg-card border p-6"
      >
        <div className="flex items-center gap-2 mb-4">
          <Zap className="w-5 h-5" />
          <h3 className="font-semibold">Événements récents</h3>
          <span className="text-xs text-muted-foreground">
            ({Object.values(messagesByTopic).reduce((sum, msgs) => sum + msgs.length, 0)} messages)
          </span>
        </div>

        <div className="space-y-3">
          {Object.entries(messagesByTopic).map(([topic, messages]) => {
            const isOpen = openAccordions[topic]
            const topicName = topic.split('/').pop()
            const topicColor = 
              topic === TOPICS.LED ? 'text-green-500' :
              topic === TOPICS.HEARTBEAT ? 'text-blue-500' :
              topic === TOPICS.ALERT ? 'text-red-500' :
              topic === TOPICS.SYSTEM_REPORT ? 'text-purple-500' :
              'text-primary'

            return (
              <div key={topic} className="border rounded-lg overflow-hidden">
                {/* Accordion Header */}
                <button
                  onClick={() => setOpenAccordions(prev => ({
                    ...prev,
                    [topic]: !prev[topic]
                  }))}
                  className="w-full flex items-center justify-between p-4 bg-muted/30 hover:bg-muted/50 transition-colors"
                >
                  <div className="flex items-center gap-3">
                    <div className={`w-2 h-2 rounded-full ${topicColor.replace('text-', 'bg-')}`} />
                    <span className={`font-mono text-sm font-semibold ${topicColor}`}>
                      {topicName}
                    </span>
                    <span className="text-xs text-muted-foreground">
                      ({messages.length} message{messages.length > 1 ? 's' : ''})
                    </span>
                  </div>
                  <motion.div
                    animate={{ rotate: isOpen ? 180 : 0 }}
                    transition={{ duration: 0.2 }}
                  >
                    <ChevronDown className="w-4 h-4" />
                  </motion.div>
                </button>

                {/* Accordion Content */}
                <AnimatePresence>
                  {isOpen && (
                    <motion.div
                      initial={{ height: 0, opacity: 0 }}
                      animate={{ height: 'auto', opacity: 1 }}
                      exit={{ height: 0, opacity: 0 }}
                      transition={{ duration: 0.2 }}
                      className="overflow-hidden"
                    >
                      <div className="p-4 space-y-2 max-h-96 overflow-y-auto">
                        <AnimatePresence>
                          {messages.map((msg, idx) => (
                            <motion.div
                              key={idx}
                              initial={{ opacity: 0, x: -10 }}
                              animate={{ opacity: 1, x: 0 }}
                              exit={{ opacity: 0, x: 10 }}
                              transition={{ delay: idx * 0.02 }}
                              className="p-3 rounded-lg bg-muted/50 text-sm"
                            >
                              <div className="flex items-center justify-between mb-2">
                                <span className="text-xs text-muted-foreground">
                                  {msg.receivedAt.toLocaleString('fr-FR')}
                                </span>
                                <span className="text-xs text-muted-foreground">
                                  #{messages.length - idx}
                                </span>
                              </div>
                              <pre className="text-xs text-muted-foreground overflow-x-auto">
                                {JSON.stringify(msg.payload, null, 2)}
                              </pre>
                            </motion.div>
                          ))}
                        </AnimatePresence>
                      </div>
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>
            )
          })}

          {Object.keys(messagesByTopic).length === 0 && (
            <p className="text-center text-muted-foreground text-sm py-8">
              En attente de messages...
            </p>
          )}
        </div>
      </motion.div>
    </div>
  )
}
