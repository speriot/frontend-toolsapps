#!/usr/bin/env pwsh
# Script pour construire l'image Docker avec la version depuis package.json

# Lire la version depuis package.json
$packageJson = Get-Content -Raw -Path "package.json" | ConvertFrom-Json
$version = $packageJson.version

Write-Host "🔨 Construction de l'image Docker avec version: v$version" -ForegroundColor Cyan

# Construire l'image Docker avec la version comme argument
docker build `
  --build-arg APP_VERSION=$version `
  -t frontend-toolsapps:v$version `
  -t frontend-toolsapps:latest `
  .

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Image construite avec succès: frontend-toolsapps:v$version" -ForegroundColor Green
    
    Write-Host "`n📝 Pour mettre à jour Helm, exécutez:" -ForegroundColor Yellow
    Write-Host "   helm upgrade frontend-toolsapps ./helm/frontend-toolsapps -f ./helm/frontend-toolsapps/values-prod.yaml --set image.tag=v$version" -ForegroundColor White
} else {
    Write-Host "❌ Erreur lors de la construction de l'image" -ForegroundColor Red
    exit 1
}
