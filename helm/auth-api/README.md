# Auth API Helm Chart

Helm chart pour déployer l'API d'authentification JWT de ToolsApps.

## Installation

### Prérequis

Créer les secrets Kubernetes avant le déploiement :

```bash
# Créer les secrets
cd ../../helm
.\create-auth-secrets.ps1

# Ou manuellement
kubectl create secret generic auth-users --from-file=users.json=users.json
kubectl create secret generic auth-jwt --from-literal=jwt-secret="votre-secret-jwt"
```

### Déploiement en développement

```bash
helm install auth-api . -f values.yaml
```

### Déploiement en production

```bash
helm install auth-api . -f values-prod.yaml --namespace default
```

### Mise à jour

```bash
# Changer la version de l'image dans values-prod.yaml
helm upgrade auth-api . -f values-prod.yaml --namespace default
```

### Désinstallation

```bash
helm uninstall auth-api --namespace default
```

## Configuration

Voir `values.yaml` pour toutes les options de configuration.

### Principales valeurs configurables

| Paramètre | Description | Défaut |
|-----------|-------------|--------|
| `replicaCount` | Nombre de replicas | `2` |
| `image.repository` | Repository Docker | `st3ph31/auth-api` |
| `image.tag` | Tag de l'image | `v1.0.0` |
| `service.port` | Port du service | `3001` |
| `ingress.enabled` | Activer l'ingress | `true` |
| `ingress.hosts[0].host` | Hostname | `api.toolsapps.eu` |
| `resources.limits.cpu` | Limite CPU | `200m` |
| `resources.limits.memory` | Limite mémoire | `256Mi` |
| `autoscaling.enabled` | Activer HPA | `false` |

## Tests

```bash
# Vérifier le déploiement
kubectl get pods -l app.kubernetes.io/name=auth-api

# Tester l'API
curl https://api.toolsapps.eu/api/health

# Voir les logs
kubectl logs -l app.kubernetes.io/name=auth-api --tail=50
```

## Structure des secrets

Le chart nécessite deux secrets :

1. **auth-users** : Contient le fichier `users.json`
   ```json
   [
     {
       "email": "admin@toolsapps.eu",
       "passwordHash": "$2a$10$...",
       "name": "Admin",
       "role": "admin"
     }
   ]
   ```

2. **auth-jwt** : Contient le secret JWT
   ```
   jwt-secret: "votre-secret-tres-long-et-securise"
   ```

## Troubleshooting

### Pods ne démarrent pas

```bash
# Vérifier les events
kubectl describe pod -l app.kubernetes.io/name=auth-api

# Vérifier que les secrets existent
kubectl get secrets | grep auth
```

### Erreur de connexion à l'API

```bash
# Vérifier l'ingress
kubectl get ingress

# Vérifier le service
kubectl get svc auth-api

# Tester depuis un pod
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- curl http://auth-api:3001/api/health
```
