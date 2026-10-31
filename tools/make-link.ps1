#requires -Version 5.1
# 生成对外分发的快捷方式。命令是明文：先把 uninstall.ps1 下载成文件，再运行这个文件。
# 不用 -EncodedCommand、不用 iex：这两种写法和木马的常见套路一样，容易被杀软报毒。
#   tools/make-link.ps1                 生成 "Steam Spa 清理工具.lnk"
#   tools/make-link.ps1 -Test           生成只扫描不清理的测试版
param([switch]$Test)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

# jsDelivr 官方节点放第一位：发布后刷新缓存（purge）就立即是新版。
# 第三方镜像（jsdmirror 等）刷新不了，可能返回长达一天的旧副本，只做备用。
$mirrors = @(
    'https://fastly.jsdelivr.net/gh/ZERONE2077/SteamSPA@main/uninstall.ps1'
    'https://cdn.jsdmirror.com/gh/ZERONE2077/SteamSPA@main/uninstall.ps1'
    'https://jsd.onmicrosoft.cn/gh/ZERONE2077/SteamSPA@main/uninstall.ps1'
    'https://raw.githubusercontent.com/ZERONE2077/SteamSPA/main/uninstall.ps1'
)
$run = if ($Test) { '& $f -ScanOnly' } else { '& $f' }
$command = @(
    "`$f = Join-Path `$env:TEMP 'SteamSPA.ps1'; `$ok = `$false; "
    "foreach (`$u in '" + ($mirrors -join "','") + "') {"
    " try { Invoke-WebRequest (`$u + '?' + [guid]::NewGuid().ToString('N')) -OutFile `$f -UseBasicParsing -TimeoutSec 20;"
    " if ((Get-Content `$f -Raw -Encoding UTF8) -match 'SteamSPA') { `$ok = `$true; break } } catch {} };"
    " if (`$ok) { $run } else { Write-Host '下载失败，请检查网络后重试。' -ForegroundColor Red; Read-Host '按回车退出' }"
) -join ''

$name = if ($Test) { 'Steam Spa 清理工具（测试-只扫描）.lnk' } else { 'Steam Spa 清理工具.lnk' }
$path = Join-Path $root $name
$shell = New-Object -ComObject WScript.Shell
$lnk = $shell.CreateShortcut($path)
$lnk.TargetPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$lnk.Arguments = '-NoProfile -ExecutionPolicy Bypass -Command "' + $command + '"'
$lnk.WorkingDirectory = '%TEMP%'
$lnk.Description = 'STEAM SPA 假入库清理工具（开源：github.com/ZERONE2077/SteamSPA）'
# 系统自带的"磁盘清理"扫帚图标，每台 Windows 都有。
$lnk.IconLocation = '%SystemRoot%\System32\cleanmgr.exe,0'
$lnk.Save()

Write-Host "已生成 $path" -ForegroundColor Green
Write-Host '命令（明文，可直接给用户看）：' -ForegroundColor DarkGray
Write-Host ('powershell ' + $lnk.Arguments)
