<#
  Build a SELF-CONTAINED, offline-ready .spl for an air-gapped Splunk.

  Run this ON AN INTERNET-CONNECTED STAGING MACHINE (not the air-gapped server).
  It downloads CesiumJS + satellite.js into the app, verifies them, then packages
  the whole app (libraries included) into globe_viz_offline.spl. Copy that single
  file to the air-gapped environment and install it there — no internet needed at
  install time or at runtime.

  Usage:
    powershell -ExecutionPolicy Bypass -File bin\package_offline.ps1

  Requires: tar (built into Windows 10+), PowerShell 5+.
#>
$ErrorActionPreference = "Stop"

$AppDir  = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$AppName = Split-Path -Leaf $AppDir
$Parent  = Split-Path -Parent $AppDir
$VizDir  = Join-Path $AppDir "appserver\static\visualizations\globe"
$Out     = Join-Path $Parent "$($AppName)_offline.spl"

Write-Host "==> Downloading libraries into the app ..."
& powershell -ExecutionPolicy Bypass -File (Join-Path $AppDir "bin\setup_libs.ps1") -AppDir $AppDir

Write-Host "==> Verifying libraries are present ..."
$missing = $false
foreach ($p in @("cesium\Cesium.js","cesium\Workers","cesium\Assets","satellite.min.js")) {
    if (-not (Test-Path (Join-Path $VizDir $p))) { Write-Host "MISSING: $p"; $missing = $true }
}
if ($missing) { throw "Libraries not fully present; re-run setup_libs.ps1." }

Write-Host "==> Packaging self-contained $Out ..."
if (Test-Path $Out) { Remove-Item $Out }
tar -C $Parent -czf $Out $AppName

Write-Host ""
Write-Host "Built: $Out"
Write-Host "This .spl contains Cesium + satellite.js and needs NO internet to install or run."
Write-Host "Transfer it to the air-gapped Splunk and install via Apps > Install app from file."
