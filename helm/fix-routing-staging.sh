#!/bin/bash
# Fix le routing Traefik + utilise certificat staging en attendant le rate limit

echo "🔧 FIX ROUTING + CERTIFICAT STAGING"
echo "===================================="
echo ""
echo "📋 Situation:"
echo "   - Rate limit Let's Encrypt atteint (5 certificats en 7 jours)"
echo "   - Prochaine tentative possible: 2 janvier 2026 à 22:54 UTC"
echo "   - On va utiliser staging Let's Encrypt + corriger le routing"
echo ""

# 1. Vérifier le Service
echo "1️⃣  Vérification du Service frontend-toolsapps..."
kubectl get svc -n production frontend-toolsapps
echo ""
echo "   Selector du service:"
kubectl get svc -n production frontend-toolsapps -o jsonpath='{.spec.selector}'
echo ""
echo ""

# 2. Vérifier les Pods
echo "2️⃣  Vérification des Pods..."
kubectl get pods -n production -o wide
echo ""
echo "   Labels des pods:"
kubectl get pods -n production -o jsonpath='{range .items[*]}{.metadata.name}: {.metadata.labels}{"\n"}{end}'
echo ""

# 3. Vérifier les Endpoints
echo "3️⃣  Endpoints du service..."
kubectl get endpoints -n production frontend-toolsapps
echo ""

# 4. Test direct sur un pod
echo "4️⃣  Test direct sur un pod..."
POD=$(kubectl get pods -n production -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$POD" ]; then
    echo "   Pod: $POD"
    echo "   Test wget localhost:80..."
    kubectl exec -n production $POD -- wget -qO- --timeout=5 http://localhost:80 2>/dev/null | head -5
    if [ $? -eq 0 ]; then
        echo "   ✅ Pod répond!"
    else
        echo "   ❌ Pod ne répond pas!"
    fi
else
    echo "   ❌ Aucun pod trouvé!"
fi
echo ""

# 5. Créer ClusterIssuer staging
echo "5️⃣  Création du ClusterIssuer STAGING (pas de rate limit)..."
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: stephane.periot@gmail.com
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - http01:
        ingress:
          ingressClassName: traefik
EOF
echo "   ✅ ClusterIssuer staging créé"
echo ""

# 6. Nettoyage
echo "6️⃣  Nettoyage..."
kubectl delete ingress frontend-toolsapps -n production 2>/dev/null || true
kubectl delete certificate frontend-toolsapps-tls -n production 2>/dev/null || true
kubectl delete secret frontend-toolsapps-tls -n production 2>/dev/null || true
kubectl delete certificaterequest -n production --all 2>/dev/null || true
kubectl delete order -n production --all 2>/dev/null || true
kubectl delete challenge -n production --all 2>/dev/null || true
sleep 2
echo "   ✅ Nettoyage effectué"
echo ""

# 7. Créer l'Ingress avec STAGING
echo "7️⃣  Création de l'Ingress avec certificat STAGING..."
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: frontend-toolsapps
  namespace: production
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-staging"
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
echo "   ✅ Ingress créé avec staging"
echo ""

# 8. Attendre le certificat staging
echo "8️⃣  Attente du certificat staging (max 2 min)..."
for i in {1..60}; do
    CERT_READY=$(kubectl get certificate frontend-toolsapps-tls -n production -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)

    if [ "$CERT_READY" == "True" ]; then
        echo ""
        echo "   ✅ Certificat staging émis!"
        break
    fi

    if [ $((i % 10)) -eq 0 ]; then
        CHALLENGE=$(kubectl get challenges -n production -o jsonpath='{.items[0].status.state}' 2>/dev/null)
        echo "   ⏳ ($i/60) Challenge: $CHALLENGE"
    fi

    sleep 2
done

# 9. Tests
echo ""
echo "9️⃣  Tests..."
sleep 3

echo ""
echo "   HTTP (sans TLS):"
HTTP=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 http://front.toolsapps.eu 2>/dev/null)
echo "   Code: $HTTP"

echo ""
echo "   HTTPS (ignore certificat staging):"
HTTPS_K=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 -k https://front.toolsapps.eu 2>/dev/null)
echo "   Code: $HTTPS_K"

if [ "$HTTPS_K" == "200" ]; then
    echo ""
    echo "   Contenu:"
    curl -s -k https://front.toolsapps.eu 2>/dev/null | head -10
fi

echo ""
echo "   Certificat:"
kubectl get secret frontend-toolsapps-tls -n production -o jsonpath='{.data.tls\.crt}' 2>/dev/null | base64 -d | openssl x509 -noout -issuer -subject 2>/dev/null

echo ""
echo "===================================="
if [ "$HTTPS_K" == "200" ]; then
    echo "🎉 ROUTING FONCTIONNE!"
    echo ""
    echo "✅ L'application répond en HTTPS"
    echo "⚠️  Certificat STAGING (non valide pour navigateur)"
    echo ""
    echo "📅 Le 2 janvier 2026 après 22:54 UTC:"
    echo "   Exécutez: ./helm/switch-staging-to-prod.sh"
    echo "   pour passer au certificat production"
elif [ "$HTTP" == "200" ]; then
    echo "⚠️  HTTP fonctionne mais HTTPS 502"
    echo ""
    echo "   Le certificat staging n'est peut-être pas encore prêt"
    echo "   Attendez 1-2 minutes et retestez"
else
    echo "❌ Problème de routing"
    echo ""
    echo "   Codes: HTTP=$HTTP, HTTPS-k=$HTTPS_K"
    echo ""
    echo "   Vérifier les logs Traefik:"
    kubectl logs -n kube-system -l app.kubernetes.io/name=traefik --tail=20 2>/dev/null | grep -i "front\|error"
fi
echo "===================================="

