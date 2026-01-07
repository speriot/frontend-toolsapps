# Script PowerShell de déploiement automatisé du MQTT-SSE Bridge
# Usage: .\deploy-mqtt-sse.ps1 [-Environment dev|prod]

param(
    [Parameter()]
    [ValidateSet('dev', 'prod')]
    [string]$Environment = 'prod'
)

$ErrorActionPreference = "Stop"

$VERSION = "v1.0.0"
$NAMESPACE = "default"
$DOCKER_REGISTRY = "st3ph31"
$IMAGE_NAME = "mqtt-sse-bridge"
$CHART_PATH = "."

Write-Host "🚀 Déploiement MQTT-SSE Bridge - Environnement: $Environment" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Fonction pour afficher les erreurs
function Write-Error-Custom {
    param([string]$Message)
    Write-Host "❌ Erreur: $Message" -ForegroundColor Red
    exit 1
}

# Fonction pour afficher les succès
function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

# Fonction pour afficher les infos
function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Yellow
}

# Vérifier les prérequis
Write-Info "Vérification des prérequis..."

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error-Custom "Docker n'est pas installé"
}
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Error-Custom "kubectl n'est pas installé"
}
if (-not (Get-Command helm -ErrorAction SilentlyContinue)) {
    Write-Error-Custom "Helm n'est pas installé"
}

Write-Success "Tous les prérequis sont présents"

# Demander confirmation pour la production
if ($Environment -eq 'prod') {
    $confirmation = Read-Host "⚠️  Déploiement en PRODUCTION. Continuer? (y/N)"
    if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
        Write-Error-Custom "Déploiement annulé"
    }
}

# Étape 1: Build de l'image Docker
Write-Info "Étape 1/6: Build de l'image Docker..."
Set-Location -Path "..\..\backend-mqtt"
docker build -t "$DOCKER_REGISTRY/$IMAGE_NAME:$VERSION" .
if ($LASTEXITCODE -ne 0) { Write-Error-Custom "Build Docker échoué" }
Write-Success "Image Docker buildée: $DOCKER_REGISTRY/$IMAGE_NAME:$VERSION"

# Étape 2: Push de l'image
Write-Info "Étape 2/6: Push de l'image Docker..."
docker push "$DOCKER_REGISTRY/$IMAGE_NAME:$VERSION"
if ($LASTEXITCODE -ne 0) { Write-Error-Custom "Push Docker échoué" }
Write-Success "Image pushée sur Docker Hub"

# Revenir au dossier helm
Set-Location -Path "..\..\helm\mqtt-sse-bridge"

# Étape 3: Vérifier/Créer le secret MQTT
Write-Info "Étape 3/6: Vérification du secret MQTT..."
$secretExists = kubectl get secret mqtt-credentials -n $NAMESPACE 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Success "Secret MQTT existe déjà"
} else {
    Write-Info "Création du secret MQTT..."
    $mqtt_username = Read-Host "Username MQTT"
    $mqtt_password = Read-Host "Password MQTT" -AsSecureString
    $mqtt_password_plain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($mqtt_password)
    )
    
    kubectl create secret generic mqtt-credentials `
        --from-literal=username="$mqtt_username" `
        --from-literal=password="$mqtt_password_plain" `
        -n $NAMESPACE
    
    if ($LASTEXITCODE -ne 0) { Write-Error-Custom "Création du secret échouée" }
    Write-Success "Secret MQTT créé"
}

# Étape 4: Lint du chart Helm
Write-Info "Étape 4/6: Validation du chart Helm..."
helm lint .
if ($LASTEXITCODE -ne 0) { Write-Error-Custom "Validation Helm échouée" }
Write-Success "Chart Helm valide"

# Étape 5: Installation/Upgrade Helm
Write-Info "Étape 5/6: Déploiement Helm..."

$VALUES_FILE = "values.yaml"
if ($Environment -eq 'prod') {
    $VALUES_FILE = "values-prod.yaml"
}

$releaseExists = helm status mqtt-sse-bridge -n $NAMESPACE 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Info "Mise à jour de la release existante..."
    helm upgrade mqtt-sse-bridge . `
        -f $VALUES_FILE `
        --set image.tag=$VERSION `
        --namespace $NAMESPACE `
        --wait `
        --timeout 5m
    if ($LASTEXITCODE -ne 0) { Write-Error-Custom "Upgrade Helm échoué" }
    Write-Success "Release mise à jour avec succès"
} else {
    Write-Info "Installation de la nouvelle release..."
    helm install mqtt-sse-bridge . `
        -f $VALUES_FILE `
        --namespace $NAMESPACE `
        --wait `
        --timeout 5m
    if ($LASTEXITCODE -ne 0) { Write-Error-Custom "Installation Helm échouée" }
    Write-Success "Release installée avec succès"
}

# Étape 6: Vérifications post-déploiement
Write-Info "Étape 6/6: Vérifications post-déploiement..."

Write-Host ""
Write-Info "Attente du démarrage des pods (30s)..."
Start-Sleep -Seconds 30

# Vérifier les pods
Write-Host ""
Write-Info "Status des pods:"
kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=mqtt-sse-bridge

# Vérifier le service
Write-Host ""
Write-Info "Service:"
kubectl get svc -n $NAMESPACE mqtt-sse-bridge

# Vérifier l'ingress
Write-Host ""
Write-Info "Ingress:"
kubectl get ingress -n $NAMESPACE mqtt-sse-bridge

# Afficher les logs récents
Write-Host ""
Write-Info "Logs récents (10 dernières lignes):"
kubectl logs -n $NAMESPACE -l app.kubernetes.io/name=mqtt-sse-bridge --tail=10

Write-Host ""
Write-Success "================================================"
Write-Success "🎉 Déploiement terminé avec succès!"
Write-Success "================================================"

Write-Host ""
Write-Info "📋 Informations utiles:"
Write-Host ""
Write-Host "  • Voir les logs en temps réel:"
Write-Host "    kubectl logs -n $NAMESPACE -l app.kubernetes.io/name=mqtt-sse-bridge -f"
Write-Host ""
Write-Host "  • Vérifier le status:"
Write-Host "    helm status mqtt-sse-bridge -n $NAMESPACE"
Write-Host ""
Write-Host "  • Port-forward pour tester localement:"
Write-Host "    kubectl port-forward -n $NAMESPACE svc/mqtt-sse-bridge 3003:3003"
Write-Host "    curl -N http://localhost:3003/api/portal/events"
Write-Host ""
Write-Host "  • Rollback en cas de problème:"
Write-Host "    helm rollback mqtt-sse-bridge -n $NAMESPACE"
Write-Host ""

if ($Environment -eq 'prod') {
    Write-Info "🌐 URL de production: https://api.toolsapps.eu/api/portal/events"
}

Write-Host ""
Write-Success "✨ Déploiement complet!"
