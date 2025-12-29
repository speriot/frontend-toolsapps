# 🚀 Guide de Transfert vers le VPS

## 📍 Situation Actuelle

✅ **Image Docker** : Pushée sur Docker Hub  
⚠️ **Fichiers Helm** : Uniquement en local (`C:\dev\frontend-app`)  
❌ **Pas de dépôt Git distant** configuré

---

## 🎯 3 Méthodes pour Transférer les Fichiers Helm

---

## MÉTHODE 1 : Via GitHub (Recommandé) ⭐

### Pourquoi ?
- ✅ Versioning et historique
- ✅ Backup automatique
- ✅ Facile à mettre à jour
- ✅ Partage avec équipe possible
- ✅ Standard de l'industrie

### Étapes

#### 1️⃣ Créer le Dépôt sur GitHub

1. Aller sur https://github.com/new
2. Remplir :
   - **Repository name** : `frontend-toolsapps`
   - **Description** : `Frontend React with Helm charts for Kubernetes`
   - **Public** ou **Private** : votre choix
   - ❌ **NE PAS** cocher "Initialize with README"
3. Cliquer sur **Create repository**

#### 2️⃣ Sur Votre Machine Windows

```powershell
cd C:\dev\frontend-app

# Ajouter le remote GitHub
git remote add origin https://github.com/st3ph31/frontend-toolsapps.git

# Vérifier
git remote -v

# Pusher tous les commits
git branch -M master
git push -u origin master
```

Si vous avez une erreur d'authentification :
```powershell
# Méthode avec token (GitHub a désactivé les mots de passe)
# Aller sur : https://github.com/settings/tokens
# Generate new token (classic) → Cocher "repo"
# Utiliser le token comme mot de passe lors du push
```

#### 3️⃣ Sur le VPS

```bash
# Installation de l'environnement (si pas déjà fait)
wget https://get.k3s.io | sudo sh -
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Cloner le projet
git clone https://github.com/st3ph31/frontend-toolsapps.git
cd frontend-toolsapps

# Déployer
helm install frontend-toolsapps helm/frontend-toolsapps \
  --namespace production \
  --create-namespace \
  --values helm/frontend-toolsapps/values-prod.yaml
```

#### 4️⃣ Pour les Mises à Jour

```bash
# Sur le VPS
cd frontend-toolsapps
git pull
helm upgrade frontend-toolsapps helm/frontend-toolsapps \
  --namespace production \
  --values helm/frontend-toolsapps/values-prod.yaml
```

---

## MÉTHODE 2 : Via SCP (Direct)

### Pourquoi ?
- ✅ Rapide et simple
- ✅ Pas besoin de GitHub
- ✅ Contrôle total

### Étapes

#### 1️⃣ Obtenir l'IP de Votre VPS

Depuis votre panel Hostinger, notez l'IP : `XXX.XXX.XXX.XXX`

#### 2️⃣ Sur Votre Machine Windows

```powershell
# Transférer le dossier helm complet
scp -r C:\dev\frontend-app\helm root@XXX.XXX.XXX.XXX:/root/

# Ou avec un nom d'utilisateur spécifique
scp -r C:\dev\frontend-app\helm user@XXX.XXX.XXX.XXX:/home/user/
```

Si vous n'avez pas `scp` sur Windows :
```powershell
# Utiliser WinSCP (interface graphique)
# Télécharger : https://winscp.net/

# Ou utiliser WSL
wsl scp -r /mnt/c/dev/frontend-app/helm root@XXX.XXX.XXX.XXX:/root/
```

#### 3️⃣ Sur le VPS

```bash
# Vérifier que les fichiers sont là
ls -la /root/helm

# Déployer
helm install frontend-toolsapps /root/helm/frontend-toolsapps \
  --namespace production \
  --create-namespace \
  --values /root/helm/frontend-toolsapps/values-prod.yaml
```

#### 4️⃣ Pour les Mises à Jour

```powershell
# Sur Windows (re-copier)
scp -r C:\dev\frontend-app\helm root@XXX.XXX.XXX.XXX:/root/
```

```bash
# Sur le VPS
helm upgrade frontend-toolsapps /root/helm/frontend-toolsapps \
  --namespace production \
  --values /root/helm/frontend-toolsapps/values-prod.yaml
```

---

## MÉTHODE 3 : Via Helm Package

### Pourquoi ?
- ✅ Un seul fichier `.tgz`
- ✅ Versionné proprement
- ✅ Facile à archiver

### Étapes

#### 1️⃣ Sur Votre Machine Windows

```powershell
cd C:\dev\frontend-app

# Packager le chart
helm package helm/frontend-toolsapps

# Résultat : frontend-toolsapps-1.0.0.tgz
```

#### 2️⃣ Transférer le Package

```powershell
scp frontend-toolsapps-1.0.0.tgz root@XXX.XXX.XXX.XXX:/root/
```

#### 3️⃣ Sur le VPS

```bash
# Déployer depuis le package
helm install frontend-toolsapps /root/frontend-toolsapps-1.0.0.tgz \
  --namespace production \
  --create-namespace \
  --set image.tag=v1.0.0

# Ou avec un fichier values externe
helm install frontend-toolsapps /root/frontend-toolsapps-1.0.0.tgz \
  --namespace production \
  --create-namespace \
  -f /root/values-prod.yaml
```

#### 4️⃣ Pour les Mises à Jour

```powershell
# Sur Windows
helm package helm/frontend-toolsapps  # Crée 1.0.1
scp frontend-toolsapps-1.0.1.tgz root@XXX.XXX.XXX.XXX:/root/
```

```bash
# Sur le VPS
helm upgrade frontend-toolsapps /root/frontend-toolsapps-1.0.1.tgz \
  --namespace production
```

---

## 📊 Comparaison des Méthodes

| Critère | GitHub | SCP | Helm Package |
|---------|--------|-----|--------------|
| **Setup initial** | Moyen | Facile | Facile |
| **Versioning** | ✅ Excellent | ❌ Manuel | ⚠️ Basique |
| **Mises à jour** | ✅ `git pull` | ⚠️ Re-copier | ⚠️ Re-transférer |
| **Backup** | ✅ Automatique | ❌ Manuel | ❌ Manuel |
| **Partage équipe** | ✅ Excellent | ❌ Difficile | ⚠️ Possible |
| **Sécurité** | ✅ Bon | ✅ Bon | ✅ Bon |

---

## 🎯 Recommandation

### Pour Production → **Méthode 1 (GitHub)** ⭐

**Pourquoi** :
- Standard de l'industrie
- Versioning automatique
- Facile à maintenir
- Backup gratuit
- Historique complet

### Pour Test Rapide → **Méthode 2 (SCP)**

**Pourquoi** :
- Le plus rapide pour tester
- Pas de setup GitHub nécessaire

### Pour Archivage → **Méthode 3 (Package)**

**Pourquoi** :
- Un seul fichier
- Facile à archiver
- Versionning clair

---

## ⚠️ Rappel Important

**Quelle que soit la méthode choisie** :

1. **L'image Docker** est déjà sur Docker Hub ✅
2. **Kubernetes téléchargera automatiquement** l'image depuis Docker Hub
3. **Les fichiers Helm** servent juste d'instructions de déploiement
4. **Le code source React** ne va JAMAIS sur le VPS

---

## 🚀 Action Immédiate

**Choisissez votre méthode** :

1. **Méthode 1** → Je vous guide pour créer le dépôt GitHub
2. **Méthode 2** → Je vous donne les commandes SCP exactes
3. **Méthode 3** → Je vous guide pour packager et transférer

**Quelle méthode préférez-vous ?**

---

## 📝 Notes

- Votre VPS Hostinger doit avoir **Kubernetes (K3s)** et **Helm** installés
- Utilisez le script `helm/setup-vps.sh` pour installer tout automatiquement
- Le DNS `front.toolsapps.eu` doit pointer vers l'IP du VPS

---

🎯 **Prêt à déployer ! Dites-moi quelle méthode vous voulez utiliser !**

