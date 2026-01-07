#!/bin/bash

# Script de déploiement automatisé du MQTT-SSE Bridge
# Usage: ./deploy-mqtt-sse.sh [dev|prod]

set -e  # Exit on error

ENV=${1:-prod}
VERSION="v1.0.0"
NAMESPACE="default"
DOCKER_REGISTRY="st3ph31"
IMAGE_NAME="mqtt-sse-bridge"
CHART_PATH="./mqtt-sse-bridge"

echo "🚀 Déploiement MQTT-SSE Bridge - Environnement: $ENV"
echo "================================================"

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour afficher les erreurs
error() {
    echo -e "${RED}❌ Erreur: $1${NC}"
    exit 1
}

# Fonction pour afficher les succès
success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Fonction pour afficher les infos
info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Vérifier les prérequis
info "Vérification des prérequis..."

command -v docker >/dev/null 2>&1 || error "Docker n'est pas installé"
command -v kubectl >/dev/null 2>&1 || error "kubectl n'est pas installé"
command -v helm >/dev/null 2>&1 || error "Helm n'est pas installé"

success "Tous les prérequis sont présents"

# Demander confirmation pour la production
if [ "$ENV" = "prod" ]; then
    read -p "⚠️  Déploiement en PRODUCTION. Continuer? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error "Déploiement annulé"
    fi
fi

# Étape 1: Build de l'image Docker
info "Étape 1/6: Build de l'image Docker..."
cd ../backend-mqtt
docker build -t $DOCKER_REGISTRY/$IMAGE_NAME:$VERSION . || error "Build Docker échoué"
success "Image Docker buildée: $DOCKER_REGISTRY/$IMAGE_NAME:$VERSION"

# Étape 2: Push de l'image
info "Étape 2/6: Push de l'image Docker..."
docker push $DOCKER_REGISTRY/$IMAGE_NAME:$VERSION || error "Push Docker échoué"
success "Image pushée sur Docker Hub"

# Revenir au dossier helm
cd ../helm/mqtt-sse-bridge

# Étape 3: Vérifier/Créer le secret MQTT
info "Étape 3/6: Vérification du secret MQTT..."
if kubectl get secret mqtt-credentials -n $NAMESPACE >/dev/null 2>&1; then
    success "Secret MQTT existe déjà"
else
    info "Création du secret MQTT..."
    read -p "Username MQTT: " mqtt_username
    read -s -p "Password MQTT: " mqtt_password
    echo
    kubectl create secret generic mqtt-credentials \
        --from-literal=username="$mqtt_username" \
        --from-literal=password="$mqtt_password" \
        -n $NAMESPACE || error "Création du secret échouée"
    success "Secret MQTT créé"
fi

# Étape 4: Lint du chart Helm
info "Étape 4/6: Validation du chart Helm..."
helm lint . || error "Validation Helm échouée"
success "Chart Helm valide"

# Étape 5: Installation/Upgrade Helm
info "Étape 5/6: Déploiement Helm..."

VALUES_FILE="values.yaml"
if [ "$ENV" = "prod" ]; then
    VALUES_FILE="values-prod.yaml"
fi

if helm status mqtt-sse-bridge -n $NAMESPACE >/dev/null 2>&1; then
    info "Mise à jour de la release existante..."
    helm upgrade mqtt-sse-bridge . \
        -f $VALUES_FILE \
        --set image.tag=$VERSION \
        --namespace $NAMESPACE \
        --wait \
        --timeout 5m || error "Upgrade Helm échoué"
    success "Release mise à jour avec succès"
else
    info "Installation de la nouvelle release..."
    helm install mqtt-sse-bridge . \
        -f $VALUES_FILE \
        --namespace $NAMESPACE \
        --wait \
        --timeout 5m || error "Installation Helm échouée"
    success "Release installée avec succès"
fi

# Étape 6: Vérifications post-déploiement
info "Étape 6/6: Vérifications post-déploiement..."

echo ""
info "Attente du démarrage des pods (30s)..."
sleep 30

# Vérifier les pods
echo ""
info "Status des pods:"
kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=mqtt-sse-bridge

# Vérifier le service
echo ""
info "Service:"
kubectl get svc -n $NAMESPACE mqtt-sse-bridge

# Vérifier l'ingress
echo ""
info "Ingress:"
kubectl get ingress -n $NAMESPACE mqtt-sse-bridge

# Afficher les logs récents
echo ""
info "Logs récents (10 dernières lignes):"
kubectl logs -n $NAMESPACE -l app.kubernetes.io/name=mqtt-sse-bridge --tail=10

# Test health check (si possible)
echo ""
info "Test du health check..."
POD_NAME=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=mqtt-sse-bridge -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n $NAMESPACE $POD_NAME -- wget -qO- http://localhost:3003/health || info "Health check via exec échoué (normal si wget n'est pas installé)"

echo ""
success "================================================"
success "🎉 Déploiement terminé avec succès!"
success "================================================"

echo ""
info "📋 Informations utiles:"
echo ""
echo "  • Voir les logs en temps réel:"
echo "    kubectl logs -n $NAMESPACE -l app.kubernetes.io/name=mqtt-sse-bridge -f"
echo ""
echo "  • Vérifier le status:"
echo "    helm status mqtt-sse-bridge -n $NAMESPACE"
echo ""
echo "  • Port-forward pour tester localement:"
echo "    kubectl port-forward -n $NAMESPACE svc/mqtt-sse-bridge 3003:3003"
echo "    curl -N http://localhost:3003/api/portal/events"
echo ""
echo "  • Rollback en cas de problème:"
echo "    helm rollback mqtt-sse-bridge -n $NAMESPACE"
echo ""

if [ "$ENV" = "prod" ]; then
    info "🌐 URL de production: https://api.toolsapps.eu/api/portal/events"
fi

echo ""
success "✨ Déploiement complet!"
