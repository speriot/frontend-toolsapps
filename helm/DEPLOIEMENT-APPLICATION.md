# 🚀 Déploiement de l'Application - Guide Rapide

## ✅ Situation Actuelle

Vous êtes ici :
```
✅ VPS configuré (K3s, Helm, Ingress, cert-manager)
✅ IPv6 corrigée → IPv4
✅ Code cloné depuis GitHub
⏳ Application PAS ENCORE déployée
```

Le message "No resources found in production namespace" est **NORMAL** !

---

## 🎯 Déploiement de l'Application

### Vous êtes dans : `~/frontend-toolsapps`

### Méthode 1 : Script Automatique (Recommandé) ⚡

```bash
# Rendre le script exécutable
chmod +x helm/deploy-app.sh

# Lancer le déploiement
./helm/deploy-app.sh
```

Le script va :
1. ✅ Créer le namespace `production`
2. ✅ Déployer l'application avec Helm
3. ✅ Attendre 30 secondes
4. ✅ Afficher l'état complet
5. ✅ Donner les prochaines étapes

---

### Méthode 2 : Commandes Manuelles

```bash
# Créer le namespace
kubectl create namespace production

# Déployer avec Helm
helm install frontend-toolsapps helm/frontend-toolsapps \
  --namespace production \
  --values helm/frontend-toolsapps/values-prod.yaml

# Vérifier le déploiement
kubectl get pods -n production
kubectl get ingress -n production
kubectl get certificate -n production
```

---

## 📊 Vérifications Après Déploiement

### 1. Vérifier les Pods

```bash
kubectl get pods -n production

# Devrait afficher 2-3 pods en "Running"
# Exemple:
# NAME                                  READY   STATUS    RESTARTS
# frontend-toolsapps-xxxxxxxxx-xxxxx   1/1     Running   0
# frontend-toolsapps-xxxxxxxxx-xxxxx   1/1     Running   0
```

Si pods en "ContainerCreating" ou "Pending" :
```bash
# Attendre 1-2 minutes et vérifier à nouveau
kubectl get pods -n production -w

# Pour voir les détails d'un pod :
kubectl describe pod <pod-name> -n production
```

---

### 2. Vérifier l'Ingress

```bash
kubectl get ingress -n production

# Devrait afficher:
# NAME                 CLASS   HOSTS                 ADDRESS
# frontend-toolsapps   nginx   front.toolsapps.eu    [IPv4]
```

Si pas d'ADDRESS après 2-3 minutes :
```bash
kubectl describe ingress -n production
```

---

### 3. Vérifier le Certificat SSL

```bash
kubectl get certificate -n production

# État initial: "Ready: False"
# Après 2-5 min: "Ready: True"
```

Pour suivre l'évolution :
```bash
kubectl get certificate -n production -w
```

Si le certificat ne s'émet pas :
```bash
kubectl describe certificate -n production
kubectl logs -n cert-manager -l app=cert-manager
```

---

## 🌐 Configuration DNS

**IMPORTANT** : Configurez le DNS maintenant !

### Obtenir l'IPv4 du VPS

```bash
curl -4 ifconfig.me
# Ou
kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.externalIPs[0]}'
```

### Dans Votre Registrar (Hostinger, Cloudflare, etc.)

```
Type: A
Nom: front (ou @)
Valeur: [IPv4 du VPS]
TTL: 300
```

### Vérifier la Propagation DNS

```bash
dig front.toolsapps.eu

# Ou depuis votre machine
nslookup front.toolsapps.eu
```

---

## ✅ Tests de Fonctionnement

### Test 1 : HTTP (Port 80)

```bash
curl http://front.toolsapps.eu

# Devrait afficher le HTML de votre application
```

### Test 2 : HTTPS (Port 443)

```bash
# Attendre que le certificat soit émis (Ready: True)
curl https://front.toolsapps.eu

# Devrait afficher le HTML avec SSL
```

### Test 3 : Depuis le Navigateur

Ouvrir : **https://front.toolsapps.eu**

---

## 📋 Checklist Complète

### Avant de Tester

- [ ] Application déployée : `helm list -n production`
- [ ] Pods Running : `kubectl get pods -n production`
- [ ] Ingress créé : `kubectl get ingress -n production`
- [ ] DNS configuré : `dig front.toolsapps.eu`
- [ ] Certificat émis : `kubectl get certificate -n production` (Ready: True)

### Tests

- [ ] `curl http://front.toolsapps.eu` → HTML affiché
- [ ] `curl https://front.toolsapps.eu` → HTML affiché
- [ ] Navigateur → https://front.toolsapps.eu → Application visible
- [ ] Certificat SSL valide (cadenas vert)

---

## 🐛 Dépannage

### Problème : Pods ne démarrent pas

```bash
# Voir les détails
kubectl describe pod <pod-name> -n production

# Voir les logs
kubectl logs <pod-name> -n production

# Voir les événements
kubectl get events -n production --sort-by='.lastTimestamp'
```

Causes fréquentes :
- Image Docker non trouvée → Vérifier `docker.io/st3ph31/frontend-toolsapps:v1.0.0`
- Ressources insuffisantes → `kubectl top nodes`

---

### Problème : Certificat SSL ne s'émet pas

```bash
# Vérifier cert-manager
kubectl get pods -n cert-manager
kubectl logs -n cert-manager -l app=cert-manager

# Vérifier le certificat
kubectl describe certificate -n production

# Vérifier le ClusterIssuer
kubectl get clusterissuer
kubectl describe clusterissuer letsencrypt-prod
```

Causes fréquentes :
- DNS pas encore propagé → Attendre 5-60 minutes
- Port 80 bloqué → Vérifier le firewall
- Email Let's Encrypt invalide → Vérifier le ClusterIssuer

---

### Problème : Ingress ne fonctionne pas

```bash
# Vérifier l'Ingress Controller
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# Vérifier la config
kubectl describe ingress -n production
```

---

## 📊 Commandes de Monitoring

### Logs de l'Application

```bash
# Logs en temps réel
kubectl logs -f -n production -l app.kubernetes.io/name=frontend-toolsapps

# Logs d'un pod spécifique
kubectl logs -f -n production <pod-name>
```

### État des Ressources

```bash
# Vue d'ensemble
kubectl get all -n production

# Métriques (CPU, RAM)
kubectl top pods -n production
kubectl top nodes
```

### Autoscaling

```bash
# Voir le HPA
kubectl get hpa -n production

# Détails
kubectl describe hpa -n production
```

---

## 🔄 Mise à Jour de l'Application

### Nouvelle Version de l'Image Docker

```bash
# Mettre à jour vers v1.0.1
helm upgrade frontend-toolsapps helm/frontend-toolsapps \
  --namespace production \
  --set image.tag=v1.0.1 \
  --reuse-values

# Suivre le rollout
kubectl rollout status deployment/frontend-toolsapps -n production
```

### Rollback si Problème

```bash
# Voir l'historique
helm history frontend-toolsapps -n production

# Rollback
helm rollback frontend-toolsapps -n production
```

---

## 🎯 Commandes à Exécuter MAINTENANT

```bash
# Vous êtes dans : ~/frontend-toolsapps

# 1. Déployer l'application
chmod +x helm/deploy-app.sh
./helm/deploy-app.sh

# 2. Attendre que les pods soient Running (1-2 min)
kubectl get pods -n production -w

# 3. Vérifier l'ingress
kubectl get ingress -n production

# 4. Configurer le DNS avec l'IPv4 affichée

# 5. Attendre le certificat SSL (2-5 min)
kubectl get certificate -n production -w

# 6. Tester
curl http://front.toolsapps.eu
curl https://front.toolsapps.eu
```

---

## ✅ Résumé

**Le message "No resources found" était normal** car vous n'aviez pas encore déployé l'application !

**Maintenant** :
1. Lancez `./helm/deploy-app.sh`
2. Attendez que les pods démarrent
3. Configurez le DNS
4. Testez l'application

**Dans 5-10 minutes, votre application sera en ligne !** 🚀

---

*Guide créé le 2025-12-29 - ToolsApps © 2025*

