#!/bin/bash
# Script de correction SSL complet pour front.toolsapps.eu
# Date: 2 janvier 2026
# Corrige: Rate Limit + HTTP-01 Challenge 404

set -e

echo "🔧 CORRECTION SSL COMPLÈTE - front.toolsapps.eu"
echo "=================================================="
echo ""

# Vérifier l'heure actuelle vs le déblocage
RETRY_AFTER="2026-01-02 23:19:54 UTC"
CURRENT_TIME=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
echo "⏰ Heure actuelle: $CURRENT_TIME"
echo "⏰ Déblocage à: $RETRY_AFTER"
echo ""

# Étape 1: Nettoyer les ressources échouées
echo "🧹 Étape 1: Nettoyage des ressources échouées"
echo "----------------------------------------------"

# Supprimer les anciens certificats/challenges échoués
kubectl delete certificate front-toolsapps-tls -n default --ignore-not-found=true
kubectl delete certificaterequest -n default -l app=frontend-toolsapps --ignore-not-found=true
kubectl delete order -n default -l app=frontend-toolsapps --ignore-not-found=true
kubectl delete challenge -n default -l app=frontend-toolsapps --ignore-not-found=true

# Supprimer les solver HTTP-01 qui causent des 404
kubectl delete ingress -n default -l acme.cert-manager.io/http01-solver=true --ignore-not-found=true
kubectl delete service -n default -l acme.cert-manager.io/http01-solver=true --ignore-not-found=true
kubectl delete pod -n default -l acme.cert-manager.io/http01-solver=true --ignore-not-found=true

echo "✅ Nettoyage terminé"
echo ""

# Étape 2: Vérifier l'Ingress principal
echo "🔍 Étape 2: Vérification de l'Ingress"
echo "--------------------------------------"

INGRESS_EXISTS=$(kubectl get ingress frontend-toolsapps -n default --ignore-not-found=true)
if [ -z "$INGRESS_EXISTS" ]; then
    echo "❌ Ingress frontend-toolsapps n'existe pas!"
    echo "   Déployez d'abord votre application avec: helm upgrade --install frontend-toolsapps ./helm/frontend-toolsapps"
    exit 1
fi

echo "✅ Ingress existe"
echo ""

# Étape 3: Corriger les annotations de l'Ingress
echo "🔧 Étape 3: Correction des annotations Ingress"
echo "------------------------------------------------"

kubectl annotate ingress frontend-toolsapps -n default \
    cert-manager.io/cluster-issuer=letsencrypt-prod \
    nginx.ingress.kubernetes.io/ssl-redirect="true" \
    nginx.ingress.kubernetes.io/force-ssl-redirect="true" \
    --overwrite

echo "✅ Annotations corrigées"
echo ""

# Étape 4: Vérifier le ClusterIssuer
echo "🔍 Étape 4: Vérification du ClusterIssuer"
echo "------------------------------------------"

ISSUER_READY=$(kubectl get clusterissuer letsencrypt-prod -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
if [ "$ISSUER_READY" != "True" ]; then
    echo "⚠️  ClusterIssuer letsencrypt-prod n'est pas prêt"
    kubectl describe clusterissuer letsencrypt-prod
    exit 1
fi

echo "✅ ClusterIssuer prêt"
echo ""

# Étape 5: Créer manuellement le Certificate
echo "📜 Étape 5: Création du Certificate"
echo "------------------------------------"

cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: front-toolsapps-tls
  namespace: default
spec:
  secretName: frontend-toolsapps-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  commonName: front.toolsapps.eu
  dnsNames:
    - front.toolsapps.eu
  privateKey:
    algorithm: RSA
    size: 2048
  usages:
    - digital signature
    - key encipherment
EOF

echo "✅ Certificate créé"
echo ""

# Attendre un peu pour la propagation
echo "⏳ Attente de 10 secondes pour la propagation..."
sleep 10

# Étape 6: Vérifier l'état du Certificate
echo "🔍 Étape 6: Vérification de l'état"
echo "-----------------------------------"

kubectl get certificate front-toolsapps-tls -n default
kubectl describe certificate front-toolsapps-tls -n default | tail -20
echo ""

# Étape 7: Surveiller les CertificateRequests
echo "📋 Étape 7: CertificateRequests"
echo "--------------------------------"
kubectl get certificaterequest -n default
echo ""

# Étape 8: Vérifier les challenges HTTP-01
echo "🎯 Étape 8: Challenges HTTP-01"
echo "-------------------------------"

CHALLENGES=$(kubectl get challenge -n default 2>/dev/null || echo "")
if [ ! -z "$CHALLENGES" ]; then
    echo "$CHALLENGES"
    echo ""
    echo "🔍 Détails du challenge:"
    kubectl describe challenge -n default | grep -A 10 "Status:"
else
    echo "Aucun challenge actif pour le moment"
fi
echo ""

# Étape 9: Test du path ACME
echo "🧪 Étape 9: Test du path ACME challenge"
echo "----------------------------------------"

echo "Test HTTP (devrait fonctionner pour ACME):"
curl -v "http://front.toolsapps.eu/.well-known/acme-challenge/test" 2>&1 | grep -E "(HTTP/|< )"
echo ""

# Étape 10: Logs cert-manager récents
echo "📝 Étape 10: Logs cert-manager (20 dernières lignes)"
echo "-----------------------------------------------------"
kubectl logs -n cert-manager deployment/cert-manager --tail=20 | grep -E "(front-toolsapps|ERROR|rate)"
echo ""

# Résumé
echo "=================================================="
echo "📊 RÉSUMÉ"
echo "=================================================="
echo ""

CERT_READY=$(kubectl get certificate front-toolsapps-tls -n default -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "Unknown")

if [ "$CERT_READY" = "True" ]; then
    echo "🎉 CERTIFICAT PRÊT !"
    echo ""
    echo "✅ Testez votre site :"
    echo "   https://front.toolsapps.eu"
    echo ""
elif echo "$CURRENT_TIME" | grep -q "2026-01-02.*2[3-9]:" || echo "$CURRENT_TIME" | grep -q "2026-01-0[3-9]"; then
    echo "⏳ CERTIFICAT EN COURS D'ÉMISSION"
    echo ""
    echo "Le rate limit devrait être levé maintenant."
    echo "Surveillez l'état avec:"
    echo "   watch kubectl get certificate -n default"
    echo ""
    echo "Les logs avec:"
    echo "   kubectl logs -n cert-manager deployment/cert-manager -f | grep front-toolsapps"
else
    echo "⏰ EN ATTENTE DU DÉBLOCAGE"
    echo ""
    echo "Rate limit Let's Encrypt actif jusqu'à:"
    echo "   $RETRY_AFTER"
    echo ""
    echo "Après cette heure, le certificat sera automatiquement"
    echo "demandé. Surveillez avec:"
    echo "   watch kubectl get certificate -n default"
    echo ""
    echo "💡 Pour tester immédiatement, utilisez Let's Encrypt Staging:"
    echo "   ./helm/switch-to-staging.sh"
fi

echo ""
echo "=================================================="
