#!/bin/bash

echo "🔧 CORRECTION CERTIFICAT TLS"
echo "============================="

NAMESPACE="production"
APP_NAME="frontend-toolsapps"

echo ""
echo "📋 Problème identifié:"
echo "   - HTTP redirige vers HTTPS (308) ✅"
echo "   - Ingress Controller reçoit le trafic HTTP ✅"
echo "   - HTTPS retourne 404 mais pas de logs HTTPS ❌"
echo "   → Le trafic HTTPS n'atteint pas l'Ingress Controller"
echo "   → Problème de certificat TLS"
echo ""

echo "1️⃣  Vérification du certificat actuel..."
kubectl get certificate -n $NAMESPACE

echo ""
echo "2️⃣  Vérification du secret TLS..."
if kubectl get secret frontend-toolsapps-tls -n $NAMESPACE &>/dev/null; then
    echo "   ✅ Secret existe"
    echo ""
    echo "   Contenu du certificat:"
    kubectl get secret frontend-toolsapps-tls -n $NAMESPACE -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout 2>/dev/null | grep -E "Issuer:|Subject:|Not After:|DNS:" | head -10
else
    echo "   ❌ Secret TLS manquant"
fi

echo ""
echo "3️⃣  Vérification de la configuration Ingress TLS..."
kubectl get ingress -n $NAMESPACE $APP_NAME -o jsonpath='{.spec.tls}' | jq '.'

echo ""
read -p "Voulez-vous recréer complètement le certificat TLS? (o/N) " CONFIRM
if [ "$CONFIRM" != "o" ] && [ "$CONFIRM" != "O" ]; then
    exit 0
fi

echo ""
echo "4️⃣  Suppression du certificat et secret existants..."
kubectl delete certificate frontend-toolsapps-tls -n $NAMESPACE 2>/dev/null
kubectl delete secret frontend-toolsapps-tls -n $NAMESPACE 2>/dev/null
echo "   ✅ Supprimés"

echo ""
echo "5️⃣  Suppression et recréation de l'Ingress..."
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
echo "6️⃣  Vérification que cert-manager crée le certificat..."
sleep 5

for i in {1..60}; do
    if kubectl get certificate frontend-toolsapps-tls -n $NAMESPACE &>/dev/null; then
        STATUS=$(kubectl get certificate frontend-toolsapps-tls -n $NAMESPACE -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
        if [ "$STATUS" = "True" ]; then
            echo "   ✅ Certificat créé et prêt!"
            break
        fi
    fi

    if [ $((i % 10)) -eq 0 ]; then
        echo "   ⏳ Attente du certificat... ($i/60 secondes)"
    fi
    sleep 1
done

echo ""
echo "7️⃣  État final du certificat..."
kubectl get certificate -n $NAMESPACE

echo ""
echo "8️⃣  Vérification du nouveau secret TLS..."
if kubectl get secret frontend-toolsapps-tls -n $NAMESPACE &>/dev/null; then
    echo "   ✅ Secret TLS créé"
    echo ""
    echo "   Détails du certificat:"
    kubectl get secret frontend-toolsapps-tls -n $NAMESPACE -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout 2>/dev/null | grep -E "Issuer:|Subject:|Not After:|DNS:"
else
    echo "   ❌ Secret TLS non créé"
    echo ""
    echo "   Logs cert-manager:"
    kubectl logs -n cert-manager -l app=cert-manager --tail=30 | grep -i "error\|frontend-toolsapps"
fi

echo ""
echo "9️⃣  Redémarrage de l'Ingress Controller pour prise en compte..."
kubectl rollout restart deployment -n ingress-nginx ingress-nginx-controller
echo "   ✅ Restart déclenché"

echo ""
echo "🔟 Attente (30 secondes)..."
sleep 30

echo ""
echo "1️⃣1️⃣  Test final HTTP..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://front.toolsapps.eu)
echo "   Code HTTP: $HTTP_CODE"

echo ""
echo "1️⃣2️⃣  Test final HTTPS..."
for i in {1..5}; do
    HTTPS_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://front.toolsapps.eu)
    echo "   Tentative $i: Code HTTPS = $HTTPS_CODE"

    if [ "$HTTPS_CODE" = "200" ]; then
        break
    fi
    sleep 3
done

echo ""
echo "============================="

if [ "$HTTPS_CODE" = "200" ]; then
    echo ""
    echo "🎉🎉🎉 SUCCÈS TOTAL! 🎉🎉🎉"
    echo "============================="
    echo ""
    echo "✅ HTTPS fonctionne parfaitement!"
    echo "✅ Code: $HTTPS_CODE"
    echo ""
    echo "📱 Testez dans votre navigateur:"
    echo "   👉 https://front.toolsapps.eu"
    echo ""
    echo "⚠️  Avertissement certificat staging = NORMAL"
    echo "   Cliquez: Avancé → Continuer"
    echo ""
    echo "   Aperçu du contenu:"
    curl -k -s https://front.toolsapps.eu | head -15
    echo ""
    echo "============================="
elif [ "$HTTPS_CODE" = "404" ]; then
    echo ""
    echo "❌ HTTPS retourne toujours 404"
    echo ""
    echo "🔍 Diagnostic approfondi..."
    echo ""
    echo "   État du certificat:"
    kubectl describe certificate -n $NAMESPACE frontend-toolsapps-tls | grep -A 10 "Status:"
    echo ""
    echo "   Challenges:"
    kubectl get challenges -n $NAMESPACE
    echo ""
    echo "   Orders:"
    kubectl get orders -n $NAMESPACE
    echo ""
    echo "   Logs Ingress Controller (HTTPS):"
    kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx --tail=30 | grep -i "https\|tls\|ssl\|front.toolsapps.eu"
else
    echo ""
    echo "⚠️  Code inattendu: $HTTPS_CODE"
fi

echo ""
echo "============================="

