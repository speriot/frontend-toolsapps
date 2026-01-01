#!/bin/bash
# Test simple du frontend après restauration API

echo "🔍 TEST FRONTEND APRÈS RESTAURATION"
echo "===================================="
echo ""

# 1. Test HTTP frontend
echo "1️⃣  Test HTTP frontend..."
HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://front.toolsapps.eu 2>/dev/null)
echo "   Code: $HTTP"

if [ "$HTTP" == "200" ]; then
    echo "   ✅ HTTP fonctionne!"
    echo ""
    echo "   Contenu:"
    curl -s http://front.toolsapps.eu 2>/dev/null | head -5
    echo ""
    echo "===================================="
    echo "🎉 FRONTEND HTTP FONCTIONNE!"
    echo "===================================="
    exit 0
fi

# 2. Si 502, vérifier les logs Traefik
echo ""
echo "2️⃣  Logs Traefik pour frontend..."
TRAEFIK_POD=$(kubectl get pods -n traefik -o jsonpath='{.items[0].metadata.name}')
kubectl logs -n traefik $TRAEFIK_POD --tail=30 2>/dev/null | grep -iE "frontend|production|502|error|cannot"
echo ""

# 3. Vérifier si le problème est le namespace
echo "3️⃣  Test connectivité interne..."
echo "   Depuis le namespace traefik vers production:"
kubectl run test-internal --rm -i --restart=Never --image=busybox -n traefik -- wget -qO- --timeout=5 http://frontend-toolsapps.production.svc.cluster.local:80 2>/dev/null | head -3
echo ""

# 4. Vérifier les NetworkPolicies
echo "4️⃣  NetworkPolicies dans production..."
kubectl get networkpolicies -n production
echo ""

# 5. Comparer avec l'API
echo "5️⃣  L'API est dans quel namespace?"
kubectl get svc --all-namespaces | grep api-node
echo ""

echo "===================================="
echo "📋 ANALYSE:"
echo ""
echo "   L'API est dans 'default', le frontend dans 'production'"
echo "   Traefik peut accéder à 'default' mais peut-être pas 'production'"
echo ""
echo "   Options:"
echo "   1. Déplacer le frontend dans 'default' (comme l'API)"
echo "   2. Configurer Traefik pour accéder à 'production'"
echo "===================================="

