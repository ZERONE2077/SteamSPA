<#
.SYNOPSIS
    SteamSPA clean engine.
.DESCRIPTION
    Scans SteamSPA leftovers first, then asks for confirmation before cleanup.
#>
# NOTE: Chinese UI text is kept as plain UTF-8 for easy editing. Save this file as UTF-8 without BOM.
Clear-Host
$host.UI.RawUI.WindowTitle = 'STEAM SPA 清理工具'
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8


# NOTE:
# This script intentionally avoids a script-level param() block so it can be
# executed by `irm <raw-url> | iex` reliably. Arguments are parsed from $args
# for normal `-File` usage.
$NoBackup = $false
$NoPause = $false
$Only = @()
$Risk = @('low', 'medium', 'high')

for ($i = 0; $i -lt $args.Count; $i++) {
    switch -Regex ($args[$i]) {
        '^-NoBackup$' { $NoBackup = $true; continue }
        '^-NoPause$' { $NoPause = $true; continue }
        '^-Only$' {
            $i++
            if ($i -lt $args.Count) { $Only = @([string]$args[$i] -split ',') | Where-Object { $_ } }
            continue
        }
        '^-Risk$' {
            $i++
            if ($i -lt $args.Count) {
                $Risk = @([string]$args[$i] -split ',') | Where-Object { $_ -in @('low', 'medium', 'high') }
                if (-not $Risk -or $Risk.Count -eq 0) { $Risk = @('low', 'medium', 'high') }
            }
            continue
        }
    }
}

if ($PSVersionTable.PSVersion -lt [version]'5.1') {
    throw 'SteamSPA uninstall.ps1 requires Windows PowerShell 5.1 or later.'
}


$scriptRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptRoot) -and -not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
    $scriptRoot = Split-Path -Parent $PSCommandPath
}
if ([string]::IsNullOrWhiteSpace($scriptRoot) -and $MyInvocation.MyCommand -and -not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}
if ([string]::IsNullOrWhiteSpace($scriptRoot)) {
    $scriptRoot = Join-Path $env:TEMP 'SteamSPA'
}
if (-not (Test-Path -LiteralPath $scriptRoot)) {
    New-Item -ItemType Directory -Path $scriptRoot -Force | Out-Null
}
