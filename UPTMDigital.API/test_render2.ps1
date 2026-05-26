$BaseUrl = "https://uptmdigital-api.onrender.com"
Write-Host "Despertando Render..."
$ready = $false
for ($i=0; $i -lt 30; $i++) {
    try {
        $r = Invoke-RestMethod -Uri "$BaseUrl/api/Setup/status" -TimeoutSec 15
        Write-Host "Render desperto."
        $ready = $true
        break
    } catch {
        Write-Host "Intento $i..."
        Start-Sleep -Seconds 5
    }
}
if (-not $ready) { Write-Host "Render no desperto"; exit 1 }

Write-Host "Creando tablas faltantes..."
try {
    Invoke-RestMethod -Uri "$BaseUrl/api/Setup/create-missing-tables" -Method Post -TimeoutSec 60
} catch { Write-Host "Fallo crear tablas" }

Write-Host "Ejecutando seed-all..."
try {
    Invoke-RestMethod -Uri "$BaseUrl/api/Setup/seed-all" -Method Post -TimeoutSec 120
} catch { Write-Host "Fallo seed-all" }

Write-Host "Obteniendo status..."
try {
    $status = Invoke-RestMethod -Uri "$BaseUrl/api/Setup/status" -TimeoutSec 30
    $status | ConvertTo-Json | Write-Host
} catch { Write-Host "Fallo status" }
