# 🚀 Frontend ToolsApps

Application frontend moderne déployée en production avec React, Vite, Tailwind CSS et Kubernetes.

[![React](https://img.shields.io/badge/React-18.3.1-blue.svg)](https://reactjs.org/)
[![Vite](https://img.shields.io/badge/Vite-5.4.21-646CFF.svg)](https://vitejs.dev/)
[![Tailwind CSS](https://img.shields.io/badge/Tailwind-3.4.19-38B2AC.svg)](https://tailwindcss.com/)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED.svg)](https://www.docker.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-Deployed-326CE5.svg)](https://kubernetes.io/)
[![Production](https://img.shields.io/badge/Status-Live-success.svg)](https://front.toolsapps.eu)

## 🌐 Application en Production

**URL Production :** https://front.toolsapps.eu  
**Status :** 🟢 Opérationnel  
**Déployé le :** 29 Décembre 2025

---

## 🎯 Quick Start

### Développement Local

```powershell
# Installation des dépendances
npm install

# Démarrage du serveur de dev
npm run dev
```

L'application sera disponible sur **http://localhost:3000** avec HMR activé.

### Build de Production

```powershell
# Build optimisé
npm run build

# Prévisualiser le build
npm run preview
```

---

## 📚 Documentation Complète

- 🎉 **[FELICITATIONS.md](./FELICITATIONS.md)** - Guide de félicitations et premiers pas
- 📊 **[DEPLOIEMENT-SUCCESS.md](./DEPLOIEMENT-SUCCESS.md)** - Documentation complète du déploiement
- ⚡ **[COMMANDES-RAPIDES.md](./COMMANDES-RAPIDES.md)** - Référence rapide des commandes VPS
- 🔧 **[helm/FIX-404-LABELS.md](./helm/FIX-404-LABELS.md)** - Résolution du problème 404 (résolu)
- ☸️ **[helm/README.md](./helm/README.md)** - Documentation Helm Charts

---

## 🐳 Docker

### Déploiement Automatisé (Recommandé)

```powershell
# Script automatisé complet
.\deploy-docker.ps1 -Registry "docker.io/USERNAME" -Tag "v1.0.0"
```

Le script effectue :
- ✅ Vérification de Docker
- ✅ Build npm
- ✅ Build de l'image Docker
- ✅ Test local
- ✅ Tag et push vers le registry

### Build Manuel

```powershell
# Build de l'image
docker build -t frontend-toolsapps .

# Test local
docker run -d -p 8080:80 --name frontend-test frontend-toolsapps

# Vérifier
curl http://localhost:8080
```

---

## 📦 Stack Technique

| Technologie | Version | Description |
|-------------|---------|-------------|
| **React** | 19.2.3 | Framework UI |
| **React Router** | 7.11.0 | Routing SPA |
| **Vite** | 7.3.0 | Build tool ultra-rapide |
| **Tailwind CSS** | 3.4.19 | Framework CSS utilitaire |
| **Axios** | 1.6.2 | Client HTTP |
| **Nginx** | Alpine | Serveur web production |

---

## 🏗️ Structure du Projet

```
frontend-app/
├── src/
│   ├── components/          # Composants réutilisables
│   │   ├── Button.jsx
│   │   ├── Card.jsx
│   │   └── Layout.jsx
│   ├── pages/               # Pages de l'application
│   │   ├── Home.jsx
│   │   ├── About.jsx
│   │   └── ApiTest.jsx
│   ├── App.jsx              # Composant racine avec routing
│   ├── main.jsx             # Point d'entrée
│   └── index.css            # Styles globaux + Tailwind
├── public/                  # Assets statiques
├── Dockerfile               # Multi-stage build optimisé
├── nginx.conf               # Config Nginx pour production
├── deploy-docker.ps1        # Script de déploiement automatisé
├── verify-before-deploy.ps1 # Script de vérification
└── vite.config.js           # Config Vite optimisée
```

---

## 🔧 Configuration

### Variables d'Environnement

Créez un fichier `.env.local` :

```env
VITE_API_URL=https://api.toolsapps.eu
```

> ⚠️ Les variables `VITE_*` sont intégrées au moment du build, pas au runtime !

### Optimisations Activées

- ✅ **HMR** (Hot Module Replacement) - Rechargement instantané
- ✅ **Code Splitting** - Chunks séparés pour vendor (React, Router)
- ✅ **Compression GZIP** - Activée dans Nginx
- ✅ **Cache HTTP** - Assets statiques cachés 1 an
- ✅ **Source Maps** - Pour debugging en production

---

## 📋 Scripts Disponibles

| Script | Commande | Description |
|--------|----------|-------------|
| **Dev** | `npm run dev` | Serveur de développement avec HMR |
| **Build** | `npm run build` | Build de production optimisé |
| **Preview** | `npm run preview` | Prévisualise le build localement |
| **Lint** | `npm run lint` | Vérifie le code avec ESLint |

---

## ☸️ Déploiement Kubernetes + Helm

### Architecture Production

L'application est déployée sur un VPS Hostinger avec :
- **Kubernetes (K3s)** - Orchestration
- **Helm Charts** - Gestion des déploiements
- **Nginx Ingress** - Reverse proxy et Load Balancer
- **cert-manager** - Certificats SSL/TLS automatiques (Let's Encrypt)
- **3 réplicas** - Haute disponibilité
- **Autoscaling** - Scale de 2 à 5 pods selon la charge

### Déploiement Initial

```bash
# Sur le VPS
cd ~/frontend-toolsapps
./helm/deploy-app.sh
```

### Mise à jour de l'application

**Sur votre machine locale :**
```powershell
# 1. Build et push de la nouvelle image
.\deploy-docker.ps1 -Registry "docker.io/st3ph31" -Tag "v1.0.1"

# 2. Commit et push des changements
git add .
git commit -m "feat: New feature"
git push
```

**Sur le VPS :**
```bash
# 3. Récupérer les changements et redéployer
cd ~/frontend-toolsapps
git pull origin main

helm upgrade frontend-toolsapps ./helm/frontend-toolsapps \
  --namespace production \
  --set image.tag=v1.0.1 \
  --wait
```

### Commandes Kubernetes Utiles

```bash
# Voir les pods
kubectl get pods -n production

# Voir les logs
kubectl logs -n production -l app.kubernetes.io/name=frontend-toolsapps

# Redémarrer l'application
kubectl rollout restart deployment/frontend-toolsapps -n production

# Vérification complète
./helm/verify-deployment.sh
```

Consultez **[COMMANDES-RAPIDES.md](./COMMANDES-RAPIDES.md)** pour plus de commandes.

---

## 🚀 Déploiement Docker Simple

### 1. Vérification Pré-Déploiement

```powershell
.\verify-before-deploy.ps1
```

### 2. Déploiement avec Docker

```powershell
# Méthode automatisée
.\deploy-docker.ps1 -Registry "docker.io/USERNAME" -Tag "v1.0.0"

# Ou manuellement
docker build -t frontend-toolsapps:v1.0.0 .
docker tag frontend-toolsapps:v1.0.0 USERNAME/frontend-toolsapps:v1.0.0
docker push USERNAME/frontend-toolsapps:v1.0.0
```

### 3. Sur le Serveur

```bash
# Pull et démarrage
docker pull USERNAME/frontend-toolsapps:v1.0.0
docker stop frontend-toolsapps 2>/dev/null || true
docker rm frontend-toolsapps 2>/dev/null || true
docker run -d -p 80:80 --name frontend-toolsapps \
  --restart unless-stopped \
  USERNAME/frontend-toolsapps:v1.0.0
```

---

## 📚 Documentation Complète

| Document | Description |
|----------|-------------|
| **GUIDE-DEPLOYMENT-COMPLET.md** | Guide détaillé de déploiement |
| **CHECKLIST-DEPLOYMENT.md** | Checklist de validation |
| **DEPLOY.md** | Documentation technique |
| **QUICKSTART.md** | Guide de démarrage rapide |

---

## 🔒 Sécurité

- ✅ `.env.local` exclu du contrôle de version
- ✅ `.dockerignore` configuré
- ✅ Headers de sécurité HTTP (Nginx)
- ✅ Dépendances régulièrement mises à jour
- ✅ Pas de secrets en dur dans le code

---

## ⚠️ Points d'Attention

### Ne PAS Faire
- ❌ **Upgrader Tailwind vers v4** (breaking changes majeurs)
- ❌ **Travailler depuis pCloud/OneDrive** (problèmes de performance)
- ❌ **Committer .env.local** (déjà ignoré par Git)

### Bonnes Pratiques
- ✅ **Projet sur disque local** (`C:\dev\frontend-app`)
- ✅ **Utiliser des tags de version** pour Docker
- ✅ **Tester localement** avant de déployer
- ✅ **Monitorer les logs** en production

---

## 🐛 Dépannage

### Logs Docker

```bash
docker logs -f frontend-toolsapps
```

### Redémarrage

```bash
docker restart frontend-toolsapps
```

### Rebuild Complet

```powershell
.\deploy-docker.ps1 -Registry "registry" -Tag "new-version"
```

---

## 📊 Monitoring

### Santé du Conteneur

```bash
# Statut
docker ps --filter name=frontend-toolsapps

# Ressources
docker stats frontend-toolsapps

# Inspection détaillée
docker inspect frontend-toolsapps
```

---

## 🤝 Support

Pour toute question ou problème :
1. Consultez la documentation dans `GUIDE-DEPLOYMENT-COMPLET.md`
2. Vérifiez les logs Docker
3. Lancez `.\verify-before-deploy.ps1` pour diagnostiquer

---

## 📄 License

Propriétaire - ToolsApps © 2025

---

## 🎊 Status

✅ **Production Ready**  
✅ Docker testé et validé  
✅ Documentation complète  
✅ Scripts automatisés  
✅ Optimisations activées

**Prêt pour le déploiement !** 🚀

