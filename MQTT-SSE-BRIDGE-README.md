# 🎯 MQTT-SSE Bridge - Résumé du Projet

## Qu'est-ce qui a été créé ?

Un **backend proxy** qui convertit les messages MQTT en Server-Sent Events (SSE) pour contourner les restrictions firewall d'entreprise.

## 📁 Nouveaux fichiers créés

### 1. Backend Node.js (`backend-mqtt/`)
```
backend-mqtt/
├── server.js              # Serveur principal MQTT → SSE
├── package.json           # Dépendances (express, mqtt, cors)
├── Dockerfile             # Image Docker optimisée
├── .dockerignore          
├── .gitignore             
└── README.md              # Documentation backend
```

### 2. Helm Charts Kubernetes (`helm/mqtt-sse-bridge/`)
```
helm/mqtt-sse-bridge/
├── Chart.yaml                    # Métadonnées Helm
├── values.yaml                   # Config dev/staging
├── values-prod.yaml              # Config production
├── .helmignore                   
├── README.md                     # Doc Helm complète
├── DEPLOYMENT-GUIDE.md           # Guide déploiement détaillé
├── STRUCTURE.md                  # Architecture complète
│
├── templates/                    # Templates Kubernetes
│   ├── _helpers.tpl              
│   ├── deployment.yaml           # Pods + containers
│   ├── service.yaml              # ClusterIP port 3003
│   ├── ingress.yaml              # HTTPS + TLS
│   ├── hpa.yaml                  # Autoscaling 2-10 replicas
│   ├── pdb.yaml                  # High availability
│   ├── networkpolicy.yaml        # Sécurité réseau
│   └── NOTES.txt                 # Instructions post-install
│
├── deploy-mqtt-sse.ps1           # 🚀 Déploiement Windows
├── deploy-mqtt-sse.sh            # 🚀 Déploiement Linux/Mac
├── create-mqtt-secret.ps1        # 🔐 Secret MQTT Windows
└── create-mqtt-secret.sh         # 🔐 Secret MQTT Linux/Mac
```

### 3. Frontend modifié
- **`src/pages/demos/PortalDashboard.jsx`** : Remplace connexion MQTT par SSE

### 4. Documentation
- **`MIGRATION-SSE.md`** : Guide de migration MQTT → SSE
- **`MQTT-SSE-BRIDGE-README.md`** : Ce fichier

## 🚀 Comment déployer ?

### Option 1 : Script automatisé (⭐ Recommandé)

#### Windows PowerShell
```powershell
cd C:\dev\frontend-app\helm\mqtt-sse-bridge

# 1. Créer le secret MQTT
.\create-mqtt-secret.ps1

# 2. Déployer en production
.\deploy-mqtt-sse.ps1 -Environment prod
```

#### Linux/Mac
```bash
cd helm/mqtt-sse-bridge

# Rendre les scripts exécutables
chmod +x *.sh

# 1. Créer le secret MQTT
./create-mqtt-secret.sh

# 2. Déployer en production
./deploy-mqtt-sse.sh prod
```

### Option 2 : Déploiement manuel

```bash
# 1. Build Docker
cd backend-mqtt
docker build -t st3ph31/mqtt-sse-bridge:v1.0.0 .
docker push st3ph31/mqtt-sse-bridge:v1.0.0

# 2. Créer secret Kubernetes
kubectl create secret generic mqtt-credentials \
  --from-literal=username='portal569' \
  --from-literal=password='VOTRE_PASSWORD'

# 3. Déployer avec Helm
cd ../helm/mqtt-sse-bridge
helm install mqtt-sse-bridge . -f values-prod.yaml

# 4. Vérifier
kubectl get pods -l app.kubernetes.io/name=mqtt-sse-bridge
kubectl logs -l app.kubernetes.io/name=mqtt-sse-bridge -f
```

## 📊 Architecture

```
ESP32 Capteur
    ↓ MQTT (WSS)
HiveMQ Cloud
    ↓ MQTT (WSS)
MQTT-SSE Bridge (Kubernetes)
    ↓ SSE (HTTPS) ← Compatible firewall !
Frontend React
    ↓ HTTPS
Navigateur (même derrière firewall d'entreprise)
```

## ✅ Avantages

| Aspect | Avant | Après |
|--------|-------|-------|
| **Protocole** | WebSocket (WSS) | HTTP/HTTPS (SSE) |
| **Firewall** | ❌ Bloqué | ✅ Compatible |
| **Credentials** | Exposés client | Sécurisés serveur |
| **Scalabilité** | 1 connexion/client | Mutualisée |

## 🔧 Configuration

### Backend
- **Port** : 3003
- **Endpoints** :
  - `GET /api/portal/events` - Stream SSE
  - `GET /api/portal/state` - État REST (fallback)
  - `GET /health` - Health check

### Frontend
Créer `.env.production` :
```env
VITE_MQTT_SSE_URL=https://api.toolsapps.eu/api/portal/events
```

## 🧪 Tests

### 1. Backend local
```bash
cd backend-mqtt
npm install
npm start

# Dans un autre terminal
curl -N http://localhost:3003/api/portal/events
```

### 2. Après déploiement K8s
```bash
# Port-forward
kubectl port-forward svc/mqtt-sse-bridge 3003:3003

# Test
curl -N http://localhost:3003/api/portal/events
```

### 3. Production (avec DNS configuré)
```bash
curl -N https://api.toolsapps.eu/api/portal/events
```

## 📖 Documentation détaillée

- **[backend-mqtt/README.md](backend-mqtt/README.md)** - Backend Node.js
- **[helm/mqtt-sse-bridge/README.md](helm/mqtt-sse-bridge/README.md)** - Helm charts
- **[helm/mqtt-sse-bridge/DEPLOYMENT-GUIDE.md](helm/mqtt-sse-bridge/DEPLOYMENT-GUIDE.md)** - Guide déploiement
- **[helm/mqtt-sse-bridge/STRUCTURE.md](helm/mqtt-sse-bridge/STRUCTURE.md)** - Architecture complète
- **[MIGRATION-SSE.md](MIGRATION-SSE.md)** - Migration MQTT → SSE

## 🐛 Troubleshooting

### Backend ne démarre pas
```bash
kubectl logs -l app.kubernetes.io/name=mqtt-sse-bridge
kubectl describe pod -l app.kubernetes.io/name=mqtt-sse-bridge
```

### Connexion MQTT échoue
```bash
# Vérifier le secret
kubectl get secret mqtt-credentials -o yaml | base64 -d
```

### SSE buffering (pas de données)
```bash
# Vérifier annotations Ingress
kubectl get ingress mqtt-sse-bridge -o yaml | grep buffering
```

## 📦 Ce qui reste à faire

1. ✅ Backend créé
2. ✅ Helm charts créés  
3. ✅ Frontend adapté
4. ✅ Scripts de déploiement
5. 🔲 **Build et push image Docker**
6. 🔲 **Déployer sur Kubernetes**
7. 🔲 **Configurer DNS/TLS**
8. 🔲 **Tester en production**

## 🚀 Prochaines étapes

```bash
# 1. Lancer le script de déploiement
cd helm/mqtt-sse-bridge
.\deploy-mqtt-sse.ps1 -Environment prod

# 2. Vérifier les logs
kubectl logs -l app.kubernetes.io/name=mqtt-sse-bridge -f

# 3. Tester l'endpoint
curl -N https://api.toolsapps.eu/api/portal/events

# 4. Ouvrir le frontend
https://front.toolsapps.eu/demos/portal
```

## 🎉 Résultat attendu

✅ Le dashboard du portail fonctionne maintenant **partout**, même derrière un firewall d'entreprise strict !

---

**Besoin d'aide ?**
- 📧 contact@toolsapps.eu
- 📖 Consultez les guides détaillés dans `helm/mqtt-sse-bridge/`
