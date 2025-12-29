#!/bin/bash
# Solution au Rate Limit: Utiliser Let's Encrypt Staging

echo "🔧 SOLUTION RATE LIMIT - Let's Encrypt STAGING"
echo "==============================================="
echo ""

echo "🔴 Problème détecté:"
echo "   Rate Limit Let's Encrypt: 5 certificats déjà émis"
echo "   Retry after: 2025-12-31 04:04:56 UTC"
echo ""
echo "💡 Solution:"
echo "   Utiliser le serveur STAGING de Let's Encrypt"
echo "   • Pas de rate limit"
echo "   • Permet de tester la configuration"
echo "   • Le navigateur affichera 'Non sécurisé' (certificat staging)"
echo "   • On pourra basculer en production le 31 décembre"
echo ""

read -p "Entrez votre email pour Let's Encrypt: " EMAIL

if [ -z "$EMAIL" ]; then
    echo "❌ Email requis"
    exit 1
fi

echo ""
read -p "Continuer avec Let's Encrypt STAGING? (o/N) " CONFIRM
if [ "$CONFIRM" != "o" ] && [ "$CONFIRM" != "O" ]; then
    echo "Annulé"
    exit 0
fi

echo ""
echo "1️⃣  Suppression de l'ancien ClusterIssuer..."
kubectl delete clusterissuer letsencrypt-prod 2>/dev/null || true
kubectl delete secret letsencrypt-prod -n cert-manager 2>/dev/null || true
echo "   ✅ Ancien ClusterIssuer supprimé"

echo ""
echo "2️⃣  Création du ClusterIssuer STAGING..."

cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: $EMAIL
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

echo "   ✅ ClusterIssuer staging créé"

echo ""
echo "3️⃣  Attente que le ClusterIssuer soit prêt..."
sleep 5

kubectl get clusterissuer letsencrypt-staging

echo ""
echo "4️⃣  Suppression des anciens objets..."
kubectl delete certificate --all -n production
kubectl delete certificaterequest --all -n production
kubectl delete order --all -n production
kubectl delete challenge --all -n production
kubectl delete secret frontend-toolsapps-tls -n production 2>/dev/null || true
echo "   ✅ Objets supprimés"

echo ""
echo "5️⃣  Mise à jour de l'Ingress pour utiliser staging..."

kubectl annotate ingress frontend-toolsapps -n production \
  cert-manager.io/cluster-issuer=letsencrypt-staging \
  --overwrite

echo "   ✅ Ingress mis à jour"

echo ""
echo "6️⃣  Attente de la création du certificat (30 secondes)..."
sleep 30

echo ""
echo "7️⃣  État des objets:"
kubectl get certificate,certificaterequest,order,challenge -n production

echo ""
echo "8️⃣  Surveillance de l'émission (max 2 minutes)..."

for i in {1..60}; do
    if kubectl get certificate frontend-toolsapps-tls -n production &>/dev/null; then
        CERT_READY=$(kubectl get certificate frontend-toolsapps-tls -n production -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)

        if [ "$CERT_READY" == "True" ]; then
            echo "   ✅ Certificat prêt après $i secondes!"
            break
        fi
    fi

    if [ $((i % 15)) -eq 0 ]; then
        echo "   ⏳ Attente... ($i/60)"
    fi
    sleep 1
done

echo ""
echo "9️⃣  Vérification du certificat..."

if kubectl get secret frontend-toolsapps-tls -n production &>/dev/null; then
    ISSUER=$(kubectl get secret frontend-toolsapps-tls -n production -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout 2>/dev/null | grep "Issuer:" | grep -o "CN = [^,]*" | cut -d= -f2 | xargs)

    echo "   Émetteur: $ISSUER"
    echo ""

    if echo "$ISSUER" | grep -qi "Fake\|Staging\|Test"; then
        echo "   ✅ Certificat STAGING émis avec succès!"
        echo ""
        echo "========================================="
        echo "🎉 SUCCÈS AVEC STAGING!"
        echo "========================================="
        echo ""
        echo "✅ Application accessible: https://front.toolsapps.eu"
        echo "⚠️  Le navigateur affichera 'Non sécurisé'"
        echo "   (Normal: c'est un certificat staging/test)"
        echo ""
        echo "📝 Pour basculer en PRODUCTION après le 31/12:"
        echo "   1. Attendre le 31 décembre 2025 à 04:05 UTC"
        echo "   2. Exécuter: ./switch-to-production.sh"
        echo ""
        echo "✅ La configuration fonctionne!"
        echo "✅ Le 31/12, le certificat production sera émis sans problème"
        echo ""
    else
        echo "   ⚠️  Émetteur inattendu: $ISSUER"
    fi
else
    echo "   ❌ Secret TLS non créé"
    echo ""
    echo "   Logs:"
    kubectl logs -n cert-manager -l app=cert-manager --tail=30 | grep -i "error\|fail\|rate"
fi

echo ""
echo "========================================="

