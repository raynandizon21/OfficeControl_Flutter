param(
  [Parameter(Mandatory = $false)]
  [string]$Port = "8000",

  [Parameter(Mandatory = $false)]
  [string]$Hostname = "localhost",

  [Parameter(Mandatory = $false)]
  [string]$Device = "edge",

  [Parameter(Mandatory = $false)]
  [string]$HaUrl,

  [Parameter(Mandatory = $false)]
  [string]$HaToken,

  [Parameter(Mandatory = $false)]
  [string[]]$ExtraArgs
)

$ErrorActionPreference = "Stop"

if (-not $HaUrl -or ($HaUrl.Trim().Length -eq 0)) {
  $HaUrl = $env:OFFICE_HA_URL
}

if (-not $HaUrl -or ($HaUrl.Trim().Length -eq 0)) {
  $HaUrl = "http://iot3core21.ddns.net:8123"
}

if (-not $HaToken -or ($HaToken.Trim().Length -eq 0)) {
  $HaToken = $env:OFFICE_HA_TOKEN
}

if (-not $HaToken -or ($HaToken.Trim().Length -eq 0)) {
  Write-Host "Missing HA token. Set OFFICE_HA_TOKEN, or pass -HaToken." -ForegroundColor Yellow
  Write-Host "Example: `$env:OFFICE_HA_TOKEN='<your-token>'; .\scripts\run-web.ps1" -ForegroundColor Cyan
  exit 1
}

$defines = @(
  "--dart-define=OFFICE_HA_URL=$HaUrl",
  "--dart-define=OFFICE_HA_TOKEN=$HaToken"
)

$cmdArgs = @("run", "-d", $Device, "--web-port", $Port, "--web-hostname", $Hostname) + $defines + $ExtraArgs

Write-Host ("Running: flutter " + ($cmdArgs -join " ")) -ForegroundColor Cyan
flutter @cmdArgs
