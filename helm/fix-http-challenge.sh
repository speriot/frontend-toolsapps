#!/bin/bash
# Solution ultime : Vérifier et corriger l'accessibilité HTTP pour Let's Encrypt

echo "🔧 CORRECTION ULTIME - HTTP-01 CHALLENGE"
echo "========================================="
echo ""

echo "🔍 Diagnostic du problème:"
echo "   Erreur: 'wrong status code 404, expected 200'"
echo "   Cause: Let's Encrypt ne peut pas valider via HTTP-01"
echo "   Raison: L'Ingress ou le Service ne répond pas correctement"
echo ""

# 1. Vérifier que l'application répond
echo "1️⃣  Vérification du Service et des Pods..."
kubectl get svc frontend-toolsapps -n production
kubectl get pods -n production -l app.kubernetes.io/name=frontend-toolsapps

POD_STATUS=$(kubectl get pods -n production -l app.kubernetes.io/name=frontend-toolsapps -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
if [ "$POD_STATUS" != "Running" ]; then
    echo "   ❌ Les pods ne sont pas en Running!"
    kubectl get pods -n production
    exit 1
fi
echo "   ✅ Pods Running"
echo ""

# 2. Test direct du service
echo "2️⃣  Test du Service en interne..."
POD_NAME=$(kubectl get pods -n production -l app.kubernetes.io/name=frontend-toolsapps -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n production $POD_NAME -- wget -O- http://localhost:80 2>/dev/null | head -5
if [ $? -eq 0 ]; then
    echo "   ✅ Le pod répond sur le port 80"
else
    echo "   ❌ Le pod ne répond pas!"
    exit 1
fi
echo ""

# 3. Vérifier l'Ingress Controller
echo "3️⃣  Vérification de l'Ingress Controller..."
kubectl get pods -n ingress-nginx
INGRESS_POD=$(kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller -o jsonpath='{.items[0].metadata.name}')
if [ -z "$INGRESS_POD" ]; then
    echo "   ❌ Ingress Controller introuvable!"
    exit 1
fi
echo "   ✅ Ingress Controller: $INGRESS_POD"
echo ""

# 4. Test HTTP direct (sans SSL)
echo "4️⃣  Test HTTP direct (port 80)..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://front.toolsapps.eu 2>/dev/null)
echo "   HTTP Status Code: $HTTP_CODE"

if [ "$HTTP_CODE" == "308" ] || [ "$HTTP_CODE" == "301" ]; then
    echo "   ⚠️  Redirection HTTPS (normal)"
elif [ "$HTTP_CODE" == "200" ]; then
    echo "   ✅ HTTP répond"
elif [ "$HTTP_CODE" == "404" ]; then
    echo "   ❌ HTTP 404 - C'est le problème!"
    echo "   L'Ingress ne route pas correctement vers le service"
else
    echo "   ⚠️  Code inattendu: $HTTP_CODE"
fi
echo ""

# 5. Vérifier la configuration de l'Ingress
echo "5️⃣  Vérification de la configuration Ingress..."
kubectl get ingress frontend-toolsapps -n production -o yaml | grep -A 10 "backend:"
echo ""

# 6. Désactiver temporairement la redirection SSL
echo "6️⃣  Désactivation temporaire de la redirection SSL..."
echo "   (Pour permettre à Let's Encrypt de valider via HTTP)"

kubectl annotate ingress frontend-toolsapps -n production \
  nginx.ingress.kubernetes.io/ssl-redirect=false \
  --overwrite

kubectl annotate ingress frontend-toolsapps -n production \
  nginx.ingress.kubernetes.io/force-ssl-redirect=false \
  --overwrite

echo "   ✅ Redirection SSL désactivée"
echo ""

# 7. Attendre propagation
echo "7️⃣  Attente de la propagation (10 secondes)..."
sleep 10

# 8. Test HTTP sans redirection
echo "8️⃣  Test HTTP (devrait répondre 200)..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://front.toolsapps.eu 2>/dev/null)
echo "   HTTP Status Code: $HTTP_CODE"

if [ "$HTTP_CODE" == "200" ]; then
    echo "   ✅ HTTP répond 200 maintenant!"
elif [ "$HTTP_CODE" == "404" ]; then
    echo "   ❌ Toujours 404 - Problème de routing Ingress"
    echo ""
    echo "   📝 Vérifier les logs de l'Ingress Controller:"
    kubectl logs -n ingress-nginx $INGRESS_POD --tail=20 | grep -i "error\|404"
    exit 1
fi
echo ""

# 9. Supprimer et recréer le certificat
echo "9️⃣  Suppression du certificat pour forcer une nouvelle tentative..."
kubectl delete certificate frontend-toolsapps-tls -n production 2>/dev/null || true
kubectl delete secret frontend-toolsapps-tls -n production 2>/dev/null || true
echo "   ✅ Certificat supprimé"
echo ""

echo "🔟 Attente de la recréation du certificat (30 secondes)..."
sleep 30

# 10. Vérifier la création du certificat
echo ""
echo "1️⃣1️⃣  État du certificat:"
kubectl get certificate -n production

# 11. Attendre que Ready = True
echo ""
echo "1️⃣2️⃣  Attente que le certificat soit prêt (max 2 minutes)..."
for i in {1..60}; do
    CERT_READY=$(kubectl get certificate frontend-toolsapps-tls -n production -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
    if [ "$CERT_READY" == "True" ]; then
        echo "   ✅ Certificat prêt!"
        break
    fi
    echo "   ⏳ Attente... ($i/60)"
    sleep 2
done

# 12. Vérifier l'émetteur
echo ""
echo "1️⃣3️⃣  Vérification de l'émetteur..."
sleep 3

ISSUER=$(kubectl get secret frontend-toolsapps-tls -n production -o jsonpath='{.data.tls\.crt}' 2>/dev/null | base64 -d | openssl x509 -text -noout 2>/dev/null | grep "Issuer:" | grep -o "CN = [^,]*" | cut -d= -f2 | xargs)

echo "   Émetteur: $ISSUER"

if echo "$ISSUER" | grep -qi "Let's Encrypt\|R3\|R11\|E1\|E2"; then
    echo "   ✅ CERTIFICAT LET'S ENCRYPT ÉMIS!"

    # Réactiver la redirection SSL
    echo ""
    echo "1️⃣4️⃣  Réactivation de la redirection SSL..."
    kubectl annotate ingress frontend-toolsapps -n production \
      nginx.ingress.kubernetes.io/ssl-redirect=true \
      --overwrite

    kubectl annotate ingress frontend-toolsapps -n production \
      nginx.ingress.kubernetes.io/force-ssl-redirect=true \
      --overwrite

    echo "   ✅ Redirection SSL réactivée"

    sleep 5

    # Test final
    echo ""
    echo "1️⃣5️⃣  Test final HTTPS..."
    if curl -s https://front.toolsapps.eu | head -1 | grep -q "<!DOCTYPE\|<html"; then
        echo "   ✅ HTTPS fonctionne!"
        echo ""
        echo "========================================="
        echo "🎉 SUCCÈS! CERTIFICAT LET'S ENCRYPT!"
        echo "========================================="
        echo ""
        echo "✅ Testez dans votre navigateur:"
        echo "   https://front.toolsapps.eu"
        echo ""
        echo "Vous devriez voir:"
        echo "  • Cadenas vert 🔒"
        echo "  • Certificat Let's Encrypt"
        echo "  • Votre application React"
        echo ""
    else
        echo "   ⚠️  HTTPS ne répond pas encore"
        echo "   Attendez 1-2 minutes et testez: https://front.toolsapps.eu"
    fi
else
    echo "   ❌ Certificat PAS de Let's Encrypt"
    echo "   Émetteur: $ISSUER"
    echo ""
    echo "   📝 Vérifier les logs cert-manager:"
    kubectl logs -n cert-manager -l app=cert-manager --tail=50 | grep -i "error\|fail\|frontend-toolsapps"
fi

echo ""
echo "========================================="

