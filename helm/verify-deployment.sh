#!/bin/bash

echo "🔍 DIAGNOSTIC COMPLET POST-CORRECTION"
echo "====================================="

NAMESPACE="production"
APP_NAME="frontend-toolsapps"

echo ""
echo "1️⃣  État des Pods:"
kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=$APP_NAME -o wide

echo ""
echo "2️⃣  État du Service:"
kubectl get svc -n $NAMESPACE $APP_NAME

echo ""
echo "3️⃣  Endpoints du Service (IPs des pods):"
kubectl get endpoints -n $NAMESPACE $APP_NAME

echo ""
echo "4️⃣  État de l'Ingress:"
kubectl get ingress -n $NAMESPACE $APP_NAME

echo ""
echo "5️⃣  Test HTTP sur un pod directement:"
POD=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=$APP_NAME -o jsonpath='{.items[0].metadata.name}')
if [ -n "$POD" ]; then
    echo "   Pod testé: $POD"
    HTTP_CODE=$(kubectl exec -n $NAMESPACE $POD -- wget -q -O- --timeout=5 http://localhost:80 2>/dev/null | head -1 | wc -l)
    if [ "$HTTP_CODE" -gt 0 ]; then
        echo "   ✅ Pod répond correctement"
    else
        echo "   ❌ Pod ne répond pas"
    fi
fi

echo ""
echo "6️⃣  Test via le Service (depuis un autre pod):"
kubectl run test-from-pod --rm -i --restart=Never --image=busybox:1.36 -n $NAMESPACE -- /bin/sh -c "wget -q -O- --timeout=5 http://$APP_NAME:80 | head -5" 2>&1 | grep -v "pod.*deleted"

echo ""
echo "7️⃣  Test HTTP externe (depuis le VPS):"
HTTP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://front.toolsapps.eu)
echo "   Code HTTP: $HTTP_RESPONSE"

if [ "$HTTP_RESPONSE" = "200" ]; then
    echo "   ✅ Ingress fonctionne correctement!"
    echo ""
    echo "   Aperçu du contenu:"
    curl -s http://front.toolsapps.eu | head -20
fi

echo ""
echo "8️⃣  Test HTTPS (certificat):"
HTTPS_RESPONSE=$(curl -k -s -o /dev/null -w "%{http_code}" https://front.toolsapps.eu)
echo "   Code HTTP: $HTTPS_RESPONSE"

if [ "$HTTPS_RESPONSE" = "200" ]; then
    echo "   ✅ HTTPS fonctionne!"
    echo ""
    echo "   Informations certificat:"
    kubectl get certificate -n $NAMESPACE frontend-toolsapps-tls -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}' 2>/dev/null
    echo ""
fi

echo ""
echo "9️⃣  Vérification DNS:"
echo "   Résolution DNS de front.toolsapps.eu:"
nslookup front.toolsapps.eu | grep -A 2 "Name:"

echo ""
echo "====================================="
echo "📊 RÉSUMÉ:"
echo ""

# Comptage des pods
POD_COUNT=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=$APP_NAME --no-headers 2>/dev/null | wc -l)
READY_PODS=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=$APP_NAME --no-headers 2>/dev/null | grep "Running" | wc -l)

echo "   Pods: $READY_PODS/$POD_COUNT Ready"

# Test endpoints
ENDPOINTS=$(kubectl get endpoints -n $NAMESPACE $APP_NAME -o jsonpath='{.subsets[0].addresses}' 2>/dev/null | grep -o "ip" | wc -l)
echo "   Endpoints: $ENDPOINTS IPs"

# Test HTTP
if [ "$HTTP_RESPONSE" = "200" ]; then
    echo "   HTTP: ✅ Fonctionne"
else
    echo "   HTTP: ❌ Ne fonctionne pas (code: $HTTP_RESPONSE)"
fi

# Test HTTPS
if [ "$HTTPS_RESPONSE" = "200" ]; then
    echo "   HTTPS: ✅ Fonctionne"
else
    echo "   HTTPS: ⚠️  Problème (code: $HTTPS_RESPONSE)"
fi

echo ""
if [ "$HTTP_RESPONSE" = "200" ]; then
    echo "🎉 APPLICATION DÉPLOYÉE AVEC SUCCÈS!"
    echo ""
    echo "📱 Accédez à votre application:"
    echo "   👉 http://front.toolsapps.eu"
    echo "   👉 https://front.toolsapps.eu (certificat staging)"
else
    echo "⚠️  Il reste des problèmes à résoudre"
fi

echo ""
echo "====================================="

