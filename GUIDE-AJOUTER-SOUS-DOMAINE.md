# 🎯 Guide générique - Ajouter un nouveau sous-domaine

Ce guide vous permet d'ajouter facilement n'importe quel sous-domaine à votre infrastructure Kubernetes.

---

## 🚀 Processus en 4 étapes

### 1️⃣ Configuration DNS Cloudflare (5 min)
### 2️⃣ Créer le Deployment (5-10 min)
### 3️⃣ Créer l'Ingress (2 min)
### 4️⃣ Vérifier (5 min)

---

## 📋 Étape 1: Configuration DNS

### 1.1 Accéder à Cloudflare
- URL: https://dash.cloudflare.com/
- Sélectionner: **toolsapps.eu**
- Menu: **DNS** > **Records**

### 1.2 Ajouter l'enregistrement
Cliquez sur **"Add record"**:

```
Type:           A
Name:           [NOM-DU-SOUS-DOMAINE]
IPv4 address:   72.62.16.206
Proxy status:   DNS only ☁️ (IMPORTANT !)
TTL:            Auto
```

**Exemples**:
- `front` → front.toolsapps.eu
- `admin` → admin.toolsapps.eu
- `blog` → blog.toolsapps.eu
- `app` → app.toolsapps.eu

### 1.3 Vérifier la propagation
```powershell
nslookup [sous-domaine].toolsapps.eu
# Devrait retourner: 72.62.16.206
```

---

## 📋 Étape 2: Créer le Deployment

### 2.1 Template de base

Créez un fichier `[nom]-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: [NOM-APP]
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: [NOM-APP]
  template:
    metadata:
      labels:
        app: [NOM-APP]
    spec:
      containers:
        - name: [NOM-APP]
          image: [VOTRE-IMAGE:TAG]
          ports:
            - containerPort: [PORT]
          # Variables d'environnement (optionnel)
          # env:
          #   - name: API_URL
          #     value: "https://api.toolsapps.eu"
---
apiVersion: v1
kind: Service
metadata:
  name: [NOM-APP]
  namespace: default
spec:
  selector:
    app: [NOM-APP]
  ports:
    - port: 80
      targetPort: [PORT]
```

### 2.2 Remplacer les variables

| Variable | Description | Exemple |
|----------|-------------|---------|
| `[NOM-APP]` | Nom de l'application | `frontend`, `admin`, `blog` |
| `[VOTRE-IMAGE:TAG]` | Image Docker | `nginx:alpine`, `myapp:v1.0` |
| `[PORT]` | Port du conteneur | `80`, `3000`, `8080` |

### 2.3 Exemples concrets

#### Application Node.js
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-v2
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api-v2
  template:
    metadata:
      labels:
        app: api-v2
    spec:
      containers:
        - name: api-v2
          image: node:18-alpine
          ports:
            - containerPort: 3000
          env:
            - name: NODE_ENV
              value: "production"
            - name: PORT
              value: "3000"
---
apiVersion: v1
kind: Service
metadata:
  name: api-v2
  namespace: default
spec:
  selector:
    app: api-v2
  ports:
    - port: 80
      targetPort: 3000
```

#### Application Python Flask/FastAPI
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
        - name: backend
          image: python:3.11-slim
          ports:
            - containerPort: 8000
          env:
            - name: PYTHONUNBUFFERED
              value: "1"
---
apiVersion: v1
kind: Service
metadata:
  name: backend
  namespace: default
spec:
  selector:
    app: backend
  ports:
    - port: 80
      targetPort: 8000
```

#### Application React/Vue/Angular (build)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
        - name: frontend
          image: nginx:alpine
          ports:
            - containerPort: 80
          volumeMounts:
            - name: frontend-build
              mountPath: /usr/share/nginx/html
      volumes:
        - name: frontend-build
          # Utilisez un volume avec votre build
          emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
  namespace: default
spec:
  selector:
    app: frontend
  ports:
    - port: 80
      targetPort: 80
```

### 2.4 Déployer
```bash
sudo kubectl apply -f [nom]-deployment.yaml
sudo kubectl get pods -n default
sudo kubectl logs -n default -l app=[NOM-APP]
```

---

## 📋 Étape 3: Créer l'Ingress

### 3.1 Template de base

Créez un fichier `[nom]-ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: [NOM-INGRESS]
  namespace: default
  annotations:
    kubernetes.io/ingress.class: traefik
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: traefik
  tls:
    - hosts:
        - [SOUS-DOMAINE].toolsapps.eu
      secretName: le-cert-[SOUS-DOMAINE]-toolsapps
  rules:
    - host: [SOUS-DOMAINE].toolsapps.eu
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: [NOM-APP]
                port:
                  number: 80
```

### 3.2 Remplacer les variables

| Variable | Description | Exemple |
|----------|-------------|---------|
| `[NOM-INGRESS]` | Nom de l'Ingress | `front-toolsapps`, `admin-toolsapps` |
| `[SOUS-DOMAINE]` | Sous-domaine | `front`, `admin`, `blog` |
| `[NOM-APP]` | Nom du Service | `frontend`, `admin`, `blog` |

### 3.3 Exemples concrets

#### Pour front.toolsapps.eu
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: front-toolsapps
  namespace: default
  annotations:
    kubernetes.io/ingress.class: traefik
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: traefik
  tls:
    - hosts:
        - front.toolsapps.eu
      secretName: le-cert-front-toolsapps
  rules:
    - host: front.toolsapps.eu
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend
                port:
                  number: 80
```

#### Pour admin.toolsapps.eu
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: admin-toolsapps
  namespace: default
  annotations:
    kubernetes.io/ingress.class: traefik
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: traefik
  tls:
    - hosts:
        - admin.toolsapps.eu
      secretName: le-cert-admin-toolsapps
  rules:
    - host: admin.toolsapps.eu
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: admin
                port:
                  number: 80
```

### 3.4 Déployer
```bash
sudo kubectl apply -f [nom]-ingress.yaml
sudo kubectl get ingress -n default
sudo kubectl describe ingress [NOM-INGRESS] -n default
```

---

## 📋 Étape 4: Vérifier le certificat SSL

### 4.1 Surveiller la génération
```bash
# Voir tous les certificats
sudo kubectl get certificate -n default

# Surveiller en temps réel
sudo kubectl get certificate -n default -w

# Détails du certificat
sudo kubectl describe certificate -n default
```

### 4.2 Statut attendu
```
NAME                        READY   SECRET                      AGE
le-cert-front-toolsapps     True    le-cert-front-toolsapps     2m
```

**Ready: True** = Certificat généré avec succès ! ✅

### 4.3 Vérifier le secret
```bash
sudo kubectl get secret le-cert-[sous-domaine]-toolsapps -n default
```

---

## ✅ Tests finaux

### 1. Test DNS
```powershell
nslookup [sous-domaine].toolsapps.eu
# Résultat attendu: 72.62.16.206
```

### 2. Test HTTP
```powershell
curl http://[sous-domaine].toolsapps.eu
```

### 3. Test HTTPS
```powershell
curl https://[sous-domaine].toolsapps.eu
```

### 4. Test navigateur
Ouvrez: `https://[sous-domaine].toolsapps.eu`
- ✅ Cadenas vert 🔒
- ✅ Certificat Let's Encrypt
- ✅ Page s'affiche

---

## 📊 Tableau récapitulatif

| Sous-domaine | Fichier Deployment | Fichier Ingress | Secret SSL |
|--------------|-------------------|-----------------|------------|
| api.toolsapps.eu | whoami-deployment.yaml | whoami-ingress-api.yaml | le-cert-api-toolsapps |
| front.toolsapps.eu | front-deployment.yaml | front-ingress.yaml | le-cert-front-toolsapps |
| admin.toolsapps.eu | admin-deployment.yaml | admin-ingress.yaml | le-cert-admin-toolsapps |
| blog.toolsapps.eu | blog-deployment.yaml | blog-ingress.yaml | le-cert-blog-toolsapps |

---

## 🎯 Checklist complète

### DNS
- [ ] Enregistrement DNS créé dans Cloudflare
- [ ] Proxy désactivé (nuage gris ☁️)
- [ ] DNS résolu: `nslookup [sous-domaine].toolsapps.eu`

### Deployment
- [ ] Fichier `[nom]-deployment.yaml` créé
- [ ] Variables remplacées (nom, image, port)
- [ ] Appliqué: `sudo kubectl apply -f [nom]-deployment.yaml`
- [ ] Pod en état "Running"
- [ ] Service créé

### Ingress
- [ ] Fichier `[nom]-ingress.yaml` créé
- [ ] Variables remplacées (nom, sous-domaine)
- [ ] Appliqué: `sudo kubectl apply -f [nom]-ingress.yaml`
- [ ] Ingress créé

### Certificat SSL
- [ ] Certificate en "Ready: True"
- [ ] Secret créé
- [ ] HTTPS accessible

### Tests
- [ ] HTTP fonctionne
- [ ] HTTPS fonctionne
- [ ] Cadenas vert dans le navigateur
- [ ] Certificat Let's Encrypt valide

---

## 🐛 Dépannage rapide

### Le certificat ne se génère pas
```bash
# Vérifier les challenges
sudo kubectl get challenges -n default
sudo kubectl describe challenges -n default

# Points de contrôle:
# 1. Proxy Cloudflare désactivé ?
# 2. DNS pointe vers 72.62.16.206 ?
# 3. Port 80 accessible ?

# Logs cert-manager
sudo kubectl logs -n cert-manager -l app=cert-manager --tail=50
```

### Le pod ne démarre pas
```bash
# Voir les détails
sudo kubectl describe pod -n default -l app=[NOM-APP]

# Voir les logs
sudo kubectl logs -n default -l app=[NOM-APP]

# Causes fréquentes:
# - Image Docker inexistante
# - Port incorrect
# - Application crash
```

### Le site ne répond pas
```bash
# Vérifier l'ordre:
# 1. Pod running ?
sudo kubectl get pods -n default

# 2. Service existe ?
sudo kubectl get svc -n default

# 3. Ingress configuré ?
sudo kubectl get ingress -n default

# 4. Certificat ready ?
sudo kubectl get certificate -n default

# Test direct du service
sudo kubectl port-forward -n default svc/[NOM-APP] 8080:80
# Puis: curl http://localhost:8080
```

---

## 💡 Astuces et bonnes pratiques

### Nommage cohérent
```
Sous-domaine: front
Deployment: frontend
Service: frontend
Ingress: front-toolsapps
Secret SSL: le-cert-front-toolsapps
Fichiers: front-deployment.yaml, front-ingress.yaml
```

### Organisation des fichiers
```
P:\Hostinger\
  ├── api-toolsapps\
  │   ├── whoami-deployment.yaml
  │   └── whoami-ingress-api.yaml
  ├── front-toolsapps\
  │   ├── front-deployment.yaml
  │   └── front-ingress.yaml
  ├── admin-toolsapps\
  │   ├── admin-deployment.yaml
  │   └── admin-ingress.yaml
```

### Variables d'environnement
Passez les URLs en variables:
```yaml
env:
  - name: API_URL
    value: "https://api.toolsapps.eu"
  - name: FRONTEND_URL
    value: "https://front.toolsapps.eu"
```

### Secrets sensibles
Pour les secrets (mots de passe, clés API):
```bash
# Créer un secret
kubectl create secret generic mon-secret \
  --from-literal=password='mon-mot-de-passe' \
  --namespace=default

# Utiliser dans le Deployment
env:
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: mon-secret
        key: password
```

---

## 🚀 Automatisation

### Script pour créer un nouveau sous-domaine

Créez `create-subdomain.sh`:

```bash
#!/bin/bash

# Usage: ./create-subdomain.sh nom-app sous-domaine image:tag port

NOM_APP=$1
SOUS_DOMAINE=$2
IMAGE=$3
PORT=$4

# Créer le Deployment
cat > ${NOM_APP}-deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${NOM_APP}
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${NOM_APP}
  template:
    metadata:
      labels:
        app: ${NOM_APP}
    spec:
      containers:
        - name: ${NOM_APP}
          image: ${IMAGE}
          ports:
            - containerPort: ${PORT}
---
apiVersion: v1
kind: Service
metadata:
  name: ${NOM_APP}
  namespace: default
spec:
  selector:
    app: ${NOM_APP}
  ports:
    - port: 80
      targetPort: ${PORT}
EOF

# Créer l'Ingress
cat > ${NOM_APP}-ingress.yaml <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${SOUS_DOMAINE}-toolsapps
  namespace: default
  annotations:
    kubernetes.io/ingress.class: traefik
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: traefik
  tls:
    - hosts:
        - ${SOUS_DOMAINE}.toolsapps.eu
      secretName: le-cert-${SOUS_DOMAINE}-toolsapps
  rules:
    - host: ${SOUS_DOMAINE}.toolsapps.eu
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: ${NOM_APP}
                port:
                  number: 80
EOF

echo "✅ Fichiers créés:"
echo "  - ${NOM_APP}-deployment.yaml"
echo "  - ${NOM_APP}-ingress.yaml"
echo ""
echo "📝 Prochaines étapes:"
echo "1. Configurer le DNS dans Cloudflare: ${SOUS_DOMAINE}.toolsapps.eu → 72.62.16.206"
echo "2. kubectl apply -f ${NOM_APP}-deployment.yaml"
echo "3. kubectl apply -f ${NOM_APP}-ingress.yaml"
```

**Usage**:
```bash
./create-subdomain.sh frontend front nginx:alpine 80
./create-subdomain.sh admin admin myapp:v1.0 3000
```

---

## 📚 Ressources

- **Plan d'action front.toolsapps.eu**: [PLAN-FRONT-TOOLSAPPS.md](PLAN-FRONT-TOOLSAPPS.md)
- **Documentation principale**: [INDEX.md](INDEX.md)
- **Guide Cloudflare**: [CLOUDFLARE.md](CLOUDFLARE.md)
- **Aide-mémoire K3s**: [AIDE-MEMOIRE.md](AIDE-MEMOIRE.md)

---

## 🎯 Résumé ultra-rapide

```bash
# 1. DNS Cloudflare
# Ajouter: [sous-domaine] A 72.62.16.206 (proxy désactivé)

# 2. Créer les fichiers YAML
# - [nom]-deployment.yaml
# - [nom]-ingress.yaml

# 3. Déployer
sudo kubectl apply -f [nom]-deployment.yaml
sudo kubectl apply -f [nom]-ingress.yaml

# 4. Vérifier
sudo kubectl get certificate -n default
curl https://[sous-domaine].toolsapps.eu
```

**Temps total: ~20-30 minutes par sous-domaine** ⏱️

---

**💡 Conseil**: Gardez ce guide sous la main, vous l'utiliserez à chaque nouveau sous-domaine !

