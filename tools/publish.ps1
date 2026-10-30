#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$Message = 'Update SteamSPA'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $root
$utf8 = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = $utf8
[Console]::OutputEncoding = $utf8

function Invoke-Step {
    param(
        [string]$Name,
        [scriptblock]$Command
    )

    Write-Host "==> $Name" -ForegroundColor Cyan
    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "$Name failed with exit code $LASTEXITCODE"
    }
}

Invoke-Step 'Build generated artifact' {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File '.\tools\build.ps1'
}

# 冒烟测试已包含：语法、生成物一致性、规则库、样本引用、沙盒删除、生成物只扫描运行。
Invoke-Step 'Run smoke tests' {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File '.\tests\SmokeTests.ps1'
}

# research/docs 和 research/samples 被 .gitignore 排除，git add 不会带上它们。
$publishPaths = @(
    'README.md',
    'uninstall.ps1',
    'data',
    'src',
    'tools',
    'tests',
    'research'
)
git add -- $publishPaths
if ($LASTEXITCODE -ne 0) {
    throw 'git add failed'
}

$staged = @(git diff --cached --name-only)
if ($staged.Count -eq 0) {
    Write-Host 'No tracked changes to publish.' -ForegroundColor Yellow
    exit 0
}

git commit -m $Message
if ($LASTEXITCODE -ne 0) {
    throw 'git commit failed'
}

git push origin main
if ($LASTEXITCODE -ne 0) {
    throw 'git push failed'
}

$localHead = (git rev-parse HEAD).Trim()
$remoteLine = (git ls-remote origin refs/heads/main).Trim()
if (-not $remoteLine.StartsWith($localHead)) {
    throw "remote main does not match local HEAD: $localHead"
}

$version = Get-Content -LiteralPath '.\data\version.json' -Raw -Encoding UTF8 | ConvertFrom-Json
$rawUrl = 'https://raw.githubusercontent.com/ZERONE2077/SteamSPA/main/uninstall.ps1?' + [guid]::NewGuid().ToString('N')
$response = Invoke-WebRequest -Uri $rawUrl -UseBasicParsing -Headers @{ 'Cache-Control' = 'no-cache' }
$rawText = [Text.Encoding]::UTF8.GetString($response.RawContentStream.ToArray()).TrimStart([char]0xFEFF)
if ($rawText -notmatch "SteamSPAReleaseVersion = '$([regex]::Escape([string]$version.version))'" -or
    $rawText -notmatch "SteamSPAUpdatedAt = '$([regex]::Escape([string]$version.updatedAt))'") {
    throw 'online uninstall.ps1 does not match version.json'
}

Write-Host ("Published {0} to origin/main." -f $localHead) -ForegroundColor Green
Write-Host ("Online version: {0} · {1}" -f $version.version, $version.updatedAt) -ForegroundColor Green
