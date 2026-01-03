# Script de diagnostic SSL pour front.toolsapps.eu
# Date: 2 janvier 2026

$VPS_IP = "72.62.16.206"
$DOMAIN = "front.toolsapps.eu"

Write-Host "🔍 DIAGNOSTIC SSL - front.toolsapps.eu" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Gray
Write-Host ""

# Test 1: Vérifier si le domaine répond
Write-Host "📡 Test 1: Connectivité HTTP/HTTPS" -ForegroundColor Yellow
Write-Host ""

try {
    $httpResponse = Invoke-WebRequest -Uri "http://$DOMAIN" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    Write-Host "   ✅ HTTP (port 80): " -NoNewline -ForegroundColor Green
    Write-Host "$($httpResponse.StatusCode)" -ForegroundColor White
} catch {
    Write-Host "   ❌ HTTP (port 80): Échec - $($_.Exception.Message)" -ForegroundColor Red
}

try {
    $httpsResponse = Invoke-WebRequest -Uri "https://$DOMAIN" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    Write-Host "   ✅ HTTPS (port 443): " -NoNewline -ForegroundColor Green
    Write-Host "$($httpsResponse.StatusCode)" -ForegroundColor White
} catch {
    Write-Host "   ❌ HTTPS (port 443): Échec - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 2: Vérifier le certificat SSL
Write-Host "🔐 Test 2: Certificat SSL" -ForegroundColor Yellow
Write-Host ""

try {
    $request = [System.Net.HttpWebRequest]::Create("https://$DOMAIN")
    $request.ServerCertificateValidationCallback = { $true }
    $response = $request.GetResponse()
    $cert = $request.ServicePoint.Certificate
    
    if ($cert) {
        $cert2 = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $cert
        Write-Host "   ✅ Certificat trouvé" -ForegroundColor Green
        Write-Host "   📋 Émetteur: $($cert2.Issuer)" -ForegroundColor White
        Write-Host "   📅 Valide du: $($cert2.NotBefore)" -ForegroundColor White
        Write-Host "   📅 Expire le: $($cert2.NotAfter)" -ForegroundColor White
        Write-Host "   🔑 Sujet: $($cert2.Subject)" -ForegroundColor White
        
        if ($cert2.Issuer -like "*Staging*" -or $cert2.Issuer -like "*Fake*") {
            Write-Host "   ⚠️  CERTIFICAT STAGING (Let's Encrypt Test)" -ForegroundColor Yellow
        } elseif ($cert2.Issuer -like "*Let's Encrypt*" -or $cert2.Issuer -like "*R3*" -or $cert2.Issuer -like "*R10*" -or $cert2.Issuer -like "*R11*") {
            Write-Host "   ✅ CERTIFICAT PRODUCTION (Let's Encrypt)" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️  Type de certificat: $($cert2.Issuer)" -ForegroundColor Yellow
        }
        
        $daysLeft = ($cert2.NotAfter - (Get-Date)).Days
        if ($daysLeft -lt 7) {
            Write-Host "   ⚠️  Expire dans $daysLeft jours" -ForegroundColor Red
        } else {
            Write-Host "   ⏱️  Expire dans $daysLeft jours" -ForegroundColor White
        }
    }
    $response.Close()
} catch {
    Write-Host "   ❌ Impossible de récupérer le certificat: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=" * 60 -ForegroundColor Gray
Write-Host ""

# Commandes à exécuter sur le VPS
Write-Host "🖥️  COMMANDES À EXÉCUTER SUR LE VPS" -ForegroundColor Cyan
Write-Host ""
Write-Host "Connectez-vous à votre VPS et exécutez:" -ForegroundColor White
Write-Host ""
Write-Host "ssh root@$VPS_IP" -ForegroundColor Green
Write-Host ""

$commands = @"
# 1. Vérifier les certificats dans le namespace default
kubectl get certificate -n default

# 2. Détails du certificat front.toolsapps.eu
kubectl describe certificate frontend-toolsapps-tls -n default

# 3. Vérifier les CertificateRequests
kubectl get certificaterequest -n default

# 4. Logs de cert-manager
kubectl logs -n cert-manager deployment/cert-manager --tail=50

# 5. Vérifier le secret TLS
kubectl get secret frontend-toolsapps-tls -n default

# 6. Vérifier l'Ingress
kubectl get ingress -n default
kubectl describe ingress frontend-toolsapps -n default

# 7. Vérifier les événements récents
kubectl get events -n default --sort-by='.lastTimestamp' | grep -i cert

# 8. Vérifier le ClusterIssuer
kubectl get clusterissuer letsencrypt-prod
kubectl describe clusterissuer letsencrypt-prod
"@

Write-Host $commands -ForegroundColor Yellow
Write-Host ""
Write-Host "=" * 60 -ForegroundColor Gray
Write-Host ""
Write-Host "💡 Copiez ces commandes et exécutez-les sur votre VPS" -ForegroundColor Cyan
Write-Host "   puis partagez-moi les résultats pour un diagnostic complet." -ForegroundColor White
Write-Host ""
