#!/bin/bash
# Solution définitive pour forcer l'émission du certificat Let's Encrypt

echo "🔧 SOLUTION DÉFINITIVE - CERTIFICAT LET'S ENCRYPT"
echo "================================================="
echo ""

echo "📋 Ce script va:"
echo "   1. Supprimer complètement l'Ingress et le certificat"
echo "   2. Attendre la fin de la suppression"
echo "   3. Recréer l'Ingress avec la bonne configuration"
echo "   4. Forcer cert-manager à émettre un nouveau certificat"
echo ""

read -p "Continuer? (o/N) " CONFIRM
if [ "$CONFIRM" != "o" ] && [ "$CONFIRM" != "O" ]; then
    echo "Annulé"
    exit 0
fi

echo ""

# 1. Supprimer le certificat
echo "1️⃣  Suppression du certificat..."
kubectl delete certificate frontend-toolsapps-tls -n production 2>/dev/null || true
kubectl delete secret frontend-toolsapps-tls -n production 2>/dev/null || true
echo "   ✅ Certificat supprimé"
sleep 3

# 2. Supprimer l'Ingress
echo ""
echo "2️⃣  Suppression de l'Ingress..."
kubectl delete ingress frontend-toolsapps -n production
echo "   ✅ Ingress supprimé"
sleep 5

# 3. Vérifier que le ClusterIssuer existe
echo ""
echo "3️⃣  Vérification du ClusterIssuer..."
if ! kubectl get clusterissuer letsencrypt-prod &>/dev/null; then
    echo "   ❌ ClusterIssuer manquant! Création..."

    read -p "   Entrez votre email pour Let's Encrypt: " EMAIL

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
    sleep 5
fi
echo "   ✅ ClusterIssuer OK"

# 4. Recréer l'Ingress manuellement
echo ""
echo "4️⃣  Recréation de l'Ingress..."

cat <<'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: frontend-toolsapps
  namespace: production
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  ingressClassName: nginx
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
  tls:
  - hosts:
    - front.toolsapps.eu
    secretName: frontend-toolsapps-tls
EOF

echo "   ✅ Ingress recréé"

# 5. Attendre la création du certificat
echo ""
echo "5️⃣  Attente de la création du certificat..."
echo "   (Cela peut prendre 1-3 minutes)"
echo ""

for i in {1..90}; do
    if kubectl get certificate frontend-toolsapps-tls -n production &>/dev/null; then
        READY=$(kubectl get certificate frontend-toolsapps-tls -n production -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
        if [ "$READY" == "True" ]; then
            echo "   ✅ Certificat créé et Ready!"
            break
        fi
    fi
    echo "   ⏳ Attente... ($i/90 secondes)"
    sleep 2
done

echo ""
echo "6️⃣  Vérification du certificat émis..."
sleep 5

# Vérifier l'émetteur du certificat
ISSUER=$(kubectl get secret frontend-toolsapps-tls -n production -o jsonpath='{.data.tls\.crt}' 2>/dev/null | base64 -d | openssl x509 -text -noout 2>/dev/null | grep "Issuer:" | grep -o "CN = [^,]*" | cut -d= -f2 | xargs)

echo "   Émetteur: $ISSUER"

if echo "$ISSUER" | grep -qi "Let's Encrypt\|R3\|E1"; then
    echo "   ✅ Certificat Let's Encrypt émis!"
else
    echo "   ⚠️  Certificat NOT de Let's Encrypt"
    echo "   Émetteur: $ISSUER"
    echo ""
    echo "   📝 Vérifier les logs cert-manager:"
    kubectl logs -n cert-manager -l app=cert-manager --tail=50 | grep -i "error\|fail"
fi

echo ""
echo "7️⃣  Test final..."
sleep 3

# Test avec curl
if curl -s -o /dev/null -w "%{http_code}" https://front.toolsapps.eu 2>/dev/null | grep -q "200\|301\|308"; then
    echo "   ✅ curl fonctionne!"

    # Vérifier le certificat vu par curl
    CURL_ISSUER=$(echo | openssl s_client -servername front.toolsapps.eu -connect front.toolsapps.eu:443 2>/dev/null | openssl x509 -noout -issuer 2>/dev/null | grep -o "CN = [^,]*" | cut -d= -f2 | xargs)
    echo "   Certificat vu par curl: $CURL_ISSUER"

    if echo "$CURL_ISSUER" | grep -qi "Let's Encrypt\|R3\|E1"; then
        echo ""
        echo "================================================="
        echo "🎉 SUCCESS! CERTIFICAT LET'S ENCRYPT ÉMIS!"
        echo "================================================="
        echo ""
        echo "✅ Testez dans votre navigateur:"
        echo "   https://front.toolsapps.eu"
        echo ""
    else
        echo ""
        echo "⚠️  curl voit toujours un certificat self-signed"
        echo "   Cela peut être du au cache. Attendez 1-2 minutes."
    fi
else
    echo "   ⚠️  curl échoue"
    echo ""
    echo "   Vérifier:"
    kubectl get certificate -n production
    kubectl get ingress -n production
    kubectl describe certificate frontend-toolsapps-tls -n production | tail -20
fi

echo ""
echo "================================================="

