# 🎯 MIGRATION EN 1 COMMANDE

## 🚀 La méthode la plus simple

Ouvrez PowerShell et exécutez :

```powershell
cd P:\Hostinger\frontend-app
.\MIGRATE-TO-LOCAL.ps1
```

**C'est tout !** Le script fait tout automatiquement :
- ✅ Copie le projet en local (C:\Dev\frontend-app)
- ✅ Nettoie et réinstalle les dépendances
- ✅ Configure le HMR
- ✅ Lance le serveur

---

## 📋 Ou en manuel (si vous préférez)

```powershell
# 1. Créer le dossier
mkdir C:\Dev

# 2. Copier le projet
xcopy P:\Hostinger\frontend-app C:\Dev\frontend-app /E /I /H /Y

# 3. Aller dans le projet
cd C:\Dev\frontend-app

# 4. Nettoyer et réinstaller
Remove-Item -Recurse -Force node_modules
Remove-Item -Force package-lock.json
npm install

# 5. Lancer le serveur
npm run dev
```

---

## ✅ Après la migration

### Ouvrir : http://localhost:3000

**Le HMR fonctionne maintenant !**
- Modifiez un fichier `.jsx`
- Sauvegardez (Ctrl+S)
- 👀 Le navigateur se met à jour AUTOMATIQUEMENT

---

## 💾 Sauvegarder vers pCloud

### En fin de journée ou quand vous avez terminé :

```powershell
cd C:\Dev\frontend-app
# Copier le script depuis pCloud d'abord
copy P:\Hostinger\frontend-app\sync-to-pcloud.ps1 .
# Lancer la sauvegarde
.\sync-to-pcloud.ps1
```

### Ou manuellement :

```powershell
xcopy C:\Dev\frontend-app P:\Hostinger\frontend-app /E /I /H /Y
```

---

## 🎉 C'est fait !

Vous avez maintenant :
- ✅ Projet en LOCAL (C:\Dev\frontend-app)
- ✅ HMR activé (rechargement automatique)
- ✅ Performances maximales
- ✅ Backup sur pCloud

**Bon développement ! 🚀**

