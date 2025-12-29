# 🚀 Guide GitHub pour speriot - Déploiement Frontend ToolsApps

## ✅ Compte GitHub Détecté

**Votre compte** : https://github.com/speriot

---

## 📋 ÉTAPE 1 : Créer le Dépôt sur GitHub

### 1️⃣ Créer le Nouveau Repository

**Option A : Via l'interface web (Recommandé)**

1. Aller sur : **https://github.com/new**
2. Ou cliquer sur le **+** en haut à droite → **New repository**

3. Remplir le formulaire :
   ```
   Owner: speriot
   Repository name: frontend-toolsapps
   Description: Frontend React with Vite, Tailwind CSS and Helm charts for Kubernetes deployment
   Public ✅ (ou Private si vous préférez)
   
   ❌ NE PAS cocher "Add a README file"
   ❌ NE PAS cocher "Add .gitignore"
   ❌ NE PAS cocher "Choose a license"
   ```

4. Cliquer sur **Create repository**

**Option B : Via GitHub CLI (si installé)**

```powershell
gh repo create speriot/frontend-toolsapps --public --description "Frontend React with Helm charts for Kubernetes"
```

---

## 📋 ÉTAPE 2 : Préparer le Repository Local

### 2️⃣ Initialiser Git (si pas déjà fait)

```powershell
cd C:\dev\frontend-app

# Vérifier si Git est initialisé
git status

# Si erreur "not a git repository", initialiser :
git init
git add .
git commit -m "Initial commit - Frontend React + Vite + Tailwind with Helm charts"
```

### 3️⃣ Ajouter le Remote GitHub

```powershell
# Ajouter le remote (remplacer par votre URL exacte)
git remote add origin https://github.com/speriot/frontend-toolsapps.git

# Vérifier
git remote -v
# Devrait afficher :
# origin  https://github.com/speriot/frontend-toolsapps.git (fetch)
# origin  https://github.com/speriot/frontend-toolsapps.git (push)
```

---

## 📋 ÉTAPE 3 : Configurer l'Authentification

GitHub a désactivé les mots de passe pour Git. Vous devez utiliser un **Personal Access Token (PAT)**.

### 4️⃣ Créer un Token GitHub

1. Aller sur : **https://github.com/settings/tokens**
2. Ou : **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**

3. Cliquer sur **Generate new token** → **Generate new token (classic)**

4. Remplir :
   ```
   Note: Frontend ToolsApps Deployment
   Expiration: 90 days (ou No expiration)
   
   Scopes à cocher :
   ✅ repo (Full control of private repositories)
      ✅ repo:status
      ✅ repo_deployment
      ✅ public_repo
      ✅ repo:invite
   ```

5. Cliquer sur **Generate token**

6. **COPIER LE TOKEN IMMÉDIATEMENT** (vous ne pourrez plus le voir après)
   ```
   ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

### 5️⃣ Alternative : GitHub CLI (Plus Simple)

Si vous avez GitHub CLI installé :

```powershell
# Installer GitHub CLI
winget install GitHub.cli

# Authentification
gh auth login
# Choisir :
# - GitHub.com
# - HTTPS
# - Yes (authentifier avec le navigateur)
```

---

## 📋 ÉTAPE 4 : Pusher vers GitHub

### 6️⃣ Premier Push

```powershell
cd C:\dev\frontend-app

# Renommer la branche en main (standard GitHub)
git branch -M main

# Premier push
git push -u origin main
```

**Si demande de credentials** :
- **Username** : `speriot`
- **Password** : `ghp_xxxxxxxxxxxx` (le token créé à l'étape 4)

### 7️⃣ Sauvegarder les Credentials (Optionnel)

Pour ne pas retaper le token à chaque fois :

```powershell
# Windows Credential Manager
git config --global credential.helper wincred

# Ou Git Credential Manager (recommandé)
git config --global credential.helper manager-core
```

---

## 📋 ÉTAPE 5 : Vérification

### 8️⃣ Vérifier sur GitHub

1. Aller sur : **https://github.com/speriot/frontend-toolsapps**
2. Vous devriez voir tous vos fichiers
3. Vérifier que le dossier `helm/` est présent

---

## 📋 ÉTAPE 6 : Déploiement sur le VPS

### 9️⃣ Maintenant que le dépôt est public, sur votre VPS :

```bash
# Se connecter au VPS
ssh root@votre-vps-ip

# Installer l'environnement K3s + Helm (si pas déjà fait)
wget https://raw.githubusercontent.com/speriot/frontend-toolsapps/main/helm/setup-vps.sh
chmod +x setup-vps.sh
./setup-vps.sh

# Cloner le projet
git clone https://github.com/speriot/frontend-toolsapps.git
cd frontend-toolsapps

# Déployer avec Helm
helm install frontend-toolsapps helm/frontend-toolsapps \
  --namespace production \
  --create-namespace \
  --values helm/frontend-toolsapps/values-prod.yaml

# Vérifier le déploiement
kubectl get pods -n production
kubectl get ingress -n production
kubectl get certificate -n production
```

---

## 🔄 Workflow de Mise à Jour

### Pour les Futures Modifications

**Sur votre machine Windows** :

```powershell
cd C:\dev\frontend-app

# Faire vos modifications...

# Committer
git add .
git commit -m "feat: Description des changements"

# Pusher
git push
```

**Sur le VPS** :

```bash
cd frontend-toolsapps

# Récupérer les dernières modifications
git pull

# Mettre à jour le déploiement Helm
helm upgrade frontend-toolsapps helm/frontend-toolsapps \
  --namespace production \
  --values helm/frontend-toolsapps/values-prod.yaml
```

---

## 📊 Checklist Complète

- [ ] **Étape 1** : Dépôt créé sur https://github.com/new
- [ ] **Étape 2** : Git initialisé localement (`git init`)
- [ ] **Étape 3** : Remote ajouté (`git remote add origin`)
- [ ] **Étape 4** : Token GitHub créé (https://github.com/settings/tokens)
- [ ] **Étape 5** : Code pushé (`git push -u origin main`)
- [ ] **Étape 6** : Vérification sur GitHub (https://github.com/speriot/frontend-toolsapps)
- [ ] **Étape 7** : VPS configuré (K3s + Helm)
- [ ] **Étape 8** : Code cloné sur le VPS (`git clone`)
- [ ] **Étape 9** : Application déployée (`helm install`)
- [ ] **Étape 10** : Vérification (`kubectl get pods`)

---

## 🐛 Dépannage

### Erreur : "not a git repository"

```powershell
cd C:\dev\frontend-app
git init
git add .
git commit -m "Initial commit"
```

### Erreur : "remote origin already exists"

```powershell
git remote remove origin
git remote add origin https://github.com/speriot/frontend-toolsapps.git
```

### Erreur : "Authentication failed"

- Vérifier que vous utilisez le **token** et non votre mot de passe
- Recréer un token : https://github.com/settings/tokens

### Erreur : "rejected because remote contains work"

```powershell
# Si vous avez initialisé avec un README sur GitHub
git pull origin main --allow-unrelated-histories
git push -u origin main
```

---

## 📞 Support

Si vous rencontrez un problème :

1. Vérifier les messages d'erreur
2. Vérifier que le token a les bons scopes
3. Vérifier que le dépôt GitHub est créé
4. Consulter : https://docs.github.com/en/authentication

---

## 🎯 Résumé des URLs Importantes

| Quoi | URL |
|------|-----|
| Créer un repo | https://github.com/new |
| Vos repos | https://github.com/speriot?tab=repositories |
| Créer un token | https://github.com/settings/tokens |
| Le nouveau repo | https://github.com/speriot/frontend-toolsapps |
| Setup VPS script | https://raw.githubusercontent.com/speriot/frontend-toolsapps/main/helm/setup-vps.sh |

---

## ✅ Prochaines Étapes

1. **Créer le dépôt** sur GitHub (Étape 1)
2. **Pusher le code** (Étapes 2-5)
3. **Déployer sur VPS** (Étape 6)

**Commencez par l'Étape 1 !** 🚀

---

🎉 **Une fois pushé, tout sera automatique sur le VPS avec `git clone` !**

*Guide créé le 2025-12-29 pour speriot*
*ToolsApps © 2025*

