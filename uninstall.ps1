#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Steam 破解工具卸载清理脚本
.DESCRIPTION
    清理以下脚本曾下载、注册、修改的所有痕迹：
      - 142785900.ps1
      - steam-run.com.ps1
      - cdks.run.ps1
      - steam.run.ps1
      - steam.icu.ps1
    包含：Steam 目录注入 DLL、注册表键值、AppData 目录、
          Defender 排除项、临时文件等
#>

Clear-Host
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'SilentlyContinue'

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Steam 破解工具 卸载 / 清理脚本"         -ForegroundColor Cyan
Write-Host "  覆盖脚本: 142785900 / steam-run.com"    -ForegroundColor Cyan
Write-Host "           cdks.run / steam.run / steam.icu" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ─── 辅助函数 ────────────────────────────────────────────────────────────────

function Remove-SafeItem {
    param([string]$Path, [switch]$Recurse)
    if (Test-Path $Path) {
        try {
            if ($Recurse) {
                Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
            }
            else {
                Remove-Item -Path $Path -Force -ErrorAction Stop
            }
            Write-Host "  [已删除] $Path" -ForegroundColor Green
            return $true
        }
        catch {
            Write-Host "  [失败]   $Path — $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
    else {
        Write-Host "  [不存在] $Path" -ForegroundColor DarkGray
        return $false
    }
}

function Remove-RegistryValue {
    param([string]$KeyPath, [string]$Name)
    if (Test-Path $KeyPath) {
        $prop = Get-ItemProperty -Path $KeyPath -Name $Name -ErrorAction SilentlyContinue
        if ($null -ne $prop) {
            try {
                Remove-ItemProperty -Path $KeyPath -Name $Name -Force -ErrorAction Stop
                Write-Host "  [已删除] 注册表值  $KeyPath\$Name" -ForegroundColor Green
            }
            catch {
                Write-Host "  [失败]   注册表值  $KeyPath\$Name — $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        else {
            Write-Host "  [不存在] 注册表值  $KeyPath\$Name" -ForegroundColor DarkGray
        }
    }
    else {
        Write-Host "  [不存在] 注册表键  $KeyPath" -ForegroundColor DarkGray
    }
}

# ─── 1. 获取 Steam 路径 ───────────────────────────────────────────────────────

Write-Host "[步骤 1] 定位 Steam 安装目录..." -ForegroundColor Yellow

$steamRegPath = 'HKCU:\Software\Valve\Steam'
$steamToolsRegPath = 'HKCU:\Software\Valve\Steamtools'
$steamPath = $null

try {
    $steamPath = (Get-ItemProperty -Path $steamRegPath -ErrorAction Stop).SteamPath
}
catch {}

if ([string]::IsNullOrWhiteSpace($steamPath) -or -not (Test-Path $steamPath -PathType Container)) {
    Write-Host "  [警告] 未找到 Steam 安装目录，将跳过 Steam 目录相关清理。" -ForegroundColor Yellow
    $steamPath = $null
}
else {
    Write-Host "  [找到] Steam 目录: $steamPath" -ForegroundColor Green
}
Write-Host ""

# ─── 2. 停止 Steam 进程 ──────────────────────────────────────────────────────

Write-Host "[步骤 2] 强制终止 Steam 进程..." -ForegroundColor Yellow

$steamProcs = Get-Process -Name "steam*" -ErrorAction SilentlyContinue
if ($steamProcs) {
    $steamProcs | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    # 如果仍在运行则用 taskkill
    if (Get-Process -Name "steam" -ErrorAction SilentlyContinue) {
        Start-Process cmd -ArgumentList "/c taskkill /f /im steam.exe" -WindowStyle Hidden -Wait
    }
    Write-Host "  [完成] Steam 进程已终止" -ForegroundColor Green
}
else {
    Write-Host "  [跳过] 未检测到运行中的 Steam 进程" -ForegroundColor DarkGray
}
Write-Host ""

# ─── 3. 清理 Steam 目录内的注入文件 ─────────────────────────────────────────

Write-Host "[步骤 3] 清理 Steam 目录内的注入 DLL 及配置文件..." -ForegroundColor Yellow

if ($steamPath) {
    # 所有脚本可能放入 Steam 根目录的文件
    $steamFiles = @(
        # 64 位注入 DLL (142785900 / steam-run.com / cdks.run / steam.run / steam.icu)
        "dwmapi.dll",
        "xinput1_4.dll",
        "xinput1_4.dll.old",
        "xinput1_4.log",
        "dwmapi.log",

        # 32 位注入 DLL (142785900 / steam-run.com)
        "hid.dll",
        "hid.log",
        "zlib1.dll",
        "zlib1.log",

        # 旧版残留 (steam.run / cdks.run / steam.icu)
        "version.dll",
        "user32.dll",
        "wtsapi32.dll",

        # Steam Beta 标志 / 配置
        "steam.cfg",
        "package\beta",

        # appdata.vdf (64 位路径)
        "config\appdata.vdf",
        # appdata.vdf (32 位路径)
        "appcache\appdata.vdf",
        # packageinfo (steam.icu)
        "appcache\packageinfo.vdf"
    )

    foreach ($f in $steamFiles) {
        $fullPath = Join-Path $steamPath $f
        Remove-SafeItem -Path $fullPath
    }
}
else {
    Write-Host "  [跳过] 无法确定 Steam 目录" -ForegroundColor DarkGray
}
Write-Host ""

# ─── 4. 清理注册表 HKCU:\Software\Valve\Steamtools ──────────────────────────

Write-Host "[步骤 4] 清理注册表 Steamtools 键..." -ForegroundColor Yellow

if (Test-Path $steamToolsRegPath) {
    # 先单独删除各脚本写入的具体值，再整体删除整个键
    $regValues = @(
        "packageinfo",    # 142785900 / steam-run.com
        "steamclient",    # 142785900 / steam-run.com
        "s",              # 142785900 / steam-run.com
        "c",              # 142785900 / steam-run.com
        "iscdkey",        # cdks.run / steam.run
        "ActivateUnlockMode",
        "AlwaysStayUnlocked",
        "notUnlockDepot"
    )
    foreach ($v in $regValues) {
        Remove-RegistryValue -KeyPath $steamToolsRegPath -Name $v
    }

    # 整体删除整个 Steamtools 键
    try {
        Remove-Item -Path $steamToolsRegPath -Recurse -Force -ErrorAction Stop
        Write-Host "  [已删除] 注册表键 $steamToolsRegPath" -ForegroundColor Green
    }
    catch {
        Write-Host "  [失败]   删除注册表键 $steamToolsRegPath — $($_.Exception.Message)" -ForegroundColor Red
    }
}
else {
    Write-Host "  [不存在] 注册表键 $steamToolsRegPath" -ForegroundColor DarkGray
}
Write-Host ""

# ─── 5. 清理 %APPDATA%\Stool 目录 ────────────────────────────────────────────

Write-Host "[步骤 5] 清理 AppData\Roaming\Stool 目录 (142785900 / steam-run.com)..." -ForegroundColor Yellow

$stoolDir = Join-Path $env:APPDATA "Stool"
Remove-SafeItem -Path $stoolDir -Recurse
Write-Host ""

# ─── 6. 清理 %LOCALAPPDATA%\Steam 目录 ───────────────────────────────────────

Write-Host "[步骤 6] 清理 LocalAppData\Steam 目录 (cdks.run / steam.run)..." -ForegroundColor Yellow

$localSteamDir = Join-Path $env:LOCALAPPDATA "steam"
if (Test-Path $localSteamDir) {
    Write-Host "  [警告] 发现 $localSteamDir" -ForegroundColor Yellow
    Write-Host "  该目录由 cdks.run / steam.run 创建，可能含临时数据。" -ForegroundColor Yellow
    $ans = Read-Host "  确认删除？输入 Y 确认，其他键跳过"
    if ($ans -eq 'Y' -or $ans -eq 'y') {
        Remove-SafeItem -Path $localSteamDir -Recurse
    }
    else {
        Write-Host "  [跳过] 保留 $localSteamDir" -ForegroundColor DarkGray
    }
}
else {
    Write-Host "  [不存在] $localSteamDir" -ForegroundColor DarkGray
}
Write-Host ""

# ─── 7. 清理 %LOCALAPPDATA%\Steam\localData.vdf ──────────────────────────────

Write-Host "[步骤 7] 清理 localData.vdf (steam.icu)..." -ForegroundColor Yellow

$localDataVdf = Join-Path $env:LOCALAPPDATA "Steam\localData.vdf"
Remove-SafeItem -Path $localDataVdf
Write-Host ""

# ─── 8. 清理 Tencent 缓存目录 ────────────────────────────────────────────────

Write-Host "[步骤 8] 清理 LocalAppData\Microsoft\Tencent 缓存 (cdks.run / steam.run)..." -ForegroundColor Yellow

$tencentCache = Join-Path $env:LOCALAPPDATA "Microsoft\Tencent"
Remove-SafeItem -Path $tencentCache -Recurse
Write-Host ""

# ─── 9. 清理临时脚本文件 ──────────────────────────────────────────────────────

Write-Host "[步骤 9] 清理临时脚本文件..." -ForegroundColor Yellow

$tempFiles = @(
    (Join-Path $env:USERPROFILE "get.ps1"),   # cdks.run / steam.run
    (Join-Path $PSScriptRoot   "a.ps1")       # 142785900 / steam-run.com
)
foreach ($f in $tempFiles) {
    Remove-SafeItem -Path $f
}
Write-Host ""

# ─── 10. 移除 Windows Defender 排除项 ────────────────────────────────────────

Write-Host "[步骤 10] 处理 Windows Defender 排除项..." -ForegroundColor Yellow
Write-Host "  (142785900 / steam-run.com / steam.icu 曾添加排除项)" -ForegroundColor DarkGray

$ans2 = Read-Host "  是否从 Defender 排除列表中移除 Steam 相关路径？(Y/其他键跳过)"
if ($ans2 -eq 'Y' -or $ans2 -eq 'y') {
    $stoolDir2 = Join-Path $env:APPDATA "Stool"
    try {
        if ($steamPath) {
            Remove-MpPreference -ExclusionPath $steamPath -ErrorAction SilentlyContinue
            Write-Host "  [已移除] 排除路径: $steamPath" -ForegroundColor Green
        }
        Remove-MpPreference -ExclusionPath $stoolDir2 -ErrorAction SilentlyContinue
        Write-Host "  [已移除] 排除路径: $stoolDir2" -ForegroundColor Green

        # steam.icu 只排除了路径，未排除扩展名，但 142785900 排除了 exe/dll 扩展名
        # 注意：移除扩展名排除可能影响系统其他软件，这里只移除 dll/exe 扩展名排除
        Remove-MpPreference -ExclusionExtension 'exe' -ErrorAction SilentlyContinue
        Remove-MpPreference -ExclusionExtension 'dll' -ErrorAction SilentlyContinue
        Write-Host "  [已移除] Defender 扩展名排除: exe、dll" -ForegroundColor Green
    }
    catch {
        Write-Host "  [失败]   移除 Defender 排除项: $($_.Exception.Message)" -ForegroundColor Red
    }
}
else {
    Write-Host "  [跳过] 保留 Defender 排除设置" -ForegroundColor DarkGray
}
Write-Host ""

# ─── 完成汇总 ─────────────────────────────────────────────────────────────────

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  清理完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "已覆盖清理范围：" -ForegroundColor Yellow
Write-Host "  ✔ Steam 目录注入 DLL（dwmapi / xinput1_4 / hid / zlib1 / version / user32 / wtsapi32）" -ForegroundColor Gray
Write-Host "  ✔ Steam 配置文件（steam.cfg / appdata.vdf / package\beta / packageinfo.vdf）" -ForegroundColor Gray
Write-Host "  ✔ 注册表键 HKCU:\Software\Valve\Steamtools" -ForegroundColor Gray
Write-Host "  ✔ %APPDATA%\Stool 工具目录" -ForegroundColor Gray
Write-Host "  ✔ %LOCALAPPDATA%\Steam\localData.vdf" -ForegroundColor Gray
Write-Host "  ✔ %LOCALAPPDATA%\Microsoft\Tencent 缓存" -ForegroundColor Gray
Write-Host "  ✔ 临时脚本文件（get.ps1 / a.ps1）" -ForegroundColor Gray
Write-Host ""
Write-Host "建议后续操作：" -ForegroundColor Yellow
Write-Host "  1. 在 Steam 中对游戏执行「验证游戏文件完整性」" -ForegroundColor Gray
Write-Host "  2. 重新启动 Steam 客户端" -ForegroundColor Gray
Write-Host "  3. 若 Steam 仍有异常，可考虑重新安装 Steam" -ForegroundColor Gray
Write-Host ""

Read-Host "按 Enter 键退出"
