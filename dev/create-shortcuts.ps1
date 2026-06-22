#Requires -Version 5.1
<#
.SYNOPSIS
    Create SteamSPA shortcut files.
.DESCRIPTION
    Generates .lnk launchers for local, GitHub Raw, and Gitee Raw versions.
    Online launchers download uninstall.ps1 and targets.json to a temp folder before running.
#>
[CmdletBinding()]
param(
    [string]$OutputDirectory,
    [string]$LocalScriptPath,
    [string]$LocalTargetsPath,
    [string]$GitHubRawBaseUrl,
    [string]$GiteeRawBaseUrl,
    [switch]$Clean,
    [switch]$NoPause,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($scriptRoot)) {
    $scriptRoot = (Get-Location).Path
}

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $scriptRoot '..'
}

if ([string]::IsNullOrWhiteSpace($LocalScriptPath)) {
    $LocalScriptPath = Join-Path $scriptRoot '..\uninstall.ps1'
}

if ([string]::IsNullOrWhiteSpace($LocalTargetsPath)) {
    $LocalTargetsPath = Join-Path $scriptRoot '..\targets.json'
}

function Resolve-FullPath {
    param([string]$Path)

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }

    return [System.IO.Path]::GetFullPath((Join-Path (Get-Location).Path $Path))
}

function ConvertTo-EncodedCommand {
    param([string]$Command)

    $bytes = [System.Text.Encoding]::Unicode.GetBytes($Command)
    return [Convert]::ToBase64String($bytes)
}

function Join-Url {
    param([string]$BaseUrl, [string]$Child)

    return ($BaseUrl.TrimEnd('/') + '/' + $Child.TrimStart('/'))
}

function New-ElevatedEncodedArguments {
    param([string]$ElevatedCommand)

    $encoded = ConvertTo-EncodedCommand -Command $ElevatedCommand
    $launcher = "Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -EncodedCommand $encoded'"
    return '-NoProfile -ExecutionPolicy Bypass -EncodedCommand ' + (ConvertTo-EncodedCommand -Command $launcher)
}

function New-Shortcut {
    param(
        [string]$Path,
        [string]$Arguments,
        [string]$Description,
        [string]$WorkingDirectory
    )

    if ((Test-Path -LiteralPath $Path) -and -not $Force) {
        Write-Host "跳过已存在: $Path" -ForegroundColor DarkGray
        return
    }

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($Path)
    $shortcut.TargetPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $shortcut.Arguments = $Arguments
    $shortcut.WorkingDirectory = $WorkingDirectory
    $shortcut.Description = $Description
    $shortcut.IconLocation = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe,0'
    $shortcut.Save()

    Write-Host "已生成: $Path" -ForegroundColor Green
}

function New-LocalCommand {
    param([string]$ScriptPath, [string]$TargetsPath)

    $parts = @(
        '&',
        "'$ScriptPath'",
        '-TargetsPath',
        "'$TargetsPath'"
    )

    if ($Clean) { $parts += '-Clean' }
    if ($NoPause) { $parts += '-NoPause' }

    return ($parts -join ' ')
}

function New-OnlineCommand {
    param([string]$BaseUrl, [string]$SourceName)

    $scriptUrl = Join-Url -BaseUrl $BaseUrl -Child 'uninstall.ps1'
    $targetsUrl = Join-Url -BaseUrl $BaseUrl -Child 'targets.json'
    $tempRoot = "`$root = Join-Path `$env:TEMP 'SteamSPA\$SourceName'"
    $common = @(
        "$tempRoot",
        "New-Item -ItemType Directory -Path `$root -Force | Out-Null",
        "`$script = Join-Path `$root 'uninstall.ps1'",
        "`$targets = Join-Path `$root 'targets.json'",
        "Invoke-WebRequest -UseBasicParsing -Uri '$scriptUrl' -OutFile `$script",
        "Invoke-WebRequest -UseBasicParsing -Uri '$targetsUrl' -OutFile `$targets"
    )

    $run = "& `$script -TargetsPath `$targets"
    if ($Clean) { $run += ' -Clean' }
    if ($NoPause) { $run += ' -NoPause' }
    $common += $run

    return ($common -join '; ')
}

$OutputDirectory = Resolve-FullPath -Path $OutputDirectory
$LocalScriptPath = Resolve-FullPath -Path $LocalScriptPath
$LocalTargetsPath = Resolve-FullPath -Path $LocalTargetsPath

if (-not (Test-Path -LiteralPath $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}

if (-not (Test-Path -LiteralPath $LocalScriptPath -PathType Leaf)) {
    throw "本地脚本不存在: $LocalScriptPath"
}

if (-not (Test-Path -LiteralPath $LocalTargetsPath -PathType Leaf)) {
    throw "本地清单不存在: $LocalTargetsPath"
}

$localArguments = New-ElevatedEncodedArguments -ElevatedCommand (New-LocalCommand -ScriptPath $LocalScriptPath -TargetsPath $LocalTargetsPath)
New-Shortcut `
    -Path (Join-Path $OutputDirectory 'SteamSPA-local.lnk') `
    -Arguments $localArguments `
    -Description 'SteamSPA local cleanup launcher' `
    -WorkingDirectory (Split-Path -Parent $LocalScriptPath)

if ($GitHubRawBaseUrl) {
    $githubArguments = New-ElevatedEncodedArguments -ElevatedCommand (New-OnlineCommand -BaseUrl $GitHubRawBaseUrl -SourceName 'github')
    New-Shortcut `
        -Path (Join-Path $OutputDirectory 'SteamSPA-github-raw.lnk') `
        -Arguments $githubArguments `
        -Description 'SteamSPA GitHub Raw cleanup launcher' `
        -WorkingDirectory $OutputDirectory
}

if ($GiteeRawBaseUrl) {
    $giteeArguments = New-ElevatedEncodedArguments -ElevatedCommand (New-OnlineCommand -BaseUrl $GiteeRawBaseUrl -SourceName 'gitee')
    New-Shortcut `
        -Path (Join-Path $OutputDirectory 'SteamSPA-gitee-raw.lnk') `
        -Arguments $giteeArguments `
        -Description 'SteamSPA Gitee Raw cleanup launcher' `
        -WorkingDirectory $OutputDirectory
}