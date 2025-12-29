#!/bin/bash
# Script de correction rapide du problème SSL self-signed certificate

echo "🔧 CORRECTION DU CERTIFICAT SSL"
echo "================================"
echo ""

echo "📋 Problème détecté:"
echo "   - Certificate 'Ready: True' mais curl voit 'self-signed certificate'"
echo "   - Cela signifie que cert-manager a créé un certificat temporaire"
echo "   - Le vrai certificat Let's Encrypt n'a pas été émis"
echo ""

# Vérifier le ClusterIssuer
echo "1️⃣  Vérification du ClusterIssuer Let's Encrypt..."
if kubectl get clusterissuer letsencrypt-prod &>/dev/null; then
    echo "   ✅ ClusterIssuer existe"

    # Vérifier s'il est prêt
    ISSUER_READY=$(kubectl get clusterissuer letsencrypt-prod -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
    if [ "$ISSUER_READY" == "True" ]; then
        echo "   ✅ ClusterIssuer est prêt"
    else
        echo "   ❌ ClusterIssuer n'est pas prêt"
        echo "   📝 Création du ClusterIssuer..."

        # Demander l'email
        read -p "   Entrez votre email pour Let's Encrypt: " EMAIL

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

        echo "   ✅ ClusterIssuer créé/mis à jour"
        sleep 5
    fi
else
    echo "   ❌ ClusterIssuer manquant!"
    echo "   📝 Création du ClusterIssuer..."

    read -p "   Entrez votre email pour Let's Encrypt: " EMAIL

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

    echo "   ✅ ClusterIssuer créé"
    sleep 5
fi

echo ""

# Vérifier le DNS
echo "2️⃣  Vérification du DNS..."
DNS_IP=$(dig +short front.toolsapps.eu | head -n 1)
VPS_IP=$(curl -4 -s ifconfig.me)

if [ -n "$DNS_IP" ]; then
    echo "   📍 DNS pointe vers: $DNS_IP"
    echo "   📍 VPS IP: $VPS_IP"

    if [ "$DNS_IP" == "$VPS_IP" ]; then
        echo "   ✅ DNS correctement configuré"
    else
        echo "   ⚠️  DNS ne pointe pas vers ce VPS!"
        echo "   Configurez: front.toolsapps.eu → $VPS_IP"
    fi
else
    echo "   ❌ DNS non résolu!"
    echo "   Configurez: front.toolsapps.eu → $VPS_IP"
fi

echo ""

# Supprimer et recréer le certificat
echo "3️⃣  Suppression du certificat self-signed..."
kubectl delete certificate frontend-toolsapps-tls -n production 2>/dev/null
kubectl delete secret frontend-toolsapps-tls -n production 2>/dev/null
echo "   ✅ Certificat supprimé"

echo ""
echo "4️⃣  Attente de 5 secondes..."
sleep 5

echo ""
echo "5️⃣  Redémarrage de l'Ingress Controller pour forcer la recréation..."
kubectl rollout restart deployment ingress-nginx-controller -n ingress-nginx
echo "   ✅ Ingress Controller redémarré"

echo ""
echo "6️⃣  Attente de 10 secondes..."
sleep 10

echo ""
echo "7️⃣  Le certificat devrait se recréer automatiquement..."
echo "   Suivi en temps réel:"
echo ""

# Attendre que le certificat réapparaisse
for i in {1..60}; do
    if kubectl get certificate frontend-toolsapps-tls -n production &>/dev/null; then
        echo "   ✅ Certificat recréé!"
        break
    fi
    echo "   ⏳ Attente de la recréation du certificat... ($i/60)"
    sleep 2
done

echo ""
echo "8️⃣  État actuel du certificat:"
kubectl get certificate -n production
echo ""

CERT_READY=$(kubectl get certificate frontend-toolsapps-tls -n production -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)

if [ "$CERT_READY" == "True" ]; then
    echo "   ✅ Certificat marqué comme Ready"
    echo ""
    echo "9️⃣  Test HTTPS..."
    sleep 5

    if curl -s -o /dev/null -w "%{http_code}" https://front.toolsapps.eu | grep -q "200\|301\|308"; then
        echo "   ✅ HTTPS fonctionne!"
        echo ""
        echo "================================"
        echo "🎉 CERTIFICAT SSL CORRECTEMENT ÉMIS!"
        echo ""
        echo "📝 Testez dans votre navigateur:"
        echo "   https://front.toolsapps.eu"
        echo ""
    else
        echo "   ⚠️  Le certificat est marqué Ready mais curl échoue encore"
        echo ""
        echo "📝 Causes possibles:"
        echo "   1. DNS pas encore propagé (attendre 5-30 min)"
        echo "   2. Firewall bloque le port 80 (nécessaire pour validation)"
        echo "   3. Attendre encore 2-3 minutes"
        echo ""
        echo "🔍 Pour diagnostiquer:"
        echo "   kubectl describe certificate frontend-toolsapps-tls -n production"
        echo "   kubectl logs -n cert-manager -l app=cert-manager --tail=50"
    fi
else
    echo "   ⚠️  Certificat pas encore prêt"
    echo ""
    echo "📝 Suivez l'évolution avec:"
    echo "   kubectl get certificate -n production -w"
    echo ""
    echo "   Le certificat devrait être émis dans 2-5 minutes"
    echo ""
    echo "🔍 Pour voir les logs:"
    echo "   kubectl logs -n cert-manager -l app=cert-manager -f"
fi

echo ""
echo "================================"

