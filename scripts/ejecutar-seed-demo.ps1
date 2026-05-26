# --------------------------------------------------------------------------------
# ejecutar-seed-demo.ps1
# Levanta la API localmente apuntando a Supabase y ejecuta el seed completo.
#
# USO:
#   .\scripts\ejecutar-seed-demo.ps1 -SupabasePassword "TU_PASSWORD_AQUI"
#
# OPCIONAL (si ya tienes la connection string completa):
#   .\scripts\ejecutar-seed-demo.ps1 -ConnectionString "Host=aws-0-us-west-2.pooler.supabase.com;..."
# --------------------------------------------------------------------------------

param(
    [string]$SupabasePassword = "",
    [string]$ConnectionString = "",
    [string]$BaseUrl          = "http://localhost:8080",
    [int]   $SeedTimeoutSec   = 300
)

$ApiProject = "UPTMDigital.API/UPTMDigital.API.csproj"
$ScriptDir  = Split-Path $MyInvocation.MyCommand.Path
$WorkspaceDir = Split-Path $ScriptDir

Set-Location $WorkspaceDir

# -- Construir la connection string -------------------------------------------
if (-not $ConnectionString) {
    if (-not $SupabasePassword) {
        Write-Error "Debes proveer -SupabasePassword o -ConnectionString"
        exit 1
    }
    $ConnectionString = "Host=aws-0-us-west-2.pooler.supabase.com;Port=6543;Database=postgres;Username=postgres.gacjsnxmldpvweuwfopx;Password=$SupabasePassword;SSL Mode=Require;Trust Server Certificate=true;"
}

Write-Host "Connection string configurada (apuntando a Supabase)" -ForegroundColor Cyan

# -- Lanzar API en background con variable de entorno -------------------------
$env:ConnectionStrings__DefaultConnection = $ConnectionString
$env:ConnectionStrings__NominaConnection  = $ConnectionString
$env:ASPNETCORE_ENVIRONMENT               = "Development"
$env:Jwt__Key                             = "DEMO_KEY_FOR_LOCAL_SEED_ONLY_MIN32CHARS!"

Write-Host "Iniciando API en background..." -ForegroundColor Yellow
$apiProcess = Start-Process -FilePath "dotnet" `
    -ArgumentList "run", "--project", $ApiProject, "--no-build" `
    -PassThru -WindowStyle Hidden

Write-Host "   PID: $($apiProcess.Id). Esperando 15s para que arranque..." -ForegroundColor Gray
Start-Sleep -Seconds 15

# -- Funcion helper para llamadas POST ----------------------------------------
function Invoke-SeedStep {
    param([string]$Endpoint, [string]$Label)
    Write-Host "`n $Label..." -ForegroundColor Cyan
    try {
        $r = Invoke-RestMethod -Uri "$BaseUrl/api/Setup/$Endpoint" -Method Post -TimeoutSec $SeedTimeoutSec
        Write-Host "   [OK] - $($r.message)" -ForegroundColor Green
        if ($r.log) { $r.log | ForEach-Object { Write-Host "      > $_" -ForegroundColor DarkGray } }
        return $true
    } catch {
        Write-Host "   [Error] : $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# -- Verificar que la API responde --------------------------------------------
Write-Host "`n Verificando estado de la API..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "$BaseUrl/health" -TimeoutSec 15
    Write-Host "   [OK] API activa: $($health.status) ($($health.env))" -ForegroundColor Green
} catch {
    Write-Host "   [Error] La API no respondio. Verifica que compilo sin errores." -ForegroundColor Red
    $apiProcess.Kill()
    exit 1
}

# -- Estado antes del seed -----------------------------------------------------
Write-Host "`n Estado ANTES del seed:" -ForegroundColor Magenta
try {
    $before = Invoke-RestMethod -Uri "$BaseUrl/api/Setup/status" -TimeoutSec 15
    $before | ConvertTo-Json | Write-Host
} catch { Write-Host "   (endpoint status no disponible aun)" -ForegroundColor Gray }

# -- Ejecutar seed-all ---------------------------------------------------------
$ok = Invoke-SeedStep "seed-all" "SEED ALL (todos los pasos en un solo llamado)"

if (-not $ok) {
    Write-Host "`n seed-all fallo. Intentando paso a paso..." -ForegroundColor Yellow
    Invoke-SeedStep "seed-base"          "Paso 1: Roles + Profesores + Estudiantes"
    Invoke-SeedStep "seed-academico"     "Paso 2: Asignaturas + Horarios + Inscripciones"
    Invoke-SeedStep "seed-extra"         "Paso 3: Notas + Anuncios + Asistencias + Constancias"
    Invoke-SeedStep "seed-notificaciones" "Paso 4: Notificaciones"
    Invoke-SeedStep "seed-mensajes-v2"   "Paso 5: Mensajes de chat por asignatura"
}

# -- Estado despues del seed ---------------------------------------------------
Write-Host "`n Estado DESPUES del seed:" -ForegroundColor Magenta
try {
    $after = Invoke-RestMethod -Uri "$BaseUrl/api/Setup/status" -TimeoutSec 15
    $after | ConvertTo-Json | Write-Host
} catch { Write-Host "   (endpoint status no disponible)" -ForegroundColor Gray }

# -- Mostrar credenciales ------------------------------------------------------
Write-Host @"

--------------------------------------------------------------------------------
               CREDENCIALES PARA LA MESA TECNICA
--------------------------------------------------------------------------------
  PROFESORES (pass: 123456)
    prof_garcia    -> Carlos Garcia    (Informatica)
    prof_mendoza   -> Maria Mendoza    (Matematicas)
    prof_torres    -> Luis Torres      (Sistemas)
    prof_ramirez   -> Ana Ramirez      (Ingenieria/Adm)
--------------------------------------------------------------------------------
  ESTUDIANTES (pass: 123456)
    est_rodriguez  -> Daniela Rodriguez  (Informatica)
    est_lopez      -> Andres Lopez       (Informatica)
    est_fernandez  -> Valentina Fernandez (Administracion)
    est_perez      -> Miguel Perez       (Administracion)
    est_morales    -> Gabriela Morales   (Contaduria)
    est_vargas     -> Jose Vargas        (Informatica - avanzado)
--------------------------------------------------------------------------------
"@ -ForegroundColor Cyan

# -- Matar proceso de API ------------------------------------------------------
Write-Host "`n Deteniendo API local..." -ForegroundColor Yellow
$apiProcess.Kill()
Write-Host " Script de seed completado." -ForegroundColor Green
