# 🚀 Guide Complet de Déploiement sur Hostinger VPS avec Helm

Guide étape par étape pour déployer votre application Frontend ToolsApps sur un VPS Hostinger avec Kubernetes et Helm.

## 📋 Prérequis

- VPS Hostinger avec Ubuntu 20.04+ ou Debian 11+
- Au moins 2 CPU et 4GB RAM
- Accès SSH root ou sudo
- Nom de domaine configuré (front.toolsapps.eu)

---

## 🎯 ÉTAPE 1 : Préparer le VPS

### 1.1 Connexion SSH

```bash
ssh root@votre-vps-hostinger.com
```

### 1.2 Mise à jour du système

```bash
apt update && apt upgrade -y
apt install -y curl wget git apt-transport-https ca-certificates software-properties-common
```

### 1.3 Installation de Docker

```bash
# Installation de Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Démarrage et activation
systemctl enable docker
systemctl start docker

# Vérification
docker --version
```

---

## 🎯 ÉTAPE 2 : Installation de Kubernetes (K3s)

K3s est parfait pour un VPS : léger, rapide et facile à installer.

### 2.1 Installation de K3s

```bash
# Installation de K3s
curl -sfL https://get.k3s.io | sh -

# Vérification
kubectl get nodes

# Configuration du kubeconfig
mkdir -p ~/.kube
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
chmod 600 ~/.kube/config
```

### 2.2 Vérification de Kubernetes

```bash
# Voir les nodes
kubectl get nodes

# Voir tous les pods système
kubectl get pods --all-namespaces

# Attendre que tout soit Ready
watch kubectl get pods --all-namespaces
```

---

## 🎯 ÉTAPE 3 : Installation de Helm

```bash
# Téléchargement et installation de Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Vérification
helm version
```

---

## 🎯 ÉTAPE 4 : Configuration de l'Ingress Controller

### 4.1 Installation de NGINX Ingress Controller

```bash
# Ajout du repo Helm
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Installation
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.service.externalIPs[0]=$(curl -s ifconfig.me)

# Vérification
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

### 4.2 Attendre que l'Ingress soit prêt

```bash
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

---

## 🎯 ÉTAPE 5 : Installation de cert-manager (SSL automatique)

```bash
# Installation de cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml

# Vérification
kubectl get pods -n cert-manager

# Attendre que cert-manager soit prêt
kubectl wait --namespace cert-manager \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/instance=cert-manager \
  --timeout=120s
```

### 5.1 Configuration de Let's Encrypt

Créez le fichier `letsencrypt-prod.yaml` :

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: contact@toolsapps.eu
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
```

Appliquez :

```bash
kubectl apply -f letsencrypt-prod.yaml

# Vérification
kubectl get clusterissuer
```

---

## 🎯 ÉTAPE 6 : Transfert du Helm Chart

### 6.1 Sur votre machine locale

```powershell
# Packager le chart Helm
cd C:\dev\frontend-app
helm package helm/frontend-toolsapps

# Le fichier frontend-toolsapps-1.0.0.tgz est créé
```

### 6.2 Transfert vers le VPS

```powershell
# Via SCP
scp frontend-toolsapps-1.0.0.tgz root@votre-vps:/root/

# Ou via Git (recommandé)
cd C:\dev\frontend-app
git add helm/
git commit -m "Add Helm chart"
git push origin master
```

### 6.3 Sur le VPS

```bash
# Si via Git
cd /root
git clone https://github.com/st3ph31/frontend-toolsapps.git
cd frontend-toolsapps

# Si via SCP
tar -xzf frontend-toolsapps-1.0.0.tgz
```

---

## 🎯 ÉTAPE 7 : Configuration DNS

Sur votre registrar (Hostinger, Cloudflare, etc.) :

```
Type: A
Name: front (ou @)
Value: [IP_DE_VOTRE_VPS]
TTL: 300 (ou Auto)
```

Vérifiez la propagation DNS :

```bash
dig front.toolsapps.eu
nslookup front.toolsapps.eu
```

---

## 🎯 ÉTAPE 8 : Déploiement avec Helm

### 8.1 Créer un namespace

```bash
kubectl create namespace production
```

### 8.2 Vérification du chart

```bash
# Lint du chart
helm lint helm/frontend-toolsapps

# Dry-run
helm install frontend-toolsapps helm/frontend-toolsapps \
  --namespace production \
  --dry-run --debug
```

### 8.3 Installation en production

```bash
helm install frontend-toolsapps helm/frontend-toolsapps \
  --namespace production \
  --values helm/frontend-toolsapps/values-prod.yaml \
  --set image.tag=v1.0.0

# Ou sans values-prod.yaml
helm install frontend-toolsapps helm/frontend-toolsapps \
  --namespace production \
  --set replicaCount=3 \
  --set image.tag=v1.0.0
```

---

## 🎯 ÉTAPE 9 : Vérification du Déploiement

### 9.1 État des ressources

```bash
# Pods
kubectl get pods -n production

# Services
kubectl get svc -n production

# Ingress
kubectl get ingress -n production

# HPA (Autoscaling)
kubectl get hpa -n production
```

### 9.2 Logs

```bash
# Logs de l'application
kubectl logs -n production -l app.kubernetes.io/name=frontend-toolsapps

# Logs en temps réel
kubectl logs -n production -l app.kubernetes.io/name=frontend-toolsapps -f
```

### 9.3 Événements

```bash
kubectl get events -n production --sort-by='.lastTimestamp'
```

### 9.4 Test du certificat SSL

```bash
# Vérifier le certificat
kubectl get certificate -n production

# Détails du certificat
kubectl describe certificate -n production

# Attendre que le certificat soit prêt (peut prendre 2-5 minutes)
kubectl wait --for=condition=ready certificate/frontend-toolsapps-tls -n production --timeout=300s
```

---

## 🎯 ÉTAPE 10 : Test de l'Application

### 10.1 Test HTTP

```bash
curl http://front.toolsapps.eu
```

### 10.2 Test HTTPS

```bash
curl https://front.toolsapps.eu

# Vérifier le certificat SSL
curl -vI https://front.toolsapps.eu 2>&1 | grep -i "subject\|issuer"
```

### 10.3 Test depuis le navigateur

Ouvrez : **https://front.toolsapps.eu**

---

## 🔄 Mises à Jour

### Mise à jour de l'image

```bash
# Nouvelle version
helm upgrade frontend-toolsapps helm/frontend-toolsapps \
  --namespace production \
  --set image.tag=v1.1.0 \
  --reuse-values

# Vérifier le rollout
kubectl rollout status deployment/frontend-toolsapps -n production
```

### Mise à jour de la configuration

```bash
# Modifier values-prod.yaml puis
helm upgrade frontend-toolsapps helm/frontend-toolsapps \
  --namespace production \
  --values helm/frontend-toolsapps/values-prod.yaml
```

### Rollback

```bash
# Voir l'historique
helm history frontend-toolsapps -n production

# Rollback
helm rollback frontend-toolsapps -n production
```

---

## 📊 Monitoring

### Dashboard Kubernetes

```bash
# Installation du dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# Créer un user admin
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

# Obtenir le token
kubectl -n kubernetes-dashboard create token admin-user

# Port-forward
kubectl port-forward -n kubernetes-dashboard service/kubernetes-dashboard 8443:443

# Accéder via : https://localhost:8443
```

### Métriques

```bash
# CPU et mémoire des pods
kubectl top pods -n production

# CPU et mémoire des nodes
kubectl top nodes
```

---

## 🔒 Sécurité

### Firewall

```bash
# UFW
apt install -y ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw allow 6443/tcp  # Kubernetes API
ufw enable
```

### Sauvegarde

```bash
# Sauvegarder la config Helm
helm get values frontend-toolsapps -n production > backup-values.yaml

# Sauvegarder les resources K8s
kubectl get all -n production -o yaml > backup-k8s.yaml
```

---

## 🐛 Dépannage

### Problème 1 : Pods ne démarrent pas

```bash
kubectl describe pod -n production [pod-name]
kubectl logs -n production [pod-name]
```

### Problème 2 : Certificat SSL non émis

```bash
# Vérifier cert-manager
kubectl get pods -n cert-manager
kubectl logs -n cert-manager -l app=cert-manager

# Vérifier le certificat
kubectl describe certificate -n production
kubectl describe certificaterequest -n production
```

### Problème 3 : Ingress ne fonctionne pas

```bash
# Vérifier l'ingress controller
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# Vérifier la config ingress
kubectl describe ingress -n production
```

---

## 📈 Optimisations

### 1. Resource Limits

Ajustez selon vos besoins :

```yaml
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 200m
    memory: 256Mi
```

### 2. Autoscaling

```yaml
autoscaling:
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

### 3. Cache DNS

```bash
# Configurer le cache DNS dans K3s
# Éditer /etc/rancher/k3s/config.yaml
```

---

## ✅ Checklist Finale

- [ ] VPS configuré et à jour
- [ ] Docker installé
- [ ] K3s (Kubernetes) installé
- [ ] Helm installé
- [ ] Ingress Controller NGINX installé
- [ ] cert-manager installé
- [ ] Let's Encrypt ClusterIssuer configuré
- [ ] DNS configuré (front.toolsapps.eu)
- [ ] Helm chart déployé
- [ ] Pods en état Running
- [ ] Certificat SSL émis et valide
- [ ] Application accessible via HTTPS
- [ ] Autoscaling configuré
- [ ] Monitoring en place

---

## 🎊 Félicitations !

Votre application est maintenant déployée professionnellement avec :

✅ Kubernetes (K3s)
✅ Helm Charts
✅ Ingress NGINX
✅ SSL automatique (Let's Encrypt)
✅ Autoscaling (HPA)
✅ Haute disponibilité
✅ Network Policies
✅ Monitoring

**Prêt pour la production ! 🚀**

---

*Document créé le 2025-12-29*
*ToolsApps © 2025*

