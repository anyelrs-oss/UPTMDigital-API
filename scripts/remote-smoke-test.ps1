param(
  [string]$BaseUrl = "https://uptmdigital-api.onrender.com",
  [string]$Username = "tester1",
  [string]$Password = "123456",
  [int]$LoginAttempts = 3
)

$ErrorActionPreference = "Stop"

function Invoke-Test {
  param(
    [string]$Name,
    [scriptblock]$Action
  )

  try {
    $result = & $Action
    Write-Host "[OK] $Name -> $result" -ForegroundColor Green
  }
  catch {
    $message = $_.Exception.Message

    if ($_.Exception.Response -and $_.Exception.Response.GetResponseStream()) {
      $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
      $message = $reader.ReadToEnd()
    }

    Write-Host "[FAIL] $Name" -ForegroundColor Red
    Write-Host $message -ForegroundColor Yellow
  }
}

Write-Host "Testing base URL: $BaseUrl" -ForegroundColor Cyan

Invoke-Test -Name "Swagger" -Action {
  $r = Invoke-WebRequest -Uri "$BaseUrl/swagger/index.html" -UseBasicParsing -TimeoutSec 30
  "HTTP $($r.StatusCode)"
}

Invoke-Test -Name "Health" -Action {
  $healthPaths = @("/health", "/api/health")
  $lastError = ""

  foreach ($path in $healthPaths) {
    try {
      $r = Invoke-WebRequest -Uri "$BaseUrl$path" -UseBasicParsing -TimeoutSec 30
      return "HTTP $($r.StatusCode) PATH=$path BODY=$($r.Content)"
    }
    catch {
      $lastError = $_.Exception.Message
      if ($_.Exception.Response -and $_.Exception.Response.GetResponseStream()) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $lastError = $reader.ReadToEnd()
      }
    }
  }

  throw "Health failed for /health and /api/health. LastError: $lastError"
}

Invoke-Test -Name "Login" -Action {
  $payload = @{ nombreUsuario = $Username; contrasena = $Password } | ConvertTo-Json
  $lastError = ""

  for ($i = 1; $i -le $LoginAttempts; $i++) {
    try {
      $response = Invoke-RestMethod -Uri "$BaseUrl/api/auth/login" -UseBasicParsing -Method POST -ContentType "application/json" -Body $payload -TimeoutSec 30

      if (-not $response.token) {
        throw "Login response did not include token."
      }

      $parts = $response.token.Split('.')
      if ($parts.Length -ne 3) {
        throw "Returned token is not a valid JWT shape (header.payload.signature)."
      }

      return "HTTP 200 ATTEMPT=$i USER=$($response.nombreUsuario) ROLE=$($response.rol) EXP=$($response.expiracion) JWT=OK"
    }
    catch {
      $lastError = $_.Exception.Message
      if ($_.Exception.Response -and $_.Exception.Response.GetResponseStream()) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $lastError = $reader.ReadToEnd()
      }
      Start-Sleep -Milliseconds 400
    }
  }

  throw "Login failed after $LoginAttempts attempts. LastError: $lastError"
}
