# Backend MQTT-SSE Bridge

Backend qui fait le pont entre le broker MQTT (HiveMQ Cloud) et le frontend via Server-Sent Events (SSE).

## 🎯 Pourquoi ce backend ?

Les connexions WebSocket (WSS) sont souvent bloquées par les firewalls d'entreprise. Ce backend résout le problème en :
- Se connectant au broker MQTT depuis le serveur (pas de firewall)
- Exposant les données via SSE (HTTP standard, compatible firewall)
- Permettant aux clients de recevoir les mises à jour en temps réel via HTTPS

## 🚀 Installation

```bash
cd backend-mqtt
npm install
```

## 🏃 Démarrage

### Développement local
```bash
npm start
```

Le serveur démarre sur `http://localhost:3003`

### Variables d'environnement (optionnel)

```bash
PORT=3003 npm start
```

## 📡 Endpoints

### SSE Stream (événements temps réel)
```
GET http://localhost:3003/api/portal/events
Content-Type: text/event-stream
```

Reçoit les messages MQTT en temps réel au format :
```json
{
  "topic": "portal/main/led",
  "payload": { "state": "OPEN", "color": "red", "timestamp": "..." },
  "receivedAt": "2026-01-07T10:30:00.000Z"
}
```

### Health Check
```
GET http://localhost:3003/health
```

Retourne :
```json
{
  "status": "ok",
  "mqtt": "connected",
  "clients": 2
}
```

### État actuel (REST fallback)
```
GET http://localhost:3003/api/portal/state
```

## 🔧 Configuration MQTT

Les identifiants MQTT sont codés en dur dans `server.js` (ligne 10-14). Pour la production, utilisez des variables d'environnement :

```bash
MQTT_HOST=wss://...
MQTT_USERNAME=portal569
MQTT_PASSWORD=...
```

## 📦 Topics MQTT écoutés

- `portal/main/led` - État du portail (ouvert/fermé)
- `portal/main/heartbeat` - Signal de vie du capteur
- `portal/main/alert` - Alertes
- `portal/main/system_report` - Rapport système

## 🛠️ Déploiement sur VPS

1. Copier le dossier sur le VPS
2. Installer les dépendances : `npm install --production`
3. Utiliser PM2 pour le démarrage automatique :

```bash
npm install -g pm2
pm2 start server.js --name mqtt-sse-bridge
pm2 startup
pm2 save
```

4. Configurer Nginx/Traefik pour exposer en HTTPS

## 📊 Monitoring

```bash
# Via PM2
pm2 logs mqtt-sse-bridge
pm2 monit

# Via Health Check
curl http://localhost:3003/health
```

## 🔒 Sécurité

⚠️ En production :
- Utiliser HTTPS (via Nginx/Traefik)
- Ajouter une authentification sur les endpoints
- Déplacer les credentials MQTT dans des variables d'environnement
- Limiter les origines CORS
