$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $PSScriptRoot 'uninstall.ps1'
if (-not (Test-Path -LiteralPath $scriptPath)) {
    Write-Host "未找到脚本: $scriptPath" -ForegroundColor Red
    Read-Host '按 Enter 键退出'
    exit 1
}

$powerShellExe = Join-Path $PSHOME 'powershell.exe'
$argumentList = @(
    '-NoExit',
    '-NoProfile',
    '-ExecutionPolicy', 'Bypass',
    '-File', $scriptPath,
    '-Clean'
)

Start-Process -FilePath $powerShellExe -ArgumentList $argumentList -WorkingDirectory $PSScriptRoot -Verb RunAs
