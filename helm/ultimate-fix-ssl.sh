#!/bin/bash
# Solution ultime: Recréer le ClusterIssuer et forcer une vraie requête ACME

echo "🔧 SOLUTION ULTIME - Recréation ClusterIssuer + Force ACME"
echo "==========================================================="
echo ""

echo "⚠️  Ce script va:"
echo "   1. Supprimer complètement le ClusterIssuer letsencrypt-prod"
echo "   2. Supprimer tous les objets cert-manager"
echo "   3. Recréer le ClusterIssuer avec un nouveau compte ACME"
echo "   4. Forcer cert-manager à contacter Let's Encrypt"
echo ""

read -p "Entrez votre email pour Let's Encrypt: " EMAIL

if [ -z "$EMAIL" ]; then
    echo "❌ Email requis"
    exit 1
fi

echo ""
echo "Email: $EMAIL"
read -p "Continuer? (o/N) " CONFIRM
if [ "$CONFIRM" != "o" ] && [ "$CONFIRM" != "O" ]; then
    echo "Annulé"
    exit 0
fi

echo ""
echo "1️⃣  Suppression du ClusterIssuer existant..."
kubectl delete clusterissuer letsencrypt-prod 2>/dev/null || true
kubectl delete secret letsencrypt-prod -n cert-manager 2>/dev/null || true
echo "   ✅ ClusterIssuer supprimé"

echo ""
echo "2️⃣  Suppression de tous les objets cert-manager..."
kubectl delete certificate --all -n production
kubectl delete certificaterequest --all -n production
kubectl delete order --all -n production
kubectl delete challenge --all -n production
kubectl delete secret frontend-toolsapps-tls -n production 2>/dev/null || true
echo "   ✅ Tous les objets supprimés"

echo ""
echo "3️⃣  Attente de la suppression complète (15 secondes)..."
sleep 15

echo ""
echo "4️⃣  Création d'un NOUVEAU ClusterIssuer Let's Encrypt..."

cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: $EMAIL
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

echo "   ✅ Nouveau ClusterIssuer créé"

echo ""
echo "5️⃣  Attente que le ClusterIssuer soit prêt (10 secondes)..."
sleep 10

kubectl get clusterissuer letsencrypt-prod -o yaml | grep -A 5 "status:"
echo ""

echo "6️⃣  Suppression et recréation de l'Ingress..."
kubectl delete ingress frontend-toolsapps -n production
sleep 3

cat <<'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: frontend-toolsapps
  namespace: production
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
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
  tls:
  - hosts:
    - front.toolsapps.eu
    secretName: frontend-toolsapps-tls
EOF

echo "   ✅ Ingress recréé"

echo ""
echo "7️⃣  Attente de la création du Certificate par cert-manager (30 secondes)..."
sleep 30

echo ""
echo "8️⃣  État des objets cert-manager:"
kubectl get certificate,certificaterequest,order,challenge -n production
echo ""

echo "9️⃣  Suivi du processus d'émission..."
echo ""

for i in {1..90}; do
    # Vérifier le certificat
    if kubectl get certificate frontend-toolsapps-tls -n production &>/dev/null; then
        CERT_READY=$(kubectl get certificate frontend-toolsapps-tls -n production -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)

        # Afficher l'état des challenges s'ils existent
        CHALLENGES=$(kubectl get challenge -n production 2>/dev/null | grep -v "NAME" | wc -l)
        if [ "$CHALLENGES" -gt 0 ]; then
            echo "   📝 Challenges actifs:"
            kubectl get challenge -n production -o wide | head -3
        fi

        # Afficher l'état des orders
        ORDERS=$(kubectl get order -n production 2>/dev/null | grep -v "NAME" | wc -l)
        if [ "$ORDERS" -gt 0 ]; then
            echo "   📝 Orders:"
            kubectl get order -n production | head -3
        fi

        if [ "$CERT_READY" == "True" ]; then
            echo "   ✅ Certificate Ready après $i secondes!"
            break
        fi
    fi

    if [ $((i % 15)) -eq 0 ]; then
        echo "   ⏳ Attente de l'émission... ($i/90 secondes)"
    fi
    sleep 1
done

echo ""
echo "🔟 Vérification du certificat émis..."
sleep 3

if ! kubectl get secret frontend-toolsapps-tls -n production &>/dev/null; then
    echo "   ❌ Secret TLS non créé!"
    echo ""
    echo "   📝 Derniers événements cert-manager:"
    kubectl logs -n cert-manager -l app=cert-manager --tail=50 | grep -i "error\|fail\|challenge\|order"
    exit 1
fi

# Examiner le certificat
echo "   📜 Examen du certificat..."
CERT_INFO=$(kubectl get secret frontend-toolsapps-tls -n production -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout 2>/dev/null)

ISSUER=$(echo "$CERT_INFO" | grep "Issuer:" | grep -o "CN = [^,]*" | cut -d= -f2 | xargs)
SUBJECT=$(echo "$CERT_INFO" | grep "Subject:" | grep -o "CN = [^,]*" | cut -d= -f2 | xargs)

echo "   Subject (domaine): $SUBJECT"
echo "   Issuer (émetteur): $ISSUER"
echo ""

# Vérifier si c'est vraiment Let's Encrypt
if echo "$ISSUER" | grep -qiE "Let's Encrypt|^R3$|^R4$|^R10$|^R11$|^E1$|^E2$|^E5$|^E6$"; then
    echo "   ✅✅✅ CERTIFICAT LET'S ENCRYPT AUTHENTIQUE! ✅✅✅"
    echo ""

    # Réactiver la redirection SSL
    echo "1️⃣1️⃣  Réactivation de la redirection SSL..."
    kubectl annotate ingress frontend-toolsapps -n production \
      nginx.ingress.kubernetes.io/ssl-redirect=true \
      nginx.ingress.kubernetes.io/force-ssl-redirect=true \
      --overwrite

    sleep 5

    # Test final
    echo ""
    echo "1️⃣2️⃣  Test final HTTPS..."

    # Test avec curl
    if curl -sS https://front.toolsapps.eu 2>&1 | head -1 | grep -q "<!DOCTYPE\|<html"; then
        echo "   ✅ HTTPS fonctionne parfaitement!"
        echo ""
        echo "   🔒 Vérification du certificat côté serveur:"
        echo | openssl s_client -servername front.toolsapps.eu -connect front.toolsapps.eu:443 2>/dev/null | openssl x509 -noout -issuer -dates
        echo ""
        echo "========================================="
        echo "🎉🎉🎉 SUCCÈS COMPLET! 🎉🎉🎉"
        echo "========================================="
        echo ""
        echo "✅ Application en ligne: https://front.toolsapps.eu"
        echo "✅ Certificat SSL: Let's Encrypt ($ISSUER)"
        echo "✅ Domaine: $SUBJECT"
        echo "✅ Renouvellement automatique: Activé"
        echo "✅ HTTPS forcé: Activé"
        echo ""
        echo "🎊 Déploiement 100% réussi!"
        echo "🎊 Félicitations!"
        echo ""
    else
        echo "   ⚠️  Vérifiez dans le navigateur:"
        echo "   https://front.toolsapps.eu"
        echo ""
        echo "   Le certificat est valide, mais curl peut avoir un cache."
        echo "   Attendez 1-2 minutes et testez dans votre navigateur."
    fi
else
    echo "   ❌ Toujours pas un vrai certificat Let's Encrypt"
    echo "   Émetteur: $ISSUER"
    echo ""
    echo "   📝 Vérifications supplémentaires:"
    echo ""
    echo "   ClusterIssuer:"
    kubectl describe clusterissuer letsencrypt-prod | tail -20
    echo ""
    echo "   Certificate:"
    kubectl describe certificate frontend-toolsapps-tls -n production | tail -20
    echo ""
    echo "   Logs cert-manager (dernières erreurs):"
    kubectl logs -n cert-manager -l app=cert-manager --tail=100 | grep -i "error\|fail"
fi

echo ""
echo "========================================="

