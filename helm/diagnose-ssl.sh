#!/bin/bash
# Script de diagnostic et correction du certificat SSL
# Le certificat apparaît comme "Ready: True" mais curl voit "self-signed certificate"

echo "🔍 DIAGNOSTIC DU CERTIFICAT SSL"
echo "================================"
echo ""

# 1. Vérifier le certificat
echo "1️⃣  État du certificat:"
kubectl get certificate -n production
echo ""

# 2. Détails du certificat
echo "2️⃣  Détails du certificat:"
kubectl describe certificate frontend-toolsapps-tls -n production | grep -A 10 "Status:"
echo ""

# 3. Vérifier le secret
echo "3️⃣  Secret TLS:"
kubectl get secret frontend-toolsapps-tls -n production
echo ""

# 4. Vérifier cert-manager
echo "4️⃣  Logs cert-manager (dernières 20 lignes):"
kubectl logs -n cert-manager -l app=cert-manager --tail=20
echo ""

# 5. Vérifier le ClusterIssuer
echo "5️⃣  ClusterIssuer Let's Encrypt:"
kubectl get clusterissuer letsencrypt-prod -o yaml | grep -A 5 "status:"
echo ""

# 6. Vérifier CertificateRequest
echo "6️⃣  CertificateRequest:"
kubectl get certificaterequest -n production
echo ""

# 7. Vérifier l'Ingress
echo "7️⃣  Ingress TLS config:"
kubectl get ingress frontend-toolsapps -n production -o jsonpath='{.spec.tls}' | jq .
echo ""

echo "================================"
echo "✅ Diagnostic terminé"
echo ""
echo "📝 Solutions possibles:"
echo "  1. Le certificat est peut-être en cours de renouvellement"
echo "  2. Le ClusterIssuer n'est peut-être pas configuré"
echo "  3. Le DNS n'est peut-être pas encore propagé"
echo ""
echo "🔧 Pour forcer le renouvellement du certificat:"
echo "   kubectl delete certificate frontend-toolsapps-tls -n production"
echo "   kubectl delete secret frontend-toolsapps-tls -n production"
echo "   # Attendre 2-3 minutes"
echo "   kubectl get certificate -n production -w"
echo ""

