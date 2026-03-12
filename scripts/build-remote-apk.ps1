param(
  [string]$ApiBaseUrl = "https://uptmdigital-api.onrender.com"
)

$ErrorActionPreference = "Stop"

Push-Location "uptmdigital_app"
try {
  flutter clean
  flutter pub get
  flutter build apk --release --dart-define=API_BASE_URL=$ApiBaseUrl

  $apk = Get-Item ".\\build\\app\\outputs\\flutter-apk\\app-release.apk"
  Write-Host "APK generated:" -ForegroundColor Green
  Write-Host $apk.FullName
  Write-Host "Size(bytes): $($apk.Length)"
}
finally {
  Pop-Location
}
