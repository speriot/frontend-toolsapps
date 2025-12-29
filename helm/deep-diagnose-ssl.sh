#!/bin/bash
# Script de diagnostic approfondi du certificat SSL

echo "🔍 DIAGNOSTIC APPROFONDI DU CERTIFICAT SSL"
echo "==========================================="
echo ""

# 1. Vérifier le secret TLS en détail
echo "1️⃣  Contenu du secret TLS:"
kubectl get secret frontend-toolsapps-tls -n production -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout | grep -A 2 "Issuer:\|Subject:\|Not Before\|Not After"
echo ""

# 2. Vérifier l'émetteur
echo "2️⃣  Émetteur du certificat:"
ISSUER=$(kubectl get secret frontend-toolsapps-tls -n production -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout | grep "Issuer:" | sed 's/.*CN = //')
echo "   $ISSUER"

if echo "$ISSUER" | grep -qi "Let's Encrypt\|ACME\|R3\|E1"; then
    echo "   ✅ Certificat émis par Let's Encrypt"
else
    echo "   ❌ Certificat NOT émis par Let's Encrypt!"
    echo "   Émetteur actuel: $ISSUER"
fi
echo ""

# 3. Vérifier les événements du certificat
echo "3️⃣  Événements du certificat:"
kubectl describe certificate frontend-toolsapps-tls -n production | grep -A 10 "Events:"
echo ""

# 4. Vérifier CertificateRequest
echo "4️⃣  CertificateRequest:"
kubectl get certificaterequest -n production
echo ""

# 5. Logs cert-manager
echo "5️⃣  Logs cert-manager (dernières 30 lignes):"
kubectl logs -n cert-manager -l app=cert-manager --tail=30 | grep -i "error\|fail\|frontend-toolsapps"
echo ""

# 6. Vérifier l'Ingress annotation
echo "6️⃣  Annotation cert-manager sur l'Ingress:"
kubectl get ingress frontend-toolsapps -n production -o jsonpath='{.metadata.annotations.cert-manager\.io/cluster-issuer}'
echo ""
echo ""

# 7. Test curl avec détails
echo "7️⃣  Test curl avec informations du certificat:"
echo "   Certificat vu par curl:"
echo | openssl s_client -servername front.toolsapps.eu -connect front.toolsapps.eu:443 2>/dev/null | openssl x509 -noout -issuer -subject -dates
echo ""

echo "==========================================="
echo "✅ Diagnostic terminé"
echo ""
echo "📝 Si le certificat n'est pas de Let's Encrypt:"
echo "   1. Le ClusterIssuer n'est peut-être pas correctement référencé"
echo "   2. Vérifier les logs cert-manager pour les erreurs"
echo "   3. Supprimer complètement le certificat et l'ingress"
echo ""

