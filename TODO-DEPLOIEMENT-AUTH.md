# ✅ TODO - Déploiement de l'authentification

## 🎯 Résumé

Votre application frontend est maintenant protégée par un système d'authentification complet !

## 📦 Ce qui a été créé

- ✅ Frontend avec AuthContext, ProtectedRoute et page Login
- ✅ Backend API Node.js pour l'authentification
- ✅ Scripts de gestion des secrets Kubernetes
- ✅ Déploiement Kubernetes complet
- ✅ Documentation détaillée

## 🚀 Pour déployer (dans l'ordre)

### 1️⃣ Installer les dépendances backend

```powershell
cd backend-auth
npm install
```

### 2️⃣ Créer les secrets Kubernetes

```powershell
cd ..\helm
.\create-auth-secrets.ps1
```

**Identifiants par défaut suggérés:**
- Email: admin@toolsapps.eu
- Mot de passe: *(créez un mot de passe fort !)*
- Nom: Admin

### 3️⃣ Déployer l'API backend sur Kubernetes

```powershell
# Build et push l'image Docker
cd ..\backend-auth
docker build -t st3ph31/auth-api:v1.0.0 .
docker push st3ph31/auth-api:v1.0.0

# Déployer sur Kubernetes
kubectl apply -f ..\helm\auth-api-deployment.yaml

# Vérifier le déploiement
kubectl get pods -l app=auth-api
kubectl logs -l app=auth-api --tail=20
```

### 4️⃣ Mettre à jour le frontend

```powershell
cd ..

# Rebuild le frontend
npm run build

# Build et push l'image
docker build -t st3ph31/frontend-toolsapps:v2.0.0 .
docker push st3ph31/frontend-toolsapps:v2.0.0

# Mettre à jour le déploiement Kubernetes
kubectl set image deployment/frontend-toolsapps `
  frontend=st3ph31/frontend-toolsapps:v2.0.0 `
  -n default

# Vérifier
kubectl rollout status deployment/frontend-toolsapps
```

### 5️⃣ Tester l'authentification

1. Accéder à https://front.toolsapps.eu
2. Vous serez redirigé vers /login
3. Entrer vos identifiants
4. Vérifier l'accès aux pages protégées

## 🧪 Test en local (optionnel)

Pour tester avant de déployer:

```powershell
# Terminal 1 - Backend
cd backend-auth
$env:JWT_SECRET="dev-secret-key"
$env:USERS_FILE="./users-dev.json"

# Créer users-dev.json (copier depuis users-dev.example.json)
Copy-Item users-dev.example.json users-dev.json

npm start
# API sur http://localhost:3001

# Terminal 2 - Frontend
cd ..
npm run dev
# Frontend sur http://localhost:5173
```

**Identifiants de test:**
- Email: admin@toolsapps.eu
- Mot de passe: admin123

## 📚 Documentation

- **[QUICKSTART-AUTH.md](QUICKSTART-AUTH.md)** - Démarrage rapide (lisez en premier !)
- **[GUIDE-AUTHENTIFICATION.md](GUIDE-AUTHENTIFICATION.md)** - Guide complet
- **[RESUME-IMPLEMENTATION-AUTH.md](RESUME-IMPLEMENTATION-AUTH.md)** - Résumé technique
- **[backend-auth/README.md](backend-auth/README.md)** - Documentation API

## 🔑 Commandes utiles

### Voir les secrets

```powershell
kubectl get secrets | Select-String "auth"
```

### Voir les logs de l'API

```powershell
kubectl logs -l app=auth-api --tail=50 -f
```

### Tester l'API

```powershell
# Health check
curl https://api.toolsapps.eu/api/health

# Login (remplacer email/password)
Invoke-RestMethod -Method Post `
  -Uri "https://api.toolsapps.eu/api/auth/login" `
  -ContentType "application/json" `
  -Body '{"email":"admin@toolsapps.eu","password":"votre-mdp"}'
```

### Ajouter un utilisateur

1. Générer le hash:
```powershell
node backend-auth\generate-hash.js "nouveau-mot-de-passe"
```

2. Récupérer users.json:
```powershell
kubectl get secret auth-users -o jsonpath='{.data.users\.json}' | 
  ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) } |
  Out-File users.json
```

3. Éditer `users.json` pour ajouter l'utilisateur

4. Mettre à jour le secret:
```powershell
kubectl create secret generic auth-users `
  --from-file=users.json=users.json `
  --namespace=default `
  --dry-run=client -o yaml | kubectl apply -f -
```

5. Redémarrer l'API:
```powershell
kubectl rollout restart deployment/auth-api
```

## ⚠️ Important

### Avant de déployer en production:

- [ ] Changer les mots de passe par défaut
- [ ] Utiliser des mots de passe forts (12+ caractères)
- [ ] Générer un JWT_SECRET aléatoire fort
- [ ] Ne JAMAIS committer users.json ou les secrets dans Git
- [ ] Activer HTTPS (déjà fait si vous avez Traefik/cert-manager)
- [ ] Tester la connexion/déconnexion
- [ ] Vérifier les logs de l'API

### Après le déploiement:

- [ ] Tester l'authentification
- [ ] Vérifier que toutes les pages sont protégées
- [ ] Tester la déconnexion
- [ ] Vérifier le bouton de déconnexion
- [ ] Tester sur mobile
- [ ] Documenter les identifiants (de façon sécurisée !)

## 🎉 C'est prêt !

Une fois ces étapes complétées, votre application sera entièrement protégée par authentification.

Toutes les pages nécessiteront une connexion, et seule la page `/login` sera publique.

## 💡 Prochaines améliorations possibles

- 🔄 Ajout d'un système de réinitialisation de mot de passe
- 📧 Envoi d'email de confirmation
- 🔐 Authentification à deux facteurs (2FA)
- 👥 Gestion des rôles et permissions avancées
- 📊 Dashboard d'administration des utilisateurs
- 🕒 Historique des connexions
- 🚫 Verrouillage après X tentatives échouées

## 🆘 Besoin d'aide ?

Consultez la section **Dépannage** dans [GUIDE-AUTHENTIFICATION.md](GUIDE-AUTHENTIFICATION.md#-dépannage)
