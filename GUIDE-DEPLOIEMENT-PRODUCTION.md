# Guide de Déploiement en Production

**Application:** frontend-toolsapps  
**Registry:** docker.io/st3ph31/frontend-toolsapps  
**Production:** front.toolsapps.eu (VPS Hostinger)

## 📋 Prérequis

- Node.js installé localement
- Docker Desktop en cours d'exécution
- Accès SSH au VPS (srv1172005.hstgr.cloud)
- Docker Hub login configuré

## 🚀 Processus de Déploiement Complet

### Étape 1 : Développement local

```bash
# Modifier votre code dans src/
# Tester en dev
npm run dev
```

### Étape 2 : Build de l'application

```bash
# Build de production avec Vite
npm run build

# Vérification : dossier dist/ créé avec les fichiers statiques
ls dist/
```

⚠️ **Important** : Toujours rebuilder l'application avant de créer l'image Docker !

### Étape 3 : Incrémenter la version

```bash
# Choisir la nouvelle version (exemple: v1.1.1, v1.2.0, etc.)
$NEW_VERSION = "v1.2.0"
```

### Étape 4 : Build de l'image Docker

```bash
# Build de l'image avec le nouveau tag
docker build -t st3ph31/frontend-toolsapps:$NEW_VERSION .

# Optionnel : Tagger aussi comme "latest"
docker tag st3ph31/frontend-toolsapps:$NEW_VERSION st3ph31/frontend-toolsapps:latest
```

**Vérification de l'image :**
```bash
docker images st3ph31/frontend-toolsapps
# Doit afficher la nouvelle version avec une date récente
```

### Étape 5 : Push vers Docker Hub

```bash
# Login si nécessaire
docker login

# Push de la version spécifique
docker push st3ph31/frontend-toolsapps:$NEW_VERSION

# Push du tag latest
docker push st3ph31/frontend-toolsapps:latest
```

**Vérification :** https://hub.docker.com/repository/docker/st3ph31/frontend-toolsapps/general

### Étape 6 : Mise à jour du Helm Chart

Modifier le fichier `helm/frontend-toolsapps/values-prod.yaml` :

```yaml
image:
  repository: docker.io/st3ph31/frontend-toolsapps
  pullPolicy: Always  # Important !
  tag: "v1.2.0"  # ← Changer ici
```

Commit et push (optionnel mais recommandé) :

```bash
git add helm/frontend-toolsapps/values-prod.yaml
git commit -m "Deploy v1.2.0 to production"
git push origin main
```

### Étape 7 : Déploiement sur le VPS

```bash
# Connexion SSH au VPS
ssh root@srv1172005.hstgr.cloud

# Aller dans le dossier du projet
cd ~/frontend-toolsapps

# Si vous avez pushé sur GitHub, récupérer les changements
git pull origin main

# Déploiement via Helm
helm upgrade frontend-toolsapps ./helm/frontend-toolsapps \
  --namespace production \
  --values ./helm/frontend-toolsapps/values-prod.yaml \
  --wait

# Affichera : Release "frontend-toolsapps" has been upgraded. Happy Helming!
```

### Étape 8 : Vérification du déploiement

```bash
# Vérifier que les nouveaux pods sont créés
kubectl get pods -n production -l app.kubernetes.io/name=frontend-toolsapps

# Vérifier la version de l'image dans les pods
kubectl get pods -n production -l app.kubernetes.io/name=frontend-toolsapps \
  -o jsonpath='{.items[*].spec.containers[*].image}'

# Doit afficher : docker.io/st3ph31/frontend-toolsapps:v1.2.0

# Vérifier que les pods sont "Running" et "Ready 1/1"
kubectl get pods -n production -w
```

### Étape 9 : Test en production

```bash
# Depuis le VPS
curl -I https://front.toolsapps.eu/
# Doit retourner : HTTP/2 200

# Depuis votre navigateur
# Ouvrir : https://front.toolsapps.eu/
# Vérifier que les changements sont visibles
```

## 🎯 Commandes Rapides (PowerShell)

Script complet pour Windows :

```powershell
# Variables
$NEW_VERSION = "v1.2.0"

# Build de l'application
npm run build

# Build et push Docker
docker build -t st3ph31/frontend-toolsapps:$NEW_VERSION .
docker tag st3ph31/frontend-toolsapps:$NEW_VERSION st3ph31/frontend-toolsapps:latest
docker push st3ph31/frontend-toolsapps:$NEW_VERSION
docker push st3ph31/frontend-toolsapps:latest

# Mise à jour du fichier values-prod.yaml
(Get-Content helm/frontend-toolsapps/values-prod.yaml) `
  -replace 'tag: "v[\d\.]+"', "tag: `"$NEW_VERSION`"" `
  | Set-Content helm/frontend-toolsapps/values-prod.yaml

# Git
git add helm/frontend-toolsapps/values-prod.yaml
git commit -m "Deploy $NEW_VERSION to production"
git push origin main

Write-Host "✅ Image pushée. Connectez-vous au VPS pour déployer :" -ForegroundColor Green
Write-Host "ssh root@srv1172005.hstgr.cloud" -ForegroundColor Cyan
Write-Host "cd ~/frontend-toolsapps && git pull" -ForegroundColor Cyan
Write-Host "helm upgrade frontend-toolsapps ./helm/frontend-toolsapps --namespace production --values ./helm/frontend-toolsapps/values-prod.yaml --wait" -ForegroundColor Cyan
```

## 🔧 Dépannage

### Les pods n'utilisent pas la nouvelle image

```bash
# Forcer la recréation des pods
kubectl rollout restart deployment frontend-toolsapps -n production

# Suivre le rollout
kubectl rollout status deployment frontend-toolsapps -n production
```

### Vérifier les logs d'un pod

```bash
kubectl logs -n production -l app.kubernetes.io/name=frontend-toolsapps --tail=50
```

### Rollback en cas de problème

```bash
# Voir l'historique
helm history frontend-toolsapps -n production

# Rollback vers la version précédente
helm rollback frontend-toolsapps -n production

# Ou vers une révision spécifique
helm rollback frontend-toolsapps 14 -n production
```

### Image non mise à jour malgré le nouveau tag

**Cause :** Image Docker contient l'ancien build  
**Solution :** Toujours faire `npm run build` AVANT `docker build`

```bash
# Nettoyer et reconstruire proprement
rm -rf dist/
npm run build
docker build --no-cache -t st3ph31/frontend-toolsapps:$NEW_VERSION .
docker push st3ph31/frontend-toolsapps:$NEW_VERSION
```

## 📝 Checklist de Déploiement

- [ ] Code modifié et testé en dev
- [ ] `npm run build` exécuté
- [ ] Dossier `dist/` contient les nouveaux fichiers
- [ ] Version incrémentée (ex: v1.1.0 → v1.2.0)
- [ ] `docker build` avec le nouveau tag
- [ ] `docker push` vers Docker Hub
- [ ] Image visible sur https://hub.docker.com/r/st3ph31/frontend-toolsapps
- [ ] `values-prod.yaml` mis à jour avec le nouveau tag
- [ ] Changements committés et pushés sur GitHub
- [ ] SSH sur le VPS
- [ ] `git pull` sur le VPS
- [ ] `helm upgrade` exécuté
- [ ] Pods redémarrés avec la nouvelle image
- [ ] Site accessible sur https://front.toolsapps.eu/
- [ ] Changements visibles dans le navigateur

## ⚠️ Pièges à éviter

1. **Oublier `npm run build`** → L'image Docker contiendra l'ancien code
2. **Même tag Docker** → Kubernetes ne téléchargera pas la nouvelle image
3. **NetworkPolicy incorrecte** → 502 Bad Gateway (voir RESOLUTION-502-NETWORKPOLICY.md)
4. **Cache Docker** → Utiliser `--no-cache` si nécessaire
5. **ImagePullPolicy: IfNotPresent** → Changer en `Always` dans values-prod.yaml

## 🎯 Temps de déploiement typique

- Build local : 30 secondes
- Docker build : 1-2 minutes
- Docker push : 2-3 minutes
- Helm upgrade : 30 secondes
- Rollout des pods : 30-60 secondes

**Total : ~5-7 minutes**

## 📚 Fichiers importants

- **Code source :** `src/`
- **Build :** `dist/`
- **Dockerfile :** `Dockerfile`
- **Helm values prod :** `helm/frontend-toolsapps/values-prod.yaml`
- **Helm chart :** `helm/frontend-toolsapps/`

---

**Dernière mise à jour :** 3 janvier 2026  
**Version actuelle en production :** v1.1.0
