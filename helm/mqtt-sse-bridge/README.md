# MQTT-SSE Bridge Helm Chart

Helm chart pour déployer le MQTT-SSE Bridge sur Kubernetes. Ce service fait le pont entre un broker MQTT et des clients web via Server-Sent Events (SSE).

## 🎯 Objectif

Contourner les restrictions de firewall d'entreprise qui bloquent les connexions WebSocket (WSS) en utilisant SSE sur HTTP/HTTPS standard.

## 📋 Prérequis

- Kubernetes 1.19+
- Helm 3.0+
- Un broker MQTT accessible (ex: HiveMQ Cloud)
- Cert-manager installé pour les certificats TLS (optionnel)

## 🚀 Installation

### 1. Créer le secret MQTT (recommandé pour la production)

```bash
kubectl create secret generic mqtt-credentials \
  --from-literal=username='portal569' \
  --from-literal=password='VOTRE_MOT_DE_PASSE' \
  -n default
```

### 2. Installation avec Helm

```bash
# Installation basique
helm install mqtt-sse-bridge ./mqtt-sse-bridge

# Installation en production avec valeurs personnalisées
helm install mqtt-sse-bridge ./mqtt-sse-bridge \
  -f values-prod.yaml \
  --namespace production \
  --create-namespace
```

### 3. Mise à jour

```bash
helm upgrade mqtt-sse-bridge ./mqtt-sse-bridge \
  -f values-prod.yaml \
  --namespace production
```

## ⚙️ Configuration

### Valeurs principales

| Paramètre | Description | Défaut |
|-----------|-------------|--------|
| `replicaCount` | Nombre de réplicas | `2` |
| `image.repository` | Image Docker | `st3ph31/mqtt-sse-bridge` |
| `image.tag` | Tag de l'image | `v1.0.0` |
| `service.port` | Port du service | `3003` |
| `ingress.enabled` | Activer l'Ingress | `true` |
| `ingress.className` | Classe Ingress | `nginx` |
| `autoscaling.enabled` | Activer l'autoscaling | `false` |

### Variables d'environnement MQTT

```yaml
env:
  - name: MQTT_HOST
    value: "wss://broker.hivemq.cloud:8884/mqtt"
  - name: MQTT_USERNAME
    valueFrom:
      secretKeyRef:
        name: mqtt-credentials
        key: username
  - name: MQTT_PASSWORD
    valueFrom:
      secretKeyRef:
        name: mqtt-credentials
        key: password
```

## 🔧 Configuration pour SSE

### Annotations Nginx importantes

```yaml
annotations:
  # Désactiver le buffering pour SSE
  nginx.ingress.kubernetes.io/proxy-buffering: "off"
  nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
  nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
```

### Annotations Traefik importantes

```yaml
annotations:
  traefik.ingress.kubernetes.io/buffering: "off"
```

## 📊 Monitoring

### Vérifier l'état des pods

```bash
kubectl get pods -l app.kubernetes.io/name=mqtt-sse-bridge
```

### Voir les logs

```bash
kubectl logs -l app.kubernetes.io/name=mqtt-sse-bridge --tail=100 -f
```

### Health check

```bash
curl https://api.toolsapps.eu/health
```

Réponse attendue :
```json
{
  "status": "ok",
  "mqtt": "connected",
  "clients": 2
}
```

## 🔍 Tests

### Tester le endpoint SSE

```bash
curl -N https://api.toolsapps.eu/api/portal/events
```

Vous devriez recevoir un flux d'événements en temps réel.

### Tester depuis le frontend

```javascript
const eventSource = new EventSource('https://api.toolsapps.eu/api/portal/events')
eventSource.onmessage = (event) => {
  console.log('Message reçu:', JSON.parse(event.data))
}
```

## 🐛 Dépannage

### Le pod ne démarre pas

```bash
kubectl describe pod -l app.kubernetes.io/name=mqtt-sse-bridge
kubectl logs -l app.kubernetes.io/name=mqtt-sse-bridge
```

### Problème de connexion MQTT

Vérifier les credentials :
```bash
kubectl get secret mqtt-credentials -o yaml
```

### Problème SSE / Buffering

Vérifier les annotations Ingress :
```bash
kubectl get ingress mqtt-sse-bridge -o yaml
```

### Network Policy bloque les connexions

Si `networkPolicy.enabled: true`, s'assurer que :
- Le traffic entrant depuis le frontend est autorisé
- Le traffic sortant vers le broker MQTT (port 8884) est autorisé
- Le DNS (port 53 UDP) est autorisé

## 🚀 Déploiement complet

### Étape 1 : Build et push de l'image Docker

```bash
cd backend-mqtt
docker build -t st3ph31/mqtt-sse-bridge:v1.0.0 .
docker push st3ph31/mqtt-sse-bridge:v1.0.0
```

### Étape 2 : Créer les secrets

```bash
kubectl create secret generic mqtt-credentials \
  --from-literal=username='portal569' \
  --from-literal=password='VOTRE_PASSWORD' \
  -n production
```

### Étape 3 : Installer le chart

```bash
helm install mqtt-sse-bridge ./helm/mqtt-sse-bridge \
  -f ./helm/mqtt-sse-bridge/values-prod.yaml \
  --namespace production \
  --create-namespace
```

### Étape 4 : Vérifier le déploiement

```bash
kubectl get all -n production -l app.kubernetes.io/name=mqtt-sse-bridge
```

## 📦 Structure des fichiers

```
mqtt-sse-bridge/
├── Chart.yaml              # Métadonnées du chart
├── values.yaml            # Valeurs par défaut
├── values-prod.yaml       # Valeurs de production
└── templates/
    ├── _helpers.tpl       # Helpers Helm
    ├── deployment.yaml    # Déploiement Kubernetes
    ├── service.yaml       # Service Kubernetes
    ├── ingress.yaml       # Ingress (exposition HTTPS)
    ├── hpa.yaml          # Horizontal Pod Autoscaler
    ├── pdb.yaml          # Pod Disruption Budget
    ├── networkpolicy.yaml # Network Policy (sécurité)
    └── NOTES.txt         # Instructions post-installation
```

## 🔒 Sécurité

### Recommandations

1. **Utiliser des secrets Kubernetes** pour les credentials MQTT
2. **Activer le TLS** avec cert-manager
3. **Limiter les origines CORS** en production
4. **Activer les Network Policies** pour isoler le trafic
5. **Configurer les resource limits** pour éviter les abus

### Exemple de restriction CORS (modifier le code server.js)

```javascript
app.use(cors({
  origin: 'https://front.toolsapps.eu',
  credentials: true,
}));
```

## 📚 Ressources

- [Documentation Server-Sent Events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events)
- [Documentation MQTT.js](https://github.com/mqttjs/MQTT.js)
- [Helm Documentation](https://helm.sh/docs/)

## 🤝 Support

Pour toute question ou problème :
- Email : contact@toolsapps.eu
- Issues : https://github.com/st3ph31/mqtt-sse-bridge/issues
