#!/bin/bash
# Fix Traefik service not found

echo "🔧 FIX TRAEFIK - SERVICE NOT FOUND"
echo "==================================="
echo ""

# 1. Vérifier l'état actuel
echo "1️⃣  État actuel..."
echo "   Service:"
kubectl get svc -n production frontend-toolsapps
echo ""
echo "   Endpoints:"
kubectl get endpoints -n production frontend-toolsapps
echo ""
echo "   Ingress:"
kubectl get ingress -n production frontend-toolsapps
echo ""

# 2. Redémarrer Traefik pour vider son cache
echo "2️⃣  Redémarrage de Traefik..."
kubectl rollout restart deployment -n traefik traefik
echo "   Attente du redémarrage..."
kubectl rollout status deployment -n traefik traefik --timeout=60s
echo "   ✅ Traefik redémarré"
sleep 5

# 3. Vérifier les logs Traefik
echo ""
echo "3️⃣  Logs Traefik après redémarrage..."
TRAEFIK_POD=$(kubectl get pods -n traefik -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
kubectl logs -n traefik $TRAEFIK_POD --tail=10 2>/dev/null
echo ""

# 4. Recréer l'Ingress pour forcer Traefik à le recharger
echo "4️⃣  Recréation de l'Ingress..."
kubectl delete ingress frontend-toolsapps -n production 2>/dev/null || true
sleep 3

cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: frontend-toolsapps
  namespace: production
spec:
  ingressClassName: traefik
  rules:
  - host: front.toolsapps.eu
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-toolsapps
            port:
              number: 80
EOF
echo "   ✅ Ingress recréé"
sleep 5

# 5. Vérifier les logs Traefik pour le nouvel Ingress
echo ""
echo "5️⃣  Logs Traefik après création Ingress..."
kubectl logs -n traefik $TRAEFIK_POD --tail=15 2>/dev/null | grep -iE "frontend|production|error|updated"
echo ""

# 6. Test HTTP
echo "6️⃣  Test HTTP..."
for i in {1..10}; do
    HTTP=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://front.toolsapps.eu 2>/dev/null)
    echo "   Tentative $i: HTTP = $HTTP"
    if [ "$HTTP" == "200" ]; then
        echo "   ✅ HTTP fonctionne!"
        echo ""
        echo "   Contenu:"
        curl -s http://front.toolsapps.eu 2>/dev/null | head -5
        break
    fi
    sleep 3
done

echo ""
echo "==================================="
if [ "$HTTP" == "200" ]; then
    echo "🎉 SUCCÈS!"
    echo ""
    echo "✅ http://front.toolsapps.eu fonctionne!"
    echo ""
    echo "📝 Prochaine étape: ajouter TLS"
    echo "   ./helm/add-tls-staging.sh"
else
    echo "❌ Toujours 404"
    echo ""
    echo "   Vérification détaillée..."
    echo ""
    echo "   Service existe?"
    kubectl get svc -n production frontend-toolsapps -o wide
    echo ""
    echo "   Ingress voit le service?"
    kubectl describe ingress -n production frontend-toolsapps | grep -A 5 "Rules:"
    echo ""
    echo "   Traefik voit l'Ingress?"
    kubectl logs -n traefik $TRAEFIK_POD --tail=20 2>/dev/null | grep -i "frontend"
    echo ""
    echo "   Test DNS:"
    nslookup front.toolsapps.eu 2>/dev/null | tail -3
fi
echo "==================================="

