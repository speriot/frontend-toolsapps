#!/bin/bash

echo "🔧 CORRECTION ULTIME HTTPS 404"
echo "================================"

NAMESPACE="production"
APP_NAME="frontend-toolsapps"

echo ""
echo "1️⃣  Identification de l'Ingress Controller..."

# Recherche dans différents namespaces possibles
for NS in kube-system ingress-nginx default; do
    echo "   Recherche dans namespace: $NS"
    INGRESS_PODS=$(kubectl get pods -n $NS -l app.kubernetes.io/name=ingress-nginx -o name 2>/dev/null)

    if [ -n "$INGRESS_PODS" ]; then
        echo "   ✅ Ingress Controller trouvé dans: $NS"
        INGRESS_NAMESPACE=$NS
        break
    fi
done

if [ -z "$INGRESS_NAMESPACE" ]; then
    echo "   ⚠️  Ingress Controller non trouvé avec label standard"
    echo "   Recherche alternative..."

    for NS in kube-system ingress-nginx default; do
        INGRESS_PODS=$(kubectl get pods -n $NS | grep -i ingress | grep -i nginx | awk '{print $1}')
        if [ -n "$INGRESS_PODS" ]; then
            echo "   ✅ Ingress Controller trouvé dans: $NS"
            INGRESS_NAMESPACE=$NS
            break
        fi
    done
fi

if [ -z "$INGRESS_NAMESPACE" ]; then
    echo "   ❌ Impossible de trouver l'Ingress Controller"
    echo ""
    echo "   Liste de tous les pods système:"
    kubectl get pods -A | grep -i ingress
    exit 1
fi

echo ""
echo "2️⃣  Pods Ingress Controller actuels:"
kubectl get pods -n $INGRESS_NAMESPACE | grep -i ingress

echo ""
echo "3️⃣  Redémarrage de l'Ingress Controller..."

# Essayer de trouver le deployment
INGRESS_DEPLOY=$(kubectl get deploy -n $INGRESS_NAMESPACE -o name | grep -i ingress | head -1)

if [ -n "$INGRESS_DEPLOY" ]; then
    echo "   Deployment trouvé: $INGRESS_DEPLOY"
    kubectl rollout restart -n $INGRESS_NAMESPACE $INGRESS_DEPLOY
    echo "   ✅ Restart déclenché"
else
    echo "   ⚠️  Deployment non trouvé, suppression des pods..."
    kubectl delete pods -n $INGRESS_NAMESPACE -l app.kubernetes.io/name=ingress-nginx 2>/dev/null || \
    kubectl delete pods -n $INGRESS_NAMESPACE $(kubectl get pods -n $INGRESS_NAMESPACE | grep ingress | awk '{print $1}')
    echo "   ✅ Pods supprimés (recréation automatique)"
fi

echo ""
echo "4️⃣  Attente du redémarrage (30 secondes)..."
sleep 30

echo ""
echo "5️⃣  Vérification des nouveaux pods Ingress:"
kubectl get pods -n $INGRESS_NAMESPACE | grep -i ingress

echo ""
echo "6️⃣  Attente de la disponibilité complète (15 secondes)..."
sleep 15

echo ""
echo "7️⃣  Vérification de l'Ingress..."
kubectl get ingress -n $NAMESPACE $APP_NAME

echo ""
echo "8️⃣  Test HTTP..."
for i in {1..3}; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://front.toolsapps.eu)
    echo "   Tentative $i: Code HTTP = $HTTP_CODE"
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "308" ] || [ "$HTTP_CODE" = "301" ]; then
        break
    fi
    sleep 3
done

echo ""
echo "9️⃣  Test HTTPS..."
for i in {1..3}; do
    HTTPS_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://front.toolsapps.eu)
    echo "   Tentative $i: Code HTTPS = $HTTPS_CODE"
    if [ "$HTTPS_CODE" = "200" ]; then
        break
    fi
    sleep 3
done

echo ""
echo "🔟 Résultat final..."

if [ "$HTTPS_CODE" = "200" ]; then
    echo ""
    echo "================================"
    echo "🎉 SUCCÈS! HTTPS FONCTIONNE!"
    echo "================================"
    echo ""
    echo "✅ Code HTTPS: $HTTPS_CODE"
    echo ""
    echo "📱 Testez dans votre navigateur:"
    echo "   👉 https://front.toolsapps.eu"
    echo ""
    echo "⚠️  Avertissement certificat normal (staging)"
    echo "   Cliquez: Avancé → Continuer"
    echo ""
    echo "   Aperçu du contenu:"
    curl -k -s https://front.toolsapps.eu | head -10
    echo ""
    echo "================================"
elif [ "$HTTPS_CODE" = "404" ]; then
    echo ""
    echo "❌ HTTPS retourne toujours 404"
    echo ""
    echo "🔍 Analyse approfondie nécessaire..."
    echo ""
    echo "📋 Logs Ingress Controller (20 dernières lignes):"
    INGRESS_POD=$(kubectl get pods -n $INGRESS_NAMESPACE -o name | grep ingress | head -1 | cut -d/ -f2)
    if [ -n "$INGRESS_POD" ]; then
        kubectl logs -n $INGRESS_NAMESPACE $INGRESS_POD --tail=20 2>&1 | grep -v "^Error"
    fi
    echo ""
    echo "📋 Configuration Ingress complète:"
    kubectl get ingress -n $NAMESPACE $APP_NAME -o yaml | head -60
    echo ""
    echo "📋 Test direct au service:"
    kubectl run test-direct --rm -i --restart=Never --image=curlimages/curl -n $NAMESPACE -- curl -v http://$APP_NAME:80 2>&1 | head -20
else
    echo ""
    echo "⚠️  Code inattendu: $HTTPS_CODE"
fi

echo ""
echo "================================"

