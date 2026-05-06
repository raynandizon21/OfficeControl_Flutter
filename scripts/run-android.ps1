param(
  [Parameter(Mandatory = $false)]
  [string]$DeviceId,

  [Parameter(Mandatory = $false)]
  [switch]$Release,

  [Parameter(Mandatory = $false)]
  [string[]]$ExtraArgs
)

$ErrorActionPreference = "Stop"

function Get-AndroidDeviceId {
  $json = flutter devices --machine | Out-String
  if (-not $json.Trim()) { return $null }
  $devices = $json | ConvertFrom-Json

  $android = $devices | Where-Object {
    $_.targetPlatform -like "android-*"
  }
  if (-not $android) { return $null }

  return $android[0].id
}

if (-not $DeviceId) {
  $DeviceId = Get-AndroidDeviceId
}

if (-not $DeviceId) {
  Write-Host "No Android device detected by Flutter." -ForegroundColor Red
  Write-Host "Run: flutter devices" -ForegroundColor Yellow
  exit 1
}

$modeArgs = @()
if ($Release) { $modeArgs += "--release" }

$argsList = @("run", "-d", $DeviceId) + $modeArgs
if ($ExtraArgs) { $argsList += $ExtraArgs }

Write-Host ("Running: flutter " + ($argsList -join " ")) -ForegroundColor Cyan
flutter @argsList

