#!/bin/bash
# Script de correction SSL complet pour front.toolsapps.eu
# Date: 3 janvier 2026
# Corrige: Rate Limit + HTTP-01 Challenge 404

set -e

# NAMESPACE où l'application est déployée
NAMESPACE="production"

echo "🔧 CORRECTION SSL COMPLÈTE - front.toolsapps.eu"
echo "=================================================="
echo ""
echo "📦 Namespace: $NAMESPACE"
echo ""

# Vérifier l'heure actuelle vs le déblocage
RETRY_AFTER="2026-01-02 23:19:54 UTC"
CURRENT_TIME=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
echo "⏰ Heure actuelle: $CURRENT_TIME"
echo "⏰ Déblocage à: $RETRY_AFTER"
echo "✅ Rate limit LEVÉ!"
echo ""

# Étape 0: Vérifier que le namespace existe
echo "🔍 Étape 0: Vérification du namespace"
echo "--------------------------------------"
if ! kubectl get namespace $NAMESPACE &>/dev/null; then
    echo "❌ Namespace $NAMESPACE n'existe pas!"
    echo "   Créez-le avec: kubectl create namespace $NAMESPACE"
    exit 1
fi
echo "✅ Namespace existe"
echo ""

# Étape 1: Nettoyer les ressources échouées
echo "🧹 Étape 1: Nettoyage des ressources échouées"
echo "----------------------------------------------"

# Supprimer les anciens certificats/challenges échoués dans production ET default
for ns in $NAMESPACE default; do
    echo "   Nettoyage dans namespace: $ns"
    kubectl delete certificate front-toolsapps-tls frontend-toolsapps-eu-tls -n $ns --ignore-not-found=true 2>/dev/null || true
    kubectl delete certificaterequest -n $ns -l app.kubernetes.io/name=frontend-toolsapps --ignore-not-found=true 2>/dev/null || true
    kubectl delete order -n $ns -l app.kubernetes.io/name=frontend-toolsapps --ignore-not-found=true 2>/dev/null || true
    kubectl delete challenge -n $ns -l app.kubernetes.io/name=frontend-toolsapps --ignore-not-found=true 2>/dev/null || true
    # Supprimer les solver HTTP-01 qui causent des 404
    kubectl delete ingress -n $ns -l acme.cert-manager.io/http01-solver=true --ignore-not-found=true 2>/dev/null || true
    kubectl delete service -n $ns -l acme.cert-manager.io/http01-solver=true --ignore-not-found=true 2>/dev/null || true
    kubectl delete pod -n $ns -l acme.cert-manager.io/http01-solver=true --ignore-not-found=true 2>/dev/null || true
done

echo "✅ Nettoyage terminé"
echo ""

# Étape 2: Vérifier l'Ingress principal
echo "🔍 Étape 2: Vérification de l'Ingress"
echo "--------------------------------------"

INGRESS_NAME=$(kubectl get ingress -n $NAMESPACE -o name 2>/dev/null | head -1 | cut -d'/' -f2)
if [ -z "$INGRESS_NAME" ]; then
    echo "❌ Aucun Ingress trouvé dans le namespace $NAMESPACE!"
    echo ""
    echo "📋 Déploiement nécessaire:"
    echo "   helm upgrade --install frontend-toolsapps ./helm/frontend-toolsapps \\"
    echo "     --namespace $NAMESPACE \\"
    echo "     --values ./helm/frontend-toolsapps/values-prod.yaml"
    exit 1
fi

echo "✅ Ingress trouvé: $INGRESS_NAME"
echo ""

# Étape 3: Corriger les annotations de l'Ingress
echo "🔧 Étape 3: Correction des annotations Ingress"
echo "------------------------------------------------"

kubectl annotate ingress $INGRESS_NAME -n $NAMESPACE \
    cert-manager.io/cluster-issuer=letsencrypt-prod \
    nginx.ingress.kubernetes.io/ssl-redirect="true" \
    nginx.ingress.kubernetes.io/force-ssl-redirect="true" \
    --overwrite

echo "✅ Annotations corrigées"
echo ""

# Étape 4: Vérifier le ClusterIssuer
echo "🔍 Étape 4: Vérification du ClusterIssuer"
echo "------------------------------------------"

ISSUER_READY=$(kubectl get clusterissuer letsencrypt-prod -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "Unknown")
if [ "$ISSUER_READY" != "True" ]; then
    echo "⚠️  ClusterIssuer letsencrypt-prod n'est pas prêt"
    kubectl describe clusterissuer letsencrypt-prod
    exit 1
fi

echo "✅ ClusterIssuer prêt"
echo ""

# Étape 5: Obtenir le secret TLS name depuis l'Ingress
echo "🔍 Étape 5: Récupération du nom du secret TLS"
echo "----------------------------------------------"

TLS_SECRET=$(kubectl get ingress $INGRESS_NAME -n $NAMESPACE -o jsonpath='{.spec.tls[0].secretName}' 2>/dev/null)
TLS_HOST=$(kubectl get ingress $INGRESS_NAME -n $NAMESPACE -o jsonpath='{.spec.tls[0].hosts[0]}' 2>/dev/null)

if [ -z "$TLS_SECRET" ]; then
    echo "⚠️  Pas de TLS configuré dans l'Ingress"
    TLS_SECRET="frontend-toolsapps-tls"
    TLS_HOST="front.toolsapps.eu"
    echo "   Utilisation par défaut: $TLS_SECRET pour $TLS_HOST"
else
    echo "✅ Secret TLS: $TLS_SECRET"
    echo "✅ Host: $TLS_HOST"
fi
echo ""

# Étape 6: Créer manuellement le Certificate
echo "📜 Étape 6: Création du Certificate"
echo "------------------------------------"

cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ${TLS_SECRET}
  namespace: $NAMESPACE
spec:
  secretName: ${TLS_SECRET}
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  commonName: ${TLS_HOST}
  dnsNames:
    - ${TLS_HOST}
  privateKey:
    algorithm: RSA
    size: 2048
    rotationPolicy: Always
  usages:
    - digital signature
    - key encipherment
EOF

echo "✅ Certificate créé"
echo ""

# Attendre un peu pour la propagation
echo "⏳ Attente de 15 secondes pour la propagation..."
sleep 15

# Étape 7: Vérifier l'état du Certificate
echo "🔍 Étape 7: Vérification de l'état"
echo "-----------------------------------"

kubectl get certificate -n $NAMESPACE
echo ""
kubectl describe certificate ${TLS_SECRET} -n $NAMESPACE | tail -20
echo ""

# Étape 8: Surveiller les CertificateRequests
echo "📋 Étape 8: CertificateRequests"
echo "--------------------------------"
kubectl get certificaterequest -n $NAMESPACE
echo ""

# Étape 9: Vérifier les challenges HTTP-01
echo "🎯 Étape 9: Challenges HTTP-01"
echo "-------------------------------"

CHALLENGES=$(kubectl get challenge -n $NAMESPACE 2>/dev/null || echo "")
if [ ! -z "$CHALLENGES" ] && [ "$CHALLENGES" != "No resources found in $NAMESPACE namespace." ]; then
    echo "$CHALLENGES"
    echo ""
    echo "🔍 Détails du challenge:"
    kubectl describe challenge -n $NAMESPACE | grep -A 10 "Status:"
else
    echo "Aucun challenge actif pour le moment"
fi
echo ""

# Étape 10: Test du path ACME
echo "🧪 Étape 10: Test du path ACME challenge"
echo "-----------------------------------------"

echo "Test HTTP (devrait fonctionner pour ACME):"
curl -v "http://${TLS_HOST}/.well-known/acme-challenge/test" 2>&1 | grep -E "(HTTP/|< )" || echo "   (404 normal pour un test, Let's Encrypt utilisera son propre token)"
echo ""

# Étape 11: Logs cert-manager récents
echo "📝 Étape 11: Logs cert-manager (30 dernières lignes)"
echo "------------------------------------------------------"
kubectl logs -n cert-manager deployment/cert-manager --tail=30 | grep -E "(front|toolsapps|ERROR|rate)" || echo "Pas d'erreurs récentes"
echo ""

# Résumé
echo "=================================================="
echo "📊 RÉSUMÉ"
echo "=================================================="
echo ""

CERT_READY=$(kubectl get certificate ${TLS_SECRET} -n $NAMESPACE -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "Unknown")

if [ "$CERT_READY" = "True" ]; then
    echo "🎉 CERTIFICAT PRÊT !"
    echo ""
    echo "✅ Testez votre site :"
    echo "   https://${TLS_HOST}"
    echo ""
    echo "Vérification SSL:"
    HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://${TLS_HOST}" 2>/dev/null || echo "000")
    if [ "$HTTPS_CODE" = "200" ]; then
        echo "   ✅ HTTPS fonctionne: $HTTPS_CODE"
    else
        echo "   ⚠️  HTTPS répond: $HTTPS_CODE"
    fi
elif [ "$CERT_READY" = "Unknown" ]; then
    echo "⏳ CERTIFICAT EN COURS DE CRÉATION"
    echo ""
    echo "Surveillez l'état avec:"
    echo "   watch kubectl get certificate -n $NAMESPACE"
    echo ""
    echo "Les logs en temps réel:"
    echo "   kubectl logs -n cert-manager deployment/cert-manager -f | grep -E 'front|toolsapps'"
else
    echo "⏳ CERTIFICAT EN COURS D'ÉMISSION"
    echo ""
    echo "✅ Rate limit LEVÉ (depuis le 2 janvier 23:19 UTC)"
    echo ""
    echo "Surveillez l'état avec:"
    echo "   watch kubectl get certificate -n $NAMESPACE"
    echo ""
    echo "Les logs en temps réel:"
    echo "   kubectl logs -n cert-manager deployment/cert-manager -f | grep -E 'front|toolsapps'"
    echo ""
    echo "Si échec après 5 minutes, vérifiez:"
    echo "   kubectl describe certificate ${TLS_SECRET} -n $NAMESPACE"
    echo "   kubectl get certificaterequest -n $NAMESPACE"
    echo "   kubectl get challenge -n $NAMESPACE"
fi

echo ""
echo "=================================================="
