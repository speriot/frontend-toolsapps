# Script de Push vers GitHub pour speriot
# Usage: .\push-to-github.ps1

Write-Host "`n╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                       ║" -ForegroundColor Cyan
Write-Host "║   🚀 Push vers GitHub - Frontend ToolsApps           ║" -ForegroundColor Green
Write-Host "║                                                       ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Configuration
$RepoUrl = "https://github.com/speriot/frontend-toolsapps.git"
$RepoName = "frontend-toolsapps"
$Username = "speriot"

# Vérifier si on est dans le bon dossier
if (-not (Test-Path "package.json")) {
    Write-Host "❌ Erreur: Ce script doit être exécuté depuis C:\dev\frontend-app" -ForegroundColor Red
    exit 1
}

Write-Host "📂 Dossier: $(Get-Location)" -ForegroundColor Cyan
Write-Host ""

# Étape 1: Vérifier/Initialiser Git
Write-Host "1️⃣  Vérification du repository Git..." -ForegroundColor Yellow

if (-not (Test-Path ".git")) {
    Write-Host "   ⚠️  Pas de repository Git détecté" -ForegroundColor Yellow
    Write-Host "   📝 Initialisation de Git..." -ForegroundColor Cyan

    git init
    git add .
    git commit -m "Initial commit - Frontend React + Vite + Tailwind with Helm charts"

    Write-Host "   ✅ Repository Git initialisé" -ForegroundColor Green
} else {
    Write-Host "   ✅ Repository Git existe" -ForegroundColor Green

    # Vérifier s'il y a des modifications non commitées
    $Status = git status --porcelain
    if ($Status) {
        Write-Host "   📝 Modifications détectées, création d'un commit..." -ForegroundColor Cyan
        git add .
        $CommitMsg = Read-Host "   Message de commit (ou Entrée pour message auto)"
        if ([string]::IsNullOrWhiteSpace($CommitMsg)) {
            $CommitMsg = "Update: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
        }
        git commit -m $CommitMsg
        Write-Host "   ✅ Commit créé" -ForegroundColor Green
    } else {
        Write-Host "   ℹ️  Aucune modification à committer" -ForegroundColor White
    }
}

Write-Host ""

# Étape 2: Vérifier/Ajouter le remote
Write-Host "2️⃣  Configuration du remote GitHub..." -ForegroundColor Yellow

$Remotes = git remote -v 2>&1
if ($Remotes -match "origin") {
    Write-Host "   ℹ️  Remote 'origin' existe déjà" -ForegroundColor White
    Write-Host "   📍 $(git remote get-url origin)" -ForegroundColor Cyan

    # Vérifier si c'est le bon remote
    $CurrentRemote = git remote get-url origin
    if ($CurrentRemote -ne $RepoUrl) {
        Write-Host "   ⚠️  Remote différent détecté!" -ForegroundColor Yellow
        $UpdateRemote = Read-Host "   Voulez-vous le changer pour $RepoUrl ? (o/N)"
        if ($UpdateRemote -eq "o" -or $UpdateRemote -eq "O") {
            git remote set-url origin $RepoUrl
            Write-Host "   ✅ Remote mis à jour" -ForegroundColor Green
        }
    } else {
        Write-Host "   ✅ Remote correctement configuré" -ForegroundColor Green
    }
} else {
    Write-Host "   📝 Ajout du remote GitHub..." -ForegroundColor Cyan
    git remote add origin $RepoUrl
    Write-Host "   ✅ Remote ajouté: $RepoUrl" -ForegroundColor Green
}

Write-Host ""

# Étape 3: Vérifier la branche
Write-Host "3️⃣  Vérification de la branche..." -ForegroundColor Yellow

$CurrentBranch = git branch --show-current
Write-Host "   📍 Branche actuelle: $CurrentBranch" -ForegroundColor Cyan

if ($CurrentBranch -ne "main" -and $CurrentBranch -ne "master") {
    Write-Host "   📝 Renommage en 'main'..." -ForegroundColor Cyan
    git branch -M main
    Write-Host "   ✅ Branche renommée en 'main'" -ForegroundColor Green
    $CurrentBranch = "main"
} else {
    if ($CurrentBranch -eq "master") {
        $Rename = Read-Host "   Voulez-vous renommer 'master' en 'main' ? (o/N)"
        if ($Rename -eq "o" -or $Rename -eq "O") {
            git branch -M main
            $CurrentBranch = "main"
            Write-Host "   ✅ Branche renommée en 'main'" -ForegroundColor Green
        }
    } else {
        Write-Host "   ✅ Branche OK" -ForegroundColor Green
    }
}

Write-Host ""

# Étape 4: Instructions pour le token
Write-Host "4️⃣  Authentification GitHub..." -ForegroundColor Yellow
Write-Host ""
Write-Host "   ⚠️  IMPORTANT: GitHub nécessite un Personal Access Token" -ForegroundColor Yellow
Write-Host ""
Write-Host "   📝 Pour créer un token:" -ForegroundColor Cyan
Write-Host "      1. Aller sur: https://github.com/settings/tokens" -ForegroundColor White
Write-Host "      2. Cliquer sur 'Generate new token (classic)'" -ForegroundColor White
Write-Host "      3. Cocher le scope 'repo'" -ForegroundColor White
Write-Host "      4. Copier le token généré (ghp_...)" -ForegroundColor White
Write-Host ""
Write-Host "   Lors du push, utilisez:" -ForegroundColor Cyan
Write-Host "      Username: $Username" -ForegroundColor White
Write-Host "      Password: [VOTRE TOKEN]" -ForegroundColor White
Write-Host ""

$Continue = Read-Host "   Avez-vous un token prêt ? (o/N)"
if ($Continue -ne "o" -and $Continue -ne "O") {
    Write-Host ""
    Write-Host "   ⏸️  Arrêt du script." -ForegroundColor Yellow
    Write-Host "   📝 Créez un token puis relancez ce script." -ForegroundColor Cyan
    Write-Host ""
    exit 0
}

Write-Host ""

# Étape 5: Push vers GitHub
Write-Host "5️⃣  Push vers GitHub..." -ForegroundColor Yellow
Write-Host ""

try {
    # Vérifier si le remote existe
    git ls-remote origin 2>&1 | Out-Null
    $RemoteExists = $?

    if ($RemoteExists) {
        Write-Host "   📡 Remote accessible, push en cours..." -ForegroundColor Cyan
        git push origin $CurrentBranch
    } else {
        Write-Host "   📡 Premier push vers le remote..." -ForegroundColor Cyan
        git push -u origin $CurrentBranch
    }

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "   ✅ Push réussi!" -ForegroundColor Green
        Write-Host ""
        Write-Host "╔═══════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║                                                       ║" -ForegroundColor Green
        Write-Host "║   🎉 Code pushé avec succès sur GitHub!              ║" -ForegroundColor Green
        Write-Host "║                                                       ║" -ForegroundColor Green
        Write-Host "╚═══════════════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""
        Write-Host "📍 Votre repository:" -ForegroundColor Cyan
        Write-Host "   https://github.com/$Username/$RepoName" -ForegroundColor White
        Write-Host ""
        Write-Host "🚀 Prochaine étape: Déployer sur le VPS!" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "   ssh root@votre-vps-ip" -ForegroundColor White
        Write-Host "   git clone $RepoUrl" -ForegroundColor White
        Write-Host "   cd $RepoName" -ForegroundColor White
        Write-Host "   helm install frontend-toolsapps helm/frontend-toolsapps -n production" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host ""
        Write-Host "   ❌ Erreur lors du push" -ForegroundColor Red
        Write-Host ""
        Write-Host "   Vérifiez:" -ForegroundColor Yellow
        Write-Host "   • Que le repository existe sur GitHub" -ForegroundColor White
        Write-Host "   • Que votre token a les bons droits (scope 'repo')" -ForegroundColor White
        Write-Host "   • Que vous avez utilisé le token comme mot de passe" -ForegroundColor White
        Write-Host ""
    }
} catch {
    Write-Host ""
    Write-Host "   ❌ Erreur: $_" -ForegroundColor Red
    Write-Host ""
}

Write-Host ""
Write-Host "📚 Documentation complète: GUIDE-GITHUB-SPERIOT.md" -ForegroundColor Cyan
Write-Host ""

