# 🔐 Guide d'Authentification ToolsApps

## Vue d'ensemble

Ce guide explique comment mettre en place l'authentification complète pour votre application ToolsApps.

## 📋 Architecture

```
┌─────────────────┐
│   Frontend      │
│   (React)       │
│   - Login Page  │
│   - AuthContext │
└────────┬────────┘
         │
         │ HTTP POST /api/auth/login
         ▼
┌─────────────────┐
│   Auth API      │
│   (Node.js)     │
│   Port: 3001    │
└────────┬────────┘
         │
         │ Read secrets
         ▼
┌─────────────────┐
│  Kubernetes     │
│  Secrets        │
│  - auth-users   │
│  - auth-jwt     │
└─────────────────┘
```

## 🚀 Mise en place rapide

### Étape 1: Installer les dépendances backend

```bash
cd backend-auth
npm install
```

### Étape 2: Générer le hash de mot de passe

```bash
# Générer un hash pour votre mot de passe
node generate-hash.js "votre-mot-de-passe"
```

Copiez le hash généré, vous en aurez besoin pour l'étape suivante.

### Étape 3: Créer les secrets Kubernetes

#### Option A: Utiliser le script PowerShell (Windows)

```powershell
cd helm
.\create-auth-secrets.ps1 -Namespace default
```

Le script vous demandera:
- Email de l'admin
- Mot de passe de l'admin
- Nom de l'admin

#### Option B: Utiliser le script Bash (Linux/Mac)

```bash
cd helm
chmod +x create-auth-secrets.sh
./create-auth-secrets.sh default
```

#### Option C: Créer manuellement

1. Créer le fichier `users.json`:

```json
[
  {
    "email": "admin@toolsapps.eu",
    "passwordHash": "$2a$10$VotreHashIci",
    "name": "Admin",
    "role": "admin"
  }
]
```

2. Créer les secrets:

```bash
# Secret pour les utilisateurs
kubectl create secret generic auth-users \
  --from-file=users.json=users.json \
  --namespace=default

# Secret pour JWT
kubectl create secret generic auth-jwt \
  --from-literal=jwt-secret="votre-secret-jwt-tres-long-et-securise" \
  --namespace=default
```

### Étape 4: Déployer l'API backend

1. Construire l'image Docker:

```bash
cd backend-auth
docker build -t st3ph31/auth-api:v1.0.0 .
docker push st3ph31/auth-api:v1.0.0
```

2. Créer le déploiement Kubernetes:

```bash
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: auth-api
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: auth-api
  template:
    metadata:
      labels:
        app: auth-api
    spec:
      containers:
      - name: auth-api
        image: st3ph31/auth-api:v1.0.0
        ports:
        - containerPort: 3001
        env:
        - name: PORT
          value: "3001"
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: auth-jwt
              key: jwt-secret
        - name: USERS_FILE
          value: "/app/secrets/users.json"
        volumeMounts:
        - name: users-secret
          mountPath: /app/secrets
          readOnly: true
      volumes:
      - name: users-secret
        secret:
          secretName: auth-users
---
apiVersion: v1
kind: Service
metadata:
  name: auth-api
  namespace: default
spec:
  selector:
    app: auth-api
  ports:
  - port: 3001
    targetPort: 3001
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: auth-api
  namespace: default
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - api.toolsapps.eu
    secretName: api-tls
  rules:
  - host: api.toolsapps.eu
    http:
      paths:
      - path: /api/auth
        pathType: Prefix
        backend:
          service:
            name: auth-api
            port:
              number: 3001
EOF
```

### Étape 5: Mettre à jour le frontend

Le frontend est déjà configuré ! Il suffit de rebuild et redéployer:

```bash
# Rebuild le frontend
npm run build

# Build et push l'image Docker
docker build -t st3ph31/frontend-toolsapps:v2.0.0 .
docker push st3ph31/frontend-toolsapps:v2.0.0

# Mettre à jour le déploiement
kubectl set image deployment/frontend-toolsapps \
  frontend=st3ph31/frontend-toolsapps:v2.0.0 \
  -n default
```

## 🧪 Test de l'authentification

### Test en local

1. Démarrer l'API backend:

```bash
cd backend-auth
npm start
```

2. Démarrer le frontend:

```bash
cd ..
npm run dev
```

3. Accéder à http://localhost:5173 et essayer de naviguer
4. Vous serez redirigé vers /login
5. Entrez vos identifiants et connectez-vous

### Test en production

1. Accéder à https://front.toolsapps.eu
2. Vous serez redirigé vers /login
3. Entrez vos identifiants:
   - Email: admin@toolsapps.eu
   - Mot de passe: celui que vous avez défini
4. Après connexion, vous aurez accès à toutes les pages

## 🔑 Gestion des utilisateurs

### Ajouter un utilisateur

1. Générer le hash du mot de passe:

```bash
node backend-auth/generate-hash.js "nouveau-mot-de-passe"
```

2. Récupérer le fichier users.json actuel:

```bash
kubectl get secret auth-users -o jsonpath='{.data.users\.json}' | base64 -d > users.json
```

3. Éditer `users.json` pour ajouter l'utilisateur:

```json
[
  {
    "email": "admin@toolsapps.eu",
    "passwordHash": "$2a$10$...",
    "name": "Admin",
    "role": "admin"
  },
  {
    "email": "user@toolsapps.eu",
    "passwordHash": "$2a$10$...",
    "name": "User",
    "role": "user"
  }
]
```

4. Mettre à jour le secret:

```bash
kubectl create secret generic auth-users \
  --from-file=users.json=users.json \
  --namespace=default \
  --dry-run=client -o yaml | kubectl apply -f -
```

5. Redémarrer l'API:

```bash
kubectl rollout restart deployment/auth-api -n default
```

### Supprimer un utilisateur

1. Suivre les étapes 2-5 ci-dessus en retirant l'utilisateur du fichier JSON

### Changer un mot de passe

1. Suivre les étapes 1-5 de "Ajouter un utilisateur" en modifiant le `passwordHash`

## 🔒 Sécurité

### Bonnes pratiques

1. **Mots de passe forts**: Utilisez des mots de passe d'au moins 12 caractères
2. **JWT Secret**: Générez un secret JWT aléatoire et long
3. **HTTPS obligatoire**: Toujours utiliser HTTPS en production
4. **Secrets Kubernetes**: Ne jamais committer les secrets dans Git
5. **Rotation des secrets**: Changez régulièrement le secret JWT
6. **Logs**: Surveillez les tentatives de connexion échouées

### Variables d'environnement

Backend Auth API:
- `PORT`: Port d'écoute (défaut: 3001)
- `JWT_SECRET`: Secret pour signer les tokens JWT
- `USERS_FILE`: Chemin vers users.json (défaut: /app/secrets/users.json)

Frontend:
- `VITE_API_URL`: URL de l'API (défaut: https://api.toolsapps.eu)

## 📊 Surveillance

### Vérifier l'état des secrets

```bash
# Lister les secrets
kubectl get secrets -n default | grep auth

# Voir le contenu d'un secret (base64 encoded)
kubectl get secret auth-users -o yaml
```

### Logs de l'API

```bash
# Voir les logs de l'API backend
kubectl logs -l app=auth-api -n default --tail=100 -f
```

### Vérifier la santé de l'API

```bash
# Test direct
curl https://api.toolsapps.eu/api/health

# Ou depuis un pod
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://auth-api:3001/api/health
```

## 🐛 Dépannage

### Problème: "Email ou mot de passe incorrect"

1. Vérifier que le hash du mot de passe est correct
2. Vérifier que le secret `auth-users` est bien monté
3. Vérifier les logs de l'API

### Problème: "Erreur serveur lors de la connexion"

1. Vérifier que l'API backend est en cours d'exécution
2. Vérifier les logs de l'API
3. Vérifier la connectivité réseau

### Problème: Redirection infinie vers /login

1. Vérifier que le localStorage contient `auth_user` et `auth_token`
2. Vérifier que le token JWT est valide
3. Vérifier la console du navigateur pour les erreurs

## 📚 Références

- [bcrypt.js Documentation](https://github.com/dcodeIO/bcrypt.js)
- [JWT Documentation](https://jwt.io/)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [React Context API](https://react.dev/reference/react/useContext)

## ✅ Checklist de déploiement

- [ ] Backend auth API déployé et accessible
- [ ] Secrets Kubernetes créés (auth-users, auth-jwt)
- [ ] Frontend mis à jour avec AuthContext
- [ ] Tests de connexion réussis
- [ ] HTTPS activé
- [ ] Mots de passe forts configurés
- [ ] Documentation partagée avec l'équipe
- [ ] Plan de rotation des secrets en place
