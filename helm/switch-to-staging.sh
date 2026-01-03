#!/bin/bash
# Passer temporairement à Let's Encrypt Staging
# Pour tester sans rate limit

set -e

echo "🔄 PASSAGE À LET'S ENCRYPT STAGING"
echo "===================================="
echo ""
echo "⚠️  ATTENTION: Certificat de test (non reconnu par les navigateurs)"
echo "   Utilisez ceci uniquement pour tester la configuration"
echo ""

# Nettoyer les anciennes tentatives
kubectl delete certificate front-toolsapps-tls -n default --ignore-not-found=true
kubectl delete certificaterequest -n default -l app=frontend-toolsapps --ignore-not-found=true
kubectl delete secret frontend-toolsapps-tls -n default --ignore-not-found=true

# Mettre à jour l'annotation de l'Ingress
kubectl annotate ingress frontend-toolsapps -n default \
    cert-manager.io/cluster-issuer=letsencrypt-staging \
    --overwrite

# Créer le Certificate avec staging
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: front-toolsapps-tls
  namespace: default
spec:
  secretName: frontend-toolsapps-tls
  issuerRef:
    name: letsencrypt-staging
    kind: ClusterIssuer
  commonName: front.toolsapps.eu
  dnsNames:
    - front.toolsapps.eu
EOF

echo ""
echo "✅ Configuration mise à jour pour Staging"
echo ""
echo "Surveillez l'émission:"
echo "   watch kubectl get certificate -n default"
echo ""
echo "Pour revenir en production après le rate limit:"
echo "   ./helm/switch-to-production.sh"
