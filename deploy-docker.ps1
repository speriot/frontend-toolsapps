# Script de déploiement Docker pour Frontend ToolsApps
# Usage: .\deploy-docker.ps1 [registry] [tag]

param(
    [string]$Registry = "docker.io/votreusername",
    [string]$Tag = "latest"
)

$ImageName = "frontend-toolsapps"
$FullImageName = "$Registry/$ImageName" + ":" + "$Tag"

Write-Host "🚀 Déploiement de Frontend ToolsApps" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier que Docker est en cours d'exécution
Write-Host "1️⃣  Vérification de Docker..." -ForegroundColor Yellow
try {
    docker version | Out-Null
    Write-Host "   ✅ Docker est opérationnel" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Erreur: Docker n'est pas démarré" -ForegroundColor Red
    exit 1
}

# Build de l'application
Write-Host ""
Write-Host "2️⃣  Build de l'application..." -ForegroundColor Yellow
npm run build
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ❌ Erreur lors du build npm" -ForegroundColor Red
    exit 1
}
Write-Host "   ✅ Build npm réussi" -ForegroundColor Green

# Build de l'image Docker
Write-Host ""
Write-Host "3️⃣  Build de l'image Docker..." -ForegroundColor Yellow
$LocalImageTag = "${ImageName}:${Tag}"
docker build -t $LocalImageTag .
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ❌ Erreur lors du build Docker" -ForegroundColor Red
    exit 1
}
Write-Host "   ✅ Image Docker créée: $LocalImageTag" -ForegroundColor Green

# Test local (optionnel)
Write-Host ""
Write-Host "4️⃣  Test local de l'image..." -ForegroundColor Yellow
$TestContainer = "frontend-test-temp"

# Arrêter et supprimer le conteneur s'il existe
docker stop $TestContainer 2>$null | Out-Null
docker rm $TestContainer 2>$null | Out-Null

# Lancer le conteneur de test
docker run -d -p 8888:80 --name $TestContainer $LocalImageTag
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ❌ Erreur lors du lancement du conteneur de test" -ForegroundColor Red
    exit 1
}

Start-Sleep -Seconds 2

# Tester l'accès HTTP
try {
    $Response = Invoke-WebRequest -Uri "http://localhost:8888" -UseBasicParsing -TimeoutSec 5
    if ($Response.StatusCode -eq 200) {
        Write-Host "   ✅ Test local réussi (HTTP 200)" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Test local retourne HTTP $($Response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ❌ Erreur lors du test HTTP: $_" -ForegroundColor Red
    docker stop $TestContainer | Out-Null
    docker rm $TestContainer | Out-Null
    exit 1
}

# Nettoyage du conteneur de test
docker stop $TestContainer | Out-Null
docker rm $TestContainer | Out-Null

# Tag pour le registry
Write-Host ""
Write-Host "5️⃣  Tag de l'image pour le registry..." -ForegroundColor Yellow
docker tag $LocalImageTag $FullImageName
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ❌ Erreur lors du tag" -ForegroundColor Red
    exit 1
}
Write-Host "   ✅ Image taguée: $FullImageName" -ForegroundColor Green

# Push vers le registry
Write-Host ""
Write-Host "6️⃣  Push vers le registry..." -ForegroundColor Yellow
Write-Host "   Registry: $FullImageName" -ForegroundColor Cyan

$Confirmation = Read-Host "   Voulez-vous pusher l'image vers le registry? (o/N)"
if ($Confirmation -eq "o" -or $Confirmation -eq "O") {
    docker push $FullImageName
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   ❌ Erreur lors du push" -ForegroundColor Red
        exit 1
    }
    Write-Host "   ✅ Image pushée avec succès!" -ForegroundColor Green
} else {
    Write-Host "   ⏭️  Push annulé" -ForegroundColor Yellow
}

# Résumé
Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "✅ Déploiement terminé!" -ForegroundColor Green
Write-Host ""
Write-Host "📦 Image locale : $LocalImageTag" -ForegroundColor White
Write-Host "📦 Image registry : $FullImageName" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Commandes pour déployer sur le serveur:" -ForegroundColor Cyan
Write-Host "   docker pull $FullImageName" -ForegroundColor White
Write-Host "   docker stop frontend-toolsapps || true" -ForegroundColor White
Write-Host "   docker rm frontend-toolsapps || true" -ForegroundColor White
Write-Host "   docker run -d -p 80:80 --name frontend-toolsapps --restart unless-stopped $FullImageName" -ForegroundColor White
Write-Host ""

