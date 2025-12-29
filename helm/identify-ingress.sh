#!/bin/bash

echo "🔍 IDENTIFICATION INGRESS CONTROLLER"
echo "===================================="

echo ""
echo "1️⃣  Recherche dans tous les namespaces..."
kubectl get pods -A | grep -i ingress

echo ""
echo "2️⃣  Recherche des deployments Ingress..."
kubectl get deploy -A | grep -i ingress

echo ""
echo "3️⃣  Recherche des services Ingress..."
kubectl get svc -A | grep -i ingress

echo ""
echo "4️⃣  Recherche avec labels standards..."
echo "   Label: app.kubernetes.io/name=ingress-nginx"
kubectl get pods -A -l app.kubernetes.io/name=ingress-nginx

echo ""
echo "5️⃣  Informations Kubernetes..."
echo "   Version:"
kubectl version --short 2>/dev/null || kubectl version

echo ""
echo "   Nodes:"
kubectl get nodes

echo ""
echo "===================================="
echo "📊 RÉSUMÉ:"
echo ""

FOUND=false

for NS in kube-system ingress-nginx default; do
    COUNT=$(kubectl get pods -n $NS 2>/dev/null | grep -i ingress | wc -l)
    if [ "$COUNT" -gt 0 ]; then
        echo "✅ $COUNT pod(s) Ingress trouvé(s) dans namespace: $NS"
        FOUND=true
    fi
done

if [ "$FOUND" = false ]; then
    echo "❌ Aucun pod Ingress Controller trouvé"
    echo ""
    echo "💡 Cela peut signifier:"
    echo "   1. L'Ingress Controller n'est pas installé"
    echo "   2. Il utilise un nom différent"
    echo "   3. Il est dans un état crashloop"
fi

echo ""
echo "===================================="

