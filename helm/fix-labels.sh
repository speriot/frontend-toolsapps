#!/bin/bash

echo "🔧 CORRECTION LABELS ET TEST PODS"
echo "=================================="

NAMESPACE="production"
APP_NAME="frontend-toolsapps"

echo ""
echo "1️⃣  Vérification des labels actuels..."
kubectl get pods -n $NAMESPACE --show-labels | grep $APP_NAME

echo ""
echo "2️⃣  Test direct sur un pod..."
POD=$(kubectl get pods -n $NAMESPACE -o name | head -1 | cut -d'/' -f2)

if [ -z "$POD" ]; then
    echo "   ❌ Aucun pod trouvé!"
    exit 1
fi

echo "   Pod: $POD"

echo ""
echo "3️⃣  Test HTTP sur le pod (port 80)..."
echo "   Installation de curl si nécessaire..."
kubectl exec -n $NAMESPACE $POD -- sh -c "command -v curl > /dev/null || (apk add --no-cache curl 2>/dev/null || apt-get update && apt-get install -y curl 2>/dev/null || yum install -y curl 2>/dev/null)" 2>&1 | grep -v "WARNING"

echo "   Test HTTP..."
HTTP_RESPONSE=$(kubectl exec -n $NAMESPACE $POD -- curl -s -o /dev/null -w "%{http_code}" http://localhost:80 2>/dev/null)

if [ "$HTTP_RESPONSE" = "200" ]; then
    echo "   ✅ Pod répond 200 sur le port 80"
    echo ""
    echo "   Contenu de la page (20 premières lignes):"
    kubectl exec -n $NAMESPACE $POD -- curl -s http://localhost:80 2>/dev/null | head -20
elif [ "$HTTP_RESPONSE" = "404" ]; then
    echo "   ⚠️  Pod répond 404 (nginx fonctionne mais contenu manquant)"
else
    echo "   ❌ Pod ne répond pas correctement (code: $HTTP_RESPONSE)"
fi

echo ""
echo "4️⃣  Vérification du Service et sélecteurs..."
echo "   Sélecteurs du Service:"
kubectl get svc -n $NAMESPACE $APP_NAME -o jsonpath='{.spec.selector}' | jq '.'

echo ""
echo "   Labels des pods:"
kubectl get pods -n $NAMESPACE -o jsonpath='{.items[0].metadata.labels}' | jq '.'

echo ""
echo "5️⃣  Test du Service en interne..."
kubectl run test-curl-pod --rm -i --restart=Never --image=curlimages/curl -n $NAMESPACE -- curl -s -o /dev/null -w "Code HTTP: %{http_code}\n" http://$APP_NAME.$NAMESPACE.svc.cluster.local 2>&1

echo ""
echo "6️⃣  Vérification de l'Ingress..."
kubectl describe ingress -n $NAMESPACE $APP_NAME | grep -A 10 "Rules:"

echo ""
echo "7️⃣  Test HTTP externe..."
curl -I http://front.toolsapps.eu 2>&1 | head -15

echo ""
echo "=================================="
echo "✅ Diagnostic terminé"

