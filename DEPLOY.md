# Frontend ToolsApps

Application frontend React avec Vite, Tailwind CSS et React Router.

## 🚀 Quick Start

### Développement Local

```bash
npm install
npm run dev
```

L'application sera disponible sur http://localhost:3000

### Build de Production

```bash
npm run build
npm run preview
```

## 🐳 Docker

### Build de l'image

```bash
docker build -t frontend-toolsapps .
```

### Lancer le conteneur

```bash
docker run -d -p 80:80 --name frontend frontend-toolsapps
```

### Push vers un registry

```bash
# Tag de l'image
docker tag frontend-toolsapps votre-registry/frontend-toolsapps:latest

# Push vers le registry
docker push votre-registry/frontend-toolsapps:latest
```

## 📦 Stack Technique

- **React 19.2.3** - Framework UI
- **Vite 7.3.0** - Build tool et dev server
- **Tailwind CSS 3.4.19** - Framework CSS utilitaire
- **React Router 7.11.0** - Routing côté client
- **Axios** - Client HTTP

## 🏗️ Structure du Projet

```
frontend-app/
├── src/
│   ├── components/      # Composants réutilisables
│   ├── pages/          # Pages de l'application
│   ├── App.jsx         # Composant racine
│   ├── main.jsx        # Point d'entrée
│   └── index.css       # Styles globaux
├── public/             # Assets statiques
├── Dockerfile          # Configuration Docker multi-stage
├── nginx.conf          # Configuration Nginx pour production
└── vite.config.js      # Configuration Vite

```

## 🔧 Configuration

### Variables d'Environnement

Créez un fichier `.env.local` pour la configuration locale :

```env
VITE_API_URL=https://api.toolsapps.eu
```

### Optimisations de Performance

- **HMR (Hot Module Replacement)** : Activé en développement local
- **Code Splitting** : Vendor chunks séparés (React, React Router)
- **Compression Gzip** : Activée dans Nginx
- **Cache HTTP** : Assets statiques cachés 1 an
- **Source Maps** : Générés pour le debugging

## 🌐 Déploiement

L'application est configurée pour être déployée avec :
- **Nginx** comme serveur web
- **Docker** pour la conteneurisation
- **Multi-stage build** pour une image optimale (~20MB)

### Configuration Nginx

- SPA routing : toutes les routes redirigent vers index.html
- Proxy API : `/api` redirige vers `https://api.toolsapps.eu`
- Headers de sécurité : X-Frame-Options, X-Content-Type-Options, etc.
- Compression GZIP pour tous les assets

## 📝 Scripts Disponibles

- `npm run dev` - Démarre le serveur de développement
- `npm run build` - Build de production
- `npm run preview` - Prévisualise le build de production
- `npm run lint` - Vérifie le code avec ESLint

## 🔒 Sécurité

- `.env.local` exclu du contrôle de version
- `.dockerignore` configuré pour exclure les fichiers sensibles
- Headers de sécurité HTTP configurés dans Nginx
- Dependencies régulièrement mises à jour

## 📄 License

Propriétaire - ToolsApps © 2025

