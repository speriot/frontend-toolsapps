# Script PowerShell pour créer le secret MQTT Kubernetes
# Usage: .\create-mqtt-secret.ps1 [-Namespace default]

param(
    [Parameter()]
    [string]$Namespace = "default"
)

Write-Host "🔐 Création du secret MQTT pour Kubernetes" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier que kubectl est installé
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Erreur: kubectl n'est pas installé" -ForegroundColor Red
    exit 1
}

# Vérifier si le secret existe déjà
$secretExists = kubectl get secret mqtt-credentials -n $Namespace 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "⚠️  Le secret 'mqtt-credentials' existe déjà dans le namespace '$Namespace'" -ForegroundColor Yellow
    $overwrite = Read-Host "Voulez-vous le remplacer? (y/N)"
    if ($overwrite -ne 'y' -and $overwrite -ne 'Y') {
        Write-Host "❌ Opération annulée" -ForegroundColor Red
        exit 0
    }
    Write-Host "🗑️  Suppression de l'ancien secret..." -ForegroundColor Yellow
    kubectl delete secret mqtt-credentials -n $Namespace
}

# Demander les credentials
Write-Host "📝 Entrez les credentials MQTT:" -ForegroundColor Green
Write-Host ""

$username = Read-Host "Username MQTT (ex: portal569)"
if ([string]::IsNullOrWhiteSpace($username)) {
    Write-Host "❌ Le username ne peut pas être vide" -ForegroundColor Red
    exit 1
}

$password = Read-Host "Password MQTT" -AsSecureString
$password_plain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
)

if ([string]::IsNullOrWhiteSpace($password_plain)) {
    Write-Host "❌ Le password ne peut pas être vide" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🔨 Création du secret..." -ForegroundColor Yellow

# Créer le secret
kubectl create secret generic mqtt-credentials `
    --from-literal=username="$username" `
    --from-literal=password="$password_plain" `
    --namespace $Namespace

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors de la création du secret" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Secret créé avec succès!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Informations:" -ForegroundColor Cyan
Write-Host "  • Nom du secret: mqtt-credentials"
Write-Host "  • Namespace: $Namespace"
Write-Host "  • Username: $username"
Write-Host "  • Password: ********"
Write-Host ""
Write-Host "🔍 Vérification:" -ForegroundColor Yellow
kubectl get secret mqtt-credentials -n $Namespace

Write-Host ""
Write-Host "✨ Configuration terminée!" -ForegroundColor Green
Write-Host "Vous pouvez maintenant déployer l'application avec:" -ForegroundColor White
Write-Host "  .\deploy-mqtt-sse.ps1" -ForegroundColor Cyan
