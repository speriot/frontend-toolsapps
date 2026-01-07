# 📦 Structure Complète - MQTT-SSE Bridge

## 📁 Arborescence des fichiers

```
C:\dev\frontend-app\
│
├── backend-mqtt/                           # ⭐ Backend MQTT-SSE Bridge
│   ├── server.js                          # Serveur Node.js principal
│   ├── package.json                       # Dépendances npm
│   ├── Dockerfile                         # Image Docker optimisée
│   ├── .dockerignore                      # Exclusions Docker
│   ├── .gitignore                         # Exclusions Git
│   └── README.md                          # Documentation du backend
│
├── helm/mqtt-sse-bridge/                   # ⭐ Charts Helm Kubernetes
│   ├── Chart.yaml                         # Métadonnées Helm
│   ├── values.yaml                        # Configuration par défaut
│   ├── values-prod.yaml                   # Configuration production
│   ├── .helmignore                        # Exclusions Helm
│   ├── README.md                          # Documentation Helm
│   ├── DEPLOYMENT-GUIDE.md                # Guide de déploiement détaillé
│   │
│   ├── templates/                         # Templates Kubernetes
│   │   ├── _helpers.tpl                   # Helpers Helm
│   │   ├── deployment.yaml                # Déploiement K8s
│   │   ├── service.yaml                   # Service ClusterIP
│   │   ├── ingress.yaml                   # Ingress HTTPS
│   │   ├── hpa.yaml                       # Autoscaling
│   │   ├── pdb.yaml                       # Pod Disruption Budget
│   │   ├── networkpolicy.yaml             # Règles réseau (optionnel)
│   │   └── NOTES.txt                      # Instructions post-install
│   │
│   ├── deploy-mqtt-sse.ps1                # 🚀 Script déploiement Windows
│   ├── deploy-mqtt-sse.sh                 # 🚀 Script déploiement Linux
│   ├── create-mqtt-secret.ps1             # 🔐 Création secret Windows
│   └── create-mqtt-secret.sh              # 🔐 Création secret Linux
│
├── src/pages/demos/
│   └── PortalDashboard.jsx                # ⭐ Frontend modifié (SSE)
│
└── MIGRATION-SSE.md                        # 📖 Documentation migration
```

## 🎯 Fichiers clés

### Backend (backend-mqtt/)

| Fichier | Description | Utilisation |
|---------|-------------|-------------|
| `server.js` | Serveur Node.js principal | Se connecte à MQTT et expose SSE |
| `Dockerfile` | Image Docker multi-stage | Build optimisé pour production |
| `package.json` | Dépendances npm | Express, MQTT, CORS |

### Helm Charts (helm/mqtt-sse-bridge/)

| Fichier | Description | Utilisation |
|---------|-------------|-------------|
| `Chart.yaml` | Métadonnées du chart | Version, description, maintainers |
| `values.yaml` | Config par défaut | Dev/staging |
| `values-prod.yaml` | Config production | Autoscaling, resources optimisées |
| `templates/deployment.yaml` | Déploiement K8s | Pods, containers, env vars |
| `templates/service.yaml` | Service K8s | ClusterIP port 3003 |
| `templates/ingress.yaml` | Ingress K8s | HTTPS + Certificats TLS |
| `templates/hpa.yaml` | Autoscaling | 2-10 replicas selon CPU/RAM |

### Scripts de déploiement

| Script | Plateforme | Description |
|--------|-----------|-------------|
| `deploy-mqtt-sse.ps1` | Windows | Déploiement automatisé complet |
| `deploy-mqtt-sse.sh` | Linux/Mac | Déploiement automatisé complet |
| `create-mqtt-secret.ps1` | Windows | Création secret MQTT |
| `create-mqtt-secret.sh` | Linux/Mac | Création secret MQTT |

## 🚀 Workflow de déploiement

### Méthode 1 : Script automatisé (Recommandé)

#### Windows
```powershell
cd C:\dev\frontend-app\helm\mqtt-sse-bridge

# Créer le secret MQTT
.\create-mqtt-secret.ps1

# Déployer en production
.\deploy-mqtt-sse.ps1 -Environment prod
```

#### Linux/Mac
```bash
cd /dev/frontend-app/helm/mqtt-sse-bridge

# Créer le secret MQTT
chmod +x create-mqtt-secret.sh deploy-mqtt-sse.sh
./create-mqtt-secret.sh

# Déployer en production
./deploy-mqtt-sse.sh prod
```

### Méthode 2 : Manuel

```bash
# 1. Build et push Docker
cd backend-mqtt
docker build -t st3ph31/mqtt-sse-bridge:v1.0.0 .
docker push st3ph31/mqtt-sse-bridge:v1.0.0

# 2. Créer le secret
kubectl create secret generic mqtt-credentials \
  --from-literal=username='portal569' \
  --from-literal=password='VOTRE_PASSWORD'

# 3. Installer avec Helm
cd ../helm/mqtt-sse-bridge
helm install mqtt-sse-bridge . -f values-prod.yaml

# 4. Vérifier
kubectl get pods -l app.kubernetes.io/name=mqtt-sse-bridge
kubectl logs -l app.kubernetes.io/name=mqtt-sse-bridge -f
```

## 🔧 Configuration

### Variables d'environnement (backend)

| Variable | Défaut | Description |
|----------|--------|-------------|
| `PORT` | 3003 | Port du serveur |
| `NODE_ENV` | production | Environnement Node.js |
| `MQTT_HOST` | wss://...hivemq.cloud:8884/mqtt | Broker MQTT |
| `MQTT_USERNAME` | (secret) | Username MQTT |
| `MQTT_PASSWORD` | (secret) | Password MQTT |

### Ports

| Port | Service | Description |
|------|---------|-------------|
| 3003 | MQTT-SSE Bridge | Endpoint SSE |
| 3001 | Auth API | API d'authentification existante |
| 5173 | Frontend (dev) | Vite dev server |
| 443 | Ingress | HTTPS externe |

### Endpoints exposés

| Endpoint | Méthode | Description |
|----------|---------|-------------|
| `/api/portal/events` | GET (SSE) | Stream d'événements temps réel |
| `/api/portal/state` | GET (REST) | État actuel (fallback) |
| `/health` | GET | Health check |

## 📊 Architecture finale

```
┌─────────────┐
│  ESP32      │ Capteur portail
│  Capteur    │
└──────┬──────┘
       │ MQTT (WSS)
       │
┌──────▼──────────────────┐
│  HiveMQ Cloud Broker    │
│  (wss://...hivemq...)   │
└──────┬──────────────────┘
       │ MQTT (WSS)
       │
┌──────▼──────────────────┐
│  MQTT-SSE Bridge (K8s)  │
│  • Port: 3003           │
│  • Replicas: 2-10       │
│  • Ingress: HTTPS       │
└──────┬──────────────────┘
       │ SSE (HTTPS)
       │
┌──────▼──────────────────┐
│  Frontend React (K8s)   │
│  PortalDashboard.jsx    │
└──────┬──────────────────┘
       │ HTTPS
       │
┌──────▼──────────────────┐
│  Navigateur Utilisateur │
│  (Même derrière firewall)│
└─────────────────────────┘
```

## ✅ Avantages de cette architecture

1. **✅ Compatible firewall** : Utilise HTTP/HTTPS standard (pas de WSS bloqué)
2. **✅ Sécurisé** : Credentials MQTT cachés côté serveur
3. **✅ Scalable** : Autoscaling 2-10 replicas selon charge
4. **✅ Résilient** : Pod Disruption Budget, Health checks
5. **✅ Production-ready** : TLS, monitoring, logs centralisés
6. **✅ Easy deploy** : Scripts automatisés Windows/Linux

## 🔄 Comparaison avant/après

| Aspect | Avant (MQTT direct) | Après (SSE Bridge) |
|--------|---------------------|---------------------|
| **Protocole client** | WebSocket (WSS) | HTTP/HTTPS (SSE) |
| **Firewall compatibility** | ❌ Souvent bloqué | ✅ Compatible partout |
| **Credentials** | Exposés dans le frontend | Sécurisés backend |
| **Connexions MQTT** | 1 par client | 1 partagée (bridge) |
| **Latence** | ~100ms | ~150ms (acceptable) |
| **Déploiement** | Frontend uniquement | Frontend + Backend |
| **Monitoring** | Difficile | Kubernetes natif |

## 📖 Documentation

- **[backend-mqtt/README.md](../backend-mqtt/README.md)** : Documentation du backend Node.js
- **[helm/mqtt-sse-bridge/README.md](README.md)** : Documentation Helm complète
- **[helm/mqtt-sse-bridge/DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md)** : Guide de déploiement pas-à-pas
- **[MIGRATION-SSE.md](../../MIGRATION-SSE.md)** : Documentation de la migration

## 🐛 Troubleshooting

### Backend ne se connecte pas au MQTT
```bash
kubectl logs -l app.kubernetes.io/name=mqtt-sse-bridge
# Vérifier les credentials dans le secret
kubectl get secret mqtt-credentials -o yaml
```

### SSE ne fonctionne pas (buffering)
```bash
kubectl get ingress mqtt-sse-bridge -o yaml
# Vérifier les annotations de buffering
```

### Pods crashent
```bash
kubectl describe pod -l app.kubernetes.io/name=mqtt-sse-bridge
kubectl logs -l app.kubernetes.io/name=mqtt-sse-bridge --previous
```

## 📞 Support

- **Email** : contact@toolsapps.eu
- **Logs** : `kubectl logs -l app.kubernetes.io/name=mqtt-sse-bridge -f`
- **Health** : `curl https://api.toolsapps.eu/health`

## 🎉 Next Steps

1. ✅ Backend créé (`backend-mqtt/`)
2. ✅ Helm charts créés (`helm/mqtt-sse-bridge/`)
3. ✅ Frontend adapté (SSE au lieu de MQTT)
4. ✅ Scripts de déploiement créés
5. 🔲 Build et push de l'image Docker
6. 🔲 Déploiement sur Kubernetes
7. 🔲 Configuration DNS et TLS
8. 🔲 Tests en production

**Prêt à déployer !** 🚀
