#!/bin/bash
# Copier la configuration SSL de api.toolsapps.eu vers front.toolsapps.eu

echo "🔍 ANALYSE DE api.toolsapps.eu (qui fonctionne)"
echo "================================================"
echo ""

# 1. Trouver l'Ingress de api.toolsapps.eu
echo "1️⃣  Recherche de l'Ingress api.toolsapps.eu..."
API_INGRESS=$(kubectl get ingress --all-namespaces -o wide 2>/dev/null | grep "api.toolsapps.eu")
echo "$API_INGRESS"
echo ""

# Trouver le namespace
API_NS=$(kubectl get ingress --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.spec.rules[0].host}{"\n"}{end}' 2>/dev/null | grep "api.toolsapps.eu" | awk '{print $1}')
echo "   Namespace de api.toolsapps.eu: $API_NS"

if [ -z "$API_NS" ]; then
    echo "   ❌ Ingress api.toolsapps.eu non trouvé!"
    echo "   Recherche dans tous les namespaces..."
    kubectl get ingress --all-namespaces
    exit 1
fi

# 2. Extraire la configuration de l'Ingress api
echo ""
echo "2️⃣  Configuration de l'Ingress api.toolsapps.eu..."
API_INGRESS_NAME=$(kubectl get ingress -n $API_NS -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.spec.rules[0].host}{"\n"}{end}' | grep "api.toolsapps.eu" | awk '{print $1}')
echo "   Nom: $API_INGRESS_NAME"
echo ""

echo "   Annotations:"
kubectl get ingress -n $API_NS $API_INGRESS_NAME -o jsonpath='{.metadata.annotations}' | python3 -m json.tool 2>/dev/null || kubectl get ingress -n $API_NS $API_INGRESS_NAME -o jsonpath='{.metadata.annotations}'
echo ""

echo "   IngressClass:"
kubectl get ingress -n $API_NS $API_INGRESS_NAME -o jsonpath='{.spec.ingressClassName}'
echo ""

echo "   TLS Config:"
kubectl get ingress -n $API_NS $API_INGRESS_NAME -o jsonpath='{.spec.tls}'
echo ""

# 3. Vérifier le certificat de api
echo ""
echo "3️⃣  Certificat de api.toolsapps.eu..."
API_SECRET=$(kubectl get ingress -n $API_NS $API_INGRESS_NAME -o jsonpath='{.spec.tls[0].secretName}')
echo "   Secret TLS: $API_SECRET"

if [ -n "$API_SECRET" ]; then
    echo "   Émetteur:"
    kubectl get secret -n $API_NS $API_SECRET -o jsonpath='{.data.tls\.crt}' 2>/dev/null | base64 -d | openssl x509 -noout -issuer -dates 2>/dev/null
fi
echo ""

# 4. Vérifier le ClusterIssuer utilisé
echo "4️⃣  ClusterIssuer utilisé par api..."
API_ISSUER=$(kubectl get ingress -n $API_NS $API_INGRESS_NAME -o jsonpath='{.metadata.annotations.cert-manager\.io/cluster-issuer}')
echo "   ClusterIssuer: $API_ISSUER"

if [ -n "$API_ISSUER" ]; then
    echo ""
    echo "   Configuration du ClusterIssuer:"
    kubectl get clusterissuer $API_ISSUER -o yaml 2>/dev/null | grep -A 20 "spec:"
fi
echo ""

# 5. Exporter la configuration complète de l'Ingress api
echo "5️⃣  Export de la configuration complète..."
kubectl get ingress -n $API_NS $API_INGRESS_NAME -o yaml > /tmp/api-ingress-config.yaml
echo "   ✅ Configuration exportée dans /tmp/api-ingress-config.yaml"
echo ""

echo "================================================"
echo "🔧 APPLICATION À front.toolsapps.eu"
echo "================================================"
read -p "Appliquer la même configuration à front.toolsapps.eu? (o/N) " confirm
if [ "$confirm" != "o" ] && [ "$confirm" != "O" ]; then
    echo "Annulé."
    exit 0
fi

# A. Récupérer les annotations de api
echo ""
echo "A. Récupération des annotations de api..."
ANNOTATIONS=$(kubectl get ingress -n $API_NS $API_INGRESS_NAME -o json | python3 -c "
import json, sys
data = json.load(sys.stdin)
annotations = data.get('metadata', {}).get('annotations', {})
# Filtrer les annotations pertinentes
for key, value in annotations.items():
    if 'kubectl' not in key:
        print(f'    {key}: \"{value}\"')
" 2>/dev/null)

echo "$ANNOTATIONS"
echo ""

# B. Supprimer l'ancien Ingress frontend
echo "B. Suppression de l'ancien Ingress frontend..."
kubectl delete ingress frontend-toolsapps -n production 2>/dev/null || true
kubectl delete certificate frontend-toolsapps-tls -n production 2>/dev/null || true
kubectl delete secret frontend-toolsapps-tls -n production 2>/dev/null || true
echo "   ✅ Ancien Ingress supprimé"
sleep 3

# C. Créer le nouvel Ingress en copiant la config de api
echo ""
echo "C. Création du nouvel Ingress frontend (copie de api)..."

# Déterminer l'ingressClassName
INGRESS_CLASS=$(kubectl get ingress -n $API_NS $API_INGRESS_NAME -o jsonpath='{.spec.ingressClassName}')
if [ -z "$INGRESS_CLASS" ]; then
    INGRESS_CLASS="nginx"
fi

# Créer l'Ingress
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: frontend-toolsapps
  namespace: production
  annotations:
    cert-manager.io/cluster-issuer: "${API_ISSUER:-letsencrypt-prod}"
$(kubectl get ingress -n $API_NS $API_INGRESS_NAME -o json | python3 -c "
import json, sys
data = json.load(sys.stdin)
annotations = data.get('metadata', {}).get('annotations', {})
for key, value in annotations.items():
    if 'kubectl' not in key and 'cert-manager' not in key:
        print(f'    {key}: \"{value}\"')
" 2>/dev/null)
spec:
  ingressClassName: ${INGRESS_CLASS}
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

echo "   ✅ Ingress frontend créé avec la même config que api"
echo ""

# D. Attendre le certificat
echo "D. Attente du certificat (max 3 min)..."
for i in {1..90}; do
    CERT_READY=$(kubectl get certificate frontend-toolsapps-tls -n production -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)

    if [ "$CERT_READY" == "True" ]; then
        ISSUER=$(kubectl get secret frontend-toolsapps-tls -n production -o jsonpath='{.data.tls\.crt}' 2>/dev/null | base64 -d | openssl x509 -noout -issuer 2>/dev/null)
        echo ""
        echo "   ✅ Certificat Ready!"
        echo "   $ISSUER"
        break
    fi

    if [ $((i % 15)) -eq 0 ]; then
        CHALLENGE=$(kubectl get challenges -n production -o jsonpath='{.items[0].status.state}' 2>/dev/null)
        echo "   ⏳ ($i/90) Challenge: $CHALLENGE"
    fi

    sleep 2
done

# E. Tests finaux
echo ""
echo "E. Tests finaux..."
sleep 5

echo ""
echo "   Comparaison api vs front:"
echo ""
echo "   api.toolsapps.eu (référence):"
curl -s -o /dev/null -w "   HTTP: %{http_code}\n" http://api.toolsapps.eu 2>/dev/null
curl -s -o /dev/null -w "   HTTPS: %{http_code}\n" https://api.toolsapps.eu 2>/dev/null

echo ""
echo "   front.toolsapps.eu (corrigé):"
curl -s -o /dev/null -w "   HTTP: %{http_code}\n" http://front.toolsapps.eu 2>/dev/null
curl -s -o /dev/null -w "   HTTPS (insecure): %{http_code}\n" -k https://front.toolsapps.eu 2>/dev/null
curl -s -o /dev/null -w "   HTTPS: %{http_code}\n" https://front.toolsapps.eu 2>/dev/null

echo ""
echo "   Certificats:"
echo "   api:"
kubectl get secret -n $API_NS $API_SECRET -o jsonpath='{.data.tls\.crt}' 2>/dev/null | base64 -d | openssl x509 -noout -issuer 2>/dev/null
echo "   front:"
kubectl get secret frontend-toolsapps-tls -n production -o jsonpath='{.data.tls\.crt}' 2>/dev/null | base64 -d | openssl x509 -noout -issuer 2>/dev/null

echo ""
echo "================================================"
HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://front.toolsapps.eu 2>/dev/null)
if [ "$HTTPS_CODE" == "200" ]; then
    echo "🎉 SUCCÈS! HTTPS fonctionne!"
    echo ""
    echo "✅ https://front.toolsapps.eu"
else
    HTTPS_K=$(curl -s -o /dev/null -w "%{http_code}" -k https://front.toolsapps.eu 2>/dev/null)
    if [ "$HTTPS_K" == "200" ]; then
        echo "⚠️  HTTPS répond 200 mais certificat pas encore validé"
        echo "   Attendez 1-2 minutes et retestez"
    else
        echo "⚠️  Problème persistant (HTTPS=$HTTPS_CODE, HTTPS-k=$HTTPS_K)"
        echo ""
        echo "📝 Vérifier les challenges:"
        kubectl get challenges -n production
        kubectl describe challenges -n production 2>/dev/null | grep -A 5 "Status:"
    fi
fi
echo "================================================"

