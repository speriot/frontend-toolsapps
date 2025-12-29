#!/bin/bash
# Script pour basculer de Staging vers Production après le 31 décembre

echo "🔄 BASCULEMENT STAGING → PRODUCTION"
echo "===================================="
echo ""

echo "⚠️  Ce script bascule de Let's Encrypt STAGING vers PRODUCTION"
echo "   À exécuter APRÈS le 31 décembre 2025 à 04:05 UTC"
echo ""

read -p "Êtes-vous après le 31 décembre 2025? (o/N) " CONFIRM
if [ "$CONFIRM" != "o" ] && [ "$CONFIRM" != "O" ]; then
    echo ""
    echo "⏸️  Attendez le 31 décembre 2025 à 04:05 UTC"
    echo "   Rate limit: https://letsencrypt.org/docs/rate-limits/"
    exit 0
fi

read -p "Entrez votre email pour Let's Encrypt: " EMAIL

if [ -z "$EMAIL" ]; then
    echo "❌ Email requis"
    exit 1
fi

echo ""
echo "1️⃣  Suppression du ClusterIssuer staging..."
kubectl delete clusterissuer letsencrypt-staging 2>/dev/null || true
kubectl delete secret letsencrypt-staging -n cert-manager 2>/dev/null || true

echo ""
echo "2️⃣  Création du ClusterIssuer PRODUCTION..."

cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: $EMAIL
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

echo "   ✅ ClusterIssuer production créé"

echo ""
echo "3️⃣  Mise à jour de l'Ingress..."
kubectl annotate ingress frontend-toolsapps -n production \
  cert-manager.io/cluster-issuer=letsencrypt-prod \
  --overwrite

echo ""
echo "4️⃣  Suppression de l'ancien certificat staging..."
kubectl delete certificate frontend-toolsapps-tls -n production
kubectl delete secret frontend-toolsapps-tls -n production

echo ""
echo "5️⃣  Attente de l'émission du certificat production (2-3 minutes)..."
sleep 30

for i in {1..90}; do
    if kubectl get certificate frontend-toolsapps-tls -n production &>/dev/null; then
        CERT_READY=$(kubectl get certificate frontend-toolsapps-tls -n production -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)

        if [ "$CERT_READY" == "True" ]; then
            echo "   ✅ Certificat prêt!"
            break
        fi
    fi

    if [ $((i % 15)) -eq 0 ]; then
        echo "   ⏳ Attente... ($i/90)"
    fi
    sleep 1
done

echo ""
echo "6️⃣  Vérification du certificat production..."

if kubectl get secret frontend-toolsapps-tls -n production &>/dev/null; then
    ISSUER=$(kubectl get secret frontend-toolsapps-tls -n production -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout 2>/dev/null | grep "Issuer:" | grep -o "CN = [^,]*" | cut -d= -f2 | xargs)

    echo "   Émetteur: $ISSUER"
    echo ""

    if echo "$ISSUER" | grep -qiE "^R3$|^R4$|^R10$|^R11$|^E1$|^E2$"; then
        echo "========================================="
        echo "🎉 SUCCÈS! CERTIFICAT PRODUCTION!"
        echo "========================================="
        echo ""
        echo "✅ Certificat Let's Encrypt: $ISSUER"
        echo "✅ Application: https://front.toolsapps.eu"
        echo "✅ Cadenas vert dans le navigateur"
        echo ""
    else
        echo "   ⚠️  Émetteur: $ISSUER"
        echo "   Vérifiez les logs si ce n'est pas Let's Encrypt"
    fi
else
    echo "   ❌ Erreur lors de l'émission"
    kubectl logs -n cert-manager -l app=cert-manager --tail=50 | grep -i "error\|fail\|rate"
fi

echo ""
echo "========================================="

