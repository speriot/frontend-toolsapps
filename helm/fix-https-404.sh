#!/bin/bash

echo "🔧 CORRECTION HTTPS 404"
echo "======================="

NAMESPACE="production"
APP_NAME="frontend-toolsapps"

echo ""
echo "📋 Problème: HTTP fonctionne (200) mais HTTPS retourne 404"
echo ""
echo "🔍 Cause probable:"
echo "   - L'Ingress HTTPS ne trouve pas le bon backend"
echo "   - Ou problème de configuration TLS/SSL"
echo ""

read -p "Continuer avec la correction? (o/N) " CONFIRM
if [ "$CONFIRM" != "o" ] && [ "$CONFIRM" != "O" ]; then
    exit 0
fi

echo ""
echo "1️⃣  Vérification de la configuration actuelle..."
kubectl get ingress -n $NAMESPACE $APP_NAME -o yaml > /tmp/ingress-backup.yaml
echo "   ✅ Backup sauvegardé: /tmp/ingress-backup.yaml"

echo ""
echo "2️⃣  Vérification du service..."
SVC_PORT=$(kubectl get svc -n $NAMESPACE $APP_NAME -o jsonpath='{.spec.ports[0].port}')
echo "   Service port: $SVC_PORT"

echo ""
echo "3️⃣  Patch de l'Ingress avec configuration explicite..."

# Supprimer et recréer l'Ingress avec la bonne configuration
kubectl delete ingress $APP_NAME -n $NAMESPACE

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
echo "4️⃣  Attente de la propagation (10 secondes)..."
sleep 10

echo ""
echo "5️⃣  Redémarrage de l'Ingress Controller..."
kubectl rollout restart deployment -n kube-system ingress-nginx-controller 2>/dev/null || \
kubectl delete pods -n kube-system -l app.kubernetes.io/name=ingress-nginx

echo "   ✅ Ingress Controller redémarré"

echo ""
echo "6️⃣  Attente du redémarrage (20 secondes)..."
sleep 20

echo ""
echo "7️⃣  Vérification des endpoints..."
kubectl get endpoints -n $NAMESPACE $APP_NAME

echo ""
echo "8️⃣  Test HTTP..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://front.toolsapps.eu)
echo "   Code HTTP: $HTTP_CODE"

echo ""
echo "9️⃣  Test HTTPS..."
HTTPS_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://front.toolsapps.eu)
echo "   Code HTTPS: $HTTPS_CODE"

echo ""
echo "🔟 Vérification du contenu HTTPS..."
if [ "$HTTPS_CODE" = "200" ]; then
    echo "   ✅ HTTPS fonctionne!"
    echo ""
    echo "   Aperçu du contenu:"
    curl -k -s https://front.toolsapps.eu | head -15
elif [ "$HTTPS_CODE" = "404" ]; then
    echo "   ❌ HTTPS retourne toujours 404"
    echo ""
    echo "   📝 Vérification détaillée:"
    echo ""
    echo "   Ingress rules:"
    kubectl describe ingress -n $NAMESPACE $APP_NAME | grep -A 20 "Rules:"
    echo ""
    echo "   Logs Ingress Controller (404):"
    INGRESS_POD=$(kubectl get pods -n kube-system -l app.kubernetes.io/name=ingress-nginx -o jsonpath='{.items[0].metadata.name}')
    kubectl logs -n kube-system $INGRESS_POD --tail=20 | grep "404\|front.toolsapps.eu"
else
    echo "   ⚠️  Code inattendu: $HTTPS_CODE"
fi

echo ""
echo "======================="

if [ "$HTTPS_CODE" = "200" ]; then
    echo "🎉 SUCCÈS! HTTPS fonctionne maintenant!"
    echo ""
    echo "✅ Testez dans votre navigateur:"
    echo "   👉 https://front.toolsapps.eu"
else
    echo "⚠️  Le problème persiste"
    echo ""
    echo "🔍 Prochaines étapes:"
    echo "   1. Vérifiez les logs Ingress:"
    echo "      kubectl logs -n kube-system -l app.kubernetes.io/name=ingress-nginx --tail=100"
    echo ""
    echo "   2. Testez directement le service:"
    echo "      kubectl run test --rm -i --restart=Never --image=curlimages/curl -n $NAMESPACE -- curl -v http://$APP_NAME:80"
    echo ""
    echo "   3. Vérifiez la configuration Ingress:"
    echo "      kubectl get ingress -n $NAMESPACE $APP_NAME -o yaml"
fi

echo ""
echo "======================="

