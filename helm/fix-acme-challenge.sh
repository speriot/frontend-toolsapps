#!/bin/bash
# Fix pour le HTTP-01 Challenge Let's Encrypt
# Problème: "wrong status code '404', expected '200'"

echo "🔧 FIX ACME HTTP-01 CHALLENGE"
echo "=============================="
echo ""
echo "📋 Problème: Le challenge HTTP-01 retourne 404"
echo "   Let's Encrypt ne peut pas valider le domaine"
echo ""

# 1. Vérifier le challenge en cours
echo "1️⃣  Vérification des Challenges en cours..."
kubectl get challenges -n production
CHALLENGE=$(kubectl get challenges -n production -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$CHALLENGE" ]; then
    echo "   Challenge actif: $CHALLENGE"
    kubectl describe challenge $CHALLENGE -n production | grep -A 5 "Status:"
fi
echo ""

# 2. Vérifier si le solver ingress est créé
echo "2️⃣  Vérification du solver Ingress (cm-acme-http-solver)..."
kubectl get ingress -n production | grep -i "acme\|solver\|challenge"
SOLVER_INGRESS=$(kubectl get ingress -n production -o name | grep "cm-acme" 2>/dev/null)
if [ -n "$SOLVER_INGRESS" ]; then
    echo "   ✅ Solver Ingress trouvé: $SOLVER_INGRESS"
    kubectl get $SOLVER_INGRESS -n production -o yaml | head -30
else
    echo "   ❌ Aucun solver Ingress trouvé!"
fi
echo ""

# 3. Vérifier les pods cert-manager
echo "3️⃣  Vérification des pods cert-manager..."
kubectl get pods -n cert-manager
echo ""

# 4. Vérifier l'Ingress Class
echo "4️⃣  Vérification de l'IngressClass..."
kubectl get ingressclass
echo ""

# 5. Recréer le ClusterIssuer avec la bonne configuration
echo "5️⃣  Recréation du ClusterIssuer avec solverIngress..."
read -p "   Continuer? (o/N) " confirm
if [ "$confirm" != "o" ] && [ "$confirm" != "O" ]; then
    echo "Annulé."
    exit 0
fi

# Supprimer l'ancien ClusterIssuer
echo "   Suppression de l'ancien ClusterIssuer..."
kubectl delete clusterissuer letsencrypt-prod 2>/dev/null || true
kubectl delete secret letsencrypt-prod 2>/dev/null || true
sleep 2

# Créer le nouveau ClusterIssuer avec ingressClass explicite
echo "   Création du ClusterIssuer avec configuration corrigée..."
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: stephane.periot@gmail.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          ingressClassName: nginx
EOF

echo "   ✅ ClusterIssuer créé"
sleep 3

# 6. Vérifier le ClusterIssuer
echo ""
echo "6️⃣  Vérification du ClusterIssuer..."
kubectl get clusterissuer letsencrypt-prod
kubectl describe clusterissuer letsencrypt-prod | grep -A 5 "Status:"
echo ""

# 7. Supprimer le certificat et le secret pour forcer une nouvelle demande
echo "7️⃣  Suppression du certificat pour forcer une nouvelle demande..."
kubectl delete certificate frontend-toolsapps-tls -n production 2>/dev/null || true
kubectl delete secret frontend-toolsapps-tls -n production 2>/dev/null || true
kubectl delete certificaterequest -n production --all 2>/dev/null || true
kubectl delete order -n production --all 2>/dev/null || true
kubectl delete challenge -n production --all 2>/dev/null || true
echo "   ✅ Anciens objets supprimés"
sleep 2

# 8. Désactiver la redirection SSL temporairement
echo ""
echo "8️⃣  Désactivation de la redirection SSL (pour le challenge HTTP-01)..."
kubectl annotate ingress frontend-toolsapps -n production \
  nginx.ingress.kubernetes.io/ssl-redirect=false \
  nginx.ingress.kubernetes.io/force-ssl-redirect=false \
  --overwrite
echo "   ✅ Redirection SSL désactivée"
sleep 2

# 9. Recréer l'Ingress proprement
echo ""
echo "9️⃣  Recréation de l'Ingress avec TLS..."
kubectl delete ingress frontend-toolsapps -n production 2>/dev/null || true
sleep 2

cat <<EOF | kubectl apply -f -
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
  tls:
  - hosts:
    - front.toolsapps.eu
    secretName: frontend-toolsapps-tls
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
EOF

echo "   ✅ Ingress recréé"
echo ""

# 10. Attendre que le challenge soit créé
echo "🔟 Attente de la création du challenge (20 secondes)..."
sleep 20

# 11. Vérifier les challenges
echo ""
echo "1️⃣1️⃣  Vérification des challenges..."
kubectl get challenges -n production
kubectl get orders -n production
kubectl get certificaterequests -n production
echo ""

# 12. Vérifier si le solver ingress est créé
echo "1️⃣2️⃣  Vérification du solver Ingress..."
kubectl get ingress -n production
SOLVER=$(kubectl get ingress -n production -o name 2>/dev/null | grep "cm-acme" | head -1)
if [ -n "$SOLVER" ]; then
    echo "   ✅ Solver Ingress créé: $SOLVER"
    # Test du challenge
    TOKEN=$(kubectl get $SOLVER -n production -o jsonpath='{.spec.rules[0].http.paths[0].path}' 2>/dev/null | sed 's|/.well-known/acme-challenge/||')
    if [ -n "$TOKEN" ]; then
        CHALLENGE_URL="http://front.toolsapps.eu/.well-known/acme-challenge/$TOKEN"
        echo "   🔗 URL du challenge: $CHALLENGE_URL"
        echo "   Test..."
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$CHALLENGE_URL" 2>/dev/null)
        echo "   Code HTTP: $HTTP_CODE"
    fi
else
    echo "   ⚠️  Solver Ingress pas encore créé, attente..."
fi
echo ""

# 13. Attendre le certificat
echo "1️⃣3️⃣  Attente du certificat (max 3 minutes)..."
for i in {1..90}; do
    CERT_READY=$(kubectl get certificate frontend-toolsapps-tls -n production -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
    if [ "$CERT_READY" == "True" ]; then
        echo ""
        echo "   ✅ Certificat prêt!"
        break
    fi

    # Afficher l'état du challenge
    if [ $((i % 10)) -eq 0 ]; then
        CHALLENGE_STATE=$(kubectl get challenges -n production -o jsonpath='{.items[0].status.state}' 2>/dev/null)
        echo "   ⏳ Attente... ($i/90) - Challenge: $CHALLENGE_STATE"
    fi

    sleep 2
done

# 14. Vérifier l'émetteur du certificat
echo ""
echo "1️⃣4️⃣  Vérification de l'émetteur..."
sleep 3

SECRET_EXISTS=$(kubectl get secret frontend-toolsapps-tls -n production 2>/dev/null)
if [ -z "$SECRET_EXISTS" ]; then
    echo "   ❌ Secret TLS non créé!"
    echo ""
    echo "   📝 Logs cert-manager:"
    kubectl logs -n cert-manager -l app=cert-manager --tail=30 | grep -i "error\|fail\|frontend\|challenge"
    echo ""
    echo "   📝 État des challenges:"
    kubectl describe challenges -n production
    exit 1
fi

ISSUER=$(kubectl get secret frontend-toolsapps-tls -n production -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout 2>/dev/null | grep "Issuer:" | head -1)

echo "   $ISSUER"

if echo "$ISSUER" | grep -qiE "Let's Encrypt|R3|R10|R11|R12|R13|E1|E2|E5|E6"; then
    echo "   ✅ CERTIFICAT LET'S ENCRYPT ÉMIS!"

    # Réactiver la redirection SSL
    echo ""
    echo "1️⃣5️⃣  Réactivation de la redirection SSL..."
    kubectl annotate ingress frontend-toolsapps -n production \
      nginx.ingress.kubernetes.io/ssl-redirect=true \
      nginx.ingress.kubernetes.io/force-ssl-redirect=true \
      --overwrite
    echo "   ✅ Redirection SSL réactivée"

    sleep 5

    # Test final
    echo ""
    echo "1️⃣6️⃣  Test final HTTPS..."
    HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://front.toolsapps.eu 2>/dev/null)
    echo "   Code HTTPS: $HTTPS_CODE"

    if [ "$HTTPS_CODE" == "200" ]; then
        echo ""
        echo "=============================="
        echo "🎉 SUCCÈS TOTAL!"
        echo "=============================="
        echo ""
        echo "✅ Certificat Let's Encrypt PRODUCTION émis"
        echo "✅ HTTPS fonctionne"
        echo ""
        echo "🔗 Testez: https://front.toolsapps.eu"
        echo ""
    else
        echo "   ⚠️  Code HTTP: $HTTPS_CODE"
        echo "   Attendez quelques secondes et retestez"
    fi
else
    echo "   ❌ Certificat pas Let's Encrypt: $ISSUER"
    echo ""
    echo "   📝 Vérifier les logs:"
    kubectl logs -n cert-manager -l app=cert-manager --tail=20 | grep -i "error\|fail"
fi

echo ""
echo "=============================="

