#!/usr/bin/env pwsh
# Script pour synchroniser la version entre package.json et values-prod.yaml

param(
    [string]$NewVersion
)

function Update-Version {
    param([string]$Version)
    
    # Mise à jour de package.json
    $packageJson = Get-Content -Raw -Path "package.json" | ConvertFrom-Json
    $packageJson.version = $Version
    $packageJson | ConvertTo-Json -Depth 10 | Set-Content -Path "package.json"
    
    # Mise à jour de values-prod.yaml
    $valuesContent = Get-Content -Path "helm/frontend-toolsapps/values-prod.yaml" -Raw
    $valuesContent = $valuesContent -replace 'tag:\s*"v[\d.]+"', "tag: `"v$Version`""
    $valuesContent | Set-Content -Path "helm/frontend-toolsapps/values-prod.yaml"
    
    Write-Host "✅ Version mise à jour: v$Version" -ForegroundColor Green
    Write-Host "   - package.json: $Version" -ForegroundColor Cyan
    Write-Host "   - values-prod.yaml: v$Version" -ForegroundColor Cyan
}

if ($NewVersion) {
    Update-Version -Version $NewVersion
} else {
    # Afficher la version actuelle
    $packageJson = Get-Content -Raw -Path "package.json" | ConvertFrom-Json
    $packageVersion = $packageJson.version
    
    $valuesContent = Get-Content -Path "helm/frontend-toolsapps/values-prod.yaml" -Raw
    if ($valuesContent -match 'tag:\s*"(v[\d.]+)"') {
        $helmVersion = $matches[1]
    }
    
    Write-Host "📦 Versions actuelles:" -ForegroundColor Yellow
    Write-Host "   package.json: $packageVersion" -ForegroundColor White
    Write-Host "   values-prod.yaml: $helmVersion" -ForegroundColor White
    
    if ("v$packageVersion" -eq $helmVersion) {
        Write-Host "✅ Les versions sont synchronisées" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Les versions ne sont PAS synchronisées!" -ForegroundColor Red
        Write-Host "`nPour synchroniser, exécutez:" -ForegroundColor Yellow
        Write-Host "   .\sync-version.ps1 -NewVersion $packageVersion" -ForegroundColor White
    }
}
