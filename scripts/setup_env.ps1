<#
PowerShell helper to bootstrap the LiteX/SNN development environment on Windows with WSL integration.
#>

param(
    [string]$VivadoPath = "C:\\Xilinx\\Vivado\\2023.1",
    [string]$WslDistro = "Ubuntu-22.04"
)

Write-Host "Configuring environment for LiteX SNN project..."

if (-Not (Test-Path $VivadoPath)) {
    Write-Warning "Vivado path '$VivadoPath' not found. Update the -VivadoPath parameter."
}

$env:LITEX_VIVADO_PATH = Join-Path $VivadoPath "bin"
Write-Host "Set LITEX_VIVADO_PATH to $env:LITEX_VIVADO_PATH"

if (Get-Command wsl.exe -ErrorAction SilentlyContinue) {
    Write-Host "Ensuring WSL distro '$WslDistro' is available..."
    $distroList = wsl.exe --list --quiet
    if ($distroList -notcontains $WslDistro) {
        Write-Warning "WSL distro '$WslDistro' not installed. Install via 'wsl --install -d Ubuntu-22.04'."
    }
} else {
    Write-Warning "WSL is not enabled. Enable via 'wsl --install'."
}

Write-Host "Reminder: run scripts/setup_env.sh inside WSL to install toolchains."
