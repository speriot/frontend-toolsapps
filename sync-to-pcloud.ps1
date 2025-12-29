# Script de synchronisation : Local → pCloud
# Sauvegarde votre travail depuis C:\Dev vers pCloud

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  💾 Sauvegarde vers pCloud" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

$source = "C:\Dev\frontend-app"
$destination = "P:\Hostinger\frontend-app"

# Vérifier que le dossier source existe
if (-not (Test-Path $source)) {
    Write-Host "❌ ERREUR : Le dossier source n'existe pas : $source" -ForegroundColor Red
    Write-Host "   Assurez-vous d'avoir copié le projet en local d'abord." -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "📂 Source      : $source" -ForegroundColor White
Write-Host "📂 Destination : $destination" -ForegroundColor White
Write-Host ""

# Calculer la taille (approximative)
$totalSize = (Get-ChildItem -Path $source -Recurse -File | Measure-Object -Property Length -Sum).Sum
$sizeMB = [math]::Round($totalSize / 1MB, 2)
Write-Host "📊 Taille totale : $sizeMB MB" -ForegroundColor White
Write-Host ""

# Demander confirmation
Write-Host "⚠️  Cette opération va écraser les fichiers sur pCloud" -ForegroundColor Yellow
$confirmation = Read-Host "   Continuer ? (O/N)"

if ($confirmation -ne 'O' -and $confirmation -ne 'o') {
    Write-Host "❌ Opération annulée" -ForegroundColor Red
    exit 0
}

Write-Host ""
Write-Host "🔄 Synchronisation en cours..." -ForegroundColor Cyan
Write-Host ""

# Option 1 : Synchronisation complète (plus lente mais sûre)
Write-Host "📦 Copie complète en cours..." -ForegroundColor White
$result = xcopy $source $destination /E /I /H /Y /Q 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Synchronisation réussie !" -ForegroundColor Green
    Write-Host ""
    Write-Host "📁 Votre travail est sauvegardé sur pCloud" -ForegroundColor Green
    Write-Host "   → $destination" -ForegroundColor Gray
} else {
    Write-Host ""
    Write-Host "❌ Erreur lors de la synchronisation" -ForegroundColor Red
    Write-Host "   Code erreur : $LASTEXITCODE" -ForegroundColor Red
}

Write-Host ""
Write-Host "Appuyez sur une touche pour continuer..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

