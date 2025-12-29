# Frontend ToolsApps

Application React moderne construite avec Vite, TailwindCSS et déployée sur Kubernetes.

## 🚀 Démarrage rapide

### Prérequis
- Node.js 18+ 
- npm ou yarn

### Installation

```bash
# Installer les dépendances
npm install

# Lancer le serveur de développement
npm run dev

# Accéder à http://localhost:3000
```

### Build pour la production

```bash
# Build l'application
npm run build

# Prévisualiser le build
npm run preview
```

## 🐋 Docker

### Build de l'image Docker

```bash
# Build l'image
docker build -t frontend-toolsapps:latest .

# Lancer le conteneur
docker run -p 8080:80 frontend-toolsapps:latest

# Accéder à http://localhost:8080
```

### Push vers un registry

```bash
# Tag l'image
docker tag frontend-toolsapps:latest myregistry.io/frontend-toolsapps:v1.0.0

# Push vers le registry
docker push myregistry.io/frontend-toolsapps:v1.0.0
```

## ☸️ Déploiement Kubernetes avec Helm

### Depuis le dossier parent

```bash
cd ../helm-charts

# Déployer avec l'image Docker
helm upgrade --install frontend ./frontend \
  --namespace default \
  --set image.repository=myregistry.io/frontend-toolsapps \
  --set image.tag=v1.0.0
```

### Vérifier le déploiement

```bash
# Voir les pods
kubectl get pods -n default

# Voir l'ingress
kubectl get ingress -n default

# Accéder à https://front.toolsapps.eu
```

## 📦 Stack Technologique

- **React 18** - Bibliothèque UI
- **Vite 5** - Build tool ultra-rapide
- **TailwindCSS 3** - Framework CSS utility-first
- **React Router 6** - Routing côté client
- **Axios** - Client HTTP
- **Composants** - Inspirés de shadcn/ui

## 📁 Structure du projet

```
frontend-app/
├── public/              # Fichiers statiques
├── src/
│   ├── components/      # Composants réutilisables
│   │   ├── Button.jsx
│   │   ├── Card.jsx
│   │   └── Layout.jsx
│   ├── pages/           # Pages de l'application
│   │   ├── Home.jsx
│   │   ├── About.jsx
│   │   └── ApiTest.jsx
│   ├── App.jsx          # Composant principal
│   ├── main.jsx         # Point d'entrée
│   └── index.css        # Styles globaux
├── Dockerfile           # Multi-stage build
├── nginx.conf           # Configuration nginx
└── package.json         # Dépendances npm
```

## 🎨 Personnalisation

### Modifier les couleurs

Éditez `tailwind.config.js` et `src/index.css` pour changer le thème.

### Ajouter une page

1. Créer un fichier dans `src/pages/MaPage.jsx`
2. Ajouter la route dans `src/App.jsx`
3. Ajouter le lien dans `src/components/Layout.jsx`

### Variables d'environnement

Créer un fichier `.env.local`:

```env
VITE_API_URL=https://api.toolsapps.eu
VITE_APP_NAME=ToolsApps
```

Utiliser dans le code:

```javascript
const apiUrl = import.meta.env.VITE_API_URL
```

## 🔧 Configuration Kubernetes (Helm)

### values.yaml personnalisé

```yaml
image:
  repository: myregistry.io/frontend-toolsapps
  tag: v1.0.0

replicaCount: 2

env:
  - name: VITE_API_URL
    value: "https://api.toolsapps.eu"

configMap:
  enabled: true
  data:
    config.json: |
      {
        "apiUrl": "https://api.toolsapps.eu",
        "environment": "production"
      }
```

## 📊 Commandes utiles

```bash
# Développement
npm run dev              # Lancer le dev server
npm run build            # Build pour production
npm run preview          # Prévisualiser le build

# Docker
docker build -t frontend .
docker run -p 8080:80 frontend

# Kubernetes
kubectl get pods
kubectl logs -l app.kubernetes.io/name=frontend
kubectl describe ingress
```

## 🌐 Accès

- **Développement**: http://localhost:3000
- **Production**: https://front.toolsapps.eu
- **API**: https://api.toolsapps.eu

## 📝 License

Copyright © 2024 Stephane Periot

## 🤝 Contact

Email: stephane.periot@gmail.com

