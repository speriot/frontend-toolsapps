# ✅ CHECKLIST - Déploiement Authentification

Cochez au fur et à mesure de votre progression !

## 📋 Préparation

- [ ] Node.js installé (vérifier : `node --version`)
- [ ] kubectl configuré (vérifier : `kubectl get nodes`)
- [ ] Docker installé et connecté (vérifier : `docker ps`)
- [ ] Accès à votre cluster Kubernetes
- [ ] Frontend actuel fonctionne sur https://front.toolsapps.eu

## 🔧 Configuration Backend

- [ ] Naviguer vers `backend-auth`
- [ ] Installer les dépendances : `npm install`
- [ ] Tester génération de hash : `node generate-hash.js "test123"`
- [ ] Hash généré correctement

## 🔐 Création des Secrets

- [ ] Décider d'un mot de passe admin **fort** (noter de façon sécurisée)
- [ ] Exécuter : `.\helm\create-auth-secrets.ps1`
- [ ] Email admin entré : ________________
- [ ] Mot de passe admin entré (ne pas noter ici !)
- [ ] Nom admin entré : ________________
- [ ] Script terminé avec succès
- [ ] Vérifier secrets : `kubectl get secrets | Select-String "auth"`
- [ ] Voir `auth-users` et `auth-jwt` dans la liste

## 🚢 Déploiement API Backend

- [ ] Build image : `docker build -t st3ph31/auth-api:v1.0.0 .`
- [ ] Push image : `docker push st3ph31/auth-api:v1.0.0`
- [ ] Déployer : `kubectl apply -f ..\helm\auth-api-deployment.yaml`
- [ ] Vérifier pods : `kubectl get pods -l app=auth-api`
- [ ] Pods en status `Running`
- [ ] Test health : `curl https://api.toolsapps.eu/api/health`
- [ ] Réponse OK reçue

## 🎨 Mise à jour Frontend

- [ ] Naviguer vers racine du projet
- [ ] Build frontend : `npm run build`
- [ ] Build terminé sans erreur
- [ ] Build image : `docker build -t st3ph31/frontend-toolsapps:v2.0.0 .`
- [ ] Push image : `docker push st3ph31/frontend-toolsapps:v2.0.0`
- [ ] Update deployment : `kubectl set image deployment/frontend-toolsapps frontend=st3ph31/frontend-toolsapps:v2.0.0`
- [ ] Rollout status : `kubectl rollout status deployment/frontend-toolsapps`
- [ ] Déploiement terminé

## 🧪 Tests Production

- [ ] Ouvrir https://front.toolsapps.eu
- [ ] Redirection automatique vers `/login`
- [ ] Page de login s'affiche correctement
- [ ] Entrer identifiants admin
- [ ] Connexion réussie
- [ ] Redirection vers page d'accueil
- [ ] Nom d'utilisateur affiché dans le header
- [ ] Bouton "Déconnexion" visible
- [ ] Navigation vers `/about` fonctionne
- [ ] Navigation vers `/api-test` fonctionne
- [ ] Navigation vers `/demos` fonctionne
- [ ] Tester une page de démo spécifique
- [ ] Cliquer sur "Déconnexion"
- [ ] Redirection vers `/login`
- [ ] Tentative d'accès direct à `/` sans auth
- [ ] Redirection vers `/login` (protection active)

## 🧪 Tests Locaux (Optionnel)

- [ ] Copier `users-dev.example.json` vers `users-dev.json`
- [ ] Exécuter : `.\start-dev-with-auth.ps1`
- [ ] Backend démarre sur port 3001
- [ ] Frontend démarre sur port 5173
- [ ] Ouvrir http://localhost:5173
- [ ] Login avec admin@toolsapps.eu / admin123
- [ ] Navigation locale fonctionne

## 📱 Tests Supplémentaires

- [ ] Test sur navigateur Chrome
- [ ] Test sur navigateur Firefox
- [ ] Test sur navigateur Edge
- [ ] Test sur mobile (responsive)
- [ ] Test rafraîchissement page (session persistante)
- [ ] Test avec mauvais mot de passe
- [ ] Message d'erreur approprié affiché

## 📊 Monitoring

- [ ] Logs API : `kubectl logs -l app=auth-api --tail=50`
- [ ] Pas d'erreurs dans les logs
- [ ] Logs frontend : `kubectl logs -l app=frontend-toolsapps --tail=50`
- [ ] Pas d'erreurs dans les logs
- [ ] Vérifier secrets toujours présents : `kubectl get secrets`

## 🔒 Sécurité

- [ ] Mot de passe admin **fort** (12+ caractères)
- [ ] JWT_SECRET aléatoire et long
- [ ] users.json **PAS** dans Git
- [ ] Fichier temporaire users.json supprimé localement
- [ ] backend-auth/users-dev.json dans .gitignore
- [ ] HTTPS activé et fonctionne
- [ ] Certificat SSL valide

## 📝 Documentation

- [ ] Identifiants admin notés de façon **sécurisée**
- [ ] Équipe informée de l'authentification
- [ ] Lien vers documentation partagé
- [ ] Process d'ajout d'utilisateur documenté

## 🎉 Finalisation

- [ ] Tous les tests passent ✅
- [ ] Application accessible et protégée
- [ ] Logs propres sans erreurs
- [ ] Documentation à jour
- [ ] Secrets sécurisés

## ⚠️ En cas de problème

### Backend API ne démarre pas
- [ ] Vérifier les logs : `kubectl logs -l app=auth-api`
- [ ] Vérifier les secrets existent
- [ ] Vérifier l'image Docker est accessible

### Frontend redirection infinie
- [ ] Vérifier localStorage dans le navigateur
- [ ] Vérifier console pour erreurs JS
- [ ] Vérifier l'API backend est accessible

### Login ne fonctionne pas
- [ ] Vérifier mot de passe/hash correct
- [ ] Vérifier users.json bien formaté
- [ ] Vérifier logs API pour erreurs

### Erreur CORS
- [ ] Vérifier configuration CORS dans server.js
- [ ] Vérifier URL API correcte dans frontend

## 📞 Ressources

- [QUICKSTART-AUTH.md](QUICKSTART-AUTH.md) - Guide rapide
- [GUIDE-AUTHENTIFICATION.md](GUIDE-AUTHENTIFICATION.md) - Guide complet
- [TODO-DEPLOIEMENT-AUTH.md](TODO-DEPLOIEMENT-AUTH.md) - Instructions détaillées
- [backend-auth/README.md](backend-auth/README.md) - Doc API

---

## 🎊 Félicitations !

Si toutes les cases sont cochées, votre authentification est opérationnelle ! 🚀

**Date de déploiement** : _______________  
**Déployé par** : _______________  
**Status** : ✅ Production
