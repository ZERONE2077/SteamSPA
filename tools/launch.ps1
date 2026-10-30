#requires -Version 5.1
# SteamSPA 测试启动器：给根目录的 .lnk 双击测试用。
#   -Source Local    运行本仓库的 uninstall.ps1（按文件方式运行）
#   -Source GitHub   从 raw.githubusercontent.com 取 main 分支最新版
#   -Source Mirror   从 jsDelivr 取：先问 GitHub API 拿最新 commit，再请求 @<sha>
#                    （@main 会被 CDN 缓存几个小时）；API 不通时退回 @main
# 远程版本按 irm | iex 的方式运行（不落盘、没有 $PSCommandPath）。
# 下载逻辑放在这个文件里而不是 .lnk 命令行里：命令行里直接"下载并执行"会被 Defender 判成木马。
# 其余参数（-ScanOnly、-Risk 等）原样透传给 uninstall.ps1。
# 不用 [Parameter()]：那会变成高级脚本，遇到不认识的 -ScanOnly 直接报错。
param([ValidateSet('Local', 'GitHub', 'Mirror')][string]$Source = 'Local')
$Rest = $args

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch {}
try { $Host.UI.RawUI.WindowTitle = "SteamSPA 测试 · $Source" } catch {}
$repo = 'ZERONE2077/SteamSPA'


function Get-Text {
    param([string]$Url)
    $r = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 30 -Headers @{ 'Cache-Control' = 'no-cache' }
    # jsDelivr 返回 application/octet-stream，5.1 会按 ISO-8859-1 解码，必须自己按 UTF-8 解。
    return [Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()).TrimStart([char]0xFEFF)
}

function Stop-WithMessage {
    param([string]$Message)
    Write-Host ''
    Write-Host ('  ' + $Message) -ForegroundColor Red
    Read-Host '  按回车退出' | Out-Null
    exit 1
}

if ($Source -eq 'Local') {
    $file = Join-Path (Split-Path -Parent $PSScriptRoot) 'uninstall.ps1'
    if (-not (Test-Path -LiteralPath $file)) { Stop-WithMessage "找不到 $file" }
    & $file @Rest
    exit $LASTEXITCODE
}

$urls = New-Object System.Collections.ArrayList
if ($Source -eq 'GitHub') {
    [void]$urls.Add("https://raw.githubusercontent.com/$repo/main/uninstall.ps1?" + [guid]::NewGuid().ToString('N'))
}
else {
    try {
        $sha = (Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/commits/main" -TimeoutSec 15 -Headers @{ 'User-Agent' = 'SteamSPA-launcher' }).sha
        if ($sha) { [void]$urls.Add("https://cdn.jsdelivr.net/gh/$repo@$sha/uninstall.ps1") }
    }
    catch {
        Write-Host '  GitHub API 不通，改用 @main（可能是几小时前的缓存版本）' -ForegroundColor Yellow
    }
    [void]$urls.Add("https://cdn.jsdelivr.net/gh/$repo@main/uninstall.ps1")
}

$text = $null
foreach ($url in $urls) {
    Write-Host "  下载 $url" -ForegroundColor DarkGray
    try {
        $candidate = Get-Text $url
        # 别把 CDN 错误页当脚本执行。
        if ($candidate.Length -gt 5000 -and $candidate.Contains('$SteamSPAReleaseVersion')) { $text = $candidate; break }
        Write-Host '  内容不像 SteamSPA 脚本，换下一个地址' -ForegroundColor Yellow
    }
    catch {
        Write-Host ('  失败: ' + $_.Exception.Message) -ForegroundColor Yellow
    }
}
if (-not $text) { Stop-WithMessage '所有地址都下载失败，请检查网络。' }

$version = [regex]::Match($text, "SteamSPAReleaseVersion = '([^']*)'").Groups[1].Value
$updated = [regex]::Match($text, "SteamSPAUpdatedAt = '([^']*)'").Groups[1].Value
Write-Host ("  已下载 v{0} · {1} · {2:N0} 字符，3 秒后运行..." -f $version, $updated, $text.Length) -ForegroundColor Green
Start-Sleep -Seconds 3
& ([scriptblock]::Create($text)) @Rest
