#!/bin/bash
# Script de déploiement du backend MQTT-SSE en production

set -e

echo "🚀 Déploiement du backend MQTT-SSE en production"
echo ""

NAMESPACE="production"
RELEASE_NAME="mqtt-sse-bridge"
CHART_PATH="./helm/mqtt-sse-bridge"
VALUES_FILE="values-prod.yaml"

# 1. Créer le secret MQTT si il n'existe pas
echo "🔐 Création du secret MQTT..."
kubectl get secret mqtt-credentials -n $NAMESPACE &>/dev/null || \
kubectl create secret generic mqtt-credentials \
  --from-literal=host='wss://3d3f4f89176c45f38dab27f19cc275b4.s1.eu.hivemq.cloud:8884/mqtt' \
  --from-literal=username='portal569' \
  --from-literal=password='FMBUUX288547bbxiio' \
  --namespace $NAMESPACE

echo "✅ Secret MQTT créé/vérifié"
echo ""

# 2. Déployer avec Helm
echo "📦 Déploiement Helm..."
helm upgrade --install $RELEASE_NAME $CHART_PATH \
  --namespace $NAMESPACE \
  --create-namespace \
  --values $CHART_PATH/$VALUES_FILE \
  --wait \
  --timeout 5m

echo ""
echo "✅ Déploiement terminé !"
echo ""

# 3. Vérification
echo "🔍 Vérification du déploiement..."
kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=mqtt-sse-bridge
echo ""

kubectl get svc -n $NAMESPACE -l app.kubernetes.io/name=mqtt-sse-bridge
echo ""

kubectl get ingress -n $NAMESPACE -l app.kubernetes.io/name=mqtt-sse-bridge
echo ""

echo "✅ Backend MQTT-SSE déployé avec succès !"
echo ""
echo "🌐 URL: https://api.toolsapps.eu/api/portal/events"
echo ""
echo "📝 Pour voir les logs:"
echo "   kubectl logs -n $NAMESPACE -l app.kubernetes.io/name=mqtt-sse-bridge -f"
