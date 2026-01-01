#!/bin/bash
# Fix: Créer Ingress SANS TLS d'abord

echo "🔧 FIX: INGRESS SANS TLS"
echo "========================"
echo ""

# 1. Supprimer l'Ingress actuel avec TLS
echo "1️⃣  Suppression de l'Ingress avec TLS..."
kubectl delete ingress front-toolsapps -n default 2>/dev/null || true
kubectl delete certificate le-cert-front-toolsapps -n default 2>/dev/null || true
kubectl delete secret le-cert-front-toolsapps -n default 2>/dev/null || true
sleep 2
echo "   ✅ Supprimé"

# 2. Créer un Ingress HTTP uniquement (sans TLS)
echo ""
echo "2️⃣  Création Ingress HTTP (sans TLS)..."
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: front-toolsapps
  namespace: default
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
for i in {1..5}; do
    HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://front.toolsapps.eu 2>/dev/null)
    echo "   Tentative $i: HTTP = $HTTP"
    if [ "$HTTP" == "200" ]; then
        echo "   ✅ HTTP fonctionne!"
        break
    fi
    sleep 2
done

if [ "$HTTP" != "200" ]; then
    echo "   ❌ HTTP ne fonctionne pas"
    exit 1
fi

# 4. Afficher le contenu
echo ""
echo "4️⃣  Contenu de la page..."
curl -s http://front.toolsapps.eu 2>/dev/null | head -10
echo ""

# 5. Demander si on ajoute TLS
echo "========================"
echo "✅ HTTP FONCTIONNE!"
echo ""
echo "📝 Pour ajouter HTTPS (certificat staging):"
echo "   Exécutez: ./helm/add-tls-to-ingress.sh"
echo "========================"

