#!/bin/bash
# Script de diagnostic 404 - Vérifier pods et service

echo "🔍 DIAGNOSTIC 404 - Application"
echo "================================"
echo ""

echo "1️⃣  Vérification des Pods..."
kubectl get pods -n production -o wide
echo ""

POD_COUNT=$(kubectl get pods -n production -l app.kubernetes.io/name=frontend-toolsapps --field-selector=status.phase=Running 2>/dev/null | grep -v NAME | wc -l)
echo "   Pods Running: $POD_COUNT"
echo ""

if [ "$POD_COUNT" -eq 0 ]; then
    echo "   ❌ Aucun pod Running!"
    echo ""
    echo "   Détails des pods:"
    kubectl describe pods -n production -l app.kubernetes.io/name=frontend-toolsapps | tail -30
    exit 1
fi

echo "2️⃣  Vérification du Service..."
kubectl get svc -n production
echo ""

SERVICE_EXISTS=$(kubectl get svc frontend-toolsapps -n production 2>/dev/null | grep -v NAME | wc -l)
if [ "$SERVICE_EXISTS" -eq 0 ]; then
    echo "   ❌ Service 'frontend-toolsapps' n'existe pas!"
    exit 1
fi

echo "3️⃣  Vérification des Endpoints..."
kubectl get endpoints frontend-toolsapps -n production
echo ""

ENDPOINT_COUNT=$(kubectl get endpoints frontend-toolsapps -n production -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null | wc -w)
echo "   Endpoints disponibles: $ENDPOINT_COUNT"

if [ "$ENDPOINT_COUNT" -eq 0 ]; then
    echo "   ❌ Aucun endpoint! Les pods ne sont pas connectés au service"
    echo ""
    echo "   Vérification des labels:"
    echo "   Labels du service:"
    kubectl get svc frontend-toolsapps -n production -o jsonpath='{.spec.selector}' | jq .
    echo ""
    echo "   Labels des pods:"
    kubectl get pods -n production -l app.kubernetes.io/name=frontend-toolsapps -o jsonpath='{.items[0].metadata.labels}' | jq .
    exit 1
fi

echo ""
echo "4️⃣  Test direct d'un pod (port 80)..."
POD_NAME=$(kubectl get pods -n production -l app.kubernetes.io/name=frontend-toolsapps -o jsonpath='{.items[0].metadata.name}')
echo "   Pod testé: $POD_NAME"

kubectl exec -n production $POD_NAME -- wget -O- http://localhost:80 2>/dev/null | head -10

if [ $? -eq 0 ]; then
    echo ""
    echo "   ✅ Le pod répond correctement sur le port 80"
else
    echo ""
    echo "   ❌ Le pod ne répond pas sur le port 80"
    echo ""
    echo "   Logs du pod:"
    kubectl logs -n production $POD_NAME --tail=20
    exit 1
fi

echo ""
echo "5️⃣  Vérification de l'Ingress..."
kubectl get ingress frontend-toolsapps -n production
echo ""

echo "   Configuration de routing:"
kubectl get ingress frontend-toolsapps -n production -o yaml | grep -A 10 "backend:"
echo ""

echo "6️⃣  Test du Service en interne..."
kubectl run -n production test-curl --image=curlimages/curl:latest --rm -i --restart=Never -- \
  curl -s http://frontend-toolsapps.production.svc.cluster.local:80 | head -10

if [ $? -eq 0 ]; then
    echo ""
    echo "   ✅ Le service répond en interne"
else
    echo ""
    echo "   ❌ Le service ne répond pas en interne"
fi

echo ""
echo "7️⃣  Logs de l'Ingress Controller..."
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller --tail=20 | grep "front.toolsapps.eu"
echo ""

echo "================================"
echo "📝 Diagnostic terminé"
echo ""
echo "Si tout est vert ci-dessus, le problème vient probablement"
echo "de la configuration de l'Ingress qui ne route pas correctement."

