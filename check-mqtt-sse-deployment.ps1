# Script pour vérifier le déploiement MQTT-SSE

Write-Host "🔍 Vérification du déploiement MQTT-SSE..." -ForegroundColor Cyan
Write-Host ""

$VPS_IP = "72.62.16.206"

# 1. Vérifier l'ingress configuration
Write-Host "📋 Configuration Ingress:" -ForegroundColor Yellow
ssh root@$VPS_IP "kubectl get ingress mqtt-sse-bridge -n default -o yaml | grep -A 10 'spec:'"
Write-Host ""

# 2. Vérifier les logs
Write-Host "📝 Logs du backend (20 dernières lignes):" -ForegroundColor Yellow
ssh root@$VPS_IP "kubectl logs -n default -l app.kubernetes.io/name=mqtt-sse-bridge --tail=20"
Write-Host ""

# 3. Tester le health check
Write-Host "🏥 Test Health Check:" -ForegroundColor Yellow
Write-Host "curl https://api.toolsapps.eu/health" -ForegroundColor Gray
curl -k https://api.toolsapps.eu/health
Write-Host ""

# 4. Tester l'endpoint SSE (3 secondes)
Write-Host "📡 Test SSE endpoint (3 secondes):" -ForegroundColor Yellow
Write-Host "curl -N https://api.toolsapps.eu/api/portal/events" -ForegroundColor Gray
$job = Start-Job -ScriptBlock { curl -k -N https://api.toolsapps.eu/api/portal/events }
Start-Sleep -Seconds 3
Stop-Job $job
$output = Receive-Job $job
Remove-Job $job
Write-Host $output
Write-Host ""

Write-Host "✅ Vérification terminée" -ForegroundColor Green
