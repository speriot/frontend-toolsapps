# Backend Auth - API d'authentification ToolsApps

## 📋 Description

API Node.js/Express pour gérer l'authentification des utilisateurs de ToolsApps.

## 🚀 Démarrage rapide

### Installation

```bash
npm install
```

### Développement local

1. Créer un fichier `users-dev.json` avec vos utilisateurs de test:

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

Le hash par défaut dans `users-dev.example.json` correspond au mot de passe `admin123`.

2. Générer un hash pour votre propre mot de passe:

```bash
node generate-hash.js "votre-mot-de-passe"
```

3. Lancer le serveur:

```bash
# Avec variables d'environnement
JWT_SECRET=dev-secret USERS_FILE=./users-dev.json npm start

# Ou avec PowerShell
$env:JWT_SECRET="dev-secret"; $env:USERS_FILE="./users-dev.json"; npm start
```

Le serveur démarre sur http://localhost:3001

## 🔧 Variables d'environnement

| Variable | Description | Défaut |
|----------|-------------|---------|
| `PORT` | Port d'écoute | 3001 |
| `JWT_SECRET` | Secret pour signer les JWT | (requis) |
| `USERS_FILE` | Chemin vers users.json | /app/secrets/users.json |
| `NODE_ENV` | Environnement | development |

## 📡 Endpoints

### POST /api/auth/login

Authentifie un utilisateur.

**Request:**
```json
{
  "email": "admin@toolsapps.eu",
  "password": "admin123"
}
```

**Response (200):**
```json
{
  "success": true,
  "user": {
    "email": "admin@toolsapps.eu",
    "name": "Admin",
    "role": "admin"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response (401):**
```json
{
  "message": "Email ou mot de passe incorrect"
}
```

### GET /api/auth/verify

Vérifie un token JWT.

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "valid": true,
  "user": {
    "email": "admin@toolsapps.eu",
    "name": "Admin",
    "role": "admin"
  }
}
```

### GET /api/health

Vérification de santé du service.

**Response (200):**
```json
{
  "status": "ok",
  "service": "auth-api"
}
```

## 🐳 Docker

### Build

```bash
docker build -t st3ph31/auth-api:v1.0.0 .
```

### Run

```bash
docker run -p 3001:3001 \
  -e JWT_SECRET=your-secret \
  -v $(pwd)/users.json:/app/secrets/users.json \
  st3ph31/auth-api:v1.0.0
```

## 🔐 Sécurité

### Génération de mot de passe

Toujours utiliser le script `generate-hash.js`:

```bash
node generate-hash.js "mon-mot-de-passe-fort"
```

### JWT Secret

En production, générer un secret fort:

```bash
# Linux/Mac
openssl rand -base64 32

# PowerShell
[Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 }))
```

### Format users.json

```json
[
  {
    "email": "user@example.com",
    "passwordHash": "$2a$10$...",
    "name": "User Name",
    "role": "user"
  }
]
```

**Important:** Ne JAMAIS stocker de mots de passe en clair !

## 🧪 Tests

### Test avec curl

```bash
# Login
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@toolsapps.eu","password":"admin123"}'

# Verify (remplacer TOKEN)
curl http://localhost:3001/api/auth/verify \
  -H "Authorization: Bearer TOKEN"

# Health check
curl http://localhost:3001/api/health
```

### Test avec PowerShell

```powershell
# Login
$response = Invoke-RestMethod -Method Post `
  -Uri "http://localhost:3001/api/auth/login" `
  -ContentType "application/json" `
  -Body '{"email":"admin@toolsapps.eu","password":"admin123"}'

$token = $response.token

# Verify
Invoke-RestMethod -Uri "http://localhost:3001/api/auth/verify" `
  -Headers @{"Authorization"="Bearer $token"}
```

## 📦 Dépendances

- **express**: Framework web
- **cors**: Gestion CORS
- **bcryptjs**: Hashage des mots de passe
- **jsonwebtoken**: Génération/vérification JWT

## 🚀 Déploiement Kubernetes

Voir [../GUIDE-AUTHENTIFICATION.md](../GUIDE-AUTHENTIFICATION.md) pour les instructions complètes.

Résumé:

1. Créer les secrets:
```bash
kubectl create secret generic auth-users --from-file=users.json
kubectl create secret generic auth-jwt --from-literal=jwt-secret="..."
```

2. Déployer:
```bash
kubectl apply -f ../helm/auth-api-deployment.yaml
```

## 📝 Logs

Les logs de connexion incluent:
- Tentatives de connexion
- Erreurs d'authentification
- Tokens générés (hash, pas le token complet)

Pour voir les logs en prod:
```bash
kubectl logs -l app=auth-api -f
```

## 🐛 Troubleshooting

### Erreur "Cannot find module"
```bash
npm install
```

### Erreur "USERS_FILE not found"
Créer le fichier users.json ou définir USERS_FILE

### Erreur "JWT must be provided"
Définir la variable JWT_SECRET

### Erreur "Email ou mot de passe incorrect"
- Vérifier que le hash correspond au mot de passe
- Vérifier le format du fichier users.json
- Vérifier les logs du serveur

## 📚 Documentation

- [Guide complet d'authentification](../GUIDE-AUTHENTIFICATION.md)
- [Quickstart](../QUICKSTART-AUTH.md)
- [Résumé d'implémentation](../RESUME-IMPLEMENTATION-AUTH.md)
