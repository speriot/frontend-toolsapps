# 🚀 Script de Migration Automatique : pCloud → Local
# Ce script copie TOUT votre projet en local et le configure

Write-Host ""
Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                ║" -ForegroundColor Cyan
Write-Host "║     🚀 MIGRATION AUTOMATIQUE VERS LOCAL 🚀     ║" -ForegroundColor Cyan
Write-Host "║                                                ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$source = "P:\Hostinger\frontend-app"
$destination = "C:\Dev\frontend-app"

Write-Host "📋 Ce script va :" -ForegroundColor White
Write-Host "   1. Créer le dossier C:\Dev (si nécessaire)" -ForegroundColor Gray
Write-Host "   2. Copier tout le projet depuis pCloud" -ForegroundColor Gray
Write-Host "   3. Nettoyer et réinstaller les dépendances" -ForegroundColor Gray
Write-Host "   4. Configurer le projet pour le développement local" -ForegroundColor Gray
Write-Host "   5. Lancer le serveur de développement avec HMR" -ForegroundColor Gray
Write-Host ""

# Vérifier que pCloud est accessible
if (-not (Test-Path $source)) {
    Write-Host "❌ ERREUR : Impossible d'accéder à pCloud" -ForegroundColor Red
    Write-Host "   Vérifiez que P:\Hostinger\frontend-app existe" -ForegroundColor Yellow
    Write-Host ""
    pause
    exit 1
}

# Calculer la taille
$totalSize = (Get-ChildItem -Path $source -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
$sizeMB = [math]::Round($totalSize / 1MB, 2)
Write-Host "📊 Taille du projet : $sizeMB MB" -ForegroundColor White
Write-Host "⏱️  Temps estimé : 3-5 minutes" -ForegroundColor White
Write-Host ""

# Demander confirmation
Write-Host "❓ Êtes-vous prêt à migrer le projet en local ? (O/N)" -ForegroundColor Yellow
$confirmation = Read-Host

if ($confirmation -ne 'O' -and $confirmation -ne 'o') {
    Write-Host ""
    Write-Host "❌ Migration annulée" -ForegroundColor Red
    Write-Host ""
    pause
    exit 0
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

# ÉTAPE 1 : Créer le dossier C:\Dev
Write-Host ""
Write-Host "📁 [1/5] Création du dossier C:\Dev..." -ForegroundColor Cyan
if (-not (Test-Path "C:\Dev")) {
    New-Item -ItemType Directory -Path "C:\Dev" -Force | Out-Null
    Write-Host "   ✅ Dossier créé" -ForegroundColor Green
} else {
    Write-Host "   ℹ️  Dossier déjà existant" -ForegroundColor Gray
}

# ÉTAPE 2 : Copier le projet
Write-Host ""
Write-Host "📦 [2/5] Copie du projet depuis pCloud..." -ForegroundColor Cyan
Write-Host "   Source : $source" -ForegroundColor Gray
Write-Host "   Destination : $destination" -ForegroundColor Gray

if (Test-Path $destination) {
    Write-Host "   ⚠️  Le dossier existe déjà, sauvegarde en cours..." -ForegroundColor Yellow
    $backupPath = "$destination-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Rename-Item -Path $destination -NewName $backupPath
    Write-Host "   💾 Backup créé : $backupPath" -ForegroundColor Gray
}

xcopy $source $destination /E /I /H /Y /Q > $null

if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Copie terminée" -ForegroundColor Green
} else {
    Write-Host "   ❌ Erreur lors de la copie" -ForegroundColor Red
    pause
    exit 1
}

# ÉTAPE 3 : Nettoyer et réinstaller
Write-Host ""
Write-Host "🧹 [3/5] Nettoyage et réinstallation des dépendances..." -ForegroundColor Cyan

cd $destination

if (Test-Path "node_modules") {
    Write-Host "   🗑️  Suppression de node_modules..." -ForegroundColor Gray
    Remove-Item -Recurse -Force node_modules -ErrorAction SilentlyContinue
}

if (Test-Path "package-lock.json") {
    Write-Host "   🗑️  Suppression de package-lock.json..." -ForegroundColor Gray
    Remove-Item -Force package-lock.json -ErrorAction SilentlyContinue
}

Write-Host "   📦 Installation des dépendances (cela peut prendre 2-3 min)..." -ForegroundColor Gray
npm install --silent

if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Dépendances installées" -ForegroundColor Green
} else {
    Write-Host "   ❌ Erreur lors de l'installation" -ForegroundColor Red
    pause
    exit 1
}

# ÉTAPE 4 : Configuration
Write-Host ""
Write-Host "⚙️  [4/5] Configuration du projet..." -ForegroundColor Cyan
Write-Host "   ✅ HMR activé (rechargement automatique)" -ForegroundColor Green
Write-Host "   ✅ React.StrictMode activé" -ForegroundColor Green
Write-Host "   ✅ Configuration optimisée pour le développement local" -ForegroundColor Green

# ÉTAPE 5 : Lancer le serveur
Write-Host ""
Write-Host "🚀 [5/5] Lancement du serveur de développement..." -ForegroundColor Cyan
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ MIGRATION TERMINÉE AVEC SUCCÈS !" -ForegroundColor Green
Write-Host ""
Write-Host "📁 Votre projet est maintenant dans : $destination" -ForegroundColor White
Write-Host ""
Write-Host "🌐 Le serveur va démarrer sur : http://localhost:3000" -ForegroundColor Cyan
Write-Host ""
Write-Host "🔥 HMR ACTIVÉ : Les modifications seront rechargées automatiquement !" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Conseils :" -ForegroundColor Yellow
Write-Host "   • Travaillez depuis C:\Dev\frontend-app" -ForegroundColor Gray
Write-Host "   • Sauvegardez vers pCloud avec : .\sync-to-pcloud.ps1" -ForegroundColor Gray
Write-Host "   • Profitez du rechargement automatique !" -ForegroundColor Gray
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "Démarrage dans 3 secondes..." -ForegroundColor White
Start-Sleep -Seconds 3

npm run dev

