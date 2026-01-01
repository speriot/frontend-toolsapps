#!/bin/bash
# Utiliser TRAEFIK comme api.toolsapps.eu qui fonctionne

echo "🔧 CONFIGURATION AVEC TRAEFIK (comme api.toolsapps.eu)"
echo "======================================================="
echo ""
echo "📋 Constat:"
echo "   - api.toolsapps.eu utilise IngressClass: traefik ✅"
echo "   - front.toolsapps.eu utilisait IngressClass: nginx ❌"
echo "   - On va utiliser traefik pour front aussi!"
echo ""

# 1. Vérifier que traefik est disponible
echo "1️⃣  Vérification de Traefik..."
kubectl get ingressclass traefik
if [ $? -ne 0 ]; then
    echo "   ❌ IngressClass traefik non trouvé!"
    exit 1
fi
echo "   ✅ Traefik disponible"
echo ""

# 2. Vérifier le ClusterIssuer
echo "2️⃣  Mise à jour du ClusterIssuer pour Traefik..."
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
          ingressClassName: traefik
EOF
echo "   ✅ ClusterIssuer mis à jour pour traefik"
echo ""

# 3. Supprimer l'ancien Ingress
echo "3️⃣  Nettoyage de l'ancien Ingress..."
kubectl delete ingress frontend-toolsapps -n production 2>/dev/null || true
kubectl delete certificate frontend-toolsapps-tls -n production 2>/dev/null || true
kubectl delete secret frontend-toolsapps-tls -n production 2>/dev/null || true
kubectl delete certificaterequest -n production --all 2>/dev/null || true
kubectl delete order -n production --all 2>/dev/null || true
kubectl delete challenge -n production --all 2>/dev/null || true
echo "   ✅ Nettoyage effectué"
sleep 3

# 4. Créer l'Ingress avec Traefik (comme api)
echo ""
echo "4️⃣  Création de l'Ingress avec Traefik..."
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: frontend-toolsapps
  namespace: production
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: traefik
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
echo "   ✅ Ingress créé avec Traefik"
echo ""

# 5. Vérifier l'Ingress
echo "5️⃣  Vérification de l'Ingress..."
kubectl get ingress -n production frontend-toolsapps
echo ""

# 6. Attendre le certificat
echo "6️⃣  Attente du certificat Let's Encrypt (max 3 min)..."
for i in {1..90}; do
    CERT_READY=$(kubectl get certificate frontend-toolsapps-tls -n production -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)

    if [ "$CERT_READY" == "True" ]; then
        # Vérifier l'émetteur
        ISSUER=$(kubectl get secret frontend-toolsapps-tls -n production -o jsonpath='{.data.tls\.crt}' 2>/dev/null | base64 -d | openssl x509 -noout -issuer 2>/dev/null)
        if echo "$ISSUER" | grep -qiE "Let's Encrypt|R3|R10|R11|R12|R13"; then
            echo ""
            echo "   ✅ Certificat Let's Encrypt émis!"
            echo "   $ISSUER"
            break
        fi
    fi

    if [ $((i % 10)) -eq 0 ]; then
        CHALLENGE=$(kubectl get challenges -n production -o jsonpath='{.items[0].status.state}' 2>/dev/null)
        ORDER=$(kubectl get orders -n production -o jsonpath='{.items[0].status.state}' 2>/dev/null)
        CERT_STATUS=$(kubectl get certificate frontend-toolsapps-tls -n production -o jsonpath='{.status.conditions[0].message}' 2>/dev/null)
        echo "   ⏳ ($i/90) Challenge: $CHALLENGE | Order: $ORDER"
    fi

    sleep 2
done

# 7. Tests finaux
echo ""
echo "7️⃣  Tests finaux..."
sleep 5

echo ""
echo "   Comparaison api vs front:"
echo ""
echo "   api.toolsapps.eu (référence - Traefik):"
curl -s -o /dev/null -w "   HTTPS: %{http_code}\n" https://api.toolsapps.eu 2>/dev/null

echo ""
echo "   front.toolsapps.eu (Traefik maintenant):"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://front.toolsapps.eu 2>/dev/null)
HTTPS_K=$(curl -s -o /dev/null -w "%{http_code}" -k https://front.toolsapps.eu 2>/dev/null)
HTTPS=$(curl -s -o /dev/null -w "%{http_code}" https://front.toolsapps.eu 2>/dev/null)
echo "   HTTP: $HTTP_CODE"
echo "   HTTPS (insecure): $HTTPS_K"
echo "   HTTPS: $HTTPS"

echo ""
echo "   Certificats:"
echo "   api:"
kubectl get secret -n default le-cert-api-toolsapps -o jsonpath='{.data.tls\.crt}' 2>/dev/null | base64 -d | openssl x509 -noout -issuer 2>/dev/null
echo "   front:"
kubectl get secret frontend-toolsapps-tls -n production -o jsonpath='{.data.tls\.crt}' 2>/dev/null | base64 -d | openssl x509 -noout -issuer 2>/dev/null

echo ""
echo "   État du certificat:"
kubectl get certificate -n production frontend-toolsapps-tls

echo ""
echo "======================================================="
if [ "$HTTPS" == "200" ]; then
    echo "🎉 SUCCÈS TOTAL!"
    echo ""
    echo "✅ https://front.toolsapps.eu fonctionne!"
elif [ "$HTTPS_K" == "200" ]; then
    echo "⚠️  L'application répond mais le certificat n'est pas encore validé"
    echo ""
    echo "   Vérifiez dans 1-2 minutes:"
    echo "   https://front.toolsapps.eu"
    echo ""
    echo "   État du challenge:"
    kubectl get challenges -n production
    kubectl describe certificate frontend-toolsapps-tls -n production | tail -15
else
    echo "⚠️  Problème persistant"
    echo ""
    echo "   Codes: HTTP=$HTTP_CODE, HTTPS-k=$HTTPS_K, HTTPS=$HTTPS"
    echo ""
    echo "   📝 Diagnostic:"
    echo ""
    echo "   Ingress:"
    kubectl get ingress -n production frontend-toolsapps -o wide
    echo ""
    echo "   Certificate:"
    kubectl describe certificate frontend-toolsapps-tls -n production 2>/dev/null | tail -20
    echo ""
    echo "   Challenges:"
    kubectl get challenges -n production
    kubectl describe challenges -n production 2>/dev/null | grep -A 10 "Status:"
    echo ""
    echo "   Logs cert-manager:"
    kubectl logs -n cert-manager -l app=cert-manager --tail=20 | grep -iE "error|fail|frontend"
fi
echo "======================================================="

