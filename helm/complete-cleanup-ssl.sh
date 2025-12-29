#!/bin/bash
# Nettoyage complet de tous les objets cert-manager et recréation

echo "🧹 NETTOYAGE COMPLET CERT-MANAGER"
echo "=================================="
echo ""

echo "⚠️  Ce script va supprimer TOUS les objets cert-manager:"
echo "   - Certificate"
echo "   - CertificateRequest"
echo "   - Order"
echo "   - Challenge"
echo "   - Secret TLS"
echo ""

read -p "Continuer? (o/N) " CONFIRM
if [ "$CONFIRM" != "o" ] && [ "$CONFIRM" != "O" ]; then
    echo "Annulé"
    exit 0
fi

echo ""
echo "1️⃣  Suppression de tous les objets cert-manager..."

# Supprimer le certificat
kubectl delete certificate --all -n production
echo "   ✅ Certificates supprimés"

# Supprimer tous les CertificateRequests
kubectl delete certificaterequest --all -n production
echo "   ✅ CertificateRequests supprimés"

# Supprimer tous les Orders
kubectl delete order --all -n production
echo "   ✅ Orders supprimés"

# Supprimer tous les Challenges
kubectl delete challenge --all -n production
echo "   ✅ Challenges supprimés"

# Supprimer le secret TLS
kubectl delete secret frontend-toolsapps-tls -n production 2>/dev/null || true
echo "   ✅ Secret TLS supprimé"

echo ""
echo "2️⃣  Attente de la suppression complète (10 secondes)..."
sleep 10

echo ""
echo "3️⃣  Vérification que tout est supprimé..."
kubectl get certificate,certificaterequest,order,challenge -n production
echo ""

echo "4️⃣  Suppression et recréation de l'Ingress..."
kubectl delete ingress frontend-toolsapps -n production
sleep 5

# Recréer l'Ingress SANS redirection SSL
cat <<'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: frontend-toolsapps
  namespace: production
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
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

echo "   ✅ Ingress recréé (SSL redirect désactivé)"

echo ""
echo "5️⃣  Attente de la recréation automatique du certificat..."
echo "   (cert-manager va détecter l'Ingress et créer le Certificate)"
echo ""

sleep 15

echo "6️⃣  Surveillance de la création du certificat..."
echo ""

for i in {1..60}; do
    if kubectl get certificate frontend-toolsapps-tls -n production &>/dev/null; then
        echo "   ✅ Certificate créé"
        break
    fi
    echo "   ⏳ Attente de la création du Certificate... ($i/60)"
    sleep 2
done

echo ""
echo "7️⃣  État des objets cert-manager:"
kubectl get certificate,certificaterequest,order,challenge -n production
echo ""

echo "8️⃣  Attente de l'émission du certificat (max 2 minutes)..."
echo ""

for i in {1..60}; do
    CERT_READY=$(kubectl get certificate frontend-toolsapps-tls -n production -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
    if [ "$CERT_READY" == "True" ]; then
        echo "   ✅ Certificate Ready!"
        break
    fi

    # Afficher l'état actuel
    if [ $((i % 10)) -eq 0 ]; then
        echo "   ⏳ Attente... ($i/60 secondes)"
        kubectl get certificaterequest,order,challenge -n production 2>/dev/null | head -5
    fi
    sleep 2
done

echo ""
echo "9️⃣  Vérification du certificat émis..."
sleep 3

# Vérifier le secret existe
if ! kubectl get secret frontend-toolsapps-tls -n production &>/dev/null; then
    echo "   ❌ Secret TLS non créé!"
    echo ""
    echo "   Logs cert-manager:"
    kubectl logs -n cert-manager -l app=cert-manager --tail=30 | grep -i "error\|fail"
    exit 1
fi

# Vérifier l'émetteur
ISSUER=$(kubectl get secret frontend-toolsapps-tls -n production -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout 2>/dev/null | grep "Issuer:" | grep -o "CN = [^,]*" | cut -d= -f2 | xargs)

echo "   Émetteur du certificat: $ISSUER"
echo ""

# Vérifier si c'est Let's Encrypt
if echo "$ISSUER" | grep -qi "Let's Encrypt\|^R3$\|^R4$\|^R10$\|^R11$\|^E1$\|^E2$\|^E5$\|^E6$"; then
    echo "   ✅✅✅ CERTIFICAT LET'S ENCRYPT ÉMIS! ✅✅✅"
    echo ""

    # Réactiver la redirection SSL
    echo "🔟 Réactivation de la redirection SSL..."
    kubectl annotate ingress frontend-toolsapps -n production \
      nginx.ingress.kubernetes.io/ssl-redirect=true \
      nginx.ingress.kubernetes.io/force-ssl-redirect=true \
      --overwrite

    echo "   ✅ Redirection SSL réactivée"

    sleep 5

    # Test final
    echo ""
    echo "1️⃣1️⃣  Test final HTTPS..."

    # Test avec openssl pour voir le certificat
    echo "   Certificat vu par le serveur:"
    echo | openssl s_client -servername front.toolsapps.eu -connect front.toolsapps.eu:443 2>/dev/null | openssl x509 -noout -issuer -subject
    echo ""

    # Test curl
    if curl -s https://front.toolsapps.eu | head -1 | grep -q "<!DOCTYPE\|<html"; then
        echo "   ✅ HTTPS fonctionne avec Let's Encrypt!"
        echo ""
        echo "=================================="
        echo "🎉🎉🎉 SUCCÈS TOTAL! 🎉🎉🎉"
        echo "=================================="
        echo ""
        echo "✅ Votre application est en ligne:"
        echo "   https://front.toolsapps.eu"
        echo ""
        echo "✅ Certificat SSL: Let's Encrypt ($ISSUER)"
        echo "✅ Renouvellement automatique: Oui"
        echo "✅ HTTPS forcé: Oui"
        echo ""
        echo "🎊 Félicitations! Déploiement 100% réussi!"
        echo ""
    else
        echo "   ⚠️  curl échoue encore"
        curl -v https://front.toolsapps.eu 2>&1 | head -20
    fi
else
    echo "   ❌ Certificat toujours PAS de Let's Encrypt"
    echo "   Émetteur actuel: $ISSUER"
    echo ""
    echo "   📝 Détails du certificat:"
    kubectl describe certificate frontend-toolsapps-tls -n production | tail -30
    echo ""
    echo "   📝 CertificateRequest:"
    kubectl get certificaterequest -n production
    kubectl describe certificaterequest -n production | tail -20
    echo ""
    echo "   📝 Orders:"
    kubectl get order -n production
    echo ""
    echo "   📝 Challenges:"
    kubectl get challenge -n production
    echo ""
    echo "   📝 Logs cert-manager (erreurs):"
    kubectl logs -n cert-manager -l app=cert-manager --tail=50 | grep -i "error\|fail\|frontend-toolsapps"
fi

echo ""
echo "=================================="

