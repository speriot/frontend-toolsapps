# Script de mise à jour du frontend avec support MQTT-SSE

$ErrorActionPreference = "Stop"

Write-Host "🚀 Mise à jour du frontend avec MQTT-SSE" -ForegroundColor Cyan
Write-Host ""

$VERSION = "v1.0.2"
$IMAGE_NAME = "st3ph31/frontend-toolsapps:$VERSION"
$VPS_IP = "72.62.16.206"

# 1. Vérifier .env.production
Write-Host "🔍 Vérification de .env.production..." -ForegroundColor Yellow
if (Test-Path ".env.production") {
    Write-Host "✅ Fichier .env.production trouvé" -ForegroundColor Green
    Get-Content .env.production | Select-String "VITE_MQTT_SSE_URL"
} else {
    Write-Host "❌ Fichier .env.production manquant !" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 2. Build du frontend
Write-Host "🏗️  Build du frontend..." -ForegroundColor Yellow
npm run build
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors du build !" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Build terminé" -ForegroundColor Green
Write-Host ""

# 3. Build de l'image Docker
Write-Host "🐳 Build de l'image Docker $IMAGE_NAME..." -ForegroundColor Yellow
docker build -t $IMAGE_NAME .
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors du build Docker !" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Image Docker créée" -ForegroundColor Green
Write-Host ""

# 4. Push de l'image
Write-Host "📤 Push de l'image vers Docker Hub..." -ForegroundColor Yellow
docker push $IMAGE_NAME
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors du push !" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Image pushée" -ForegroundColor Green
Write-Host ""

# 5. Mise à jour sur le VPS
Write-Host "🔄 Mise à jour sur le VPS..." -ForegroundColor Yellow
$updateScript = @"
kubectl set image deployment/frontend-toolsapps frontend-toolsapps=$IMAGE_NAME -n production && \
kubectl rollout status deployment/frontend-toolsapps -n production --timeout=5m
"@

ssh root@$VPS_IP $updateScript
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors de la mise à jour !" -ForegroundColor Red
    exit 1
}
Write-Host ""

Write-Host "✅ Mise à jour réussie !" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Frontend mis à jour : https://front.toolsapps.eu" -ForegroundColor Cyan
Write-Host "📡 Backend MQTT-SSE : https://api.toolsapps.eu/api/portal/events" -ForegroundColor Cyan
Write-Host ""
Write-Host "🧪 Pour tester :" -ForegroundColor Yellow
Write-Host "   1. Ouvrir https://front.toolsapps.eu" -ForegroundColor White
Write-Host "   2. Se connecter (admin@toolsapps.eu / admin123)" -ForegroundColor White
Write-Host "   3. Aller sur la page Portal Dashboard" -ForegroundColor White
Write-Host "   4. Vérifier que les données MQTT s'affichent" -ForegroundColor White
