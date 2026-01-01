#!/bin/bash
# Diagnostic et fix complet pour le problème SSL + 404

echo "🔧 DIAGNOSTIC COMPLET SSL + 404"
echo "================================"
echo ""

# 1. Vérifier le contenu réel du certificat
echo "1️⃣  Analyse du certificat actuel..."
SECRET_DATA=$(kubectl get secret frontend-toolsapps-tls -n production -o jsonpath='{.data.tls\.crt}' 2>/dev/null)
if [ -n "$SECRET_DATA" ]; then
    echo "$SECRET_DATA" | base64 -d | openssl x509 -text -noout 2>/dev/null | grep -E "Issuer:|Subject:|Not Before:|Not After:"
else
    echo "   ❌ Pas de certificat dans le secret!"
fi
echo ""

# 2. Vérifier l'état du Certificate
echo "2️⃣  État détaillé du Certificate..."
kubectl describe certificate frontend-toolsapps-tls -n production | tail -30
echo ""

# 3. Vérifier les CertificateRequests
echo "3️⃣  CertificateRequests..."
kubectl get certificaterequests -n production
echo ""

# 4. Vérifier les Orders
echo "4️⃣  Orders ACME..."
kubectl get orders -n production
echo ""

# 5. Vérifier les Challenges
echo "5️⃣  Challenges..."
kubectl get challenges -n production
echo ""

# 6. Logs cert-manager récents
echo "6️⃣  Logs cert-manager (erreurs)..."
kubectl logs -n cert-manager -l app=cert-manager --tail=50 2>/dev/null | grep -iE "error|fail|frontend-toolsapps" | tail -20
echo ""

# 7. Vérifier le ClusterIssuer
echo "7️⃣  ClusterIssuer..."
kubectl describe clusterissuer letsencrypt-prod | grep -A 10 "Status:"
echo ""

# 8. Test du chemin ACME challenge
echo "8️⃣  Test accessibilité HTTP (pour ACME challenge)..."
# Désactiver temporairement SSL redirect
kubectl annotate ingress frontend-toolsapps -n production \
  nginx.ingress.kubernetes.io/ssl-redirect=false \
  nginx.ingress.kubernetes.io/force-ssl-redirect=false \
  --overwrite 2>/dev/null

sleep 5

HTTP_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://front.toolsapps.eu/.well-known/acme-challenge/test 2>/dev/null)
echo "   Test /.well-known/acme-challenge/test: $HTTP_TEST"

HTTP_ROOT=$(curl -s -o /dev/null -w "%{http_code}" http://front.toolsapps.eu/ 2>/dev/null)
echo "   Test /: $HTTP_ROOT"
echo ""

# 9. Vérifier les labels des pods vs selector du service
echo "9️⃣  Vérification Labels/Selectors..."
echo "   Labels des pods:"
kubectl get pods -n production -o jsonpath='{range .items[*]}{.metadata.name}: {.metadata.labels}{"\n"}{end}' 2>/dev/null | head -5
echo ""
echo "   Selector du service:"
kubectl get svc frontend-toolsapps -n production -o jsonpath='{.spec.selector}' 2>/dev/null
echo ""
echo ""

# 10. Vérifier les EndpointSlices
echo "🔟 EndpointSlices..."
kubectl get endpointslices -n production -l kubernetes.io/service-name=frontend-toolsapps
echo ""

# 11. Test direct sur un pod
echo "1️⃣1️⃣  Test direct sur un pod..."
POD=$(kubectl get pods -n production -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$POD" ]; then
    echo "   Pod: $POD"
    kubectl exec -n production $POD -- wget -qO- http://localhost:80 2>/dev/null | head -5
else
    echo "   ❌ Pas de pod trouvé!"
fi
echo ""

# SOLUTION
echo "================================"
echo "🔧 APPLICATION DE LA SOLUTION"
echo "================================"
read -p "Continuer avec la correction? (o/N) " confirm
if [ "$confirm" != "o" ] && [ "$confirm" != "O" ]; then
    echo "Annulé."
    exit 0
fi

# A. Supprimer tout et recommencer proprement
echo ""
echo "A. Nettoyage complet..."
kubectl delete certificate frontend-toolsapps-tls -n production 2>/dev/null || true
kubectl delete secret frontend-toolsapps-tls -n production 2>/dev/null || true
kubectl delete certificaterequest -n production --all 2>/dev/null || true
kubectl delete order -n production --all 2>/dev/null || true
kubectl delete challenge -n production --all 2>/dev/null || true
kubectl delete ingress frontend-toolsapps -n production 2>/dev/null || true
echo "   ✅ Nettoyage effectué"
sleep 3

# B. Recréer l'Ingress SANS TLS d'abord (pour tester le routing)
echo ""
echo "B. Création Ingress SANS TLS (test routing)..."
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: frontend-toolsapps
  namespace: production
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
EOF
echo "   ✅ Ingress HTTP créé"
sleep 10

# C. Tester HTTP
echo ""
echo "C. Test HTTP..."
for i in {1..6}; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://front.toolsapps.eu 2>/dev/null)
    echo "   Tentative $i: HTTP = $HTTP_CODE"
    if [ "$HTTP_CODE" == "200" ]; then
        echo "   ✅ HTTP fonctionne!"
        break
    fi
    sleep 5
done

if [ "$HTTP_CODE" != "200" ]; then
    echo "   ❌ HTTP ne fonctionne pas, problème de routing!"
    echo ""
    echo "   Vérification du service..."
    kubectl get svc frontend-toolsapps -n production -o yaml | grep -A 5 "selector:"
    echo ""
    echo "   Vérification des pods..."
    kubectl get pods -n production --show-labels
    exit 1
fi

# D. Ajouter TLS
echo ""
echo "D. Ajout de TLS à l'Ingress..."
kubectl delete ingress frontend-toolsapps -n production
sleep 2

cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: frontend-toolsapps
  namespace: production
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
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
echo "   ✅ Ingress avec TLS créé"

# E. Attendre le certificat
echo ""
echo "E. Attente du certificat Let's Encrypt (max 3 min)..."
for i in {1..90}; do
    CERT_READY=$(kubectl get certificate frontend-toolsapps-tls -n production -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)

    if [ "$CERT_READY" == "True" ]; then
        # Vérifier que c'est bien Let's Encrypt
        ISSUER=$(kubectl get secret frontend-toolsapps-tls -n production -o jsonpath='{.data.tls\.crt}' 2>/dev/null | base64 -d | openssl x509 -noout -issuer 2>/dev/null)
        echo ""
        echo "   Certificat Ready!"
        echo "   $ISSUER"

        if echo "$ISSUER" | grep -qiE "Let's Encrypt|R3|R10|R11|R12|R13"; then
            echo "   ✅ Certificat Let's Encrypt valide!"
            break
        else
            echo "   ⚠️  Pas Let's Encrypt, attente..."
        fi
    fi

    # Afficher progression
    if [ $((i % 10)) -eq 0 ]; then
        CHALLENGE=$(kubectl get challenges -n production -o jsonpath='{.items[0].status.state}' 2>/dev/null)
        ORDER=$(kubectl get orders -n production -o jsonpath='{.items[0].status.state}' 2>/dev/null)
        echo "   ⏳ ($i/90) Challenge: $CHALLENGE, Order: $ORDER"
    fi

    sleep 2
done

# F. Test final
echo ""
echo "F. Tests finaux..."
sleep 5

echo "   HTTP:"
HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://front.toolsapps.eu 2>/dev/null)
echo "   Code: $HTTP"

echo "   HTTPS (insecure):"
HTTPS_I=$(curl -s -o /dev/null -w "%{http_code}" -k https://front.toolsapps.eu 2>/dev/null)
echo "   Code: $HTTPS_I"

echo "   HTTPS:"
HTTPS=$(curl -s -o /dev/null -w "%{http_code}" https://front.toolsapps.eu 2>/dev/null)
echo "   Code: $HTTPS"

echo ""
echo "   Certificat actuel:"
kubectl get secret frontend-toolsapps-tls -n production -o jsonpath='{.data.tls\.crt}' 2>/dev/null | base64 -d | openssl x509 -noout -issuer -dates 2>/dev/null

echo ""
echo "================================"
if [ "$HTTPS" == "200" ] || [ "$HTTPS_I" == "200" ]; then
    echo "🎉 SUCCÈS!"
    echo ""
    echo "✅ https://front.toolsapps.eu"
else
    echo "⚠️  Problème persistant"
    echo ""
    echo "Codes: HTTP=$HTTP, HTTPS(k)=$HTTPS_I, HTTPS=$HTTPS"
    echo ""
    echo "📝 Logs cert-manager:"
    kubectl logs -n cert-manager -l app=cert-manager --tail=20 | grep -iE "error|fail"
fi
echo "================================"

