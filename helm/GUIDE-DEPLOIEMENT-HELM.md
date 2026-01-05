# 🚀 Guide de Déploiement - ToolsApps avec Authentification

Ce guide explique comment déployer les deux services de ToolsApps en utilisant Helm.

## 📦 Structure des Charts Helm

```
helm/
├── frontend-toolsapps/          # Chart pour le frontend React
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── values-prod.yaml
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── ingress.yaml
│       ├── hpa.yaml
│       └── ...
│
└── auth-api/                    # Chart pour l'API d'authentification
    ├── Chart.yaml
    ├── values.yaml
    ├── values-prod.yaml
    └── templates/
        ├── deployment.yaml
        ├── service.yaml
        ├── ingress.yaml
        ├── hpa.yaml
        └── ...
```

## 🎯 Déploiement Complet

### Étape 1: Créer les secrets Kubernetes

```powershell
cd helm
.\create-auth-secrets.ps1
```

Cela créera :
- `auth-users` : Contient users.json
- `auth-jwt` : Contient le secret JWT

### Étape 2: Build et push des images Docker

#### Backend Auth API

```powershell
cd backend-auth

# Build
docker build -t st3ph31/auth-api:v1.0.0 .

# Push
docker push st3ph31/auth-api:v1.0.0
```

#### Frontend

```powershell
cd ..

# Build l'application
npm run build

# Build l'image Docker
docker build -t st3ph31/frontend-toolsapps:v2.0.0 .

# Push
docker push st3ph31/frontend-toolsapps:v2.0.0
```

### Étape 3: Déployer avec Helm

#### Déployer l'API d'authentification

```powershell
cd helm\auth-api

# Installation
helm install auth-api . -f values-prod.yaml --namespace default

# Ou mise à jour si déjà installé
helm upgrade auth-api . -f values-prod.yaml --namespace default
```

#### Déployer le Frontend

```powershell
cd ..\frontend-toolsapps

# Mettre à jour la version dans values-prod.yaml
# image.tag: "v2.0.0"

# Installation
helm install frontend-toolsapps . -f values-prod.yaml --namespace default

# Ou mise à jour si déjà installé
helm upgrade frontend-toolsapps . -f values-prod.yaml --namespace default
```

## 🔧 Commandes Utiles

### Vérifier les déploiements

```powershell
# Lister tous les releases Helm
helm list --namespace default

# Statut du déploiement
kubectl get pods
kubectl get services
kubectl get ingress

# Logs
kubectl logs -l app.kubernetes.io/name=auth-api --tail=50
kubectl logs -l app.kubernetes.io/name=frontend-toolsapps --tail=50
```

### Mise à jour d'une image

```powershell
# Auth API
helm upgrade auth-api ./helm/auth-api -f ./helm/auth-api/values-prod.yaml `
  --set image.tag=v1.0.1 `
  --namespace default

# Frontend
helm upgrade frontend-toolsapps ./helm/frontend-toolsapps -f ./helm/frontend-toolsapps/values-prod.yaml `
  --set image.tag=v2.0.1 `
  --namespace default
```

### Rollback en cas de problème

```powershell
# Voir l'historique
helm history auth-api --namespace default
helm history frontend-toolsapps --namespace default

# Rollback
helm rollback auth-api 1 --namespace default
helm rollback frontend-toolsapps 1 --namespace default
```

### Désinstallation

```powershell
# Désinstaller les applications
helm uninstall auth-api --namespace default
helm uninstall frontend-toolsapps --namespace default

# Supprimer les secrets (optionnel)
kubectl delete secret auth-users auth-jwt --namespace default
```

## 📊 Vérification Post-Déploiement

### 1. Vérifier que les pods sont running

```powershell
kubectl get pods
```

Attendu :
```
NAME                                  READY   STATUS    RESTARTS   AGE
auth-api-xxxxxxxxxx-xxxxx            1/1     Running   0          2m
auth-api-xxxxxxxxxx-xxxxx            1/1     Running   0          2m
frontend-toolsapps-xxxxxxxxxx-xxxxx  1/1     Running   0          2m
frontend-toolsapps-xxxxxxxxxx-xxxxx  1/1     Running   0          2m
frontend-toolsapps-xxxxxxxxxx-xxxxx  1/1     Running   0          2m
```

### 2. Tester l'API d'authentification

```powershell
# Health check
curl https://api.toolsapps.eu/api/health

# Login test
Invoke-RestMethod -Method Post `
  -Uri "https://api.toolsapps.eu/api/auth/login" `
  -ContentType "application/json" `
  -Body '{"email":"admin@toolsapps.eu","password":"votre-mdp"}'
```

### 3. Tester le Frontend

Accédez à https://front.toolsapps.eu
- Vous devriez être redirigé vers `/login`
- Connectez-vous avec vos identifiants
- Vérifiez l'accès aux pages

## 🔄 Workflow de Mise à Jour

### Mise à jour du Frontend

1. Faire les modifications du code
2. Tester en local
3. Build : `npm run build`
4. Build Docker : `docker build -t st3ph31/frontend-toolsapps:vX.Y.Z .`
5. Push : `docker push st3ph31/frontend-toolsapps:vX.Y.Z`
6. Update Helm :
   ```powershell
   helm upgrade frontend-toolsapps ./helm/frontend-toolsapps `
     -f ./helm/frontend-toolsapps/values-prod.yaml `
     --set image.tag=vX.Y.Z `
     --namespace default
   ```

### Mise à jour du Backend Auth

1. Faire les modifications du code
2. Tester en local
3. Build Docker : `docker build -t st3ph31/auth-api:vX.Y.Z .`
4. Push : `docker push st3ph31/auth-api:vX.Y.Z`
5. Update Helm :
   ```powershell
   helm upgrade auth-api ./helm/auth-api `
     -f ./helm/auth-api/values-prod.yaml `
     --set image.tag=vX.Y.Z `
     --namespace default
   ```

## 🔐 Gestion des Secrets

### Mise à jour des utilisateurs

1. Récupérer le fichier actuel :
   ```powershell
   kubectl get secret auth-users -o jsonpath='{.data.users\.json}' | `
     ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) } | `
     Out-File users.json
   ```

2. Éditer `users.json`

3. Mettre à jour le secret :
   ```powershell
   kubectl create secret generic auth-users `
     --from-file=users.json=users.json `
     --namespace=default `
     --dry-run=client -o yaml | kubectl apply -f -
   ```

4. Redémarrer les pods :
   ```powershell
   kubectl rollout restart deployment/auth-api --namespace default
   ```

### Rotation du JWT Secret

1. Générer nouveau secret :
   ```powershell
   $jwtSecret = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object {[char]$_})
   ```

2. Mettre à jour :
   ```powershell
   kubectl create secret generic auth-jwt `
     --from-literal=jwt-secret="$jwtSecret" `
     --namespace=default `
     --dry-run=client -o yaml | kubectl apply -f -
   ```

3. Redémarrer :
   ```powershell
   kubectl rollout restart deployment/auth-api --namespace default
   ```

## 📈 Scaling

### Manuel

```powershell
# Auth API
kubectl scale deployment auth-api --replicas=5 --namespace default

# Frontend
kubectl scale deployment frontend-toolsapps --replicas=10 --namespace default
```

### Auto-scaling (HPA)

Déjà configuré dans `values-prod.yaml` :

**Auth API** :
- Min: 2 replicas
- Max: 10 replicas
- Target CPU: 70%

**Frontend** :
- Min: 3 replicas
- Max: 20 replicas
- Target CPU: 70%

```powershell
# Voir le statut HPA
kubectl get hpa
```

## 🐛 Troubleshooting

### Pods ne démarrent pas

```powershell
# Voir les events
kubectl describe pod <pod-name>

# Voir les logs
kubectl logs <pod-name>
```

### Problème de secrets

```powershell
# Vérifier que les secrets existent
kubectl get secrets | Select-String "auth"

# Vérifier le contenu (base64)
kubectl get secret auth-users -o yaml
```

### Problème d'ingress

```powershell
# Vérifier l'ingress
kubectl get ingress
kubectl describe ingress auth-api
kubectl describe ingress frontend-toolsapps

# Vérifier le certificat SSL
kubectl get certificate
```

### Problème de connexion entre services

```powershell
# Test depuis un pod
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- `
  curl http://auth-api:3001/api/health
```

## 📚 Documentation

- [Guide Auth Complet](../GUIDE-AUTHENTIFICATION.md)
- [Quickstart Auth](../QUICKSTART-AUTH.md)
- [README Auth API Chart](./auth-api/README.md)
- [README Frontend Chart](./frontend-toolsapps/README.md)

## ✅ Checklist de Déploiement

- [ ] Secrets créés (auth-users, auth-jwt)
- [ ] Images Docker buildées et pushées
- [ ] Auth API déployé avec Helm
- [ ] Frontend déployé avec Helm
- [ ] Pods en status Running
- [ ] Ingress configurés
- [ ] Certificats SSL valides
- [ ] Test API health check OK
- [ ] Test login frontend OK
- [ ] HPA configuré et actif
- [ ] Logs propres sans erreurs
