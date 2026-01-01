#!/bin/bash
# Déplacer le frontend de 'production' vers 'default' (comme l'API)

echo "🔧 MIGRATION FRONTEND: production → default"
echo "============================================"
echo ""
echo "📋 Raison:"
echo "   - L'API est dans 'default' et fonctionne ✅"
echo "   - Le frontend est dans 'production' avec NetworkPolicy qui bloque Traefik"
echo "   - Solution: Tout mettre dans 'default' comme le guide le recommande"
echo ""

read -p "Continuer avec la migration? (o/N) " confirm
if [ "$confirm" != "o" ] && [ "$confirm" != "O" ]; then
    echo "Annulé."
    exit 0
fi

# 1. Récupérer l'image Docker actuelle
echo ""
echo "1️⃣  Récupération de la configuration actuelle..."
CURRENT_IMAGE=$(kubectl get deployment frontend-toolsapps -n production -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
echo "   Image actuelle: $CURRENT_IMAGE"

if [ -z "$CURRENT_IMAGE" ]; then
    CURRENT_IMAGE="docker.io/st3ph31/frontend-toolsapps:v1.0.0"
    echo "   Image par défaut utilisée: $CURRENT_IMAGE"
fi

# 2. Supprimer les ressources dans 'production'
echo ""
echo "2️⃣  Suppression des ressources dans 'production'..."
kubectl delete ingress frontend-toolsapps -n production 2>/dev/null || true
kubectl delete certificate frontend-toolsapps-tls -n production 2>/dev/null || true
kubectl delete secret frontend-toolsapps-tls -n production 2>/dev/null || true
kubectl delete svc frontend-toolsapps -n production 2>/dev/null || true
kubectl delete deployment frontend-toolsapps -n production 2>/dev/null || true
kubectl delete networkpolicy frontend-toolsapps -n production 2>/dev/null || true
echo "   ✅ Ressources supprimées de 'production'"

# 3. Créer le Deployment dans 'default'
echo ""
echo "3️⃣  Création du Deployment dans 'default'..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-toolsapps
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend-toolsapps
  template:
    metadata:
      labels:
        app: frontend-toolsapps
    spec:
      containers:
        - name: frontend-toolsapps
          image: ${CURRENT_IMAGE}
          ports:
            - containerPort: 80
          resources:
            requests:
              memory: "64Mi"
              cpu: "50m"
            limits:
              memory: "128Mi"
              cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-toolsapps
  namespace: default
spec:
  selector:
    app: frontend-toolsapps
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
      name: http
EOF
echo "   ✅ Deployment et Service créés dans 'default'"

# 4. Attendre que les pods soient prêts
echo ""
echo "4️⃣  Attente des pods..."
kubectl rollout status deployment frontend-toolsapps -n default --timeout=60s
kubectl get pods -n default -l app=frontend-toolsapps
echo ""

# 5. Créer l'Ingress avec TLS (comme l'API)
echo "5️⃣  Création de l'Ingress avec TLS..."
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: front-toolsapps
  namespace: default
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-staging
spec:
  ingressClassName: traefik
  tls:
    - hosts:
        - front.toolsapps.eu
      secretName: le-cert-front-toolsapps
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
echo "   ✅ Ingress créé"
sleep 5

# 6. Vérifier l'Ingress
echo ""
echo "6️⃣  Vérification de l'Ingress..."
kubectl get ingress -n default front-toolsapps
echo ""

# 7. Test HTTP
echo "7️⃣  Test HTTP..."
for i in {1..10}; do
    HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://front.toolsapps.eu 2>/dev/null)
    echo "   Tentative $i: HTTP = $HTTP"
    if [ "$HTTP" == "200" ]; then
        echo "   ✅ HTTP fonctionne!"
        break
    fi
    sleep 3
done

# 8. Test HTTPS
echo ""
echo "8️⃣  Test HTTPS (avec certificat staging)..."
HTTPS_K=$(curl -s -o /dev/null -w "%{http_code}" -k https://front.toolsapps.eu 2>/dev/null)
echo "   HTTPS (ignore cert): $HTTPS_K"

# 9. Vérifier le certificat
echo ""
echo "9️⃣  État du certificat..."
kubectl get certificate -n default le-cert-front-toolsapps 2>/dev/null || echo "   Certificate pas encore créé"

echo ""
echo "============================================"
if [ "$HTTP" == "200" ]; then
    echo "🎉 SUCCÈS! FRONTEND MIGRÉ!"
    echo ""
    echo "✅ http://front.toolsapps.eu → $HTTP"
    echo "✅ https://front.toolsapps.eu (staging) → $HTTPS_K"
    echo ""
    echo "📝 Note: Le certificat est en STAGING (rate limit)"
    echo "   Le 2 janvier 2026 après 22:54 UTC:"
    echo "   Changez 'letsencrypt-staging' → 'letsencrypt-prod'"
    echo ""
    if [ "$HTTPS_K" == "200" ]; then
        echo "   Contenu:"
        curl -s -k https://front.toolsapps.eu 2>/dev/null | head -5
    fi
else
    echo "❌ Problème persistant"
    echo "   HTTP: $HTTP"
    echo ""
    echo "   Vérifier les pods:"
    kubectl get pods -n default -l app=frontend-toolsapps
    echo ""
    echo "   Logs Traefik:"
    TRAEFIK_POD=$(kubectl get pods -n traefik -o jsonpath='{.items[0].metadata.name}')
    kubectl logs -n traefik $TRAEFIK_POD --tail=10 | grep -i "front"
fi
echo "============================================"

