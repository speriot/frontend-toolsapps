#!/bin/bash
# Diagnostic approfondi du routing Traefik

echo "🔍 DIAGNOSTIC APPROFONDI TRAEFIK"
echo "================================="
echo ""

# 1. Vérifier où est Traefik
echo "1️⃣  Localisation de Traefik..."
echo "   Namespace kube-system:"
kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik 2>/dev/null
echo ""
echo "   Namespace traefik:"
kubectl get pods -n traefik 2>/dev/null
echo ""
echo "   Namespace default:"
kubectl get pods -n default -l app.kubernetes.io/name=traefik 2>/dev/null
echo ""
echo "   Tous les pods traefik:"
kubectl get pods --all-namespaces | grep -i traefik
echo ""

# Trouver le namespace de Traefik
TRAEFIK_NS=$(kubectl get pods --all-namespaces -o wide | grep traefik | head -1 | awk '{print $1}')
TRAEFIK_POD=$(kubectl get pods --all-namespaces -o wide | grep traefik | head -1 | awk '{print $2}')
echo "   Traefik trouvé: $TRAEFIK_NS / $TRAEFIK_POD"
echo ""

# 2. Logs Traefik
echo "2️⃣  Logs Traefik (dernières lignes)..."
if [ -n "$TRAEFIK_NS" ] && [ -n "$TRAEFIK_POD" ]; then
    kubectl logs -n $TRAEFIK_NS $TRAEFIK_POD --tail=30 2>/dev/null
fi
echo ""

# 3. Vérifier l'Ingress api qui fonctionne
echo "3️⃣  Configuration de l'Ingress api.toolsapps.eu (qui fonctionne)..."
kubectl get ingress -n default api-node-api-node -o yaml 2>/dev/null | head -50
echo ""

# 4. Vérifier l'Ingress front
echo "4️⃣  Configuration de l'Ingress front.toolsapps.eu..."
kubectl get ingress -n production frontend-toolsapps -o yaml 2>/dev/null
echo ""

# 5. Vérifier les IngressRoutes Traefik (si utilisé)
echo "5️⃣  IngressRoutes Traefik..."
kubectl get ingressroute --all-namespaces 2>/dev/null
echo ""

# 6. Vérifier les challenges
echo "6️⃣  Challenges cert-manager..."
kubectl get challenges -n production -o wide
echo ""
kubectl describe challenges -n production 2>/dev/null | grep -A 20 "Status:"
echo ""

# 7. Vérifier le service de l'API
echo "7️⃣  Service de api.toolsapps.eu..."
kubectl get svc -n default -l app.kubernetes.io/instance=api-node
echo ""

# 8. Comparer les deux Ingress
echo "8️⃣  Comparaison des deux Ingress..."
echo ""
echo "   API (fonctionne):"
kubectl get ingress -n default api-node-api-node -o jsonpath='
   Class: {.spec.ingressClassName}
   Host: {.spec.rules[0].host}
   Path: {.spec.rules[0].http.paths[0].path}
   PathType: {.spec.rules[0].http.paths[0].pathType}
   Service: {.spec.rules[0].http.paths[0].backend.service.name}
   Port: {.spec.rules[0].http.paths[0].backend.service.port.number}
' 2>/dev/null
echo ""
echo ""
echo "   FRONT (ne fonctionne pas):"
kubectl get ingress -n production frontend-toolsapps -o jsonpath='
   Class: {.spec.ingressClassName}
   Host: {.spec.rules[0].host}
   Path: {.spec.rules[0].http.paths[0].path}
   PathType: {.spec.rules[0].http.paths[0].pathType}
   Service: {.spec.rules[0].http.paths[0].backend.service.name}
   Port: {.spec.rules[0].http.paths[0].backend.service.port.number}
' 2>/dev/null
echo ""
echo ""

# 9. Vérifier si Traefik voit l'Ingress
echo "9️⃣  Événements Ingress frontend..."
kubectl describe ingress -n production frontend-toolsapps 2>/dev/null | tail -20
echo ""

# 10. Test du service directement
echo "🔟 Test du service en interne..."
kubectl run test-curl --rm -i --restart=Never --image=curlimages/curl -n production -- curl -s -o /dev/null -w "Code: %{http_code}\n" http://frontend-toolsapps:80 2>/dev/null
echo ""

echo "================================="
echo "📋 ANALYSE"
echo "================================="

