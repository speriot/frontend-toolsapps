# Script PowerShell de déploiement du backend MQTT-SSE en production

$ErrorActionPreference = "Stop"

Write-Host "🚀 Déploiement du backend MQTT-SSE en production" -ForegroundColor Cyan
Write-Host ""

$NAMESPACE = "production"
$RELEASE_NAME = "mqtt-sse-bridge"
$CHART_PATH = "./helm/mqtt-sse-bridge"
$VALUES_FILE = "values-prod.yaml"
$VPS_IP = "72.62.16.206"

# 1. Copier les fichiers sur le VPS
Write-Host "📤 Upload des fichiers Helm sur le VPS..." -ForegroundColor Yellow
ssh root@$VPS_IP "mkdir -p ~/mqtt-sse-bridge"
scp -r ./helm/mqtt-sse-bridge/* root@${VPS_IP}:~/mqtt-sse-bridge/

# 2. Créer le secret et déployer
Write-Host "🔐 Création du secret et déploiement..." -ForegroundColor Yellow
$deployScript = @'
cd ~/mqtt-sse-bridge

# Créer le namespace si nécessaire
kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -

# Créer le secret MQTT
kubectl get secret mqtt-credentials -n production &>/dev/null || \
kubectl create secret generic mqtt-credentials \
  --from-literal=host='wss://3d3f4f89176c45f38dab27f19cc275b4.s1.eu.hivemq.cloud:8884/mqtt' \
  --from-literal=username='portal569' \
  --from-literal=password='FMBUUX288547bbxiio' \
  --namespace production

echo "✅ Secret créé"

# Déployer avec Helm
helm upgrade --install mqtt-sse-bridge . \
  --namespace production \
  --values values-prod.yaml \
  --wait \
  --timeout 5m

echo ""
echo "✅ Déploiement terminé !"
echo ""

# Vérification
kubectl get pods -n production -l app.kubernetes.io/name=mqtt-sse-bridge
kubectl get svc -n production -l app.kubernetes.io/name=mqtt-sse-bridge
kubectl get ingress -n production -l app.kubernetes.io/name=mqtt-sse-bridge
'@

ssh root@$VPS_IP $deployScript

Write-Host ""
Write-Host "✅ Backend MQTT-SSE déployé avec succès !" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 URL: https://api.toolsapps.eu/api/portal/events" -ForegroundColor Cyan
Write-Host ""
Write-Host "📝 Pour voir les logs:" -ForegroundColor Yellow
Write-Host "   ssh root@$VPS_IP" -ForegroundColor White
Write-Host "   kubectl logs -n production -l app.kubernetes.io/name=mqtt-sse-bridge -f" -ForegroundColor White
