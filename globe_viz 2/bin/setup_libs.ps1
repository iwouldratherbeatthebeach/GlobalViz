<#
  Downloads CesiumJS + satellite.js into this app so the 3D Globe visualization
  works under Splunk's Content-Security-Policy (which blocks external CDNs).

  Run once from PowerShell. Writes into the app's static folder:
    appserver\static\visualizations\globe\cesium\        (Cesium Build\Cesium)
    appserver\static\visualizations\globe\satellite.min.js

  Usage:
    powershell -ExecutionPolicy Bypass -File bin\setup_libs.ps1
    powershell -ExecutionPolicy Bypass -File bin\setup_libs.ps1 -AppDir C:\path\to\globe_viz

  Requires internet access. Uses built-in Expand-Archive.
#>
param(
    [string]$AppDir = (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
)

$ErrorActionPreference = "Stop"
$CesiumVersion = "1.118"
$SatUrl    = "https://cdn.jsdelivr.net/npm/satellite.js@5.0.0/dist/satellite.min.js"
$CesiumUrl = "https://github.com/CesiumGS/cesium/releases/download/$CesiumVersion/Cesium-$CesiumVersion.zip"

$VizDir = Join-Path $AppDir "appserver\static\visualizations\globe"
Write-Host "App dir : $AppDir"
Write-Host "Viz dir : $VizDir"
New-Item -ItemType Directory -Force -Path $VizDir | Out-Null

$Tmp = New-Item -ItemType Directory -Force -Path (Join-Path $env:TEMP ("globeviz_" + [guid]::NewGuid()))

Write-Host "Downloading satellite.js ..."
Invoke-WebRequest -Uri $SatUrl -OutFile (Join-Path $VizDir "satellite.min.js")

Write-Host "Downloading CesiumJS $CesiumVersion (~10-20 MB) ..."
$Zip = Join-Path $Tmp "cesium.zip"
Invoke-WebRequest -Uri $CesiumUrl -OutFile $Zip

Write-Host "Extracting Cesium ..."
Expand-Archive -Path $Zip -DestinationPath (Join-Path $Tmp "cesium") -Force

$CesiumDest = Join-Path $VizDir "cesium"
if (Test-Path $CesiumDest) { Remove-Item -Recurse -Force $CesiumDest }
New-Item -ItemType Directory -Force -Path $CesiumDest | Out-Null
Copy-Item -Recurse -Force (Join-Path $Tmp "cesium\Build\Cesium\*") $CesiumDest

Remove-Item -Recurse -Force $Tmp
Write-Host ""
Write-Host "Done. Installed:"
Write-Host "  $CesiumDest\Cesium.js"
Write-Host "  $VizDir\satellite.min.js"
Write-Host ""
Write-Host "Now reload Splunk Web and reopen the dashboard."
