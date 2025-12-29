# 🎯 Helm Charts - Frontend ToolsApps

Configuration Helm professionnelle pour déployer l'application Frontend ToolsApps sur Kubernetes.

## 📁 Structure

```
helm/
├── frontend-toolsapps/          # Helm Chart principal
│   ├── Chart.yaml              # Métadonnées du chart
│   ├── values.yaml             # Configuration par défaut
│   ├── values-prod.yaml        # Configuration production
│   ├── values-staging.yaml     # Configuration staging
│   ├── README.md               # Documentation du chart
│   └── templates/              # Templates Kubernetes
│       ├── deployment.yaml     # Déploiement des pods
│       ├── service.yaml        # Service ClusterIP
│       ├── ingress.yaml        # Ingress HTTPS
│       ├── hpa.yaml            # Autoscaling
│       ├── pdb.yaml            # Haute disponibilité
│       ├── networkpolicy.yaml  # Sécurité réseau
│       ├── serviceaccount.yaml # Identité
│       ├── configmap.yaml      # Configuration
│       ├── _helpers.tpl        # Helpers de templating
│       ├── NOTES.txt           # Post-installation
│       └── tests/              # Tests Helm
│           └── test-connection.yaml
├── GUIDE-DEPLOIEMENT-VPS.md    # Guide de déploiement complet
└── setup-vps.sh                # Script d'installation automatique
```

## 🚀 Déploiement Rapide

### Option 1 : Installation Automatique sur VPS

```bash
# Sur votre VPS Hostinger
wget https://raw.githubusercontent.com/st3ph31/frontend-toolsapps/master/helm/setup-vps.sh
chmod +x setup-vps.sh
sudo ./setup-vps.sh
```

Ce script installe :
- ✅ Docker
- ✅ Kubernetes (K3s)
- ✅ Helm
- ✅ NGINX Ingress Controller
- ✅ cert-manager (SSL automatique)
- ✅ Firewall (UFW)

### Option 2 : Déploiement Manuel

```bash
# Installation du chart
helm install frontend-toolsapps ./frontend-toolsapps \
  --namespace production \
  --create-namespace \
  --values ./frontend-toolsapps/values-prod.yaml
```

## 📋 Prérequis

- Kubernetes 1.24+ (K3s recommandé pour VPS)
- Helm 3.10+
- Ingress Controller NGINX
- cert-manager (pour SSL)
- DNS configuré

## 🎯 Environnements

### Production

```bash
helm install frontend-toolsapps ./frontend-toolsapps \
  --namespace production \
  --values ./frontend-toolsapps/values-prod.yaml
```

**Caractéristiques** :
- 3 réplicas minimum
- Autoscaling 3-20 pods
- SSL obligatoire
- PodDisruptionBudget activé
- Network Policies activées

### Staging

```bash
helm install frontend-toolsapps ./frontend-toolsapps \
  --namespace staging \
  --values ./frontend-toolsapps/values-staging.yaml
```

**Caractéristiques** :
- 2 réplicas minimum
- Autoscaling 2-5 pods
- Domaine : staging.front.toolsapps.eu

## 🔧 Configuration

### Paramètres Clés

| Paramètre | Production | Staging | Par Défaut |
|-----------|------------|---------|------------|
| `replicaCount` | 3 | 2 | 2 |
| `autoscaling.minReplicas` | 3 | 2 | 2 |
| `autoscaling.maxReplicas` | 20 | 5 | 10 |
| `resources.requests.cpu` | 200m | 150m | 100m |
| `resources.requests.memory` | 256Mi | 192Mi | 128Mi |

### Surcharge de Valeurs

```bash
# Via --set
helm install frontend-toolsapps ./frontend-toolsapps \
  --set image.tag=v1.0.1 \
  --set replicaCount=5

# Via fichier custom
helm install frontend-toolsapps ./frontend-toolsapps \
  -f my-custom-values.yaml
```

## 📊 Fonctionnalités Incluses

### 1. Haute Disponibilité
- ✅ Multi-réplicas avec anti-affinity
- ✅ PodDisruptionBudget (min 1 pod toujours disponible)
- ✅ Rolling updates sans downtime
- ✅ Readiness et liveness probes

### 2. Autoscaling
- ✅ HorizontalPodAutoscaler (HPA)
- ✅ Scale basé sur CPU et mémoire
- ✅ Min/Max réplicas configurables

### 3. Sécurité
- ✅ SecurityContext strict (non-root, read-only filesystem)
- ✅ Network Policies (trafic limité)
- ✅ ServiceAccount dédié
- ✅ SSL/TLS automatique (Let's Encrypt)

### 4. Monitoring
- ✅ Health checks (liveness, readiness)
- ✅ Métriques Prometheus (optionnel)
- ✅ Logs centralisés

## 🔄 Mises à Jour

### Nouvelle Version de l'Image

```bash
helm upgrade frontend-toolsapps ./frontend-toolsapps \
  --namespace production \
  --set image.tag=v1.0.2 \
  --reuse-values
```

### Changement de Configuration

```bash
helm upgrade frontend-toolsapps ./frontend-toolsapps \
  --namespace production \
  --values ./frontend-toolsapps/values-prod.yaml
```

### Rollback

```bash
# Voir l'historique
helm history frontend-toolsapps -n production

# Rollback
helm rollback frontend-toolsapps -n production
```

## 🧪 Tests

### Lint du Chart

```bash
helm lint ./frontend-toolsapps
```

### Dry-Run

```bash
helm install frontend-toolsapps ./frontend-toolsapps \
  --namespace production \
  --dry-run --debug
```

### Test Post-Installation

```bash
helm test frontend-toolsapps -n production
```

## 🐛 Dépannage

### Voir les Pods

```bash
kubectl get pods -n production
kubectl describe pod <pod-name> -n production
kubectl logs -f <pod-name> -n production
```

### Voir l'Ingress

```bash
kubectl get ingress -n production
kubectl describe ingress -n production
```

### Voir le Certificat SSL

```bash
kubectl get certificate -n production
kubectl describe certificate -n production
```

### Voir l'Autoscaling

```bash
kubectl get hpa -n production
kubectl describe hpa -n production
```

## 📚 Documentation

- **[GUIDE-DEPLOIEMENT-VPS.md](GUIDE-DEPLOIEMENT-VPS.md)** - Guide complet étape par étape
- **[frontend-toolsapps/README.md](frontend-toolsapps/README.md)** - Documentation du chart
- **[frontend-toolsapps/values.yaml](frontend-toolsapps/values.yaml)** - Toutes les options

## 🔗 Liens Utiles

- [Documentation Helm](https://helm.sh/docs/)
- [Documentation K3s](https://docs.k3s.io/)
- [Documentation NGINX Ingress](https://kubernetes.github.io/ingress-nginx/)
- [Documentation cert-manager](https://cert-manager.io/docs/)

## 🤝 Support

Pour toute question ou problème :
1. Consultez [GUIDE-DEPLOIEMENT-VPS.md](GUIDE-DEPLOIEMENT-VPS.md)
2. Vérifiez les logs des pods
3. Vérifiez les événements Kubernetes

## 📄 License

Propriétaire - ToolsApps © 2025

---

**Prêt pour un déploiement production-ready ! 🚀**

