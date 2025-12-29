#!/bin/bash

echo "🔍 DIAGNOSTIC HTTPS 404"
echo "======================="

NAMESPACE="production"
APP_NAME="frontend-toolsapps"

echo ""
echo "1️⃣  Test HTTP vs HTTPS..."
echo "   HTTP:"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://front.toolsapps.eu)
echo "   Code: $HTTP_CODE"

echo ""
echo "   HTTPS:"
HTTPS_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://front.toolsapps.eu)
echo "   Code: $HTTPS_CODE"

echo ""
echo "2️⃣  Vérification du certificat..."
kubectl get certificate -n $NAMESPACE frontend-toolsapps-tls -o yaml | grep -A 10 "status:"

echo ""
echo "3️⃣  Vérification du secret TLS..."
if kubectl get secret frontend-toolsapps-tls -n $NAMESPACE &>/dev/null; then
    echo "   ✅ Secret TLS existe"
    kubectl get secret frontend-toolsapps-tls -n $NAMESPACE -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout 2>/dev/null | grep -E "Issuer:|Subject:|Not After"
else
    echo "   ❌ Secret TLS manquant"
fi

echo ""
echo "4️⃣  Configuration Ingress..."
echo "   Hosts:"
kubectl get ingress -n $NAMESPACE $APP_NAME -o jsonpath='{.spec.rules[*].host}' && echo ""
echo ""
echo "   TLS:"
kubectl get ingress -n $NAMESPACE $APP_NAME -o jsonpath='{.spec.tls}' | jq '.'

echo ""
echo "5️⃣  Backends de l'Ingress..."
kubectl describe ingress -n $NAMESPACE $APP_NAME | grep -A 20 "Rules:"

echo ""
echo "6️⃣  Test depuis un pod interne..."
kubectl run test-https --rm -i --restart=Never --image=curlimages/curl -n $NAMESPACE -- sh -c "
  echo 'HTTP direct au service:'
  curl -s -o /dev/null -w 'Code: %{http_code}\n' http://$APP_NAME:80
  echo ''
  echo 'HTTPS via Ingress (depuis l exterieur):'
  curl -k -s -o /dev/null -w 'Code: %{http_code}\n' https://front.toolsapps.eu
" 2>&1 | grep -v "pod.*deleted"

echo ""
echo "7️⃣  Logs de l'Ingress Controller..."
INGRESS_POD=$(kubectl get pods -n kube-system -l app.kubernetes.io/name=ingress-nginx -o jsonpath='{.items[0].metadata.name}')
echo "   Pod Ingress: $INGRESS_POD"
echo "   Derniers logs (erreurs 404):"
kubectl logs -n kube-system $INGRESS_POD --tail=50 | grep -i "404\|error\|front.toolsapps.eu" | tail -10

echo ""
echo "8️⃣  Configuration SSL dans l'Ingress..."
kubectl get ingress -n $NAMESPACE $APP_NAME -o yaml | grep -A 5 "tls:"

echo ""
echo "======================="
echo "📊 ANALYSE:"
echo ""

if [ "$HTTP_CODE" = "200" ] && [ "$HTTPS_CODE" = "404" ]; then
    echo "❌ PROBLÈME: HTTP fonctionne mais HTTPS retourne 404"
    echo ""
    echo "💡 CAUSES POSSIBLES:"
    echo "   1. Le backend TLS de l'Ingress pointe vers un mauvais service"
    echo "   2. Le certificat TLS n'est pas correctement monté"
    echo "   3. L'Ingress Controller ne trouve pas le backend HTTPS"
    echo "   4. Problème de SNI (Server Name Indication)"
    echo ""
    echo "🔧 SOLUTION:"
    echo "   Exécutez: ./helm/fix-https-404.sh"
elif [ "$HTTP_CODE" = "200" ] && [ "$HTTPS_CODE" = "200" ]; then
    echo "✅ HTTP et HTTPS fonctionnent tous les deux!"
else
    echo "⚠️  Problème inattendu"
    echo "   HTTP: $HTTP_CODE"
    echo "   HTTPS: $HTTPS_CODE"
fi

echo ""
echo "======================="

