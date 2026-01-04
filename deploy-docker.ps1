# Script de déploiement Docker pour Frontend ToolsApps
# Usage: .\deploy-docker.ps1 [-NewVersion 1.2.0] [-AutoDeploy] [-SkipBuild] [-SkipPush]

param(
    [string]$NewVersion,
    [switch]$SkipBuild,
    [switch]$SkipPush,
    [switch]$AutoDeploy
)

# Configuration
$DOCKER_REGISTRY = "docker.io"
$DOCKER_USERNAME = "st3ph31"
$IMAGE_NAME = "frontend-toolsapps"
$VPS_HOST = "srv1172005.hstgr.cloud"
$VPS_USER = "root"

function Show-Usage {
    Write-Host @"
🚀 Script de déploiement ToolsApps

Usage:
  .\deploy-docker.ps1                          # Déploiement interactif
  .\deploy-docker.ps1 -NewVersion 1.2.0        # Déployer version 1.2.0
  .\deploy-docker.ps1 -SkipBuild               # Sauter le build npm
  .\deploy-docker.ps1 -SkipPush                # Ne pas push sur Docker Hub
  .\deploy-docker.ps1 -AutoDeploy              # Déployer automatiquement sur VPS

Exemples:
  .\deploy-docker.ps1 -NewVersion 1.3.0 -AutoDeploy
"@ -ForegroundColor Cyan
}

# Fonction pour lire la version actuelle
function Get-CurrentVersion {
    $packageJson = Get-Content -Raw -Path "package.json" | ConvertFrom-Json
    return $packageJson.version
}

# Si pas de version fournie, demander
if (-not $NewVersion) {
    $currentVersion = Get-CurrentVersion
    Write-Host "📦 Version actuelle: $currentVersion" -ForegroundColor Yellow
    $NewVersion = Read-Host "Nouvelle version (ex: 1.2.0)"
    
    if (-not $NewVersion) {
        Write-Host "❌ Version requise" -ForegroundColor Red
        exit 1
    }
}

$fullImageName = "$DOCKER_REGISTRY/$DOCKER_USERNAME/${IMAGE_NAME}"

Write-Host "`n🚀 Déploiement de la version $NewVersion" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan

# Vérifier que Docker est en cours d'exécution
Write-Host "`n[1/6] 🐳 Vérification de Docker..." -ForegroundColor Yellow
try {
    docker version | Out-Null
    Write-Host "✅ Docker est opérationnel" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur: Docker n'est pas démarré" -ForegroundColor Red
    exit 1
}

# Synchroniser la version
Write-Host "`n[2/6] 🔄 Synchronisation de la version..." -ForegroundColor Yellow
.\sync-version.ps1 -NewVersion $NewVersion
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors de la synchronisation de version" -ForegroundColor Red
    exit 1
}

# Build npm
if (-not $SkipBuild) {
    Write-Host "`n[3/6] 🔨 Build de l'application (npm run build)..." -ForegroundColor Yellow
    npm run build
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Erreur lors du build npm" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Build npm réussi" -ForegroundColor Green
} else {
    Write-Host "`n[3/6] ⏭️  Build npm ignoré" -ForegroundColor Gray
}

# Build Docker
Write-Host "`n[4/6] 🐳 Build de l'image Docker..." -ForegroundColor Yellow
docker build `
    --build-arg APP_VERSION=$NewVersion `
    -t ${fullImageName}:v$NewVersion `
    -t ${fullImageName}:latest `
    .

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors du build Docker" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Image Docker construite: ${fullImageName}:v$NewVersion" -ForegroundColor Green

# Push vers Docker Hub
if (-not $SkipPush) {
    Write-Host "`n[5/6] 📤 Push vers Docker Hub..." -ForegroundColor Yellow
    
    docker push ${fullImageName}:v$NewVersion
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Erreur lors du push de v$NewVersion" -ForegroundColor Red
        exit 1
    }
    
    docker push ${fullImageName}:latest
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Erreur lors du push de latest" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ Images pushées sur Docker Hub" -ForegroundColor Green
    Write-Host "   🔗 https://hub.docker.com/r/$DOCKER_USERNAME/$IMAGE_NAME" -ForegroundColor Cyan
} else {
    Write-Host "`n[5/6] ⏭️  Push Docker Hub ignoré" -ForegroundColor Gray
}

# Commit Git
Write-Host "`n[6/6] 📝 Commit Git..." -ForegroundColor Yellow
git add package.json helm/frontend-toolsapps/values-prod.yaml
git commit -m "Deploy v$NewVersion to production"
git push origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Changements committés et pushés" -ForegroundColor Green
} else {
    Write-Host "⚠️  Aucun changement à committer (ou erreur git)" -ForegroundColor Yellow
}

# Déploiement sur VPS
Write-Host "`n🚢 Déploiement sur Kubernetes..." -ForegroundColor Yellow

if ($AutoDeploy) {
    Write-Host "Déploiement automatique sur $VPS_HOST..." -ForegroundColor Cyan
    
    $sshCommand = @"
cd ~/frontend-toolsapps && \
git pull origin main && \
helm upgrade frontend-toolsapps ./helm/frontend-toolsapps \
  --namespace production \
  --values ./helm/frontend-toolsapps/values-prod.yaml \
  --set image.tag=v$NewVersion \
  --wait && \
kubectl get pods -n production -l app.kubernetes.io/name=frontend-toolsapps
"@
    
    ssh "${VPS_USER}@${VPS_HOST}" $sshCommand
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Déploiement réussi!" -ForegroundColor Green
    } else {
        Write-Host "❌ Erreur lors du déploiement" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host @"

📝 Pour déployer sur le VPS, exécutez:

ssh ${VPS_USER}@${VPS_HOST}
cd ~/frontend-toolsapps && git pull
helm upgrade frontend-toolsapps ./helm/frontend-toolsapps \
  --namespace production \
  --values ./helm/frontend-toolsapps/values-prod.yaml \
  --set image.tag=v$NewVersion \
  --wait

"@ -ForegroundColor White
}

Write-Host "`n═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🎉 Déploiement de v$NewVersion terminé!" -ForegroundColor Green
Write-Host "🌐 URL: https://front.toolsapps.eu/" -ForegroundColor Cyan
