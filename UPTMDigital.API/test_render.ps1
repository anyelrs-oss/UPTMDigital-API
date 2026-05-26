 = 'https://uptmdigital-api.onrender.com'
Write-Host 'Despertando Render...'
 = False
for (=0;  -lt 30; ++) {
    try {
         = Invoke-RestMethod -Uri "/api/Setup/status" -TimeoutSec 15
        Write-Host 'Render despertó.'
         = True
        break
    } catch {
        Write-Host "Intento ..."
        Start-Sleep -Seconds 5
    }
}
if (-not ) { Write-Host 'Render no despertó'; exit 1 }

Write-Host 'Creando tablas faltantes...'
try {
    Invoke-RestMethod -Uri "/api/Setup/create-missing-tables" -Method Post -TimeoutSec 60
} catch { Write-Host 'Falló crear tablas' }

Write-Host 'Ejecutando seed-all...'
try {
    Invoke-RestMethod -Uri "/api/Setup/seed-all" -Method Post -TimeoutSec 120
} catch { Write-Host 'Falló seed-all' }

Write-Host 'Obteniendo status...'
try {
     = Invoke-RestMethod -Uri "/api/Setup/status" -TimeoutSec 30
     | ConvertTo-Json | Write-Host
} catch { Write-Host 'Falló status' }
