require('dotenv').config();
const express = require('express');
const mqtt = require('mqtt');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3003;

// Configuration MQTT (credentials chargés depuis .env en dev, K8s secret en prod)
const MQTT_CONFIG = {
  host: process.env.MQTT_HOST,
  username: process.env.MQTT_USERNAME,
  password: process.env.MQTT_PASSWORD,
  clientId: `mqtt_sse_bridge_${Math.random().toString(16).slice(2, 10)}`,
};

// Validation des credentials
if (!MQTT_CONFIG.host || !MQTT_CONFIG.username || !MQTT_CONFIG.password) {
  console.error('❌ ERREUR: Variables MQTT manquantes!');
  console.error('   En dev: créez un fichier .env (voir .env.example)');
  console.error('   En prod: vérifiez que le secret Kubernetes "mqtt-credentials" existe');
  process.exit(1);
}

const TOPICS = [
  'portal/main/led',
  'portal/main/heartbeat',
  'portal/main/alert',
  'portal/main/system_report',
];

// Variables globales
let mqttClient = null;
let latestMessages = {
  'portal/main/led': null,
  'portal/main/heartbeat': null,
  'portal/main/alert': null,
  'portal/main/system_report': null,
};
const sseClients = new Set();

// Connexion au broker MQTT
function connectMQTT() {
  console.log('🔄 Connexion au broker MQTT...');
  
  mqttClient = mqtt.connect(MQTT_CONFIG.host, {
    username: MQTT_CONFIG.username,
    password: MQTT_CONFIG.password,
    clientId: MQTT_CONFIG.clientId,
    reconnectPeriod: 5000,
  });

  mqttClient.on('connect', () => {
    console.log('✅ Connecté au broker MQTT');
    
    // S'abonner aux topics
    TOPICS.forEach(topic => {
      mqttClient.subscribe(topic, (err) => {
        if (err) {
          console.error(`❌ Erreur abonnement ${topic}:`, err);
        } else {
          console.log(`📡 Abonné au topic: ${topic}`);
        }
      });
    });
  });

  mqttClient.on('message', (topic, message) => {
    try {
      const payload = JSON.parse(message.toString());
      const timestamp = new Date().toISOString();
      
      const data = {
        topic,
        payload,
        receivedAt: timestamp,
      };

      // Stocker le dernier message
      latestMessages[topic] = data;

      console.log(`📨 Message reçu sur ${topic}`);

      // Envoyer aux clients SSE
      broadcastToClients(data);
    } catch (err) {
      console.error('❌ Erreur parsing message MQTT:', err);
    }
  });

  mqttClient.on('error', (err) => {
    console.error('❌ Erreur MQTT:', err);
  });

  mqttClient.on('offline', () => {
    console.log('⚠️ MQTT offline');
  });

  mqttClient.on('reconnect', () => {
    console.log('🔄 Reconnexion MQTT...');
  });
}

// Broadcast aux clients SSE
function broadcastToClients(data) {
  sseClients.forEach(client => {
    try {
      client.write(`data: ${JSON.stringify(data)}\n\n`);
    } catch (err) {
      console.error('❌ Erreur envoi SSE:', err);
      sseClients.delete(client);
    }
  });
}

// Middleware
app.use(cors({
  origin: '*',
  credentials: true,
}));

app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    mqtt: mqttClient?.connected ? 'connected' : 'disconnected',
    clients: sseClients.size,
  });
});

// Endpoint SSE principal
app.get('/api/portal/events', (req, res) => {
  console.log('🔌 Nouveau client SSE connecté');

  // Headers SSE
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.setHeader('Access-Control-Allow-Origin', '*');

  // Envoyer les derniers messages connus
  Object.entries(latestMessages).forEach(([topic, data]) => {
    if (data) {
      res.write(`data: ${JSON.stringify(data)}\n\n`);
    }
  });

  // Ajouter le client à la liste
  sseClients.add(res);

  // Heartbeat pour garder la connexion active
  const heartbeatInterval = setInterval(() => {
    res.write(`: heartbeat\n\n`);
  }, 30000); // Toutes les 30s

  // Nettoyer quand le client se déconnecte
  req.on('close', () => {
    console.log('🔌 Client SSE déconnecté');
    clearInterval(heartbeatInterval);
    sseClients.delete(res);
  });
});

// Endpoint REST pour récupérer l'état actuel (fallback)
app.get('/api/portal/state', (req, res) => {
  res.json({
    mqtt_status: mqttClient?.connected ? 'connected' : 'disconnected',
    last_messages: latestMessages,
    active_clients: sseClients.size,
  });
});

// Démarrage du serveur
app.listen(PORT, () => {
  console.log(`🚀 Backend MQTT-SSE démarré sur le port ${PORT}`);
  console.log(`📡 SSE endpoint: http://localhost:${PORT}/api/portal/events`);
  console.log(`🔍 Health check: http://localhost:${PORT}/health`);
  console.log(`🔐 MQTT Credentials: ${process.env.NODE_ENV === 'production' ? 'K8s Secret' : 'Fichier .env local'}`);
  console.log(`👤 MQTT Username: ${MQTT_CONFIG.username}`);
  connectMQTT();
});

// Gestion de l'arrêt propre
process.on('SIGINT', () => {
  console.log('\n🛑 Arrêt du serveur...');
  if (mqttClient) {
    mqttClient.end();
  }
  process.exit(0);
});
