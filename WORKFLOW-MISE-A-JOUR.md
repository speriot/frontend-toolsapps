# 🎯 WORKFLOW DE MISE À JOUR - GUIDE RAPIDE

## 📋 Votre application est maintenant en production !

**URLs :**
- HTTP : http://front.toolsapps.eu
- HTTPS : https://front.toolsapps.eu

---

## 🔄 WORKFLOW COMPLET DE MISE À JOUR

### 1️⃣ Sur votre machine locale (Windows)

#### A. Développement
```powershell
cd C:\dev\frontend-app
npm run dev
# Testez vos modifications sur http://localhost:3000
```

#### B. Build et Push Docker
```powershell
# Incrémentez la version (v1.0.0 → v1.0.1)
.\deploy-docker.ps1 -Registry "docker.io/st3ph31" -Tag "v1.0.1"
```

#### C. Commit et Push Git
```powershell
git add .
git commit -m "feat: Ajout nouvelle fonctionnalité"
git push
```

### 2️⃣ Sur votre VPS (Linux)

#### A. Récupérer les derniers changements
```bash
cd ~/frontend-toolsapps
git pull origin main
```

#### B. Déployer la nouvelle version
```bash
helm upgrade frontend-toolsapps ./helm/frontend-toolsapps \
  --namespace production \
  --set image.tag=v1.0.1 \
  --wait
```

#### C. Vérifier le déploiement
```bash
./helm/verify-deployment.sh
kubectl get pods -n production
```

---

## 🚀 COMMANDES UTILES

### Vérifications
```bash
# État complet
./helm/verify-deployment.sh

# Pods
kubectl get pods -n production

# Logs
kubectl logs -n production -l app.kubernetes.io/name=frontend-toolsapps -f

# Certificat SSL
kubectl get certificate -n production
```

### Redémarrage
```bash
# Redémarrage sans interruption
kubectl rollout restart deployment/frontend-toolsapps -n production
```

### Rollback
```bash
# Retour version précédente
helm rollback frontend-toolsapps -n production
```

---

## 📅 APRÈS LE 31 DÉCEMBRE 2025

### Passer en certificat SSL production

```bash
cd ~/frontend-toolsapps
./helm/switch-to-production.sh
```

Votre site aura le cadenas vert ! 🔐✅

---

## 📚 DOCUMENTATION COMPLÈTE

- `MISSION-ACCOMPLIE.md` - Célébration et bilan
- `FELICITATIONS.md` - Guide complet
- `DEPLOIEMENT-SUCCESS.md` - Documentation technique
- `COMMANDES-RAPIDES.md` - Référence complète
- `RÉSUMÉ-SESSION-29-12-2025.md` - Récapitulatif session

---

**🎊 Profitez de votre application en production ! 🎊**

