# Script de vérification pré-déploiement
# Usage: .\verify-before-deploy.ps1

Write-Host "🔍 VÉRIFICATION PRÉ-DÉPLOIEMENT" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

$AllGood = $true

# 1. Vérifier Node.js
Write-Host "1️⃣  Node.js..." -NoNewline
try {
    $nodeVersion = node --version
    Write-Host " ✅ $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host " ❌ Non installé" -ForegroundColor Red
    $AllGood = $false
}

# 2. Vérifier npm
Write-Host "2️⃣  npm..." -NoNewline
try {
    $npmVersion = npm --version
    Write-Host " ✅ v$npmVersion" -ForegroundColor Green
} catch {
    Write-Host " ❌ Non installé" -ForegroundColor Red
    $AllGood = $false
}

# 3. Vérifier Docker
Write-Host "3️⃣  Docker..." -NoNewline
try {
    docker version | Out-Null
    $dockerVersion = docker --version
    Write-Host " ✅ $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host " ❌ Non démarré" -ForegroundColor Red
    $AllGood = $false
}

# 4. Vérifier Git
Write-Host "4️⃣  Git..." -NoNewline
try {
    $gitVersion = git --version
    Write-Host " ✅ $gitVersion" -ForegroundColor Green
} catch {
    Write-Host " ❌ Non installé" -ForegroundColor Red
    $AllGood = $false
}

# 5. Vérifier node_modules
Write-Host "5️⃣  node_modules..." -NoNewline
if (Test-Path "node_modules") {
    Write-Host " ✅ Présent" -ForegroundColor Green
} else {
    Write-Host " ⚠️  Manquant (lancer npm install)" -ForegroundColor Yellow
    $AllGood = $false
}

# 6. Vérifier package.json
Write-Host "6️⃣  package.json..." -NoNewline
if (Test-Path "package.json") {
    $packageJson = Get-Content "package.json" -Raw | ConvertFrom-Json
    Write-Host " ✅ Version $($packageJson.version)" -ForegroundColor Green
} else {
    Write-Host " ❌ Manquant" -ForegroundColor Red
    $AllGood = $false
}

# 7. Vérifier .env.local
Write-Host "7️⃣  .env.local..." -NoNewline
if (Test-Path ".env.local") {
    Write-Host " ✅ Présent" -ForegroundColor Green
} else {
    Write-Host " ⚠️  Manquant (copier depuis .env.example)" -ForegroundColor Yellow
}

# 8. Vérifier Dockerfile
Write-Host "8️⃣  Dockerfile..." -NoNewline
if (Test-Path "Dockerfile") {
    $dockerfile = Get-Content "Dockerfile" -Raw
    if ($dockerfile -match "FROM node:18-alpine AS builder") {
        Write-Host " ✅ Valide" -ForegroundColor Green
    } else {
        Write-Host " ⚠️  Format suspect" -ForegroundColor Yellow
    }
} else {
    Write-Host " ❌ Manquant" -ForegroundColor Red
    $AllGood = $false
}

# 9. Vérifier .dockerignore
Write-Host "9️⃣  .dockerignore..." -NoNewline
if (Test-Path ".dockerignore") {
    Write-Host " ✅ Présent" -ForegroundColor Green
} else {
    Write-Host " ⚠️  Manquant" -ForegroundColor Yellow
}

# 10. Vérifier .gitignore
Write-Host "🔟 .gitignore..." -NoNewline
if (Test-Path ".gitignore") {
    $gitignore = Get-Content ".gitignore" -Raw
    if ($gitignore -match ".env.local") {
        Write-Host " ✅ .env.local ignoré" -ForegroundColor Green
    } else {
        Write-Host " ⚠️  .env.local pas ignoré" -ForegroundColor Yellow
    }
} else {
    Write-Host " ❌ Manquant" -ForegroundColor Red
    $AllGood = $false
}

# 11. Test npm build
Write-Host ""
Write-Host "🔨 Test du build npm..." -ForegroundColor Yellow
try {
    npm run build | Out-Null
    if (Test-Path "dist/index.html") {
        Write-Host "   ✅ Build npm réussi" -ForegroundColor Green
    } else {
        Write-Host "   ❌ dist/index.html manquant" -ForegroundColor Red
        $AllGood = $false
    }
} catch {
    Write-Host "   ❌ Erreur lors du build" -ForegroundColor Red
    $AllGood = $false
}

# 12. Vérifier les versions des packages critiques
Write-Host ""
Write-Host "📦 Versions des packages:" -ForegroundColor Yellow
$packageJson = Get-Content "package.json" -Raw | ConvertFrom-Json

$criticalDeps = @{
    "react" = $packageJson.dependencies.react
    "react-dom" = $packageJson.dependencies."react-dom"
    "react-router-dom" = $packageJson.dependencies."react-router-dom"
}

$criticalDevDeps = @{
    "vite" = $packageJson.devDependencies.vite
    "tailwindcss" = $packageJson.devDependencies.tailwindcss
}

foreach ($dep in $criticalDeps.GetEnumerator()) {
    Write-Host "   $($dep.Key): $($dep.Value)" -ForegroundColor Cyan
}

foreach ($dep in $criticalDevDeps.GetEnumerator()) {
    if ($dep.Key -eq "tailwindcss" -and $dep.Value -match "^4\.") {
        Write-Host "   $($dep.Key): $($dep.Value) ⚠️  VERSION 4 DÉTECTÉE!" -ForegroundColor Red
        Write-Host "   → Downgrade recommandé vers v3.4.19" -ForegroundColor Yellow
        $AllGood = $false
    } else {
        Write-Host "   $($dep.Key): $($dep.Value)" -ForegroundColor Cyan
    }
}

# Résultat final
Write-Host ""
Write-Host "=================================" -ForegroundColor Cyan
if ($AllGood) {
    Write-Host "✅ TOUT EST PRÊT POUR LE DÉPLOIEMENT!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Vous pouvez maintenant:" -ForegroundColor White
    Write-Host "  1. Lancer: .\deploy-docker.ps1 -Registry 'votre-registry' -Tag 'v1.0.0'" -ForegroundColor Cyan
    Write-Host "  2. Ou consulter: GUIDE-DEPLOYMENT-COMPLET.md" -ForegroundColor Cyan
} else {
    Write-Host "⚠️  CORRECTIONS NÉCESSAIRES" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Veuillez corriger les erreurs ci-dessus avant de déployer." -ForegroundColor White
}
Write-Host ""

