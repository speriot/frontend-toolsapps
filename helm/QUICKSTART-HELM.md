# 🚀 Quick Start - Déploiement Helm sur Hostinger VPS

Guide ultra-rapide pour déployer votre frontend avec Helm en moins de 15 minutes.

## ⚡ TL;DR - Les 5 Commandes Essentielles

Sur votre VPS Hostinger, exécutez :

```bash
# 1. Installation automatique de l'environnement
curl -sfL https://raw.githubusercontent.com/st3ph31/frontend-toolsapps/master/helm/setup-vps.sh | sudo bash

# 2. Cloner le projet
git clone https://github.com/st3ph31/frontend-toolsapps.git
cd frontend-toolsapps

# 3. Configurer le DNS (à faire dans votre panel Hostinger)
# front.toolsapps.eu → [IP_DE_VOTRE_VPS]

# 4. Déployer avec Helm
helm install frontend-toolsapps helm/frontend-toolsapps \
  --namespace production \
  --create-namespace \
  --values helm/frontend-toolsapps/values-prod.yaml

# 5. Vérifier
kubectl get pods -n production
kubectl get ingress -n production
```

**🎉 Voilà ! Votre app est en ligne sur https://front.toolsapps.eu**

---

## 📋 Étape par Étape

### 1️⃣ Préparer le VPS (5 minutes)

```bash
# Connexion SSH
ssh root@votre-vps-hostinger.com

# Script d'installation automatique
wget https://raw.githubusercontent.com/st3ph31/frontend-toolsapps/master/helm/setup-vps.sh
chmod +x setup-vps.sh
./setup-vps.sh
```

Ce script installe :
- ✅ Docker
- ✅ Kubernetes (K3s)
- ✅ Helm
- ✅ NGINX Ingress
- ✅ cert-manager (SSL)
- ✅ Firewall

**Temps estimé : 5 minutes**

### 2️⃣ Configurer le DNS (2 minutes)

Dans votre panel Hostinger (ou autre registrar) :

```
Type: A
Nom: front
Valeur: [VOTRE_IP_VPS]
TTL: 300
```

**Vérifier** :
```bash
dig front.toolsapps.eu
```

**Temps estimé : 2 minutes (+ propagation DNS : 5-60 min)**

### 3️⃣ Déployer l'Application (3 minutes)

```bash
# Cloner le projet
git clone https://github.com/st3ph31/frontend-toolsapps.git
cd frontend-toolsapps

# Vérifier le chart
helm lint helm/frontend-toolsapps

# Déployer en production
helm install frontend-toolsapps helm/frontend-toolsapps \
  --namespace production \
  --create-namespace \
  --values helm/frontend-toolsapps/values-prod.yaml
```

**Temps estimé : 3 minutes**

### 4️⃣ Vérifier le Déploiement (2 minutes)

```bash
# Voir les pods
kubectl get pods -n production
# Attendre que tous soient "Running"

# Voir l'ingress
kubectl get ingress -n production

# Voir le certificat SSL (peut prendre 2-5 min)
kubectl get certificate -n production
# Attendre que STATUS = "True"

# Test HTTP
curl http://front.toolsapps.eu

# Test HTTPS (une fois le certificat émis)
curl https://front.toolsapps.eu
```

**Temps estimé : 2 minutes (+2-5 min pour le SSL)**

---

## 🎯 Commandes Utiles

### Monitoring

```bash
# Logs en temps réel
kubectl logs -f -n production -l app.kubernetes.io/name=frontend-toolsapps

# État des pods
kubectl get pods -n production -w

# Métriques
kubectl top pods -n production
```

### Mise à Jour

```bash
# Nouvelle version
helm upgrade frontend-toolsapps helm/frontend-toolsapps \
  --namespace production \
  --set image.tag=v1.0.1 \
  --reuse-values

# Rollback
helm rollback frontend-toolsapps -n production
```

### Debugging

```bash
# Détails d'un pod
kubectl describe pod <pod-name> -n production

# Événements
kubectl get events -n production --sort-by='.lastTimestamp'

# Shell dans un pod
kubectl exec -it deployment/frontend-toolsapps -n production -- /bin/sh
```

---

## 🐛 Problèmes Courants

### Problème 1 : Pods ne démarrent pas

```bash
kubectl describe pod -n production <pod-name>
# Regarder "Events" en bas
```

**Causes fréquentes** :
- Image Docker non trouvée → Vérifier `image.repository` et `image.tag`
- Ressources insuffisantes → Vérifier `kubectl top nodes`

### Problème 2 : Certificat SSL non émis

```bash
kubectl get certificate -n production
kubectl describe certificate -n production
```

**Causes fréquentes** :
- DNS pas encore propagé → Attendre 5-60 minutes
- Email Let's Encrypt invalide → Vérifier le ClusterIssuer
- Port 80 fermé → Vérifier le firewall

### Problème 3 : Ingress ne fonctionne pas

```bash
kubectl get ingress -n production
kubectl describe ingress -n production
```

**Causes fréquentes** :
- Ingress Controller pas prêt → `kubectl get pods -n ingress-nginx`
- DNS non configuré → Vérifier `dig front.toolsapps.eu`

---

## 📊 Checklist Complète

### Avant Déploiement
- [ ] VPS Hostinger accessible en SSH
- [ ] Docker Hub image pushée (`docker.io/st3ph31/frontend-toolsapps:v1.0.0`)
- [ ] Nom de domaine prêt (`front.toolsapps.eu`)

### Installation VPS
- [ ] Script `setup-vps.sh` exécuté
- [ ] K3s installé et fonctionnel
- [ ] Helm installé
- [ ] NGINX Ingress déployé
- [ ] cert-manager déployé
- [ ] Firewall configuré

### Configuration DNS
- [ ] Enregistrement A créé
- [ ] DNS propagé (test avec `dig`)

### Déploiement
- [ ] Projet cloné sur le VPS
- [ ] Helm chart validé (`helm lint`)
- [ ] Application déployée
- [ ] Pods en état "Running"
- [ ] Service créé
- [ ] Ingress créé

### Validation
- [ ] HTTP fonctionne (port 80)
- [ ] Certificat SSL émis
- [ ] HTTPS fonctionne (port 443)
- [ ] Autoscaling configuré (HPA)
- [ ] Logs accessibles

---

## 🎓 Aller Plus Loin

### Monitoring avec Dashboard

```bash
# Installation du dashboard Kubernetes
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# Accès via port-forward
kubectl port-forward -n kubernetes-dashboard service/kubernetes-dashboard 8443:443
```

### Customisation

Éditez `helm/frontend-toolsapps/values-prod.yaml` :

```yaml
# Augmenter les ressources
resources:
  limits:
    cpu: 1000m
    memory: 1Gi

# Plus de réplicas
replicaCount: 5

# Autoscaling plus agressif
autoscaling:
  maxReplicas: 30
  targetCPUUtilizationPercentage: 60
```

Puis :

```bash
helm upgrade frontend-toolsapps helm/frontend-toolsapps \
  --namespace production \
  --values helm/frontend-toolsapps/values-prod.yaml
```

---

## 📚 Documentation Complète

- **[GUIDE-DEPLOIEMENT-VPS.md](GUIDE-DEPLOIEMENT-VPS.md)** - Guide détaillé complet
- **[frontend-toolsapps/README.md](frontend-toolsapps/README.md)** - Documentation du chart
- **[README.md](README.md)** - Vue d'ensemble

---

## ✅ Résultat Final

Après ces étapes, vous aurez :

✅ **Kubernetes** (K3s) sur votre VPS  
✅ **Application** déployée avec Helm  
✅ **HTTPS** automatique (Let's Encrypt)  
✅ **Autoscaling** configuré (2-20 pods)  
✅ **Haute disponibilité** (PodDisruptionBudget)  
✅ **Sécurité** (NetworkPolicy, SecurityContext)  
✅ **Monitoring** (métriques, logs)  

**Temps total : ~15 minutes + propagation DNS**

---

🎉 **Félicitations ! Votre application est déployée comme un pro !** 🚀

*Guide créé le 2025-12-29 - ToolsApps © 2025*

