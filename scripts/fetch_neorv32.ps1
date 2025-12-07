param(
    [string]$RepoUrl = "https://github.com/stnolting/neorv32.git",
    [string]$TargetDir = "$(Get-Item -Path .).FullName\rtl\neorv32"
)

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "git is required to fetch NEORV32."
}

if (Test-Path $TargetDir) {
    Write-Host "NEORV32 already present at $TargetDir"
    return
}

Write-Host "Cloning NEORV32 into $TargetDir"
& git clone --depth 1 $RepoUrl $TargetDir
