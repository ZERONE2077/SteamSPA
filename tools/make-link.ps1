#requires -Version 5.1
# 在仓库根目录生成三个快捷方式（*.lnk 不进仓库）：
#   Steam Spa 清理工具.lnk          对外分发：jsDelivr 官方节点优先，其次国内镜像，最后 GitHub
#   Steam Spa 清理工具（GitHub）.lnk  只从 GitHub 取 main 最新版，用来验证刚推送的内容
#   Steam Spa 清理工具（本地）.lnk    运行本仓库的 uninstall.ps1，发布前自测
# 命令是明文：先把 uninstall.ps1 下载成文件，再运行这个文件。
# 不用 -EncodedCommand、不用 iex：这两种写法和木马的常见套路一样，容易被杀软报毒。
# 都勾了"以管理员身份运行"；管理员窗口会先出现在老式控制台，脚本随即换到 Windows Terminal。

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

# jsDelivr 官方节点放第一位：publish.ps1 发布后会刷新它的缓存，立即是新版。
# 第三方镜像（jsdmirror 等）刷新不了，可能返回长达一天的旧副本，只做备用。
$github = 'https://raw.githubusercontent.com/ZERONE2077/SteamSPA/main/uninstall.ps1'
$mirrors = @(
    'https://fastly.jsdelivr.net/gh/ZERONE2077/SteamSPA@main/uninstall.ps1'
    'https://cdn.jsdmirror.com/gh/ZERONE2077/SteamSPA@main/uninstall.ps1'
    'https://jsd.onmicrosoft.cn/gh/ZERONE2077/SteamSPA@main/uninstall.ps1'
    $github
)

# 依次尝试地址（加随机参数避开缓存），下载成功就运行。
function Get-DownloadCommand {
    param([string[]]$Urls)
    return (
        "`$f = Join-Path `$env:TEMP 'SteamSPA.ps1'; `$ok = `$false; " +
        "foreach (`$u in '" + ($Urls -join "','") + "') {" +
        " try { Invoke-WebRequest (`$u + '?' + [guid]::NewGuid().ToString('N')) -OutFile `$f -UseBasicParsing -TimeoutSec 20;" +
        " if ((Get-Content `$f -Raw -Encoding UTF8) -match 'SteamSPA') { `$ok = `$true; break } } catch {} };" +
        " if (`$ok) { & `$f } else { Write-Host '下载失败，请检查网络后重试。' -ForegroundColor Red; Read-Host '按回车退出' }"
    )
}

# 图标都用系统自带的，每台 Windows 都有；三个各不相同，方便区分。
$links = @(
    @{ Name = 'Steam Spa 清理工具.lnk'; Args = '-Command "' + (Get-DownloadCommand $mirrors) + '"'
        Icon = '%SystemRoot%\System32\cleanmgr.exe,0' }     # 磁盘清理扫帚
    @{ Name = 'Steam Spa 清理工具（GitHub）.lnk'; Args = '-Command "' + (Get-DownloadCommand @($github)) + '"'
        Icon = '%SystemRoot%\System32\imageres.dll,101' }   # 绿色盾牌
    @{ Name = 'Steam Spa 清理工具（本地）.lnk'; Args = '-File "' + (Join-Path $root 'uninstall.ps1') + '"'
        Icon = '%SystemRoot%\System32\imageres.dll,49' }    # 回收站
)

$shell = New-Object -ComObject WScript.Shell
foreach ($item in $links) {
    $lnk = $shell.CreateShortcut((Join-Path $root $item.Name))
    $lnk.TargetPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $lnk.Arguments = '-NoProfile -ExecutionPolicy Bypass ' + $item.Args
    $lnk.WorkingDirectory = '%TEMP%'
    $lnk.Description = 'STEAM SPA 假入库清理工具（开源：github.com/ZERONE2077/SteamSPA）'
    $lnk.IconLocation = $item.Icon
    $lnk.Save()
    # 勾上"以管理员身份运行"：双击直接弹 UAC，点一次"是"就开始，不用用户再手动设置。
    # WScript.Shell 没有这个属性，直接改文件头 LinkFlags 的 RunAsUser 位（0x2000）。
    $file = Join-Path $root $item.Name
    $bytes = [IO.File]::ReadAllBytes($file)
    $bytes[0x15] = $bytes[0x15] -bor 0x20
    [IO.File]::WriteAllBytes($file, $bytes)
    Write-Host ('已生成 ' + $item.Name) -ForegroundColor Green
}
