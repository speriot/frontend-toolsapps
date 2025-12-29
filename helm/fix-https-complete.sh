#!/bin/bash

echo "🔧 CORRECTION COMPLÈTE - HTTPS 404 + PODS"
echo "=========================================="

NAMESPACE="production"
APP_NAME="frontend-toolsapps"

echo ""
echo "📋 Problèmes identifiés:"
echo "   1. HTTPS retourne 404 (HTTP fonctionne)"
echo "   2. Pods ne répondent pas aux tests internes"
echo ""
echo "🔍 Cause:"
echo "   - Configuration Ingress HTTPS incorrecte"
echo "   - Nginx dans les pods écoute peut-être sur un autre port"
echo ""

read -p "Continuer avec la correction complète? (o/N) " CONFIRM
if [ "$CONFIRM" != "o" ] && [ "$CONFIRM" != "O" ]; then
    exit 0
fi

echo ""
echo "1️⃣  Vérification de la configuration des pods..."
POD=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=$APP_NAME -o jsonpath='{.items[0].metadata.name}')
echo "   Pod testé: $POD"

echo ""
echo "   Ports exposés dans le pod:"
kubectl get pod -n $NAMESPACE $POD -o jsonpath='{.spec.containers[0].ports}' | jq '.'

echo ""
echo "   Test sur le pod avec différents ports..."
for PORT in 80 8080 3000; do
    echo -n "   Port $PORT: "
    RESULT=$(kubectl exec -n $NAMESPACE $POD -- wget -q -O- --timeout=2 http://localhost:$PORT 2>/dev/null | head -1)
    if [ -n "$RESULT" ]; then
        echo "✅ Répond"
    else
        echo "❌ Ne répond pas"
    fi
done

echo ""
echo "2️⃣  Correction de l'Ingress pour HTTPS..."
kubectl delete ingress $APP_NAME -n $NAMESPACE 2>/dev/null

cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: $APP_NAME
  namespace: $NAMESPACE
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-staging
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - front.toolsapps.eu
    secretName: frontend-toolsapps-tls
  rules:
  - host: front.toolsapps.eu
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: $APP_NAME
            port:
              number: 80
EOF

echo "   ✅ Ingress recréé"

echo ""
echo "3️⃣  Vérification de la configuration du Service..."
kubectl get svc -n $NAMESPACE $APP_NAME -o yaml | grep -A 10 "spec:"

echo ""
echo "4️⃣  Vérification des Endpoints..."
kubectl get endpoints -n $NAMESPACE $APP_NAME -o yaml | grep -A 20 "subsets:"

echo ""
echo "5️⃣  Redémarrage de l'Ingress Controller..."
kubectl delete pods -n kube-system -l app.kubernetes.io/name=ingress-nginx
echo "   ✅ Ingress Controller en cours de redémarrage..."

echo ""
echo "6️⃣  Attente du redémarrage (30 secondes)..."
sleep 30

echo ""
echo "7️⃣  Test HTTP..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://front.toolsapps.eu)
echo "   Code HTTP: $HTTP_CODE"

if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✅ HTTP OK"
else
    echo "   ❌ HTTP KO"
fi

echo ""
echo "8️⃣  Test HTTPS..."
HTTPS_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://front.toolsapps.eu)
echo "   Code HTTPS: $HTTPS_CODE"

if [ "$HTTPS_CODE" = "200" ]; then
    echo "   ✅ HTTPS OK"
    echo ""
    echo "   Aperçu du contenu HTTPS:"
    curl -k -s https://front.toolsapps.eu | head -15
elif [ "$HTTPS_CODE" = "404" ]; then
    echo "   ❌ HTTPS retourne toujours 404"
    echo ""
    echo "   🔍 Analyse approfondie..."

    echo ""
    echo "   📝 Configuration Ingress complète:"
    kubectl get ingress -n $NAMESPACE $APP_NAME -o yaml

    echo ""
    echo "   📝 Logs Ingress Controller (dernières 30 lignes):"
    INGRESS_POD=$(kubectl get pods -n kube-system -l app.kubernetes.io/name=ingress-nginx -o jsonpath='{.items[0].metadata.name}')
    kubectl logs -n kube-system $INGRESS_POD --tail=30 | grep -i "front.toolsapps.eu\|404\|error\|upstream"
else
    echo "   ⚠️  Code inattendu: $HTTPS_CODE"
fi

echo ""
echo "9️⃣  Test depuis l'intérieur du cluster..."
kubectl run test-internal --rm -i --restart=Never --image=curlimages/curl -n $NAMESPACE -- sh -c "
echo 'Test direct au service sur port 80:'
curl -s -o /dev/null -w 'HTTP Code: %{http_code}\n' http://$APP_NAME:80 --max-time 5
echo ''
echo 'Contenu de la réponse:'
curl -s http://$APP_NAME:80 --max-time 5 | head -5
" 2>&1 | grep -v "pod.*deleted"

echo ""
echo "=========================================="

if [ "$HTTP_CODE" = "200" ] && [ "$HTTPS_CODE" = "200" ]; then
    echo "🎉 SUCCÈS COMPLET!"
    echo ""
    echo "✅ HTTP fonctionne"
    echo "✅ HTTPS fonctionne"
    echo ""
    echo "📱 Testez dans votre navigateur:"
    echo "   👉 http://front.toolsapps.eu"
    echo "   👉 https://front.toolsapps.eu"
elif [ "$HTTP_CODE" = "200" ] && [ "$HTTPS_CODE" != "200" ]; then
    echo "⚠️  HTTP fonctionne mais HTTPS a encore un problème"
    echo ""
    echo "🔍 Prochaines étapes possibles:"
    echo "   1. Vérifier si le certificat TLS est valide"
    echo "   2. Vérifier les logs de cert-manager"
    echo "   3. Essayer de recréer le certificat"
    echo ""
    echo "Commandes de diagnostic:"
    echo "   kubectl describe ingress -n $NAMESPACE $APP_NAME"
    echo "   kubectl get certificate -n $NAMESPACE"
    echo "   kubectl logs -n cert-manager -l app=cert-manager --tail=50"
else
    echo "❌ Problème persistant"
    echo ""
    echo "HTTP: $HTTP_CODE"
    echo "HTTPS: $HTTPS_CODE"
fi

echo ""
echo "=========================================="

