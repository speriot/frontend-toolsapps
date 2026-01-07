# 🚀 Guide de Déploiement MQTT-SSE Bridge sur Kubernetes

## 📋 Vue d'ensemble

Ce guide vous accompagne dans le déploiement du backend MQTT-SSE Bridge sur votre cluster Kubernetes.

## ✅ Prérequis

- [x] Accès à un cluster Kubernetes
- [x] `kubectl` configuré
- [x] `helm` installé (version 3+)
- [x] Docker pour builder l'image
- [x] Accès à un registry Docker (Docker Hub, GitHub Container Registry, etc.)
- [x] Credentials du broker MQTT HiveMQ Cloud

## 📦 Étape 1 : Build et Push de l'image Docker

### 1.1 Se connecter à Docker Hub

```bash
docker login
```

### 1.2 Builder l'image

```bash
cd backend-mqtt
docker build -t st3ph31/mqtt-sse-bridge:v1.0.0 .
```

### 1.3 Tester l'image localement (optionnel)

```bash
docker run -p 3003:3003 st3ph31/mqtt-sse-bridge:v1.0.0
```

Tester : `curl http://localhost:3003/health`

### 1.4 Push vers Docker Hub

```bash
docker push st3ph31/mqtt-sse-bridge:v1.0.0
```

## 🔐 Étape 2 : Créer les secrets Kubernetes

### 2.1 Secret pour les credentials MQTT

```bash
kubectl create secret generic mqtt-credentials \
  --from-literal=username='portal569' \
  --from-literal=password='FMBUUX288547bbxiio' \
  --namespace default
```

Ou avec un fichier YAML :

```yaml
# mqtt-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: mqtt-credentials
  namespace: default
type: Opaque
stringData:
  username: portal569
  password: FMBUUX288547bbxiio
```

```bash
kubectl apply -f mqtt-secret.yaml
```

### 2.2 Vérifier le secret

```bash
kubectl get secret mqtt-credentials -o yaml
```

## 📝 Étape 3 : Configuration Helm

### 3.1 Vérifier les valeurs

Éditer `helm/mqtt-sse-bridge/values-prod.yaml` :

```yaml
replicaCount: 2

image:
  repository: st3ph31/mqtt-sse-bridge
  tag: "v1.0.0"
  pullPolicy: Always

ingress:
  enabled: true
  className: "traefik"  # ou "nginx" selon votre setup
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: api.toolsapps.eu
      paths:
        - path: /api/portal/events
          pathType: Prefix
```

### 3.2 Personnaliser pour votre environnement

Remplacer :
- `api.toolsapps.eu` → votre domaine
- `st3ph31/mqtt-sse-bridge` → votre repository Docker
- `traefik` → `nginx` si vous utilisez Nginx Ingress

## 🎯 Étape 4 : Installation Helm

### 4.1 Valider le chart

```bash
cd helm
helm lint mqtt-sse-bridge
```

### 4.2 Dry-run pour voir ce qui sera créé

```bash
helm install mqtt-sse-bridge ./mqtt-sse-bridge \
  -f mqtt-sse-bridge/values-prod.yaml \
  --dry-run --debug
```

### 4.3 Installation réelle

```bash
helm install mqtt-sse-bridge ./mqtt-sse-bridge \
  -f mqtt-sse-bridge/values-prod.yaml \
  --namespace default
```

### 4.4 Vérifier le déploiement

```bash
# Status Helm
helm status mqtt-sse-bridge

# Pods
kubectl get pods -l app.kubernetes.io/name=mqtt-sse-bridge

# Services
kubectl get svc -l app.kubernetes.io/name=mqtt-sse-bridge

# Ingress
kubectl get ingress mqtt-sse-bridge
```

## 🔍 Étape 5 : Vérification

### 5.1 Logs des pods

```bash
kubectl logs -l app.kubernetes.io/name=mqtt-sse-bridge --tail=50 -f
```

Vous devriez voir :
```
🚀 Backend MQTT-SSE démarré sur le port 3003
✅ Connecté au broker MQTT
📡 Abonné au topic: portal/main/led
📡 Abonné au topic: portal/main/heartbeat
📡 Abonné au topic: portal/main/alert
📡 Abonné au topic: portal/main/system_report
```

### 5.2 Health check

```bash
kubectl port-forward svc/mqtt-sse-bridge 3003:3003
curl http://localhost:3003/health
```

Réponse attendue :
```json
{
  "status": "ok",
  "mqtt": "connected",
  "clients": 0
}
```

### 5.3 Test SSE endpoint

```bash
curl -N http://localhost:3003/api/portal/events
```

Vous devriez voir un flux d'événements en temps réel.

### 5.4 Test depuis Internet (après DNS configuré)

```bash
curl -N https://api.toolsapps.eu/api/portal/events
```

## 🌐 Étape 6 : Configuration DNS et TLS

### 6.1 Vérifier le certificat TLS

Si vous utilisez cert-manager :

```bash
kubectl get certificate
kubectl describe certificate mqtt-sse-bridge-tls
```

### 6.2 Vérifier l'Ingress

```bash
kubectl get ingress mqtt-sse-bridge -o yaml
```

Vérifier que le TLS est configuré :
```yaml
spec:
  tls:
    - hosts:
        - api.toolsapps.eu
      secretName: api-tls
```

## 🔧 Étape 7 : Configuration du Frontend

### 7.1 Créer le fichier .env pour le frontend

```bash
# frontend-app/.env.production
VITE_MQTT_SSE_URL=https://api.toolsapps.eu/api/portal/events
```

### 7.2 Rebuild le frontend

```bash
cd frontend-app
npm run build
```

### 7.3 Redéployer le frontend

```bash
# Si vous utilisez Kubernetes
kubectl rollout restart deployment frontend-app

# Ou rebuild et push l'image Docker
docker build -t st3ph31/frontend-app:v1.0.1 .
docker push st3ph31/frontend-app:v1.0.1
helm upgrade frontend-app ./helm/frontend-app --set image.tag=v1.0.1
```

## 🎉 Étape 8 : Test complet

### 8.1 Ouvrir le frontend

Naviguer vers : `https://front.toolsapps.eu/demos/portal`

### 8.2 Vérifier dans la console du navigateur

Vous devriez voir :
```
🔌 Connexion au backend SSE...
✅ Connecté au backend SSE
📨 Message SSE reçu: portal/main/heartbeat
```

### 8.3 Vérifier les métriques côté serveur

```bash
kubectl top pods -l app.kubernetes.io/name=mqtt-sse-bridge
```

## 🔄 Mises à jour

### Version mineure (ex: v1.0.1)

```bash
# 1. Build nouvelle version
cd backend-mqtt
docker build -t st3ph31/mqtt-sse-bridge:v1.0.1 .
docker push st3ph31/mqtt-sse-bridge:v1.0.1

# 2. Upgrade Helm
helm upgrade mqtt-sse-bridge ./helm/mqtt-sse-bridge \
  --set image.tag=v1.0.1 \
  --reuse-values
```

### Version majeure (avec changements de config)

```bash
helm upgrade mqtt-sse-bridge ./helm/mqtt-sse-bridge \
  -f mqtt-sse-bridge/values-prod.yaml
```

## 🐛 Dépannage

### Le pod crashe au démarrage

```bash
kubectl describe pod -l app.kubernetes.io/name=mqtt-sse-bridge
kubectl logs -l app.kubernetes.io/name=mqtt-sse-bridge --previous
```

Causes fréquentes :
- ❌ Secret MQTT manquant ou incorrect
- ❌ Port déjà utilisé
- ❌ Image Docker introuvable

### Connexion MQTT impossible

```bash
# Vérifier les credentials
kubectl get secret mqtt-credentials -o jsonpath='{.data.username}' | base64 -d
kubectl get secret mqtt-credentials -o jsonpath='{.data.password}' | base64 -d

# Tester depuis un pod de debug
kubectl run debug --image=curlimages/curl -it --rm -- sh
curl http://mqtt-sse-bridge:3003/health
```

### SSE ne fonctionne pas (buffering)

Vérifier les annotations Ingress :

```bash
kubectl get ingress mqtt-sse-bridge -o jsonpath='{.metadata.annotations}' | jq
```

Doit contenir (pour Nginx) :
```json
{
  "nginx.ingress.kubernetes.io/proxy-buffering": "off",
  "nginx.ingress.kubernetes.io/proxy-read-timeout": "3600"
}
```

Doit contenir (pour Traefik) :
```json
{
  "traefik.ingress.kubernetes.io/buffering": "off"
}
```

### Les clients SSE se déconnectent

Augmenter les timeouts dans `values-prod.yaml` :

```yaml
ingress:
  annotations:
    nginx.ingress.kubernetes.io/proxy-read-timeout: "7200"  # 2 heures
```

## 📊 Monitoring Production

### Activer l'autoscaling

```bash
helm upgrade mqtt-sse-bridge ./helm/mqtt-sse-bridge \
  --set autoscaling.enabled=true \
  --set autoscaling.minReplicas=2 \
  --set autoscaling.maxReplicas=10 \
  --reuse-values
```

### Surveiller les métriques

```bash
# CPU et RAM
kubectl top pods -l app.kubernetes.io/name=mqtt-sse-bridge

# Nombre de réplicas
kubectl get hpa mqtt-sse-bridge

# Events
kubectl get events --sort-by='.lastTimestamp' | grep mqtt-sse
```

## 🔐 Sécurité Production

### 1. Limiter les origines CORS

Modifier `server.js` :
```javascript
app.use(cors({
  origin: 'https://front.toolsapps.eu',
  credentials: true,
}));
```

### 2. Activer les Network Policies

```bash
helm upgrade mqtt-sse-bridge ./helm/mqtt-sse-bridge \
  --set networkPolicy.enabled=true \
  --reuse-values
```

### 3. Scanner les vulnérabilités

```bash
docker scan st3ph31/mqtt-sse-bridge:v1.0.0
```

## 🎓 Checklist finale

- [ ] Image Docker buildée et pushée
- [ ] Secret MQTT créé
- [ ] Chart Helm installé
- [ ] Pods en Running
- [ ] Health check OK
- [ ] Connexion MQTT établie
- [ ] Messages MQTT reçus
- [ ] Ingress configuré
- [ ] TLS actif
- [ ] DNS configuré
- [ ] Frontend reconfigured avec SSE_URL
- [ ] Test complet depuis le navigateur
- [ ] Monitoring actif
- [ ] CORS restreint (production)
- [ ] Documentation à jour

## 🆘 Support

En cas de problème :
1. Vérifier les logs : `kubectl logs -l app.kubernetes.io/name=mqtt-sse-bridge`
2. Vérifier le health check : `curl https://api.toolsapps.eu/health`
3. Contacter : contact@toolsapps.eu

## 🎉 Félicitations !

Votre MQTT-SSE Bridge est maintenant déployé en production et accessible depuis n'importe quel réseau, même derrière un firewall d'entreprise ! 🚀
