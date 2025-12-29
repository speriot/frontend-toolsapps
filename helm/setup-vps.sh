#!/bin/bash
# Script d'installation automatique pour VPS Hostinger
# Usage: bash setup-vps.sh

set -e

echo "🚀 Installation de l'environnement Kubernetes sur VPS Hostinger"
echo "================================================================"
echo ""

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Vérifier si root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ Ce script doit être exécuté en tant que root${NC}"
  exit 1
fi

# Fonction pour afficher les étapes
step() {
  echo -e "\n${GREEN}➜ $1${NC}"
}

# 1. Mise à jour du système
step "1/10 Mise à jour du système..."
apt update && apt upgrade -y
apt install -y curl wget git apt-transport-https ca-certificates software-properties-common

# 2. Installation de Docker
step "2/10 Installation de Docker..."
if ! command -v docker &> /dev/null; then
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  systemctl enable docker
  systemctl start docker
  rm get-docker.sh
  echo -e "${GREEN}✅ Docker installé${NC}"
else
  echo -e "${YELLOW}ℹ️  Docker déjà installé${NC}"
fi

docker --version

# 3. Installation de K3s
step "3/10 Installation de K3s (Kubernetes)..."
if ! command -v kubectl &> /dev/null; then
  curl -sfL https://get.k3s.io | sh -

  # Configuration kubeconfigfrontend-toolsapps
  mkdir -p ~/.kube
  cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
  chmod 600 ~/.kube/config
  export KUBECONFIG=~/.kube/config

  # Attendre que K3s soit prêt
  echo "Attente du démarrage de K3s..."
  sleep 10

  echo -e "${GREEN}✅ K3s installé${NC}"
else
  echo -e "${YELLOW}ℹ️  K3s déjà installé${NC}"
fi

kubectl version --client

# 4. Vérification de Kubernetes
step "4/10 Vérification de Kubernetes..."
kubectl get nodes
kubectl wait --for=condition=Ready nodes --all --timeout=120s

# 5. Installation de Helm
step "5/10 Installation de Helm..."
if ! command -v helm &> /dev/null; then
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  echo -e "${GREEN}✅ Helm installé${NC}"
else
  echo -e "${YELLOW}ℹ️  Helm déjà installé${NC}"
fi

helm version

# 6. Installation de NGINX Ingress Controller
step "6/10 Installation de NGINX Ingress Controller..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Obtenir l'IP publique du VPS (forcer IPv4)
PUBLIC_IP=$(curl -4 -s ifconfig.me 2>/dev/null || curl -s api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')
echo "IP publique détectée: $PUBLIC_IP"

# Vérifier si c'est une IPv4 valide
if [[ ! $PUBLIC_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
  echo -e "${YELLOW}⚠️  IPv6 ou IP invalide détectée: $PUBLIC_IP${NC}"
  echo -e "${YELLOW}   Tentative de récupération de l'IPv4...${NC}"
  PUBLIC_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n 1)
  if [[ -n $PUBLIC_IP ]]; then
    echo -e "${GREEN}   IPv4 trouvée: $PUBLIC_IP${NC}"
  else
    echo -e "${RED}   ❌ Impossible de détecter l'IPv4${NC}"
    read -p "   Entrez manuellement votre IPv4 publique: " PUBLIC_IP
  fi
fi

# Vérifier si déjà installé
if helm list -n ingress-nginx | grep -q ingress-nginx; then
  echo -e "${YELLOW}ℹ️  NGINX Ingress déjà installé${NC}"
else
  helm install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx \
    --create-namespace \
    --set controller.service.type=LoadBalancer \
    --set controller.service.externalIPs[0]=$PUBLIC_IP \
    --wait

  echo -e "${GREEN}✅ NGINX Ingress installé${NC}"
fi

# Attendre que l'Ingress soit prêt
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# 7. Installation de cert-manager
step "7/10 Installation de cert-manager (SSL automatique)..."
if kubectl get namespace cert-manager &> /dev/null; then
  echo -e "${YELLOW}ℹ️  cert-manager déjà installé${NC}"
else
  kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml

  # Attendre que cert-manager soit prêt
  echo "Attente du démarrage de cert-manager..."
  sleep 30

  kubectl wait --namespace cert-manager \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/instance=cert-manager \
    --timeout=120s

  echo -e "${GREEN}✅ cert-manager installé${NC}"
fi

# 8. Configuration de Let's Encrypt
step "8/10 Configuration de Let's Encrypt..."

# Demander l'email
read -p "Entrez votre email pour Let's Encrypt: " LETSENCRYPT_EMAIL

cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: $LETSENCRYPT_EMAIL
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

echo -e "${GREEN}✅ Let's Encrypt configuré${NC}"

# 9. Configuration du Firewall
step "9/10 Configuration du Firewall..."
if command -v ufw &> /dev/null; then
  ufw --force enable
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow 22/tcp    # SSH
  ufw allow 80/tcp    # HTTP
  ufw allow 443/tcp   # HTTPS
  ufw allow 6443/tcp  # Kubernetes API
  ufw reload
  echo -e "${GREEN}✅ Firewall configuré${NC}"
else
  echo -e "${YELLOW}ℹ️  UFW non installé, installation...${NC}"
  apt install -y ufw
  ufw --force enable
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow 22/tcp
  ufw allow 80/tcp
  ufw allow 443/tcp
  ufw allow 6443/tcp
  ufw reload
  echo -e "${GREEN}✅ Firewall configuré${NC}"
fi

# 10. Création du namespace production
step "10/10 Création du namespace production..."
kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -

# Résumé
echo ""
echo "================================================================"
echo -e "${GREEN}✅ Installation terminée avec succès!${NC}"
echo "================================================================"
echo ""
echo "📊 Résumé de l'installation:"
echo "  • Docker: $(docker --version | cut -d' ' -f3)"
echo "  • Kubernetes (K3s): $(kubectl version --client -o json | jq -r '.clientVersion.gitVersion')"
echo "  • Helm: $(helm version --short)"
echo "  • IP publique: $PUBLIC_IP"
echo ""
echo "🔧 Composants installés:"
echo "  ✅ Kubernetes (K3s)"
echo "  ✅ Helm"
echo "  ✅ NGINX Ingress Controller"
echo "  ✅ cert-manager"
echo "  ✅ Let's Encrypt ClusterIssuer"
echo "  ✅ Firewall (UFW)"
echo "  ✅ Namespace 'production'"
echo ""
echo "📝 Prochaines étapes:"
echo "  1. Configurer votre DNS: front.toolsapps.eu → $PUBLIC_IP"
echo ""
echo "  2a. Option A - Cloner le dépôt (pour avoir les fichiers Helm):"
echo "      git clone https://github.com/st3ph31/frontend-toolsapps.git"
echo "      cd frontend-toolsapps"
echo ""
echo "  2b. Option B - Copier juste les fichiers Helm depuis votre machine:"
echo "      scp -r C:\dev\frontend-app\helm root@$PUBLIC_IP:/root/"
echo ""
echo "  3. Déployer avec Helm:"
echo "     helm install frontend-toolsapps ./helm/frontend-toolsapps \\"
echo "       --namespace production \\"
echo "       --values ./helm/frontend-toolsapps/values-prod.yaml"
echo ""
echo "  Note: L'image Docker (docker.io/st3ph31/frontend-toolsapps:v1.0.0)"
echo "        sera automatiquement téléchargée depuis Docker Hub par Kubernetes."
echo "        Le git clone sert UNIQUEMENT à récupérer les fichiers Helm Chart."
echo ""
echo "📚 Documentation:"
echo "  • Guide complet: helm/GUIDE-DEPLOIEMENT-VPS.md"
echo "  • Helm chart: helm/frontend-toolsapps/README.md"
echo ""
echo "🎉 Votre VPS est prêt pour la production!"
echo ""

