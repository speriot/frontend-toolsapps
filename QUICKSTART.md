# ⚡ DÉMARRAGE RAPIDE

## 🎯 Migration vers Local (1 commande)

```powershell
cd P:\Hostinger\frontend-app
.\MIGRATE-TO-LOCAL.ps1
```

Puis ouvrez : **http://localhost:3000**

---

## 💾 Sauvegarder vers pCloud

```powershell
cd C:\Dev\frontend-app
xcopy . P:\Hostinger\frontend-app /E /I /H /Y
```

Ou utilisez le script (à copier depuis pCloud d'abord) :
```powershell
.\sync-to-pcloud.ps1
```

---

## 🔥 Tester le HMR

1. Modifiez `C:\Dev\frontend-app\src\pages\Home.jsx`
2. Sauvegardez (Ctrl+S)
3. 👀 Le navigateur se met à jour automatiquement !

---

## 📖 Documentation complète

- **README-MIGRATION.md** - Guide ultra-rapide
- **GUIDE-MIGRATION-LOCAL.md** - Guide détaillé complet

---

## ✅ Avantages

- ✅ HMR activé (rechargement auto)
- ✅ 10x plus rapide
- ✅ Plus de conflits pCloud/antivirus
- ✅ Workflow fluide

---

**Bon développement ! 🚀**

