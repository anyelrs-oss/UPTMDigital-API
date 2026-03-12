param(
    [string]$BaseUrl = "https://uptmdigital-api.onrender.com",
    [int]$MaxRetries = 6,
    [int]$RetryDelaySeconds = 6
)

$ErrorActionPreference = "Stop"

function Invoke-WithRetry {
    param(
        [scriptblock]$Action,
        [string]$Name
    )

    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        try {
            return & $Action
        }
        catch {
            if ($attempt -eq $MaxRetries) {
                throw "[$Name] failed after $MaxRetries attempts. Last error: $($_.Exception.Message)"
            }
            Write-Host "[$Name] attempt $attempt failed. Retrying in $RetryDelaySeconds sec..." -ForegroundColor Yellow
            Start-Sleep -Seconds $RetryDelaySeconds
        }
    }
}

function Login-User {
    param(
        [string]$Username,
        [string]$Password
    )

    $body = @{ nombreUsuario = $Username; contrasena = $Password } | ConvertTo-Json
    $resp = Invoke-WithRetry -Name "login:$Username" -Action {
        Invoke-RestMethod -Method Post -Uri "$BaseUrl/api/auth/login" -ContentType "application/json" -Body $body
    }

    if (-not $resp.token) {
        throw "Login for $Username did not return token."
    }

    Write-Host "[OK] login:$Username role=$($resp.rol)" -ForegroundColor Green
    return $resp.token
}

function Check-Me {
    param(
        [string]$Username,
        [string]$Token,
        [string]$Endpoint
    )

    $headers = @{ Authorization = "Bearer $Token" }
    $resp = Invoke-WithRetry -Name "me:$Username" -Action {
        Invoke-RestMethod -Method Get -Uri "$BaseUrl$Endpoint" -Headers $headers
    }

    Write-Host "[OK] me:$Username endpoint=$Endpoint" -ForegroundColor Green
    return $resp
}

Write-Host "== Step 1: Seed test users ==" -ForegroundColor Cyan
$seeded = $false
try {
    Invoke-WithRetry -Name "seed-test-users" -Action {
        Invoke-RestMethod -Method Post -Uri "$BaseUrl/api/setup/seed-test-users" -ContentType "application/json" -Body "{}"
    } | Out-Null
    $seeded = $true
    Write-Host "[OK] seed-test-users" -ForegroundColor Green
}
catch {
    Write-Host "[WARN] seed-test-users unavailable in deployed API (likely old version)." -ForegroundColor Yellow
    Write-Host "[WARN] Trying fallback setup endpoint /api/Setup/apply-changes" -ForegroundColor Yellow
    try {
        Invoke-WithRetry -Name "apply-changes" -Action {
            Invoke-RestMethod -Method Post -Uri "$BaseUrl/api/Setup/apply-changes" -ContentType "application/json" -Body "{}"
        } | Out-Null
        Write-Host "[OK] apply-changes fallback" -ForegroundColor Green
    }
    catch {
        Write-Host "[WARN] apply-changes fallback also failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host "== Step 2: Validate logins ==" -ForegroundColor Cyan
$tokenAdmin = $null
$tokenProf = $null
$tokenEst = $null

if ($seeded) {
    $tokenAdmin = Login-User -Username "tester_admin" -Password "123456"
    $tokenProf = Login-User -Username "tester_prof" -Password "123456"
    $tokenEst = Login-User -Username "tester_est" -Password "123456"
}
else {
    Write-Host "[INFO] Using legacy fallback user set for old deployments." -ForegroundColor Cyan
    try { $tokenProf = Login-User -Username "profesor1" -Password "123456" } catch { Write-Host "[WARN] login:profesor1 failed" -ForegroundColor Yellow }
    try { $tokenEst = Login-User -Username "tester1" -Password "123456" } catch { Write-Host "[WARN] login:tester1 failed" -ForegroundColor Yellow }
}

Write-Host "== Step 3: Validate profile endpoints ==" -ForegroundColor Cyan
if ($tokenProf) {
    try {
        $null = Check-Me -Username "prof" -Token $tokenProf -Endpoint "/api/profesores/me"
    }
    catch {
        Write-Host "[WARN] me:prof failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}
if ($tokenEst) {
    try {
        $null = Check-Me -Username "est" -Token $tokenEst -Endpoint "/api/estudiantes/me"
    }
    catch {
        Write-Host "[WARN] me:est failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host "== Completed ==" -ForegroundColor Cyan
Write-Host "Review WARN lines above for transient failures or old deployment endpoints." -ForegroundColor Cyan
