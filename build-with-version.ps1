#!/usr/bin/env pwsh
# Script pour construire l'image Docker avec la version depuis package.json

# Configuration
$DOCKER_REGISTRY = "docker.io"
$DOCKER_USERNAME = "st3ph31"
$IMAGE_NAME = "frontend-toolsapps"

# Lire la version depuis package.json
$packageJson = Get-Content -Raw -Path "package.json" | ConvertFrom-Json
$version = $packageJson.version

$fullImageName = "$DOCKER_REGISTRY/$DOCKER_USERNAME/${IMAGE_NAME}"

Write-Host "🔨 Construction de l'image Docker avec version: v$version" -ForegroundColor Cyan

# Construire l'image Docker avec la version comme argument
docker build `
  --build-arg APP_VERSION=$version `
  -t ${fullImageName}:v$version `
  -t ${fullImageName}:latest `
  .

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Image construite avec succès: ${fullImageName}:v$version" -ForegroundColor Green
    
    Write-Host "`n📦 Prêt à push vers Docker Hub :" -ForegroundColor Yellow
    Write-Host "   docker push ${fullImageName}:v$version" -ForegroundColor White
    Write-Host "   docker push ${fullImageName}:latest" -ForegroundColor White
    
    Write-Host "`n📝 Puis pour déployer sur Kubernetes:" -ForegroundColor Yellow
    Write-Host "   helm upgrade frontend-toolsapps ./helm/frontend-toolsapps -f ./helm/frontend-toolsapps/values-prod.yaml --set image.tag=v$version" -ForegroundColor White
} else {
    Write-Host "❌ Erreur lors de la construction de l'image" -ForegroundColor Red
    exit 1
}
