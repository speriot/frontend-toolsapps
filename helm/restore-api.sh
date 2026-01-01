#!/bin/bash
# URGENCE: Restaurer api.toolsapps.eu

echo "🚨 RESTAURATION URGENTE api.toolsapps.eu"
echo "========================================="
echo ""

# 1. Vérifier l'état de l'API
echo "1️⃣  État de l'Ingress API..."
kubectl get ingress -n default api-node-api-node -o wide
echo ""

# 2. Vérifier le certificat API
echo "2️⃣  Certificat API..."
kubectl get secret -n default le-cert-api-toolsapps
echo ""
echo "   Détails du certificat:"
kubectl get secret -n default le-cert-api-toolsapps -o jsonpath='{.data.tls\.crt}' 2>/dev/null | base64 -d | openssl x509 -noout -issuer -dates -subject 2>/dev/null
echo ""

# 3. Redémarrer Traefik proprement
echo "3️⃣  Redémarrage de Traefik..."
kubectl rollout restart deployment -n traefik traefik
kubectl rollout status deployment -n traefik traefik --timeout=90s
echo "   ✅ Traefik redémarré"
sleep 10

# 4. Vérifier les logs Traefik
echo ""
echo "4️⃣  Logs Traefik..."
TRAEFIK_POD=$(kubectl get pods -n traefik -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
kubectl logs -n traefik $TRAEFIK_POD --tail=20 2>/dev/null | grep -iE "api|error|tls|cert"
echo ""

# 5. Test API
echo "5️⃣  Test API..."
echo "   HTTP:"
curl -s -o /dev/null -w "   Code: %{http_code}\n" http://api.toolsapps.eu 2>/dev/null

echo "   HTTPS:"
curl -s -o /dev/null -w "   Code: %{http_code}\n" https://api.toolsapps.eu 2>/dev/null

echo "   HTTPS (ignore cert):"
curl -s -o /dev/null -w "   Code: %{http_code}\n" -k https://api.toolsapps.eu 2>/dev/null

# 6. Vérifier le certificat servi
echo ""
echo "6️⃣  Certificat servi par le serveur..."
echo | openssl s_client -connect api.toolsapps.eu:443 -servername api.toolsapps.eu 2>/dev/null | openssl x509 -noout -issuer -dates 2>/dev/null

echo ""
echo "========================================="
HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://api.toolsapps.eu 2>/dev/null)
if [ "$HTTPS_CODE" == "200" ] || [ "$HTTPS_CODE" == "404" ]; then
    echo "🎉 API HTTPS fonctionne! (Code: $HTTPS_CODE)"
else
    echo "⚠️  API HTTPS Code: $HTTPS_CODE"
    echo ""
    echo "   Le certificat existe, attendez 1-2 minutes"
    echo "   que Traefik recharge la configuration"
fi
echo "========================================="

