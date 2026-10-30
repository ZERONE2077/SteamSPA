#requires -Version 5.1
# 把 src/*.ps1 + data/rules.json + data/version.json 拼成唯一分发产物 uninstall.ps1。
#   tools/build.ps1          生成（并把 version.json 的 updatedAt 改成今天）
#   tools/build.ps1 -Check   只检查 uninstall.ps1 是否与源码一致
[CmdletBinding()]
param([switch]$Check, [string]$OutputPath)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if (-not $OutputPath) { $OutputPath = Join-Path $root 'uninstall.ps1' }
$rulesPath = Join-Path $root 'data\rules.json'
$versionPath = Join-Path $root 'data\version.json'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
# 带 BOM：Windows PowerShell 5.1 读无 BOM 脚本会按 ANSI 代码页解码，中文会乱码。
$utf8Bom = New-Object System.Text.UTF8Encoding($true)

$rulesText = [IO.File]::ReadAllText($rulesPath, $utf8NoBom).TrimStart([char]0xFEFF).TrimEnd()
$rules = $rulesText | ConvertFrom-Json
if (@($rules.rules).Count -eq 0) { throw 'rules.json 里没有规则' }
if ($rulesText -match "(?m)^'@") { throw "rules.json 里出现了行首 '@，会截断内嵌 here-string" }

$versionText = [IO.File]::ReadAllText($versionPath, $utf8NoBom)
$version = $versionText | ConvertFrom-Json
if (-not $version.version -or -not $version.updatedAt) { throw 'version.json 缺少 version 或 updatedAt' }
if (-not $Check) {
    $today = (Get-Date).ToString('yyyy-MM-dd')
    if ($version.updatedAt -ne $today) {
        $versionText = [regex]::Replace($versionText, '("updatedAt"\s*:\s*")[^"]*(")', '${1}' + $today + '${2}')
        [IO.File]::WriteAllText($versionPath, $versionText, $utf8NoBom)
        $version.updatedAt = $today
    }
}

$modules = @(Get-ChildItem -LiteralPath (Join-Path $root 'src') -Filter '*.ps1' | Sort-Object Name)
if ($modules.Count -eq 0) { throw 'src 目录为空' }

$nl = "`r`n"
$sb = New-Object System.Text.StringBuilder
[void]$sb.Append('# SteamSPA · STEAM 假入库残留清理工具' + $nl)
[void]$sb.Append('# 生成文件，请勿手改。源码在 src/，规则在 data/rules.json，用 tools/build.ps1 生成。' + $nl)
[void]$sb.Append('# 整个程序包在 & { } 里运行：irm | iex 时不会在用户会话里留下函数和变量。' + $nl)
[void]$sb.Append('& {' + $nl)
[void]$sb.Append("`$SteamSPAReleaseVersion = '" + ([string]$version.version).Replace("'", "''") + "'" + $nl)
[void]$sb.Append("`$SteamSPAUpdatedAt = '" + ([string]$version.updatedAt).Replace("'", "''") + "'" + $nl + $nl)
[void]$sb.Append('# 内嵌规则库，来源：data/rules.json' + $nl)
[void]$sb.Append("`$EmbeddedTargetsJson = @'" + $nl + $rulesText + $nl + "'@" + $nl + $nl)
foreach ($module in $modules) {
    $text = [IO.File]::ReadAllText($module.FullName, $utf8NoBom).TrimStart([char]0xFEFF).Trim()
    [void]$sb.Append($text + $nl + $nl)
}
[void]$sb.Append('} @args' + $nl)
$content = $sb.ToString() -replace "(?<!`r)`n", $nl

if ($Check) {
    if (-not (Test-Path -LiteralPath $OutputPath)) { Write-Error 'uninstall.ps1 不存在'; exit 1 }
    if ([IO.File]::ReadAllText($OutputPath, $utf8Bom) -ne $content) { Write-Error 'uninstall.ps1 与源码不一致，请运行 tools/build.ps1'; exit 1 }
    Write-Host 'SteamSPA build is up to date.'
    exit 0
}

[IO.File]::WriteAllText($OutputPath, $content, $utf8Bom)
Write-Host ('Built {0} ({1:N0} bytes, {2} modules, {3} rules)' -f $OutputPath, (Get-Item -LiteralPath $OutputPath).Length, $modules.Count, @($rules.rules).Count)
