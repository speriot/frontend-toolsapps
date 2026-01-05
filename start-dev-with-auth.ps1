# Script pour démarrer l'environnement de développement local avec authentification

Write-Host "🚀 Démarrage de l'environnement de développement ToolsApps" -ForegroundColor Cyan
Write-Host ""

# Vérifier si Node.js est installé
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Node.js n'est pas installé. Installez-le depuis https://nodejs.org/" -ForegroundColor Red
    exit 1
}

# Vérifier si les dépendances frontend sont installées
if (-not (Test-Path "node_modules")) {
    Write-Host "📦 Installation des dépendances frontend..." -ForegroundColor Yellow
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Erreur lors de l'installation des dépendances frontend" -ForegroundColor Red
        exit 1
    }
}

# Vérifier si les dépendances backend sont installées
if (-not (Test-Path "backend-auth\node_modules")) {
    Write-Host "📦 Installation des dépendances backend..." -ForegroundColor Yellow
    Push-Location backend-auth
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Erreur lors de l'installation des dépendances backend" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    Pop-Location
}

# Vérifier si le fichier users-dev.json existe
if (-not (Test-Path "backend-auth\users-dev.json")) {
    Write-Host "📝 Création du fichier users-dev.json..." -ForegroundColor Yellow
    Copy-Item "backend-auth\users-dev.example.json" "backend-auth\users-dev.json"
    Write-Host "✅ Fichier users-dev.json créé avec l'utilisateur par défaut" -ForegroundColor Green
    Write-Host "   Email: admin@toolsapps.eu" -ForegroundColor Cyan
    Write-Host "   Mot de passe: admin123" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "✅ Environnement prêt !" -ForegroundColor Green
Write-Host ""
Write-Host "🔐 Identifiants de test:" -ForegroundColor Cyan
Write-Host "   Email: admin@toolsapps.eu" -ForegroundColor White
Write-Host "   Mot de passe: admin123" -ForegroundColor White
Write-Host ""
Write-Host "🌐 URLs:" -ForegroundColor Cyan
Write-Host "   Frontend: http://localhost:5173" -ForegroundColor White
Write-Host "   Backend API: http://localhost:3002" -ForegroundColor White
Write-Host ""
Write-Host "📝 Démarrage des serveurs..." -ForegroundColor Yellow
Write-Host ""

# Fonction pour démarrer un processus en arrière-plan
function Start-BackgroundProcess {
    param(
        [string]$Name,
        [string]$Command,
        [string]$Arguments,
        [string]$WorkingDirectory = $PWD
    )
    
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = $Command
    $processInfo.Arguments = $Arguments
    $processInfo.WorkingDirectory = $WorkingDirectory
    $processInfo.UseShellExecute = $false
    $processInfo.CreateNoWindow = $false
    
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $processInfo
    $process.Start() | Out-Null
    
    return $process
}

# Démarrer le backend en arrière-plan
Write-Host "🔧 Démarrage du backend API..." -ForegroundColor Yellow
$env:PORT = "3002"
$env:JWT_SECRET = "dev-secret-key-change-in-production"
$env:USERS_FILE = ".\users-dev.json"

$backendDir = Join-Path $PSScriptRoot "backend-auth"
$backendProcess = Start-Process -FilePath "npm" -ArgumentList "start" -WorkingDirectory $backendDir -PassThru

Start-Sleep -Seconds 3

# Vérifier si le backend a démarré
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3002/frontend-auth/health" -TimeoutSec 5 -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Backend API démarré avec succès sur http://localhost:3002" -ForegroundColor Green
    }
}
catch {
    Write-Host "⚠️  Le backend API n'a pas pu être vérifié. Vérifiez les logs..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎨 Démarrage du frontend..." -ForegroundColor Yellow

# Démarrer le frontend (en avant-plan)
npm run dev

# Cleanup: arrêter le backend quand le frontend est arrêté
Write-Host ""
Write-Host "🛑 Arrêt du backend API..." -ForegroundColor Yellow
Stop-Process -Id $backendProcess.Id -Force -ErrorAction SilentlyContinue
Write-Host "✅ Backend arrêté" -ForegroundColor Green
