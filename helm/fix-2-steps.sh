#!/bin/bash
# Solution: Créer l'Ingress en 2 étapes pour éviter le cercle vicieux TLS

echo "🔧 FIX CHALLENGE HTTP-01 - MÉTHODE 2 ÉTAPES"
echo "============================================"
echo ""
echo "📋 Problème identifié:"
echo "   - Traefik ne peut pas configurer TLS car le secret n'existe pas"
echo "   - Le challenge HTTP-01 échoue (404)"
echo "   - Cercle vicieux: pas de cert → erreur TLS → challenge fail"
echo ""
echo "💡 Solution: Créer l'Ingress SANS TLS, puis ajouter TLS après"
echo ""

# 1. Nettoyage complet
echo "1️⃣  Nettoyage complet..."
kubectl delete ingress frontend-toolsapps -n production 2>/dev/null || true
kubectl delete certificate frontend-toolsapps-tls -n production 2>/dev/null || true
kubectl delete secret frontend-toolsapps-tls -n production 2>/dev/null || true
kubectl delete certificaterequest -n production --all 2>/dev/null || true
kubectl delete order -n production --all 2>/dev/null || true
kubectl delete challenge -n production --all 2>/dev/null || true
sleep 3
echo "   ✅ Nettoyage effectué"
echo ""

# 2. Créer l'Ingress SANS TLS (HTTP uniquement)
echo "2️⃣  Création de l'Ingress HTTP uniquement (sans TLS)..."
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: frontend-toolsapps
  namespace: production
spec:
  ingressClassName: traefik
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
sleep 5

# 3. Test HTTP
echo ""
echo "3️⃣  Test HTTP..."
for i in {1..6}; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://front.toolsapps.eu 2>/dev/null)
    echo "   Tentative $i: HTTP = $HTTP_CODE"
    if [ "$HTTP_CODE" == "200" ]; then
        echo "   ✅ HTTP fonctionne!"
        break
    fi
    sleep 3
done

if [ "$HTTP_CODE" != "200" ]; then
    echo "   ❌ HTTP ne fonctionne pas encore"
    echo "   Attendez et retestez: curl http://front.toolsapps.eu"
    exit 1
fi

# 4. Créer le Certificate manuellement
echo ""
echo "4️⃣  Création du Certificate manuellement..."
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: frontend-toolsapps-tls
  namespace: production
spec:
  secretName: frontend-toolsapps-tls
  issuerRef:
    name: letsencrypt-staging
    kind: ClusterIssuer
  dnsNames:
  - front.toolsapps.eu
EOF
echo "   ✅ Certificate créé"
echo ""

# 5. Attendre le certificat
echo "5️⃣  Attente du certificat staging (max 2 min)..."
for i in {1..60}; do
    CERT_READY=$(kubectl get certificate frontend-toolsapps-tls -n production -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)

    if [ "$CERT_READY" == "True" ]; then
        echo ""
        echo "   ✅ Certificat émis!"
        break
    fi

    if [ $((i % 10)) -eq 0 ]; then
        CHALLENGE=$(kubectl get challenges -n production -o jsonpath='{.items[0].status.state}' 2>/dev/null)
        REASON=$(kubectl get challenges -n production -o jsonpath='{.items[0].status.reason}' 2>/dev/null | head -c 80)
        echo "   ⏳ ($i/60) Challenge: $CHALLENGE"
        if [ -n "$REASON" ]; then
            echo "      Reason: $REASON..."
        fi
    fi

    sleep 2
done

# Vérifier si le secret existe
SECRET_EXISTS=$(kubectl get secret frontend-toolsapps-tls -n production 2>/dev/null)
if [ -z "$SECRET_EXISTS" ]; then
    echo ""
    echo "   ❌ Le certificat n'a pas été créé"
    echo "   📝 Vérifier les challenges:"
    kubectl get challenges -n production
    kubectl describe challenges -n production 2>/dev/null | grep -A 5 "Status:"
    echo ""
    echo "   📝 Logs cert-manager:"
    kubectl logs -n cert-manager -l app=cert-manager --tail=10 | grep -iE "error|fail|frontend"
    exit 1
fi

echo ""
echo "   Émetteur du certificat:"
kubectl get secret frontend-toolsapps-tls -n production -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -issuer 2>/dev/null

# 6. Mettre à jour l'Ingress avec TLS
echo ""
echo "6️⃣  Mise à jour de l'Ingress avec TLS..."
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: frontend-toolsapps
  namespace: production
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
echo "   ✅ Ingress mis à jour avec TLS"
sleep 5

# 7. Tests finaux
echo ""
echo "7️⃣  Tests finaux..."
echo ""
echo "   HTTP:"
HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://front.toolsapps.eu 2>/dev/null)
echo "   Code: $HTTP"

echo ""
echo "   HTTPS (ignore cert staging):"
HTTPS_K=$(curl -s -o /dev/null -w "%{http_code}" -k https://front.toolsapps.eu 2>/dev/null)
echo "   Code: $HTTPS_K"

if [ "$HTTPS_K" == "200" ]; then
    echo ""
    echo "   Contenu:"
    curl -s -k https://front.toolsapps.eu 2>/dev/null | head -5
fi

echo ""
echo "============================================"
if [ "$HTTPS_K" == "200" ]; then
    echo "🎉 SUCCÈS!"
    echo ""
    echo "✅ HTTP:  http://front.toolsapps.eu → $HTTP"
    echo "✅ HTTPS: https://front.toolsapps.eu → $HTTPS_K"
    echo ""
    echo "⚠️  Certificat STAGING (avertissement navigateur normal)"
    echo ""
    echo "📅 Le 2 janvier 2026 après 22:54 UTC:"
    echo "   Changez letsencrypt-staging → letsencrypt-prod"
else
    echo "❌ Problème persistant"
    echo "   HTTP: $HTTP, HTTPS: $HTTPS_K"
fi
echo "============================================"

