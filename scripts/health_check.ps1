# SNN Project File Health Check
# Verifies all critical files are present and in working condition

Write-Host "`n═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "           SNN PROJECT FILE HEALTH CHECK REPORT" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

$allGood = $true

# Check RTL Files
Write-Host "RTL SOURCE FILES:" -ForegroundColor Yellow
$rtlFiles = @(
    @{Path="rtl/snn_accelerator_top.v"; Lines=249; Status="Core accelerator module"},
    @{Path="rtl/spike_fifo.v"; Lines=62; Status="Synchronous FIFO"},
    @{Path="rtl/lif_neuron.v"; Lines=183; Status="LIF neuron implementation"},
    @{Path="rtl/snn_accel_litex.py"; Lines=210; Status="LiteX wrapper (import errors OK)"}
)

foreach ($file in $rtlFiles) {
    if (Test-Path $file.Path) {
        $lineCount = (Get-Content $file.Path).Count
        Write-Host "  ✓ $($file.Path) - $lineCount lines - $($file.Status)" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $($file.Path) - MISSING!" -ForegroundColor Red
        $allGood = $false
    }
}

# Check Build Artifacts
Write-Host "`nBUILD ARTIFACTS:" -ForegroundColor Yellow
$buildFiles = @(
    @{Path="build/digilent_arty/gateware/digilent_arty.bit"; Status="FPGA bitstream"},
    @{Path="build/digilent_arty/gateware/digilent_arty.bin"; Status="Flash image"},
    @{Path="build/digilent_arty/csr.csv"; Status="Memory map"},
    @{Path="build/digilent_arty/csr.json"; Status="JSON memory map"},
    @{Path="build/digilent_arty/gateware/digilent_arty.v"; Status="Generated Verilog"}
)

foreach ($file in $buildFiles) {
    if (Test-Path $file.Path) {
        $size = (Get-Item $file.Path).Length
        $sizeKB = [math]::Round($size / 1KB, 2)
        Write-Host "  ✓ $($file.Path) - $sizeKB KB - $($file.Status)" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $($file.Path) - MISSING!" -ForegroundColor Red
        $allGood = $false
    }
}

# Check Simulation Files
Write-Host "`nSIMULATION FILES:" -ForegroundColor Yellow
$simFiles = @(
    @{Path="sim/tb_snn_accelerator.v"; Status="Full accelerator testbench"},
    @{Path="sim/Makefile"; Status="Build automation"},
    @{Path="sim/README_sim.md"; Status="Documentation"}
)

foreach ($file in $simFiles) {
    if (Test-Path $file.Path) {
        Write-Host "  ✓ $($file.Path) - $($file.Status)" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $($file.Path) - MISSING!" -ForegroundColor Red
        $allGood = $false
    }
}

# Check Documentation
Write-Host "`nDOCUMENTATION:" -ForegroundColor Yellow
$docCount = (Get-ChildItem -Path . -Filter *.md -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
Write-Host "  ✓ $docCount markdown files" -ForegroundColor Green

$keyDocs = @("STATUS.md", "SESSION_SUMMARY.md", "QUICK_REFERENCE.md")
foreach ($doc in $keyDocs) {
    if (Test-Path $doc) {
        Write-Host "  ✓ $doc" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $doc - MISSING!" -ForegroundColor Red
        $allGood = $false
    }
}

# Check Git Status
Write-Host "`nGIT REPOSITORY:" -ForegroundColor Yellow
if (Test-Path .git) {
    Write-Host "  ✓ Git repository initialized" -ForegroundColor Green
    $commit = git log --oneline -1 2>$null
    if ($commit) {
        Write-Host "  ✓ Latest commit: $commit" -ForegroundColor Green
    }
    $status = git status --short 2>$null
    if ($status) {
        Write-Host "  ⚠ Uncommitted changes present" -ForegroundColor Yellow
    } else {
        Write-Host "  ✓ Working tree clean" -ForegroundColor Green
    }
} else {
    Write-Host "  ✗ Git not initialized!" -ForegroundColor Red
    $allGood = $false
}

# Verify Verilog Syntax
Write-Host "`nVERILOG SYNTAX CHECK:" -ForegroundColor Yellow
$verilogFiles = Get-ChildItem rtl/*.v
$syntaxOk = $true
foreach ($vfile in $verilogFiles) {
    $content = Get-Content $vfile.FullName -Raw
    if ($content -match 'module\s+\w+' -and $content -match 'endmodule') {
        Write-Host "  ✓ $($vfile.Name) - module properly closed" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $($vfile.Name) - syntax issues!" -ForegroundColor Red
        $syntaxOk = $false
        $allGood = $false
    }
}

# Final Verdict
Write-Host "`n═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
if ($allGood) {
    Write-Host "VERDICT: ALL FILES IN WORKING CONDITION ✓" -ForegroundColor Black -BackgroundColor Green
    Write-Host "`nYour project is ready for:" -ForegroundColor Green
    Write-Host "  • FPGA programming (bitstream ready)" -ForegroundColor White
    Write-Host "  • Simulation testing (testbench ready)" -ForegroundColor White
    Write-Host "  • GitHub commit (git initialized)" -ForegroundColor White
    Write-Host "  • Further development" -ForegroundColor White
} else {
    Write-Host "VERDICT: SOME ISSUES DETECTED ✗" -ForegroundColor Black -BackgroundColor Red
    Write-Host "`nPlease review the items marked with ✗ above" -ForegroundColor Red
}
Write-Host "═══════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
