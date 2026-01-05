# PowerShell Script pour créer et gérer les secrets utilisateurs dans Kubernetes

param(
    [string]$Namespace = "default"
)

Write-Host "🔐 Création des secrets utilisateurs pour ToolsApps" -ForegroundColor Cyan
Write-Host "📦 Namespace: $Namespace" -ForegroundColor Cyan
Write-Host ""

# Fonction pour générer un hash de mot de passe
function Generate-PasswordHash {
    param([string]$Password)
    
    $scriptPath = Join-Path $PSScriptRoot "..\backend-auth\generate-hash.js"
    $hash = node $scriptPath $Password 2>&1 | Select-String "Hash:" | ForEach-Object { $_.ToString().Split(":")[1].Trim() }
    return $hash
}

# Demander les informations pour l'utilisateur admin
$adminEmail = Read-Host "Email admin (défaut: admin@toolsapps.eu)"
if ([string]::IsNullOrWhiteSpace($adminEmail)) {
    $adminEmail = "admin@toolsapps.eu"
}

$adminPassword = Read-Host "Mot de passe admin (défaut: admin123)" -AsSecureString
if ($adminPassword.Length -eq 0) {
    $adminPasswordPlain = "admin123"
} else {
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($adminPassword)
    $adminPasswordPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
}

$adminName = Read-Host "Nom admin (défaut: Admin)"
if ([string]::IsNullOrWhiteSpace($adminName)) {
    $adminName = "Admin"
}

Write-Host ""
Write-Host "🔄 Génération du hash de mot de passe..." -ForegroundColor Yellow

# Générer le hash du mot de passe
$adminHash = Generate-PasswordHash -Password $adminPasswordPlain

if ([string]::IsNullOrWhiteSpace($adminHash)) {
    Write-Host "❌ Erreur lors de la génération du hash" -ForegroundColor Red
    exit 1
}

# Créer le fichier JSON
$users = @(
    @{
        email = $adminEmail
        passwordHash = $adminHash
        name = $adminName
        role = "admin"
    }
)

$usersJson = $users | ConvertTo-Json
$usersJson | Out-File -FilePath "users.json" -Encoding UTF8

Write-Host "✅ Fichier users.json créé" -ForegroundColor Green
Write-Host ""

# Créer le secret Kubernetes
Write-Host "🚀 Création du secret Kubernetes..." -ForegroundColor Cyan

try {
    kubectl create secret generic auth-users `
        --from-file=users.json=users.json `
        --namespace=$Namespace `
        --dry-run=client -o yaml | kubectl apply -f -
    
    Write-Host "✅ Secret 'auth-users' créé/mis à jour dans le namespace '$Namespace'" -ForegroundColor Green
}
catch {
    Write-Host "❌ Erreur lors de la création du secret: $_" -ForegroundColor Red
    exit 1
}

# Créer le secret JWT
Write-Host "🔄 Génération du secret JWT..." -ForegroundColor Yellow
$jwtSecret = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object {[char]$_})

try {
    kubectl create secret generic auth-jwt `
        --from-literal=jwt-secret="$jwtSecret" `
        --namespace=$Namespace `
        --dry-run=client -o yaml | kubectl apply -f -
    
    Write-Host "✅ Secret 'auth-jwt' créé/mis à jour dans le namespace '$Namespace'" -ForegroundColor Green
}
catch {
    Write-Host "❌ Erreur lors de la création du secret JWT: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 Configuration terminée !" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Informations de connexion:" -ForegroundColor Cyan
Write-Host "   Email: $adminEmail"
Write-Host "   Mot de passe: $adminPasswordPlain"
Write-Host ""
Write-Host "⚠️  N'oubliez pas de supprimer le fichier users.json après vérification:" -ForegroundColor Yellow
Write-Host "   Remove-Item users.json"
Write-Host ""
Write-Host "📦 Secrets créés:" -ForegroundColor Cyan
Write-Host "   - auth-users (contient users.json)"
Write-Host "   - auth-jwt (contient le secret JWT)"
