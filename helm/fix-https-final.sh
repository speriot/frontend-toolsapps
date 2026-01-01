#!/bin/bash
# Fix final pour HTTPS 404 avec certificat Let's Encrypt valide

echo "🔧 FIX HTTPS 404 - CERTIFICAT VALIDE"
echo "====================================="
echo ""

# 1. Vérifier l'état actuel
echo "1️⃣  État actuel..."
echo "   Pods:"
kubectl get pods -n production -l app.kubernetes.io/name=frontend-toolsapps
echo ""
echo "   Service:"
kubectl get svc -n production frontend-toolsapps
echo ""
echo "   Ingress:"
kubectl get ingress -n production frontend-toolsapps
echo ""
echo "   Certificat:"
kubectl get certificate -n production frontend-toolsapps-tls
echo ""
echo "   Secret TLS:"
kubectl get secret -n production frontend-toolsapps-tls
echo ""

# 2. Vérifier l'Ingress Controller
echo "2️⃣  Ingress Controller..."
kubectl get pods -n ingress-nginx
INGRESS_POD=$(kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
echo "   Pod: $INGRESS_POD"
echo ""

# 3. Vérifier les endpoints du service
echo "3️⃣  Endpoints du service..."
kubectl get endpoints -n production frontend-toolsapps
echo ""

# 4. Test HTTP direct
echo "4️⃣  Test HTTP (port 80)..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 http://front.toolsapps.eu 2>/dev/null)
echo "   Code HTTP: $HTTP_CODE"

# 5. Test HTTPS avec détails
echo ""
echo "5️⃣  Test HTTPS avec détails..."
curl -v --connect-timeout 10 https://front.toolsapps.eu 2>&1 | head -30
echo ""

# 6. Vérifier la configuration de l'Ingress
echo "6️⃣  Configuration complète de l'Ingress..."
kubectl get ingress -n production frontend-toolsapps -o yaml
echo ""

# 7. Redémarrer l'Ingress Controller
echo "7️⃣  Redémarrage de l'Ingress Controller..."
read -p "   Continuer? (o/N) " confirm
if [ "$confirm" != "o" ] && [ "$confirm" != "O" ]; then
    echo "Annulé."
    exit 0
fi

kubectl rollout restart deployment -n ingress-nginx ingress-nginx-controller
echo "   ✅ Restart déclenché"

echo "   Attente du redémarrage (30 secondes)..."
sleep 30

# 8. Vérifier que l'Ingress Controller est prêt
echo ""
echo "8️⃣  Vérification Ingress Controller..."
kubectl get pods -n ingress-nginx
kubectl rollout status deployment -n ingress-nginx ingress-nginx-controller --timeout=60s
echo ""

# 9. Recréer l'Ingress avec la bonne configuration
echo "9️⃣  Recréation de l'Ingress..."
kubectl delete ingress frontend-toolsapps -n production 2>/dev/null || true
sleep 3

cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: frontend-toolsapps
  namespace: production
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "60"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "60"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "60"
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
            name: frontend-toolsapps
            port:
              number: 80
EOF

echo "   ✅ Ingress recréé"
echo ""

# 10. Attendre la synchronisation
echo "🔟 Attente de la synchronisation (15 secondes)..."
sleep 15

# 11. Vérifier l'adresse IP
echo ""
echo "1️⃣1️⃣  Vérification de l'adresse IP..."
kubectl get ingress -n production frontend-toolsapps
IP=$(kubectl get ingress -n production frontend-toolsapps -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "   IP de l'Ingress: $IP"

# Attendre l'IP si pas encore assignée
for i in {1..12}; do
    IP=$(kubectl get ingress -n production frontend-toolsapps -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [ -n "$IP" ]; then
        echo "   ✅ IP assignée: $IP"
        break
    fi
    echo "   ⏳ Attente de l'IP... ($i/12)"
    sleep 5
done
echo ""

# 12. Tests finaux
echo "1️⃣2️⃣  Tests finaux..."
echo ""

echo "   Test HTTP:"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 http://front.toolsapps.eu 2>/dev/null)
echo "   Code: $HTTP_CODE"

echo ""
echo "   Test HTTPS (sans vérification certificat):"
HTTPS_CODE_INSECURE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 -k https://front.toolsapps.eu 2>/dev/null)
echo "   Code: $HTTPS_CODE_INSECURE"

echo ""
echo "   Test HTTPS (avec vérification certificat):"
HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 https://front.toolsapps.eu 2>/dev/null)
echo "   Code: $HTTPS_CODE"

echo ""
echo "   Contenu HTTPS:"
curl -s -k https://front.toolsapps.eu 2>/dev/null | head -15

# 13. Logs Ingress Controller
echo ""
echo "1️⃣3️⃣  Logs récents Ingress Controller..."
kubectl logs -n ingress-nginx $INGRESS_POD --tail=20 2>/dev/null | grep -v "healthz\|readyz"

# Résultat
echo ""
echo "====================================="
if [ "$HTTPS_CODE" == "200" ] || [ "$HTTPS_CODE_INSECURE" == "200" ]; then
    echo "🎉 HTTPS FONCTIONNE!"
    echo ""
    echo "✅ Testez: https://front.toolsapps.eu"
else
    echo "⚠️  Problème détecté"
    echo ""
    echo "Codes retournés:"
    echo "  HTTP: $HTTP_CODE"
    echo "  HTTPS (insecure): $HTTPS_CODE_INSECURE"
    echo "  HTTPS: $HTTPS_CODE"
    echo ""
    echo "📝 Vérifier:"
    echo "  1. DNS: dig front.toolsapps.eu"
    echo "  2. Port 443 ouvert: nc -zv front.toolsapps.eu 443"
    echo "  3. Certificat: openssl s_client -connect front.toolsapps.eu:443 -servername front.toolsapps.eu"
fi
echo "====================================="

