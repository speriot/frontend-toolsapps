#!/bin/bash
# Debug 404 dans namespace default

echo "🔍 DEBUG 404 DANS DEFAULT"
echo "========================="
echo ""

# 1. Vérifier les pods
echo "1️⃣  Pods frontend..."
kubectl get pods -n default -l app=frontend-toolsapps -o wide
echo ""

# 2. Vérifier le service
echo "2️⃣  Service..."
kubectl get svc -n default frontend-toolsapps -o wide
echo ""

# 3. Vérifier les endpoints
echo "3️⃣  Endpoints..."
kubectl get endpoints -n default frontend-toolsapps
echo ""

# 4. Test direct sur un pod
echo "4️⃣  Test direct sur un pod..."
POD=$(kubectl get pods -n default -l app=frontend-toolsapps -o jsonpath='{.items[0].metadata.name}')
echo "   Pod: $POD"
kubectl exec -n default $POD -- wget -qO- --timeout=5 http://localhost:80 2>/dev/null | head -5
echo ""

# 5. Vérifier l'Ingress
echo "5️⃣  Ingress..."
kubectl get ingress -n default front-toolsapps -o yaml
echo ""

# 6. Logs Traefik
echo "6️⃣  Logs Traefik..."
TRAEFIK_POD=$(kubectl get pods -n traefik -o jsonpath='{.items[0].metadata.name}')
kubectl logs -n traefik $TRAEFIK_POD --tail=30 2>/dev/null | grep -iE "front|default|error|404|cannot"
echo ""

# 7. Comparer avec API
echo "7️⃣  Comparaison Ingress API vs Frontend..."
echo "   API:"
kubectl get ingress -n default api-node-api-node -o jsonpath='   Host: {.spec.rules[0].host}, Service: {.spec.rules[0].http.paths[0].backend.service.name}'
echo ""
echo "   Frontend:"
kubectl get ingress -n default front-toolsapps -o jsonpath='   Host: {.spec.rules[0].host}, Service: {.spec.rules[0].http.paths[0].backend.service.name}'
echo ""
echo ""

# 8. Test interne du service
echo "8️⃣  Test interne du service..."
kubectl run test-svc --rm -i --restart=Never --image=busybox -n default -- wget -qO- --timeout=5 http://frontend-toolsapps:80 2>/dev/null | head -3
echo ""

echo "========================="

