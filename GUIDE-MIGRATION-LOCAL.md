# 🚀 Guide de Migration : pCloud → Disque Local

## 🎯 Pourquoi déplacer le projet ?

**Avantages du développement en LOCAL :**
- ✅ **HMR activé** : Rechargement automatique instantané
- ✅ **Performances maximales** : Pas de latence réseau
- ✅ **Pas de conflits** : Antivirus et pCloud n'interfèrent plus
- ✅ **Workflow fluide** : Vite fonctionne à 100% de ses capacités
- ✅ **Sauvegarde cloud** : pCloud reste votre backup

---

## 📋 Étapes de migration

### ✅ Étape 1 : Arrêter le serveur actuel

Si un serveur tourne sur le projet pCloud, arrêtez-le (Ctrl+C)

```powershell
# Vérifier qu'aucun Node ne tourne
Get-Process | Where-Object {$_.ProcessName -like "*node*"} | Stop-Process -Force
```

---

### ✅ Étape 2 : Créer le dossier local

```powershell
# Créer le dossier de développement sur C:
mkdir C:\Dev
```

---

### ✅ Étape 3 : Copier le projet

```powershell
# Copier TOUT le projet depuis pCloud vers C:
xcopy P:\Hostinger\frontend-app C:\Dev\frontend-app /E /I /H /Y

# Vérifier que la copie est complète
cd C:\Dev\frontend-app
dir
```

**⏱️ Durée estimée :** 2-5 minutes (selon la taille de `node_modules`)

---

### ✅ Étape 4 : Nettoyer et réinstaller (optionnel mais recommandé)

```powershell
cd C:\Dev\frontend-app

# Supprimer node_modules et package-lock.json
Remove-Item -Recurse -Force node_modules
Remove-Item -Force package-lock.json

# Réinstaller proprement
npm install
```

**⏱️ Durée estimée :** 2-3 minutes

---

### ✅ Étape 5 : Lancer le serveur avec HMR

```powershell
cd C:\Dev\frontend-app
npm run dev
```

Ouvrez : **http://localhost:3000**

**🎉 Le HMR fonctionne maintenant !**

---

## 🔥 Test du HMR

1. **Ouvrez** `C:\Dev\frontend-app\src\pages\Home.jsx`
2. **Modifiez** le texte "Bienvenue sur ToolsApps" 
3. **Sauvegardez** (Ctrl+S)
4. 👀 **Regardez le navigateur** : la page se met à jour **AUTOMATIQUEMENT** sans F5 !

---

## 💾 Workflow de sauvegarde pCloud

### Option 1 : Sauvegarde manuelle (recommandé)

**En fin de journée ou quand vous avez terminé :**

```powershell
# Sauvegarder tout le projet vers pCloud
xcopy C:\Dev\frontend-app P:\Hostinger\frontend-app /E /I /H /Y
```

### Option 2 : Sauvegarde sélective (plus rapide)

**Sauvegarder uniquement le code source (sans node_modules) :**

```powershell
# Sauvegarder src/
xcopy C:\Dev\frontend-app\src P:\Hostinger\frontend-app\src /E /I /H /Y

# Sauvegarder les fichiers de config
copy C:\Dev\frontend-app\package.json P:\Hostinger\frontend-app\package.json
copy C:\Dev\frontend-app\vite.config.js P:\Hostinger\frontend-app\vite.config.js
copy C:\Dev\frontend-app\tailwind.config.js P:\Hostinger\frontend-app\tailwind.config.js
```

### Option 3 : Script automatique

J'ai créé un script PowerShell pour vous (voir ci-dessous) : `sync-to-pcloud.ps1`

---

## 📦 Structure recommandée

```
C:\Dev\frontend-app\          ← Votre environnement de développement (LOCAL)
    ├── node_modules/
    ├── src/
    ├── public/
    └── package.json

P:\Hostinger\frontend-app\     ← Votre backup cloud (pCloud)
    ├── src/                   ← Sauvegardez régulièrement
    ├── public/
    └── package.json
    └── (pas besoin de node_modules ici)
```

---

## ⚙️ Configuration Antivirus (recommandé)

Pour des performances optimales, **excluez le dossier local** de l'analyse en temps réel :

### McAfee
1. Ouvrir McAfee
2. Paramètres → Analyse en temps réel → Fichiers exclus
3. Ajouter : `C:\Dev\frontend-app\node_modules`

### MalwareBytes
1. Ouvrir MalwareBytes
2. Paramètres → Exclusions
3. Ajouter : `C:\Dev\frontend-app\node_modules`

### Windows Defender
```powershell
# Ajouter l'exclusion via PowerShell (en tant qu'Admin)
Add-MpPreference -ExclusionPath "C:\Dev\frontend-app\node_modules"
```

---

## 🎯 Workflow quotidien recommandé

### 🌅 Le matin (si vous avez modifié depuis un autre PC)

```powershell
# Synchroniser depuis pCloud
xcopy P:\Hostinger\frontend-app C:\Dev\frontend-app /E /I /H /Y /D

# Lancer le dev
cd C:\Dev\frontend-app
npm run dev
```

### 💻 Pendant la journée

Travaillez normalement en **LOCAL** (`C:\Dev\frontend-app`)
- Modifications automatiquement rechargées (HMR)
- Performances maximales
- Aucune interférence

### 🌙 Le soir

```powershell
# Sauvegarder vers pCloud
.\sync-to-pcloud.ps1

# Ou manuellement
xcopy C:\Dev\frontend-app P:\Hostinger\frontend-app /E /I /H /Y
```

---

## 📝 Scripts PowerShell utiles

### sync-to-pcloud.ps1 (créé pour vous)
Sauvegarde automatique vers pCloud

### sync-from-pcloud.ps1 (créé pour vous)
Récupération depuis pCloud

---

## ✅ Avantages de cette approche

| Aspect | pCloud (avant) | Local (maintenant) |
|--------|----------------|-------------------|
| **HMR** | ❌ Désactivé | ✅ Activé |
| **Performances** | ⚠️ Moyennes | ✅ Excellentes |
| **Rafraîchissement auto** | ❌ Non | ✅ Oui |
| **Build speed** | ⚠️ Lent | ✅ Rapide |
| **Sauvegarde cloud** | ✅ Automatique | ✅ Manuelle (fin de journée) |
| **Conflits antivirus** | ❌ Fréquents | ✅ Rares |

---

## 🆘 En cas de problème

### Le HMR ne fonctionne toujours pas ?

```powershell
# Nettoyer le cache Vite
cd C:\Dev\frontend-app
Remove-Item -Recurse -Force node_modules/.vite
npm run dev
```

### Erreur "port 3000 already in use" ?

```powershell
# Tuer tous les processus Node
Get-Process | Where-Object {$_.ProcessName -like "*node*"} | Stop-Process -Force

# Relancer
npm run dev
```

### Le projet pCloud est désynchronisé ?

```powershell
# Forcer la synchronisation complète
xcopy C:\Dev\frontend-app P:\Hostinger\frontend-app /E /I /H /Y
```

---

## 🎉 Félicitations !

Vous avez maintenant :
- ✅ Un environnement de développement **local ultra-rapide**
- ✅ Le **HMR activé** pour un workflow fluide
- ✅ Un **backup cloud automatique** sur pCloud
- ✅ **Aucun conflit** avec les antivirus

**Bon développement ! 🚀**

---

## 📞 Besoin d'aide ?

Si vous avez des questions sur :
- La migration
- Les scripts de synchronisation
- La configuration
- Tout autre aspect

N'hésitez pas à demander ! 😊

