# Script pour lancer Vite sans conflit avec pCloud/Antivirus
Write-Host "🚀 Démarrage du serveur Vite (mode sans HMR)" -ForegroundColor Green
Write-Host ""
Write-Host "⚠️  Le Hot Module Replacement est désactivé à cause de pCloud" -ForegroundColor Yellow
Write-Host "    Vous devrez rafraîchir manuellement (F5) après vos modifications" -ForegroundColor Yellow
Write-Host ""

# Nettoyer le cache Vite
if (Test-Path "node_modules/.vite") {
    Write-Host "🧹 Nettoyage du cache Vite..." -ForegroundColor Cyan
    Remove-Item -Recurse -Force "node_modules/.vite" -ErrorAction SilentlyContinue
}

# Lancer le serveur
Write-Host "🌐 Serveur disponible sur http://localhost:3000" -ForegroundColor Green
Write-Host ""
npm run dev

