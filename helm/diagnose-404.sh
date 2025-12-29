#!/bin/bash

echo "🔍 DIAGNOSTIC 404 - ANALYSE RAPIDE"
echo "==================================="

NAMESPACE="production"
APP_NAME="frontend-toolsapps"

echo ""
echo "📦 1. Vérification des Pods..."
kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=frontend-toolsapps -o wide

if [ $? -ne 0 ]; then
    echo "   ⚠️  Aucun pod avec label app.kubernetes.io/name"
    echo "   Essai avec autre label..."
    kubectl get pods -n $NAMESPACE -o wide
fi

echo ""
echo "🔌 2. Vérification du Service..."
kubectl get svc -n $NAMESPACE $APP_NAME -o yaml | grep -A 5 "selector:"

echo ""
echo "🌐 3. Test direct sur un pod..."
POD=$(kubectl get pods -n $NAMESPACE --no-headers -o custom-columns=":metadata.name" | head -1)

if [ -n "$POD" ]; then
    echo "   Pod sélectionné: $POD"
    echo "   Test curl sur localhost:80..."

    # Test si curl existe, sinon l'installer
    kubectl exec -n $NAMESPACE $POD -- which curl > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "   Installation de curl..."
        kubectl exec -n $NAMESPACE $POD -- sh -c "apk add --no-cache curl 2>/dev/null || apt-get update && apt-get install -y curl 2>/dev/null" > /dev/null 2>&1
    fi

    # Test HTTP
    RESULT=$(kubectl exec -n $NAMESPACE $POD -- curl -s -w "\n%{http_code}" http://localhost:80 2>/dev/null)
    HTTP_CODE=$(echo "$RESULT" | tail -1)
    CONTENT=$(echo "$RESULT" | head -n -1)

    echo "   Code HTTP: $HTTP_CODE"

    if [ "$HTTP_CODE" = "200" ]; then
        echo "   ✅ Pod répond 200"
        echo "   Contenu:"
        echo "$CONTENT" | head -10
    elif [ "$HTTP_CODE" = "404" ]; then
        echo "   ⚠️  Pod répond 404 - Nginx fonctionne mais fichiers manquants"
        echo "   Vérification de l'image Docker..."
        kubectl get pods -n $NAMESPACE $POD -o jsonpath='{.spec.containers[0].image}'
        echo ""
    else
        echo "   ❌ Erreur: $HTTP_CODE"
    fi
else
    echo "   ❌ Aucun pod trouvé!"
fi

echo ""
echo "🔗 4. Test du Service Kubernetes..."
echo "   Création d'un pod de test..."
kubectl run test-service --rm -i --restart=Never --image=curlimages/curl -n $NAMESPACE -- sh -c "curl -s -w '\nHTTP Code: %{http_code}\n' http://$APP_NAME.$NAMESPACE.svc.cluster.local" 2>&1 | tail -20

echo ""
echo "🌍 5. Test Ingress externe..."
curl -I http://front.toolsapps.eu 2>&1 | head -10

echo ""
echo "==================================="
echo "✅ Diagnostic terminé"
echo ""
echo "📝 ANALYSE:"
echo "   - Si pod répond 200 mais Ingress 404 → Problème de routing"
echo "   - Si pod répond 404 → Problème dans l'image Docker"
echo "   - Si pod ne répond pas → Problème de port"

