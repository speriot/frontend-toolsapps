# Frontend ToolsApps - Helm Chart

Chart Helm professionnel pour déployer l'application Frontend ToolsApps sur Kubernetes.

## 📋 Prérequis

- Kubernetes 1.24+
- Helm 3.10+
- Traefik Ingress Controller installé
- cert-manager (pour SSL automatique avec Let's Encrypt)

## 🚀 Installation Rapide

### 1. Installation basique

```bash
helm install frontend-toolsapps ./helm/frontend-toolsapps
```

### 2. Installation en production

```bash
helm install frontend-toolsapps ./helm/frontend-toolsapps \
  --values ./helm/frontend-toolsapps/values-prod.yaml \
  --namespace production \
  --create-namespace
```

### 3. Installation en staging

```bash
helm install frontend-toolsapps ./helm/frontend-toolsapps \
  --values ./helm/frontend-toolsapps/values-staging.yaml \
  --namespace staging \
  --create-namespace
```

## 🔧 Configuration

### Valeurs principales

| Paramètre | Description | Défaut |
|-----------|-------------|--------|
| `replicaCount` | Nombre de réplicas | `2` |
| `image.repository` | Repository de l'image Docker | `docker.io/st3ph31/frontend-toolsapps` |
| `image.tag` | Tag de l'image | `v1.0.0` |
| `service.type` | Type de service K8s | `ClusterIP` |
| `ingress.enabled` | Activer l'Ingress | `true` |
| `ingress.className` | Classe Ingress (traefik) | `traefik` |
| `ingress.hosts[0].host` | Nom de domaine | `front.toolsapps.eu` |
| `autoscaling.enabled` | Activer l'autoscaling | `true` |
| `autoscaling.minReplicas` | Réplicas minimum | `2` |
| `autoscaling.maxReplicas` | Réplicas maximum | `10` |

### Exemple de surcharge de valeurs

Créez un fichier `my-values.yaml` :

```yaml
replicaCount: 3

image:
  tag: "v1.0.1"

resources:
  limits:
    cpu: 400m
    memory: 512Mi

ingress:
  hosts:
    - host: myapp.example.com
      paths:
        - path: /
          pathType: Prefix
```

Puis installez :

```bash
helm install frontend-toolsapps ./helm/frontend-toolsapps -f my-values.yaml
```

## 📦 Composants Déployés

Le chart déploie les ressources Kubernetes suivantes :

- **Deployment** - Gère les pods de l'application
- **Service** - Expose l'application en interne
- **Ingress** - Exposition HTTPS avec SSL automatique
- **HorizontalPodAutoscaler** - Autoscaling automatique
- **PodDisruptionBudget** - Haute disponibilité
- **NetworkPolicy** - Sécurité réseau
- **ServiceAccount** - Identité des pods
- **ConfigMap** - Configuration applicative

## 🔐 Sécurité

### Security Context

Le chart applique des politiques de sécurité strictes :

```yaml
podSecurityContext:
  fsGroup: 2000
  runAsNonRoot: true
  runAsUser: 1000

securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
    - ALL
  readOnlyRootFilesystem: true
  runAsNonRoot: true
```

### Network Policy

Les Network Policies limitent le trafic réseau :
- **Ingress** : Uniquement depuis Traefik Ingress Controller
- **Egress** : Uniquement vers l'API backend et DNS

## 🌐 Traefik Configuration

### Ingress Controller

Ce chart utilise **Traefik** comme Ingress Controller avec :
- Redirection automatique HTTP → HTTPS
- Certificats SSL Let's Encrypt via cert-manager
- Support des middlewares Traefik

### Annotations Traefik

Exemples d'annotations disponibles :

```yaml
ingress:
  annotations:
    # Certificat SSL automatique
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    # Middleware de redirection HTTPS
    traefik.ingress.kubernetes.io/router.middlewares: "default-redirect-https@kubernetescrd"
    # Points d'entrée
    traefik.ingress.kubernetes.io/router.entrypoints: "web,websecure"
```

## 📊 Monitoring et Observabilité

### Health Checks

Le chart configure automatiquement :

- **Liveness Probe** : Vérifie que l'app répond
- **Readiness Probe** : Vérifie que l'app est prête à recevoir du trafic

### Prometheus (optionnel)

Pour activer le monitoring Prometheus :

```yaml
serviceMonitor:
  enabled: true
  interval: 30s
```

## 🔄 Mises à Jour

### Mise à jour de l'image

```bash
# Méthode 1 : Via --set
helm upgrade frontend-toolsapps ./helm/frontend-toolsapps \
  --set image.tag=v1.0.1 \
  --reuse-values

# Méthode 2 : Via values file
helm upgrade frontend-toolsapps ./helm/frontend-toolsapps \
  -f values-prod.yaml
```

### Rolling Update

Les mises à jour se font automatiquement en rolling :
- Pas de downtime
- Rollback automatique en cas d'erreur
- PodDisruptionBudget garantit la disponibilité

### Rollback

```bash
# Voir l'historique
helm history frontend-toolsapps

# Rollback vers la version précédente
helm rollback frontend-toolsapps

# Rollback vers une version spécifique
helm rollback frontend-toolsapps 3
```

## 🧪 Tests

### Test Helm

```bash
# Test de rendu des templates
helm template frontend-toolsapps ./helm/frontend-toolsapps

# Dry-run de l'installation
helm install frontend-toolsapps ./helm/frontend-toolsapps --dry-run --debug

# Lint du chart
helm lint ./helm/frontend-toolsapps
```

### Test Kubernetes

```bash
# Test après installation
helm test frontend-toolsapps

# Vérifier les pods
kubectl get pods -l app.kubernetes.io/name=frontend-toolsapps

# Vérifier les services
kubectl get svc -l app.kubernetes.io/name=frontend-toolsapps

# Vérifier l'ingress
kubectl get ingress
```

## 🌐 Accès à l'Application

Après installation, accédez à :

```
https://front.toolsapps.eu
```

Pour vérifier l'URL exacte :

```bash
kubectl get ingress
```

## 📈 Autoscaling

L'HPA (Horizontal Pod Autoscaler) scale automatiquement selon :

- **CPU** : 80% d'utilisation
- **Memory** : 80% d'utilisation
- **Min replicas** : 2
- **Max replicas** : 10

Surveiller l'autoscaling :

```bash
kubectl get hpa
kubectl describe hpa frontend-toolsapps
```

## 🔍 Debugging

### Voir les logs

```bash
# Logs d'un pod spécifique
kubectl logs -l app.kubernetes.io/name=frontend-toolsapps

# Logs en temps réel
kubectl logs -f -l app.kubernetes.io/name=frontend-toolsapps

# Logs avec tail
kubectl logs --tail=100 -l app.kubernetes.io/name=frontend-toolsapps
```

### Shell dans un pod

```bash
kubectl exec -it deployment/frontend-toolsapps -- /bin/sh
```

### Événements

```bash
kubectl get events --sort-by='.lastTimestamp'
```

### Vérifier SSL/TLS

```bash
# Vérifier le certificat Let's Encrypt
kubectl get certificate -n production
kubectl describe certificate frontend-toolsapps-tls -n production

# Vérifier le secret TLS
kubectl get secret frontend-toolsapps-tls -n production

# Logs Traefik
kubectl logs -n traefik deployment/traefik -f

# Logs cert-manager
kubectl logs -n cert-manager deployment/cert-manager -f
```

## 🗑️ Désinstallation

```bash
# Désinstaller le release
helm uninstall frontend-toolsapps

# Supprimer le namespace (si créé)
kubectl delete namespace production
```

## 📚 Documentation Supplémentaire

- [values.yaml](values.yaml) - Toutes les valeurs configurables
- [values-prod.yaml](values-prod.yaml) - Configuration production
- [values-staging.yaml](values-staging.yaml) - Configuration staging

## 🤝 Support

Pour toute question ou problème :
1. Vérifier les logs des pods
2. Consulter les événements Kubernetes
3. Vérifier l'état du HPA et des pods

## 📄 License

Propriétaire - ToolsApps © 2025

