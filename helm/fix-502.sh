#!/bin/bash
# Diagnostic et fix du 502 Bad Gateway

echo "🔧 FIX 502 BAD GATEWAY"
echo "======================"
echo ""

# 1. Vérifier les pods
echo "1️⃣  État des Pods..."
kubectl get pods -n production -o wide
echo ""

# 2. Vérifier si les pods sont vraiment prêts
echo "2️⃣  Détails des Pods..."
kubectl describe pods -n production | grep -A 5 "Conditions:"
echo ""

# 3. Vérifier le Service
echo "3️⃣  Service..."
kubectl get svc -n production frontend-toolsapps -o yaml
echo ""

# 4. Vérifier les Endpoints
echo "4️⃣  Endpoints..."
kubectl get endpoints -n production frontend-toolsapps
kubectl get endpointslices -n production -l kubernetes.io/service-name=frontend-toolsapps
echo ""

# 5. Test direct sur le pod
echo "5️⃣  Test direct sur le pod..."
POD=$(kubectl get pods -n production -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$POD" ]; then
    echo "   Pod: $POD"
    echo "   Test curl localhost:80..."
    kubectl exec -n production $POD -- curl -s -o /dev/null -w "Code: %{http_code}\n" http://localhost:80 2>/dev/null || echo "   curl non disponible, test wget..."
    kubectl exec -n production $POD -- wget -qO- --timeout=5 http://localhost:80 2>/dev/null | head -3
fi
echo ""

# 6. Vérifier l'Ingress
echo "6️⃣  Ingress actuel..."
kubectl get ingress -n production frontend-toolsapps -o yaml
echo ""

# 7. Logs Traefik
echo "7️⃣  Logs Traefik (erreurs récentes)..."
TRAEFIK_POD=$(kubectl get pods -n traefik -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$TRAEFIK_POD" ]; then
    kubectl logs -n traefik $TRAEFIK_POD --tail=20 2>/dev/null | grep -iE "error|502|frontend|production"
fi
echo ""

# 8. Vérifier si le namespace production est accessible par Traefik
echo "8️⃣  Vérification accès cross-namespace..."
echo "   Traefik est dans: traefik"
echo "   Frontend est dans: production"
echo ""

# 9. Tester la connectivité depuis Traefik vers le service
echo "9️⃣  Test connectivité Traefik → Service..."
kubectl run test-conn --rm -i --restart=Never --image=curlimages/curl -n traefik -- curl -s -o /dev/null -w "Code: %{http_code}\n" --connect-timeout 5 http://frontend-toolsapps.production.svc.cluster.local:80 2>/dev/null || echo "   Test échoué"
echo ""

# 10. Comparer avec l'API qui fonctionne
echo "🔟 Comparaison avec API (qui fonctionne)..."
echo "   Service API:"
kubectl get svc -n default -l app.kubernetes.io/instance=api-node 2>/dev/null || kubectl get svc -n default api-node-api-node 2>/dev/null
echo ""

echo "======================"
echo "📋 DIAGNOSTIC"
echo "======================"
echo ""

# Vérifier si c'est un problème de port
SVC_PORT=$(kubectl get svc -n production frontend-toolsapps -o jsonpath='{.spec.ports[0].port}')
TARGET_PORT=$(kubectl get svc -n production frontend-toolsapps -o jsonpath='{.spec.ports[0].targetPort}')
echo "   Service Port: $SVC_PORT"
echo "   Target Port: $TARGET_PORT"
echo ""

# Vérifier le containerPort des pods
CONTAINER_PORT=$(kubectl get pods -n production -o jsonpath='{.items[0].spec.containers[0].ports[0].containerPort}' 2>/dev/null)
echo "   Container Port: $CONTAINER_PORT"
echo ""

if [ "$TARGET_PORT" != "$CONTAINER_PORT" ] && [ "$TARGET_PORT" != "80" ]; then
    echo "   ⚠️  MISMATCH: Target port ($TARGET_PORT) != Container port ($CONTAINER_PORT)"
fi

echo ""
read -p "Voulez-vous recréer le service et redéployer? (o/N) " confirm
if [ "$confirm" != "o" ] && [ "$confirm" != "O" ]; then
    echo "Annulé."
    exit 0
fi

echo ""
echo "🔧 CORRECTION..."
echo ""

# Supprimer et recréer le service
echo "A. Recréation du Service..."
kubectl delete svc frontend-toolsapps -n production 2>/dev/null || true
sleep 2

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: frontend-toolsapps
  namespace: production
spec:
  type: ClusterIP
  selector:
    app.kubernetes.io/name: frontend-toolsapps
    app.kubernetes.io/instance: frontend-toolsapps
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
    name: http
EOF
echo "   ✅ Service recréé"
sleep 3

# Vérifier les endpoints
echo ""
echo "B. Vérification des Endpoints..."
kubectl get endpoints -n production frontend-toolsapps
echo ""

# Redémarrer les pods
echo "C. Redémarrage des Pods..."
kubectl rollout restart deployment frontend-toolsapps -n production
kubectl rollout status deployment frontend-toolsapps -n production --timeout=60s
echo ""

# Recréer l'Ingress
echo "D. Recréation de l'Ingress HTTP..."
kubectl delete ingress frontend-toolsapps -n production 2>/dev/null || true
sleep 2

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
echo "   ✅ Ingress créé"
sleep 5

# Test final
echo ""
echo "E. Test HTTP..."
for i in {1..10}; do
    HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://front.toolsapps.eu 2>/dev/null)
    echo "   Tentative $i: HTTP = $HTTP"
    if [ "$HTTP" == "200" ]; then
        echo "   ✅ HTTP fonctionne!"
        break
    fi
    sleep 3
done

echo ""
echo "======================"
if [ "$HTTP" == "200" ]; then
    echo "🎉 SUCCÈS! HTTP fonctionne!"
    echo ""
    echo "   Maintenant exécutez: ./helm/fix-2-steps.sh"
    echo "   pour ajouter le certificat TLS"
else
    echo "❌ Problème persistant"
    echo ""
    echo "   Logs Traefik:"
    kubectl logs -n traefik $TRAEFIK_POD --tail=10 2>/dev/null
fi
echo "======================"

