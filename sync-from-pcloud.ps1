# Script de synchronisation : pCloud → Local
# Récupère la dernière version depuis pCloud

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  📥 Récupération depuis pCloud" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

$source = "P:\Hostinger\frontend-app"
$destination = "C:\Dev\frontend-app"

# Vérifier que le dossier source existe
if (-not (Test-Path $source)) {
    Write-Host "❌ ERREUR : Le dossier source n'existe pas : $source" -ForegroundColor Red
    Write-Host "   Vérifiez que pCloud est bien monté." -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "📂 Source      : $source" -ForegroundColor White
Write-Host "📂 Destination : $destination" -ForegroundColor White
Write-Host ""

# Vérifier si le dossier destination existe déjà
if (Test-Path $destination) {
    Write-Host "⚠️  Le dossier $destination existe déjà" -ForegroundColor Yellow
    Write-Host "   Cette opération va écraser les fichiers locaux" -ForegroundColor Yellow
    Write-Host ""
    $confirmation = Read-Host "   Continuer ? (O/N)"

    if ($confirmation -ne 'O' -and $confirmation -ne 'o') {
        Write-Host "❌ Opération annulée" -ForegroundColor Red
        exit 0
    }
} else {
    Write-Host "📁 Création du dossier local..." -ForegroundColor White
}

Write-Host ""
Write-Host "🔄 Synchronisation en cours..." -ForegroundColor Cyan
Write-Host ""

# Copier depuis pCloud vers Local
Write-Host "📦 Copie en cours..." -ForegroundColor White
$result = xcopy $source $destination /E /I /H /Y /Q 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Synchronisation réussie !" -ForegroundColor Green
    Write-Host ""
    Write-Host "📁 Projet disponible en local" -ForegroundColor Green
    Write-Host "   → $destination" -ForegroundColor Gray
    Write-Host ""

    # Proposer de lancer npm install
    Write-Host "💡 Voulez-vous installer les dépendances maintenant ? (O/N)" -ForegroundColor Yellow
    $installDeps = Read-Host

    if ($installDeps -eq 'O' -or $installDeps -eq 'o') {
        Write-Host ""
        Write-Host "📦 Installation des dépendances..." -ForegroundColor Cyan
        cd $destination
        npm install

        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "✅ Dépendances installées !" -ForegroundColor Green
            Write-Host ""
            Write-Host "🚀 Pour démarrer le serveur :" -ForegroundColor Cyan
            Write-Host "   cd $destination" -ForegroundColor White
            Write-Host "   npm run dev" -ForegroundColor White
        }
    } else {
        Write-Host ""
        Write-Host "💡 N'oubliez pas d'installer les dépendances :" -ForegroundColor Yellow
        Write-Host "   cd $destination" -ForegroundColor White
        Write-Host "   npm install" -ForegroundColor White
        Write-Host "   npm run dev" -ForegroundColor White
    }
} else {
    Write-Host ""
    Write-Host "❌ Erreur lors de la synchronisation" -ForegroundColor Red
    Write-Host "   Code erreur : $LASTEXITCODE" -ForegroundColor Red
}

Write-Host ""
Write-Host "Appuyez sur une touche pour continuer..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

