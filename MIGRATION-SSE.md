# 🎯 Migration MQTT → SSE (Server-Sent Events)

## Pourquoi cette migration ?

Les connexions WebSocket (WSS) sont **bloquées par les firewalls d'entreprise**. La solution SSE utilise HTTP/HTTPS standard, compatible avec tous les firewalls.

## ✅ Ce qui a été fait

### 1. **Nouveau backend MQTT-SSE** (`backend-mqtt/`)
- Serveur Node.js qui se connecte au broker MQTT HiveMQ
- Expose un endpoint SSE sur `http://localhost:3003/api/portal/events`
- Fait le pont entre MQTT (côté serveur) et SSE (côté client)

### 2. **Frontend modifié** (`PortalDashboard.jsx`)
- Remplacement de la connexion MQTT directe par EventSource (SSE)
- **Toute l'UI reste identique** - seule la couche transport change
- Les identifiants MQTT ne sont plus exposés côté client

## 🚀 Comment tester

### 1. Démarrer le backend MQTT-SSE

```powershell
cd backend-mqtt
npm install
npm start
```

Le serveur démarre sur `http://localhost:3003`

### 2. Démarrer le frontend (comme d'habitude)

```powershell
npm run dev
```

### 3. Ouvrir le dashboard

Allez sur `http://localhost:5173/demos/portal` (ou votre URL)

### 4. Vérifier les logs

**Dans le terminal backend-mqtt**, vous devriez voir :
```
✅ Connecté au broker MQTT
📡 Abonné au topic: portal/main/led
📡 Abonné au topic: portal/main/heartbeat
🔌 Nouveau client SSE connecté
📨 Message reçu sur portal/main/heartbeat
```

**Dans la console du navigateur**, vous devriez voir :
```
🔌 Connexion au backend SSE...
✅ Connecté au backend SSE
📨 Message SSE reçu: portal/main/heartbeat
```

## 📊 Architecture

```
ESP32 Capteur
    |
    | MQTT (WSS)
    ↓
HiveMQ Cloud Broker
    |
    | MQTT (WSS)
    ↓
Backend Node.js (backend-mqtt)
    |
    | SSE (HTTP/HTTPS)
    ↓
Frontend React (PortalDashboard.jsx)
    |
    ↓
Navigateur (même derrière firewall d'entreprise)
```

## 🔧 Configuration pour la production

### Backend sur VPS

1. Copier `backend-mqtt/` sur votre VPS
2. Installer : `npm install --production`
3. Démarrer avec PM2 :
```bash
pm2 start server.js --name mqtt-sse-bridge
pm2 startup
pm2 save
```

4. Configurer Nginx/Traefik pour exposer en HTTPS :
```nginx
location /api/portal/events {
    proxy_pass http://localhost:3003;
    proxy_http_version 1.1;
    proxy_set_header Connection "";
    proxy_buffering off;
    proxy_cache off;
}
```

### Frontend

Créer un fichier `.env` :
```
VITE_MQTT_SSE_URL=https://votre-domaine.com/api/portal/events
```

Rebuild le frontend :
```bash
npm run build
```

## ✨ Avantages

✅ Compatible avec **tous les firewalls d'entreprise**  
✅ Identifiants MQTT **non exposés** côté client  
✅ Connexion HTTPS standard  
✅ Reconnexion automatique intégrée  
✅ Moins de latence (1 seule connexion serveur ↔ MQTT)  
✅ Support natif dans tous les navigateurs  

## 📝 Différences avec MQTT

| Aspect | MQTT (avant) | SSE (maintenant) |
|--------|-------------|------------------|
| Protocole | WebSocket (WSS) | HTTP/HTTPS |
| Connexion | Client → Broker | Client → Backend → Broker |
| Firewall | ❌ Souvent bloqué | ✅ Compatible |
| Credentials | Exposés client | Sécurisés serveur |
| Bidirectionnel | Oui | Non (unidirectionnel OK) |

## 🐛 Dépannage

### Le frontend ne reçoit pas de données

1. Vérifier que le backend est démarré : `http://localhost:3003/health`
2. Vérifier les logs du backend : `npm start`
3. Vérifier la console navigateur (F12)

### Le backend ne se connecte pas au MQTT

- Vérifier les credentials dans `backend-mqtt/server.js`
- Vérifier la connexion Internet
- Tester manuellement : `curl http://localhost:3003/health`

### Erreur CORS

Le backend autorise toutes les origines (`origin: '*'`). En production, restreindre :
```javascript
app.use(cors({
  origin: 'https://votre-domaine.com',
  credentials: true,
}));
```

## 📦 Fichiers modifiés

- ✅ `backend-mqtt/` - Nouveau backend SSE
- ✅ `src/pages/demos/PortalDashboard.jsx` - Remplacé MQTT par SSE
- ✅ `package.json` - Peut retirer `mqtt` du frontend si non utilisé ailleurs

## 🎉 Résultat

Même expérience utilisateur, mais **fonctionne partout** !
