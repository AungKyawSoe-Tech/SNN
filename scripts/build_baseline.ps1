param(
    [string]$Board = "arty_a7",
    [string]$CpuType = "vexriscv",
    [string]$CpuVariant = "linux",
    [switch]$WithEthernet,
    [switch]$WithSDCard,
    [string]$LiteXPath = "$env:USERPROFILE/litex",
    [string]$LogDir = "..\reports\vivado",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $LiteXPath)) {
    throw "LiteX path '$LiteXPath' not found."
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$reportPath = Join-Path $LogDir $timestamp
New-Item -ItemType Directory -Force -Path $reportPath | Out-Null

Push-Location $LiteXPath
try {
    $cmd = "python -m litex_boards.targets.digilent_arty --cpu-type $CpuType --cpu-variant $CpuVariant --build"
    if ($WithEthernet) { $cmd += " --with-ethernet" }
    if ($WithSDCard) { $cmd += " --with-sdcard" }
    Write-Host "Running LiteX build: $cmd"

    if ($DryRun) {
        Write-Host "Dry run enabled; skipping execution."
    } else {
        Invoke-Expression $cmd
    }

    $vivadoLog = "build/digilent_arty/gateware/vivado.log"
    if (Test-Path $vivadoLog) {
        Copy-Item $vivadoLog (Join-Path $reportPath "vivado.log")
    }
    $utilReport = "build/digilent_arty/gateware/top_utilization.rpt"
    if (Test-Path $utilReport) {
        Copy-Item $utilReport (Join-Path $reportPath "utilization.rpt")
    }
    $timingReport = "build/digilent_arty/gateware/top_timing.rpt"
    if (Test-Path $timingReport) {
        Copy-Item $timingReport (Join-Path $reportPath "timing.rpt")
    }
}
finally {
    Pop-Location
}

Write-Host "Reports archived to $reportPath"
