# 🚀 Démarrage Rapide - Authentification

## Configuration en 5 minutes

### 1️⃣ Installer les dépendances backend (une seule fois)

```powershell
cd backend-auth
npm install
```

### 2️⃣ Créer les secrets Kubernetes

```powershell
cd helm
.\create-auth-secrets.ps1
```

Le script vous demandera:
- **Email**: admin@toolsapps.eu (par défaut)
- **Mot de passe**: admin123 (par défaut - **changez-le en production!**)
- **Nom**: Admin (par défaut)

### 3️⃣ Déployer l'API backend

```powershell
cd ..\backend-auth

# Build l'image
docker build -t st3ph31/auth-api:v1.0.0 .
docker push st3ph31/auth-api:v1.0.0

# Déployer sur Kubernetes
kubectl apply -f ..\helm\auth-api-deployment.yaml
```

### 4️⃣ Mettre à jour le frontend

```powershell
cd ..

# Rebuild le frontend
npm run build

# Build et push l'image
docker build -t st3ph31/frontend-toolsapps:v2.0.0 .
docker push st3ph31/frontend-toolsapps:v2.0.0

# Mettre à jour le déploiement
kubectl set image deployment/frontend-toolsapps `
  frontend=st3ph31/frontend-toolsapps:v2.0.0 `
  -n default
```

### 5️⃣ Tester l'authentification

Accédez à https://front.toolsapps.eu

Vous serez automatiquement redirigé vers la page de connexion.

**Identifiants par défaut:**
- Email: `admin@toolsapps.eu`
- Mot de passe: `admin123`

## ✅ C'est fait !

Votre application est maintenant protégée par authentification !

## 🔧 Test en local

Si vous voulez tester en local avant de déployer:

```powershell
# Terminal 1 - API Backend
cd backend-auth
$env:JWT_SECRET="dev-secret-key-change-in-production"
npm start

# Terminal 2 - Frontend
cd ..
npm run dev
```

Accédez à http://localhost:5173

## 📚 Documentation complète

Pour plus de détails, consultez [GUIDE-AUTHENTIFICATION.md](GUIDE-AUTHENTIFICATION.md)

## 🔑 Commandes utiles

### Voir les secrets

```powershell
kubectl get secrets -n default | Select-String "auth"
```

### Voir les logs de l'API

```powershell
kubectl logs -l app=auth-api -n default --tail=50
```

### Ajouter un utilisateur

1. Générer le hash:
```powershell
node backend-auth\generate-hash.js "nouveau-mot-de-passe"
```

2. Récupérer et modifier users.json:
```powershell
kubectl get secret auth-users -o jsonpath='{.data.users\.json}' | 
  ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) } |
  Out-File users.json
```

3. Éditer `users.json` pour ajouter l'utilisateur

4. Mettre à jour:
```powershell
kubectl create secret generic auth-users `
  --from-file=users.json=users.json `
  --namespace=default `
  --dry-run=client -o yaml | kubectl apply -f -

kubectl rollout restart deployment/auth-api -n default
```

## ⚠️ Important pour la production

1. **Changez les mots de passe par défaut**
2. **Générez un JWT_SECRET aléatoire fort**
3. **Ne commitez JAMAIS les secrets dans Git**
4. **Activez HTTPS en production**
5. **Surveillez les logs de connexion**
