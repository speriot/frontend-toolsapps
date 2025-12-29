#!/bin/bash

echo "🔧 CORRECTION DU PROBLÈME DE SERVICE (404)"
echo "============================================"

NAMESPACE="production"
APP_NAME="frontend-toolsapps"

echo ""
echo "📋 Problème identifié:"
echo "   - Les pods répondent 200 OK"
echo "   - Mais le service ne peut pas les atteindre"
echo "   - Cause: Les labels des pods ne correspondent pas aux selectors du service"

echo ""
echo "1️⃣  Labels actuels des pods:"
kubectl get pods -n $NAMESPACE -o json | jq -r '.items[0].metadata.labels | to_entries | .[] | "   \(.key): \(.value)"' | head -10

echo ""
echo "2️⃣  Selectors du service:"
kubectl get svc -n $NAMESPACE $APP_NAME -o json | jq -r '.spec.selector | to_entries | .[] | "   \(.key): \(.value)"'

echo ""
echo "3️⃣  Solution: Patch du deployment pour ajouter les bons labels..."
echo ""

# Patch du deployment pour ajouter les labels manquants
kubectl patch deployment $APP_NAME -n $NAMESPACE --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/metadata/labels/app.kubernetes.io~1name",
    "value": "frontend-toolsapps"
  },
  {
    "op": "add",
    "path": "/spec/template/metadata/labels/app.kubernetes.io~1instance",
    "value": "frontend-toolsapps"
  }
]'

if [ $? -eq 0 ]; then
    echo "   ✅ Deployment patché avec succès!"
    echo ""
    echo "4️⃣  Attente du redéploiement des pods (30 secondes)..."
    sleep 10
    kubectl rollout status deployment/$APP_NAME -n $NAMESPACE --timeout=60s

    echo ""
    echo "5️⃣  Vérification des nouveaux labels:"
    kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=$APP_NAME -o json | jq -r '.items[0].metadata.labels | to_entries | .[] | "   \(.key): \(.value)"' | head -10

    echo ""
    echo "6️⃣  Test du service..."
    sleep 5
    kubectl run test-service-fix --rm -i --restart=Never --image=curlimages/curl -n $NAMESPACE -- curl -s -o /dev/null -w "Code HTTP: %{http_code}\n" http://$APP_NAME.$NAMESPACE.svc.cluster.local 2>&1

    echo ""
    echo "7️⃣  Test externe via Ingress..."
    curl -s -o /dev/null -w "Code HTTP: %{http_code}\n" http://front.toolsapps.eu

    echo ""
    echo "============================================"
    echo "🎉 CORRECTION TERMINÉE!"
    echo ""
    echo "📝 Testez maintenant dans votre navigateur:"
    echo "   http://front.toolsapps.eu"
    echo "   https://front.toolsapps.eu"

else
    echo "   ❌ Erreur lors du patch!"
    echo ""
    echo "   Alternative: Mise à jour via Helm..."
    echo ""

    # Alternative: redéployer avec Helm en s'assurant des bons labels
    cd ~/frontend-toolsapps
    helm upgrade --install frontend-toolsapps ./helm/frontend-toolsapps \
        --namespace $NAMESPACE \
        --set image.repository=docker.io/st3ph31/frontend-toolsapps \
        --set image.tag=v1.0.0 \
        --set ingress.hosts[0].host=front.toolsapps.eu \
        --set ingress.hosts[0].paths[0].path=/ \
        --set ingress.hosts[0].paths[0].pathType=Prefix \
        --set ingress.tls[0].secretName=frontend-toolsapps-tls \
        --set ingress.tls[0].hosts[0]=front.toolsapps.eu \
        --wait

    echo ""
    echo "   ✅ Redéploiement Helm terminé!"
fi

echo ""
echo "============================================"

