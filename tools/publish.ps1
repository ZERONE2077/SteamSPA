#requires -Version 5.1
# 发布：更新日期 → 冒烟测试 → 提交推送 → 核对线上版本。
#   tools/publish.ps1 -Message "rules: 新增 xxx"
[CmdletBinding()]
param([string]$Message = 'Update SteamSPA')

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $root
$utf8 = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = $utf8
[Console]::OutputEncoding = $utf8
$script = Join-Path $root 'uninstall.ps1'

# 把脚本里的更新日期改成今天（启动时显示给用户）。
$utf8Bom = New-Object System.Text.UTF8Encoding($true)
$text = [IO.File]::ReadAllText($script, $utf8Bom)
$today = (Get-Date).ToString('yyyy-MM-dd')
$text = [regex]::Replace($text, "(?m)^\`$SteamSPAUpdatedAt = '[^']*'", "`$SteamSPAUpdatedAt = '$today'")
[IO.File]::WriteAllText($script, $text, $utf8Bom)
$version = [regex]::Match($text, "SteamSPAReleaseVersion = '([^']*)'").Groups[1].Value

Write-Host '==> 冒烟测试' -ForegroundColor Cyan
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File '.\tests\SmokeTests.ps1'
if ($LASTEXITCODE -ne 0) { throw '冒烟测试失败，未发布' }

git add -A
if (@(git diff --cached --name-only).Count -eq 0) { Write-Host '没有改动需要发布。' -ForegroundColor Yellow; exit 0 }
git commit -m $Message
if ($LASTEXITCODE -ne 0) { throw 'git commit 失败' }
git push origin main
if ($LASTEXITCODE -ne 0) { throw 'git push 失败' }

$head = (git rev-parse HEAD).Trim()
if (-not ((git ls-remote origin refs/heads/main).Trim().StartsWith($head))) { throw "远端 main 与本地 $head 不一致" }

# 刷新 jsDelivr 官方节点的 @main 缓存，快捷方式第一个用的就是它。
try { Invoke-RestMethod -UseBasicParsing -TimeoutSec 30 'https://purge.jsdelivr.net/gh/ZERONE2077/SteamSPA@main/uninstall.ps1' | Out-Null; Write-Host '已刷新 jsDelivr 缓存' -ForegroundColor DarkGray }
catch { Write-Host ('jsDelivr 缓存刷新失败：' + $_.Exception.Message) -ForegroundColor Yellow }

$raw = Invoke-WebRequest -UseBasicParsing -Headers @{ 'Cache-Control' = 'no-cache' } `
    -Uri ('https://raw.githubusercontent.com/ZERONE2077/SteamSPA/main/uninstall.ps1?' + [guid]::NewGuid().ToString('N'))
$online = [Text.Encoding]::UTF8.GetString($raw.RawContentStream.ToArray())
if ($online -notmatch "SteamSPAUpdatedAt = '$today'") { throw '线上 uninstall.ps1 还不是这次的版本' }

Write-Host ("已发布 v{0} · {1} ({2})" -f $version, $today, $head.Substring(0, 7)) -ForegroundColor Green
Write-Host '第三方镜像（jsdmirror 等）刷新不了，可能一天内还是旧版；快捷方式优先用 jsDelivr 官方节点。' -ForegroundColor DarkGray
