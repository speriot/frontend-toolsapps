#!/bin/bash
# Commandes de déploiement de l'application Frontend ToolsApps
# À exécuter sur le VPS après la correction IPv6

echo "🚀 Déploiement de l'application Frontend ToolsApps"
echo "=================================================="
echo ""

# Vérifier qu'on est dans le bon dossier
if [ ! -d "helm/frontend-toolsapps" ]; then
  echo "❌ Erreur: Dossier helm/frontend-toolsapps non trouvé"
  echo "   Assurez-vous d'être dans le dossier frontend-toolsapps"
  exit 1
fi

echo "✅ Dossier helm trouvé"
echo ""

# Créer le namespace production (si pas déjà fait)
echo "📦 Création du namespace production..."
kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -
echo "✅ Namespace production prêt"
echo ""

# Vérifier l'image Docker
echo "🐳 Image Docker à déployer:"
echo "   docker.io/st3ph31/frontend-toolsapps:v1.0.0"
echo ""

# Déployer avec Helm
echo "🎯 Déploiement avec Helm..."
echo ""

helm install frontend-toolsapps helm/frontend-toolsapps \
  --namespace production \
  --values helm/frontend-toolsapps/values-prod.yaml \
  --set image.repository=docker.io/st3ph31/frontend-toolsapps \
  --set image.tag=v1.0.0

if [ $? -eq 0 ]; then
  echo ""
  echo "✅ Déploiement réussi!"
  echo ""

  # Attendre un peu
  echo "⏳ Attente du démarrage des pods (30 secondes)..."
  sleep 30

  # Vérifications
  echo ""
  echo "📊 État du déploiement:"
  echo ""

  echo "1️⃣  Pods:"
  kubectl get pods -n production
  echo ""

  echo "2️⃣  Services:"
  kubectl get svc -n production
  echo ""

  echo "3️⃣  Ingress:"
  kubectl get ingress -n production
  echo ""

  echo "4️⃣  HPA (Autoscaling):"
  kubectl get hpa -n production
  echo ""

  echo "5️⃣  Certificat SSL:"
  kubectl get certificate -n production
  echo ""

  echo "=================================================="
  echo "✅ Application déployée avec succès!"
  echo ""
  echo "📝 Prochaines étapes:"
  echo ""
  echo "1. Vérifier que les pods sont 'Running':"
  echo "   kubectl get pods -n production -w"
  echo ""
  echo "2. Vérifier l'ingress pour obtenir l'URL:"
  echo "   kubectl get ingress -n production"
  echo ""
  echo "3. Configurer le DNS (si pas déjà fait):"
  echo "   front.toolsapps.eu → [IPv4 du VPS]"
  echo ""
  echo "4. Attendre l'émission du certificat SSL (2-5 min):"
  echo "   kubectl get certificate -n production -w"
  echo ""
  echo "5. Tester l'accès:"
  echo "   curl http://front.toolsapps.eu"
  echo "   curl https://front.toolsapps.eu"
  echo ""
else
  echo ""
  echo "❌ Erreur lors du déploiement"
  echo ""
  echo "📝 Pour debugger:"
  echo "   helm list -n production"
  echo "   kubectl get events -n production --sort-by='.lastTimestamp'"
  echo ""
  exit 1
fi

