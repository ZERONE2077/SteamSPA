<#
.SYNOPSIS
    SteamSPA clean engine.
.DESCRIPTION
    Scans SteamSPA leftovers first, then asks for confirmation before cleanup.
#>
# NOTE: Chinese UI text is kept as UTF-8. The generated uninstall.ps1 uses a BOM
# so Windows PowerShell 5.1 reads it correctly on non-UTF-8 Windows code pages.
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

$SteamSPAReleaseVersion = '3.2'
$SteamSPAUpdatedAt = '2026-10-18'

# Embedded rule database. Source of truth: data/rules.json
$EmbeddedTargetsJson = @'
{
    "$schema": "./rules.schema.json",
    "version": 1,
    "meta": {
        "project": "SteamSPA",
        "description": "STEAM 假入库残留清理清单。每条规则描述一个来源脚本所留下的痕迹。"
    },
    "rules": [
        {
            "id": "steam-inject-dlls",
            "title": "STEAM 目录注入 DLL",
            "sources": [
                "research/samples/steam-run.com/142785900.001.ps1",
                "research/samples/steam-run.com/steam-run.com.001.ps1",
                "research/samples/steam-run.com/steam-run.com.002.ps1",
                "research/samples/steam-run.com/steam-run.com.003.ps1",
                "research/samples/steam-run.com/steam-run.com.004.ps1",
                "research/samples/steam.run/cdks.run.001.ps1",
                "research/samples/steam.run/steam.run.001.ps1",
                "research/samples/steam.run/steam.run.002.ps1",
                "research/samples/steam.work/steam.icu.001.ps1",
                "research/samples/steam-run.com/steamcdkey.cn.001.ps1",
                "research/samples/139.196.146.200/139.196.146.200.ps1",
                "research/samples/139.196.146.200/2026-10-18/139.196.146.200.ps1"
            ],
            "enabled": true,
            "risk": "low",
            "actions": [
                {
                    "type": "file",
                    "path": "${SteamPath}\\dwmapi.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\xinput1_4.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\xinput1_4"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\xinput1_4.dll.old"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\xinput1_4.log"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\xinput1_42.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\xinput1_43.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\dwmapi.log"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\dwmapi1.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\dwmapi2.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\dwmapi3.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\hid.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\hid.vdf"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\hid.log"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\zlib1.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\zlib1.vdf"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\zlib1.txt"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\zlib1.log"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\version.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\user32.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\User32.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\User32.vdf"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\wtsapi32.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\simulator.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\steam_api.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\Sdll.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\video.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\CefResource\\locales\\ff\\core.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\CefResource\\locales\\ff\\dwmapi.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\CefResource\\locales\\ff\\hid.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\CefResource\\locales\\ff\\xinput1_4.dll"
                }
            ]
        },
        {
            "id": "sample-47-100-121-251",
            "title": "Unialls 假入库家族残留 (需确认)",
            "sources": [
                "research/samples/47.100.121.251/47.100.121.251.ps1",
                "research/samples/47.98.148.132/47.98.148.132.ps1",
                "research/samples/vfc88.cn/vfc88.cn.001.ps1",
                "research/samples/vfc88.cn/ss.vfc77.cn.001.ps1",
                "research/samples/139.196.146.200/139.196.146.200.ps1",
                "research/samples/139.196.146.200/2026-10-18/139.196.146.200.ps1"
            ],
            "enabled": true,
            "risk": "high",
            "confirm": true,
            "actions": [
                {
                    "type": "file",
                    "path": "${SteamPath}\\core.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\7z.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\versions.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\cons"
                },
                {
                    "type": "file",
                    "path": "C:\\tmp\\AppData\\LocalLow\\Unialls",
                    "recurse": true
                },
                {
                    "type": "registry-value",
                    "path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\System",
                    "name": "DisableRegistryTools"
                },
                {
                    "type": "registry-value",
                    "path": "HKLM:\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\System",
                    "name": "DisableRegistryTools"
                },
                {
                    "type": "defender-exclusion-path",
                    "path": "${SteamPath}\\core.dll"
                },
                {
                    "type": "defender-exclusion-path",
                    "path": "${SteamPath}\\versions.dll"
                },
                {
                    "type": "defender-exclusion-path",
                    "path": "${SteamPath}\\cons"
                },
                {
                    "type": "defender-exclusion-path",
                    "path": "C:\\tmp\\AppData\\LocalLow\\Unialls"
                },
                {
                    "type": "defender-exclusion-path",
                    "path": "C:\\Windows\\Temp"
                }
            ]
        },
        {
            "id": "unialls-sdko-loader",
            "title": "Unialls sdko 假入库加载器 (需确认)",
            "sources": [
                "research/samples/139.196.146.200/139.196.146.200.ps1",
                "research/samples/139.196.146.200/2026-10-18/139.196.146.200.ps1"
            ],
            "enabled": true,
            "risk": "high",
            "confirm": true,
            "actions": [
                {
                    "type": "file",
                    "path": "${SteamPath}\\sdko.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\core.exe"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\bin\\dwmapi.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\bin\\SdkoInjector.exe"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\.cef-enable-remote-debugging"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\SdkoInjector.log"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\bin\\SdkoInjector.log"
                }
            ]
        },
        {
            "id": "steam-config-files",
            "title": "STEAM 配置文件 / Beta 标志 / appdata 缓存",
            "sources": [
                "research/samples/steam-run.com/142785900.001.ps1",
                "research/samples/steam-run.com/steam-run.com.001.ps1",
                "research/samples/steam-run.com/steam-run.com.002.ps1",
                "research/samples/steam-run.com/steam-run.com.003.ps1",
                "research/samples/steam-run.com/steam-run.com.004.ps1",
                "research/samples/steam.work/steam.icu.001.ps1",
                "research/samples/139.196.146.200/139.196.146.200.ps1",
                "research/samples/139.196.146.200/2026-10-18/139.196.146.200.ps1"
            ],
            "enabled": true,
            "risk": "low",
            "actions": [
                {
                    "type": "file",
                    "path": "${SteamPath}\\steam.cfg"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\package\\beta"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\config\\appdata.vdf"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\appcache\\appdata.vdf"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\appcache\\appdata64.vdf"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\appdata.vdf"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\appdata64.vdf"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\appdata64.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\appcache\\packageinfo.vdf"
                }
            ]
        },
        {
            "id": "registry-steamtools",
            "title": "注册表 Steamtools / SteamTools 键 (HKCU + HKLM)",
            "sources": [
                "research/samples/steam-run.com/142785900.001.ps1",
                "research/samples/steam-run.com/steam-run.com.001.ps1",
                "research/samples/steam-run.com/steam-run.com.002.ps1",
                "research/samples/steam-run.com/steam-run.com.003.ps1",
                "research/samples/steam-run.com/steam-run.com.004.ps1",
                "research/samples/steam.run/cdks.run.001.ps1",
                "research/samples/steam.run/steam.run.001.ps1",
                "research/samples/steam.run/steam.run.002.ps1",
                "research/samples/steamcn.cc/steamcn.cc.2026-09-30.ps1"
            ],
            "enabled": true,
            "risk": "low",
            "actions": [
                {
                    "type": "registry-value",
                    "path": "HKCU:\\Software\\Valve\\Steamtools",
                    "name": "packageinfo"
                },
                {
                    "type": "registry-value",
                    "path": "HKCU:\\Software\\Valve\\Steamtools",
                    "name": "steamclient"
                },
                {
                    "type": "registry-value",
                    "path": "HKCU:\\Software\\Valve\\Steamtools",
                    "name": "s"
                },
                {
                    "type": "registry-value",
                    "path": "HKCU:\\Software\\Valve\\Steamtools",
                    "name": "c"
                },
                {
                    "type": "registry-value",
                    "path": "HKCU:\\Software\\Valve\\Steamtools",
                    "name": "iscdkey"
                },
                {
                    "type": "registry-value",
                    "path": "HKCU:\\Software\\Valve\\Steamtools",
                    "name": "ActivateUnlockMode"
                },
                {
                    "type": "registry-value",
                    "path": "HKCU:\\Software\\Valve\\Steamtools",
                    "name": "AlwaysStayUnlocked"
                },
                {
                    "type": "registry-value",
                    "path": "HKCU:\\Software\\Valve\\Steamtools",
                    "name": "notUnlockDepot"
                },
                {
                    "type": "registry-key",
                    "path": "HKCU:\\Software\\Valve\\Steamtools",
                    "recurse": true
                },
                {
                    "type": "registry-key",
                    "path": "HKCU:\\Software\\SteamTools",
                    "recurse": true
                },
                {
                    "type": "registry-key",
                    "path": "HKLM:\\Software\\SteamTools",
                    "recurse": true
                },
                {
                    "type": "registry-key",
                    "path": "HKLM:\\Software\\Valve\\Steamtools",
                    "recurse": true
                }
            ]
        },
        {
            "id": "appdata-stool",
            "title": "%APPDATA%\\Stool 工具目录",
            "sources": [
                "research/samples/steam-run.com/142785900.001.ps1",
                "research/samples/steam-run.com/steam-run.com.001.ps1",
                "research/samples/steam-run.com/steam-run.com.002.ps1",
                "research/samples/steam-run.com/steam-run.com.003.ps1",
                "research/samples/steam-run.com/steam-run.com.004.ps1",
                "https://gitee.com/mrsiyecao/powershell2"
            ],
            "enabled": true,
            "risk": "low",
            "actions": [
                {
                    "type": "file",
                    "path": "${APPDATA}\\Stool",
                    "recurse": true
                }
            ]
        },
        {
            "id": "localappdata-steam",
            "title": "%LOCALAPPDATA%\\Steam 客户端缓存目录 (默认禁用，避免登录/启动异常)",
            "sources": [
                "research/samples/steam.run/cdks.run.001.ps1",
                "research/samples/steam.run/steam.run.001.ps1",
                "research/samples/steam.run/steam.run.002.ps1"
            ],
            "enabled": false,
            "risk": "medium",
            "confirm": true,
            "actions": [
                {
                    "type": "file",
                    "path": "${LOCALAPPDATA}\\steam",
                    "recurse": true
                }
            ]
        },
        {
            "id": "localdata-vdf",
            "title": "%LOCALAPPDATA%\\Steam\\localData.vdf",
            "sources": [
                "research/samples/steam.work/steam.icu.001.ps1"
            ],
            "enabled": true,
            "risk": "low",
            "actions": [
                {
                    "type": "file",
                    "path": "${LOCALAPPDATA}\\Steam\\localData.vdf"
                }
            ]
        },
        {
            "id": "tencent-cache",
            "title": "%LOCALAPPDATA%\\Microsoft\\Tencent 缓存",
            "sources": [
                "research/samples/steam.run/cdks.run.001.ps1",
                "research/samples/steam.run/steam.run.001.ps1",
                "research/samples/steam.run/steam.run.002.ps1",
                "research/samples/139.196.146.200/139.196.146.200.ps1",
                "research/samples/139.196.146.200/2026-10-18/139.196.146.200.ps1"
            ],
            "enabled": true,
            "risk": "medium",
            "actions": [
                {
                    "type": "file",
                    "path": "${LOCALAPPDATA}\\Microsoft\\Tencent",
                    "recurse": true
                }
            ]
        },
        {
            "id": "temp-scripts",
            "title": "下载用的临时脚本",
            "sources": [
                "research/samples/steam-run.com/142785900.001.ps1",
                "research/samples/steam-run.com/steam-run.com.001.ps1",
                "research/samples/steam-run.com/steam-run.com.002.ps1",
                "research/samples/steam-run.com/steam-run.com.003.ps1",
                "research/samples/steam-run.com/steam-run.com.004.ps1",
                "research/samples/steam.run/cdks.run.001.ps1",
                "research/samples/steam.run/steam.run.001.ps1",
                "research/samples/steam.run/steam.run.002.ps1",
                "research/samples/cdk.ruku.run/cdk.ruku.run.ps1"
            ],
            "enabled": true,
            "risk": "low",
            "actions": [
                {
                    "type": "file",
                    "path": "${USERPROFILE}\\get.ps1"
                },
                {
                    "type": "file",
                    "path": "${ScriptRoot}\\a.ps1"
                },
                {
                    "type": "file",
                    "path": "${TEMP}\\1.ps1"
                }
            ]
        },
        {
            "id": "defender-exclusions",
            "title": "Windows Defender 排除项 (需确认)",
            "sources": [
                "research/samples/steam-run.com/142785900.001.ps1",
                "research/samples/steam-run.com/steam-run.com.001.ps1",
                "research/samples/steam-run.com/steam-run.com.002.ps1",
                "research/samples/steam-run.com/steam-run.com.003.ps1",
                "research/samples/steam-run.com/steam-run.com.004.ps1",
                "research/samples/steam.work/steam.icu.001.ps1",
                "research/samples/cdk.ruku.run/a.ps1",
                "research/samples/cdk.ruku.run/cdk.ruku.run.ps1",
                "research/samples/steam.run/cdks.run.001.ps1",
                "research/samples/steam.run/steam.run.001.ps1",
                "research/samples/steam.run/steam.run.002.ps1",
                "research/samples/steam-run.com/steamcdkey.cn.001.ps1",
                "research/samples/steamcn.cc/steamcn.cc.001.ps1",
                "research/samples/steamcn.cc/steamcn.cc.2026-09-30.ps1",
                "research/samples/139.196.146.200/139.196.146.200.ps1",
                "research/samples/139.196.146.200/2026-10-18/139.196.146.200.ps1"
            ],
            "enabled": true,
            "risk": "high",
            "confirm": true,
            "actions": [
                {
                    "type": "defender-exclusion-path",
                    "path": "${SteamPath}"
                },
                {
                    "type": "defender-exclusion-path",
                    "path": "${SteamPath}\\dwmapi.dll"
                },
                {
                    "type": "defender-exclusion-path",
                    "path": "${SteamPath}\\hid.dll"
                },
                {
                    "type": "defender-exclusion-path",
                    "path": "${APPDATA}\\Stool"
                },
                {
                    "type": "defender-exclusion-extension",
                    "name": "exe"
                },
                {
                    "type": "defender-exclusion-extension",
                    "name": "dll"
                },
                {
                    "name": ".exe",
                    "type": "defender-exclusion-extension"
                },
                {
                    "name": ".dll",
                    "type": "defender-exclusion-extension"
                },
                {
                    "type": "defender-exclusion-path",
                    "path": "${SteamPath}\\xinput1_4.dll"
                },
                {
                    "type": "defender-exclusion-path",
                    "path": "${SteamPath}\\dwmapi.dll"
                },
                {
                    "type": "defender-exclusion-path",
                    "path": "${SteamPath}\\hid.dll"
                },
                {
                    "type": "defender-exclusion-path",
                    "path": "${SteamPath}\\steamcdk.exe"
                },
                {
                    "type": "defender-exclusion-path",
                    "path": "${SteamPath}\\SDL3_voder.dll"
                },
                {
                    "type": "defender-exclusion-path",
                    "path": "${TEMP}\\sdl3_setup"
                },
                {
                    "type": "defender-exclusion-extension",
                    "name": "bin"
                },
                {
                    "type": "defender-exclusion-process",
                    "name": "Steam.exe"
                },
                {
                    "type": "defender-exclusion-process",
                    "name": "curl.exe"
                },
                {
                    "type": "defender-exclusion-path",
                    "path": "${SteamPath}\\sdko.dll"
                },
                {
                    "type": "defender-exclusion-path",
                    "path": "C:\\tmp\\AppData\\LocalLow\\Unialls\\Temp\\Download\\steams.zip"
                }
            ]
        },
        {
            "id": "smartscreen-ci-policy-registry",
            "title": "SmartScreen / CI Policy 相关注册表改动 (需确认)",
            "sources": [
                "research/samples/cdk.ruku.run/a.ps1",
                "research/samples/cdk.ruku.run/cdk.ruku.run.ps1"
            ],
            "enabled": true,
            "risk": "high",
            "confirm": true,
            "actions": [
                {
                    "type": "registry-value",
                    "path": "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\CI\\Policy",
                    "name": "VerifiedAndReputablePolicyState"
                },
                {
                    "type": "registry-value",
                    "path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer",
                    "name": "SmartScreenEnabled"
                },
                {
                    "type": "registry-value",
                    "path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\System",
                    "name": "EnableSmartScreen"
                },
                {
                    "type": "registry-value",
                    "path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows Defender\\SmartScreen",
                    "name": "ConfigureAppInstallControl"
                },
                {
                    "type": "registry-value",
                    "path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows Defender\\SmartScreen",
                    "name": "ConfigureAppInstallControlEnabled"
                },
                {
                    "type": "registry-value",
                    "path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows Defender\\SmartScreen",
                    "name": "EnableSmartScreenInShell"
                }
            ]
        },
        {
            "id": "startup-steamauthdaemon",
            "title": "启动项 SteamAuthDaemon (需确认)",
            "sources": [
                "research/samples/cdk.ruku.run/a.ps1",
                "research/samples/cdk.ruku.run/cdk.ruku.run.ps1"
            ],
            "enabled": true,
            "risk": "medium",
            "confirm": true,
            "actions": [
                {
                    "type": "registry-value",
                    "path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Run",
                    "name": "SteamAuthDaemon"
                }
            ]
        },
        {
            "id": "process-steam-auth",
            "title": "steam_auth 进程 (需确认)",
            "sources": [
                "research/samples/cdk.ruku.run/a.ps1",
                "research/samples/cdk.ruku.run/cdk.ruku.run.ps1"
            ],
            "enabled": true,
            "risk": "medium",
            "confirm": true,
            "actions": [
                {
                    "type": "process",
                    "name": "steam_auth"
                }
            ]
        },
        {
            "id": "downloaded-steamcdk-exe",
            "title": "STEAM 目录下载的 steamcdk.exe (需确认)",
            "sources": [
                "research/samples/cdk.ruku.run/a.ps1",
                "research/samples/cdk.ruku.run/cdk.ruku.run.ps1"
            ],
            "enabled": true,
            "risk": "high",
            "confirm": true,
            "actions": [
                {
                    "type": "file",
                    "path": "${SteamPath}\\steamcdk.exe"
                }
            ]
        },
        {
            "id": "opensteamtool-root-files",
            "title": "OpenSteamTool 根目录文件",
            "sources": [
                "https://github.com/OpenSteam001/OpenSteamTool",
                "research/samples/139.196.146.200/139.196.146.200.ps1",
                "research/samples/139.196.146.200/2026-10-18/139.196.146.200.ps1"
            ],
            "enabled": true,
            "risk": "low",
            "actions": [
                {
                    "type": "file",
                    "path": "${SteamPath}\\OpenSteamTool.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\dwmapi.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\xinput1_4.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\opensteamtool.toml"
                }
            ]
        },
        {
            "id": "opensteamtool-lua-config",
            "title": "OpenSteamTool Lua 配置目录 (需确认，默认禁用)",
            "sources": [
                "https://github.com/OpenSteam001/OpenSteamTool",
                "research/samples/steamcn.cc/steamcn.cc.2026-09-30.ps1"
            ],
            "enabled": false,
            "risk": "medium",
            "confirm": true,
            "actions": [
                {
                    "type": "file",
                    "path": "${SteamPath}\\config\\lua",
                    "recurse": true
                }
            ]
        },
        {
            "id": "steamking-installed-app",
            "title": "SteamKing 安装本体残留 (需确认)",
            "sources": [
                "SteamKing-Setup-1.5.3.exe (local sample, not archived)"
            ],
            "enabled": true,
            "risk": "medium",
            "confirm": true,
            "actions": [
                {
                    "type": "process",
                    "name": "SteamKing"
                },
                {
                    "type": "file",
                    "path": "%ProgramFiles%\\SteamKing",
                    "recurse": true
                },
                {
                    "type": "file",
                    "path": "${LOCALAPPDATA}\\SteamKing",
                    "recurse": true
                },
                {
                    "type": "registry-key",
                    "path": "HKLM:\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\{A7C3E9F1-2B4D-4F6A-9C8E-1D5F7A3B2E90}_is1",
                    "recurse": true
                }
            ]
        },
        {
            "id": "steam-extra-exes",
            "title": "STEAM 目录新增可执行文件 (需确认)",
            "sources": [
                "research/samples/steam-run.com/steamcdkey.cn.001.ps1"
            ],
            "enabled": true,
            "risk": "high",
            "confirm": true,
            "actions": [
                {
                    "type": "file",
                    "path": "${SteamPath}\\steam-lucky.exe"
                }
            ]
        },
        {
            "id": "rival-residue-steam-root",
            "title": "竞品残留：假入库竞品 DLL / 目录 (需确认)",
            "sources": [
                "research/samples/steamcn.cc/steamcn.cc.001.ps1",
                "research/samples/steamcn.cc/steamcn.cc.2026-09-30.ps1"
            ],
            "enabled": true,
            "risk": "high",
            "confirm": true,
            "actions": [
                {
                    "type": "file",
                    "path": "${SteamPath}\\diversion.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\winmm.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\steamclient_loader.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\GameOverlayRenderer64.bak"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\xinput9_1_0.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\msimg32.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\dbghelp.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\Core",
                    "recurse": true
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\CoreBeta",
                    "recurse": true
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\diversion",
                    "recurse": true
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\bin\\diversion.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\bin\\diversion",
                    "recurse": true
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\cdk.exe"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\f1.exe"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\steam_emu.ini"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\emu.cfg"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\local.vdf.bak"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\config\\stUI",
                    "recurse": true
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\config\\steamunlocked",
                    "recurse": true
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\config\\greenluma",
                    "recurse": true
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\dinput8.dll"
                }
            ]
        },
        {
            "id": "fake-library-team-steam-root-artifacts",
            "title": "假入库团队 powershell2 根目录残留 (需确认；游戏素材包已排除)",
            "sources": [
                "https://gitee.com/mrsiyecao/powershell2",
                "research/samples/mrsiyecao-powershell2/2.ps1",
                "research/samples/mrsiyecao-powershell2/script1.ps1",
                "research/samples/mrsiyecao-powershell2/Online.ps1"
            ],
            "enabled": true,
            "risk": "high",
            "confirm": true,
            "actions": [
                {
                    "type": "file",
                    "path": "${SteamPath}\\legit"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\legit64"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\legit64274"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\legit.zip"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\legit64.dll"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\legit197.vdf"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\legit200.vdf"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\legit203.vdf"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\legit206.vdf"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\legit214.vdf"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\legit215.vdf"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\legit218.vdf"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\winhttp-log.txt"
                },
                {
                    "type": "file",
                    "path": "${SteamPath}\\winhttp-log1.txt"
                }
            ]
        },
        {
            "id": "steam-apps-manifest-registry",
            "title": "STEAM Apps Manifest 注册表项 (需确认)",
            "sources": [
                "research/samples/steam-run.com/steamcdkey.cn.001.ps1"
            ],
            "enabled": true,
            "risk": "high",
            "confirm": true,
            "actions": [
                {
                    "type": "registry-key",
                    "path": "HKCU:\\Software\\Valve\\Steam\\Apps\\3545990",
                    "recurse": true
                },
                {
                    "type": "registry-key",
                    "path": "HKCU:\\Software\\Valve\\Steam\\Apps\\2050650",
                    "recurse": true
                },
                {
                    "type": "registry-key",
                    "path": "HKCU:\\Software\\Valve\\Steam\\Apps\\3218580",
                    "recurse": true
                }
            ]
        },
        {
            "id": "windows-update-pause-policy",
            "title": "Windows Update 暂停更新策略 (需确认)",
            "sources": [
                "research/samples/steam-run.com/steamcdkey.cn.001.ps1"
            ],
            "enabled": true,
            "risk": "high",
            "confirm": true,
            "actions": [
                {
                    "type": "registry-value",
                    "path": "HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings",
                    "name": "FlightSettingsMaxPauseDays"
                },
                {
                    "type": "registry-value",
                    "path": "HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings",
                    "name": "PauseFeatureUpdatesStartTime"
                },
                {
                    "type": "registry-value",
                    "path": "HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings",
                    "name": "PauseFeatureUpdatesEndTime"
                },
                {
                    "type": "registry-value",
                    "path": "HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings",
                    "name": "PauseQualityUpdatesStartTime"
                },
                {
                    "type": "registry-value",
                    "path": "HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings",
                    "name": "PauseQualityUpdatesEndTime"
                },
                {
                    "type": "registry-value",
                    "path": "HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings",
                    "name": "PauseUpdatesStartTime"
                },
                {
                    "type": "registry-value",
                    "path": "HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings",
                    "name": "PauseUpdatesExpiryTime"
                }
            ]
        },
        {
            "id": "sdl3-voder-family",
            "title": "SDL3_voder 假入库家族残留 (steamcn.cc)",
            "sources": [
                "research/samples/steamcn.cc/steamcn.cc.001.ps1",
                "research/samples/steamcn.cc/steamcn.cc.2026-09-30.ps1"
            ],
            "enabled": true,
            "risk": "low",
            "actions": [
                {
                    "type": "file",
                    "path": "${SteamPath}\\SDL3_voder.dll"
                },
                {
                    "type": "file",
                    "path": "${LOCALAPPDATA}\\SDL3\\cache",
                    "recurse": true
                }
            ]
        },
        {
            "id": "stool-scheduled-tasks",
            "title": "%APPDATA%\\\\Stool 相关计划任务 (需确认)",
            "sources": [
                "research/samples/steam-run.com/steamcdkey.cn.001.ps1"
            ],
            "enabled": true,
            "risk": "high",
            "confirm": true,
            "actions": [
                {
                    "type": "task-contains",
                    "contains": "${APPDATA}\\Stool"
                },
                {
                    "type": "task-contains",
                    "contains": "%APPDATA%\\Stool"
                }
            ]
        }
    ]
}
'@

# SteamSPA source module
# Edit this module, then run tools/build.ps1.

function Get-ThemeColor {
    param([string]$Name)

    switch ($Name) {
        # Calm, terminal-native palette inspired by Claude/Gemini CLI:
        # warm semantic accents, low-contrast borders, no saturated rainbow colors.
        'Ink'       { return '229;231;235' }
        'Muted'     { return '148;163;184' }
        'Dim'       { return '100;116;139' }
        'Border'    { return '51;65;85' }
        'Accent'    { return '125;211;252' }
        'Accent2'   { return '196;181;253' }
        'Success'   { return '134;239;172' }
        'Warning'   { return '253;224;71' }
        'WarningSoft' { return '254;240;138' }
        'Danger'    { return '252;165;165' }
        'Title'     { return '56;189;248' }
        'Path'      { return '186;230;253' }
        'Code'      { return '203;213;225' }
        default     { return $null }
    }
}

function ConvertTo-ThemeRole {
    param($Color)

    switch ([string]$Color) {
        'Black'       { return 'Dim' }
        'DarkBlue'    { return 'Accent2' }
        'DarkGreen'   { return 'Success' }
        'DarkCyan'    { return 'Border' }
        'DarkRed'     { return 'Danger' }
        'DarkMagenta' { return 'Accent2' }
        'DarkYellow'  { return 'Warning' }
        'Gray'        { return 'Ink' }
        'DarkGray'    { return 'Muted' }
        'Blue'        { return 'Accent2' }
        'Green'       { return 'Success' }
        'Cyan'        { return 'Accent' }
        'Red'         { return 'Danger' }
        'Magenta'     { return 'Accent2' }
        'Yellow'      { return 'Warning' }
        'White'       { return 'Ink' }
        default       { return [string]$Color }
    }
}

function Get-Ansi {
    param($Color)

    if ($env:NO_COLOR) { return '' }
    $role = ConvertTo-ThemeRole $Color
    $rgb = Get-ThemeColor $role
    if (-not $rgb) { return '' }
    return "$([char]27)[38;2;${rgb}m"
}

function Write-Status {
    param([string]$Message = '', $Color = 'Ink', [switch]$NoNewline)

    $ansi = Get-Ansi $Color
    if ($ansi) {
        $reset = "$([char]27)[0m"
        if ($NoNewline) {
            Write-Host ($ansi + $Message + $reset) -NoNewline
        }
        else {
            Write-Host ($ansi + $Message + $reset)
        }
        return
    }

    $fallback = [ConsoleColor]::Gray
    try {
        $fallback = [ConsoleColor]([string]$Color)
        Write-Host $Message -ForegroundColor $fallback -NoNewline:$NoNewline
    }
    catch {
        Write-Host $Message -NoNewline:$NoNewline
    }
}

function Write-GradientText {
    param(
        [string]$Text,
        [int[]]$From = @(45, 212, 255),
        [int[]]$To = @(110, 231, 183)
    )

    if ($env:NO_COLOR) {
        Write-Host $Text
        return
    }

    $chars = $Text.ToCharArray()
    $steps = [Math]::Max(1, $chars.Count - 1)
    for ($i = 0; $i -lt $chars.Count; $i++) {
        $t = $i / $steps
        $r = [int]($From[0] + (($To[0] - $From[0]) * $t))
        $g = [int]($From[1] + (($To[1] - $From[1]) * $t))
        $b = [int]($From[2] + (($To[2] - $From[2]) * $t))
        Write-Host "$([char]27)[38;2;$r;$g;${b}m$($chars[$i])$([char]27)[0m" -NoNewline
    }
    Write-Host ''
}

function Write-Blank {
    Write-Host ''
}

function Write-Rule {
    param([string]$Title, $Color = 'Border')
    Write-Status '────────────────────────────────────────────────────────────' $Color
    if (-not [string]::IsNullOrWhiteSpace($Title)) {
        Write-Status ("  {0}" -f $Title) Accent
        Write-Status '────────────────────────────────────────────────────────────' $Color
    }
}

function Get-TextDisplayWidth {
    param([string]$Text)

    if ([string]::IsNullOrEmpty($Text)) { return 0 }

    $width = 0
    foreach ($ch in $Text.ToCharArray()) {
        $code = [int][char]$ch
        if (
            ($code -ge 0x1100 -and $code -le 0x11FF) -or
            ($code -ge 0x2E80 -and $code -le 0xA4CF) -or
            ($code -ge 0xAC00 -and $code -le 0xD7A3) -or
            ($code -ge 0xF900 -and $code -le 0xFAFF) -or
            ($code -ge 0xFE10 -and $code -le 0xFE6F) -or
            ($code -ge 0xFF00 -and $code -le 0xFF60) -or
            ($code -ge 0xFFE0 -and $code -le 0xFFE6)
        ) {
            $width += 2
        }
        else {
            $width += 1
        }
    }
    return $width
}

function Format-DisplayPadRight {
    param([string]$Text, [int]$Width)

    $displayWidth = Get-TextDisplayWidth $Text
    $padding = [Math]::Max(0, $Width - $displayWidth)
    return $Text + (' ' * $padding)
}

function Write-KeyValue {
    param([string]$Key, [string]$Value, $ValueColor = 'Ink')
    Write-Status ('  ' + (Format-DisplayPadRight $Key 18)) Muted -NoNewline
    Write-Status $Value $ValueColor
}

function Write-Section {
    param([string]$Title)
    Write-Blank
    Write-Status ("  {0}" -f $Title) Accent
    Write-Status '  ────────────────────────────────────────────────────────' Border
}

function Write-ProgressLine {
    param(
        [int]$Current,
        [int]$Total,
        [string]$Status = '扫描中'
    )

    $width = 28
    if ($Total -le 0) { $Total = 1 }
    $percent = [Math]::Min(100, [Math]::Max(0, [int](($Current / $Total) * 100)))
    $filled = [Math]::Min($width, [Math]::Max(0, [int][Math]::Round(($percent / 100) * $width)))
    $bar = ('█' * $filled) + ('░' * ($width - $filled))
    $line = "  {0,-8} [{1}] {2,3}%" -f $Status, $bar, $percent

    if ([Console]::IsOutputRedirected -or $env:NO_COLOR) {
        if ($Current -eq 0 -or $Current -ge $Total) {
            Write-Status $line Accent
        }
        return
    }

    Write-Status ($line + "`r") Accent -NoNewline
    if ($Current -ge $Total) {
        Write-Host ''
    }
}

function Write-Step {
    param([string]$Label, [string]$Value = '', $ValueColor = 'Ink')
    Write-Status '  ◆ ' Accent -NoNewline
    Write-Status $Label Muted -NoNewline
    if (-not [string]::IsNullOrWhiteSpace($Value)) {
        Write-Status $Value $ValueColor
    }
    else {
        Write-Host ''
    }
}

function Write-Result {
    param([string]$Icon, [string]$Label, [string]$Text, $Color = 'Ink')
    Write-Status ("  {0} " -f $Icon) $Color -NoNewline
    Write-Status ("{0,-8}" -f $Label) Muted -NoNewline
    Write-Status $Text $Color
}

function Write-ProtectedItems {
    param($Items)

    if (@($Items).Count -eq 0) { return }

    Write-Blank
    Write-Status ('  🛡️ 官方文件保护：{0} 项 Valve 数字签名文件已自动跳过（Steam 官方组件，不清理）' -f @($Items).Count) Success
    foreach ($item in @($Items) | Select-Object -Unique -Property Label) {
        Write-Status ('        · ' + $item.Label) Muted
    }
    Write-Blank
}

function Get-RiskText {
    param([string]$Risk)
    switch ($Risk) {
        'low' { return '低风险' }
        'medium' { return '中风险' }
        'high' { return '高风险' }
        default { return $Risk }
    }
}

function Get-RiskColor {
    param([string]$Risk)
    switch ($Risk) {
        'low' { return 'Muted' }
        'medium' { return 'Warning' }
        'high' { return 'Danger' }
        default { return 'Ink' }
    }
}

function Read-CleanupConfirmation {
    Write-Blank
    Write-Section '✅ 确认清理？'
    Write-Status '  输入 Y 并回车 = 确认清理      |  其他任何输入 = 取消' Muted
    $choice = [string](Read-Host '  请选择')
    if ($choice -and $choice.Trim().ToUpperInvariant() -eq 'Y') {
        Write-Status '确认清理' Accent
        return $true
    }

    Write-Status '取消' Warning
    return $false
}

# SteamSPA source module
# Edit this module, then run tools/build.ps1.

function Resolve-Template {
    param(
        [string]$Text,
        [hashtable]$Variables
    )

    $resolved = $Text
    foreach ($key in $Variables.Keys) {
        $resolved = $resolved.Replace('${' + $key + '}', [string]$Variables[$key])
    }

    return [Environment]::ExpandEnvironmentVariables($resolved)
}

function ConvertTo-SafeName {
    param([string]$Text)
    $safe = $Text
    foreach ($char in [System.IO.Path]::GetInvalidFileNameChars()) {
        $safe = $safe.Replace($char, '_')
    }
    return $safe.Trim().TrimEnd('.')
}

function Get-SteamPath {
    $candidates = New-Object System.Collections.Generic.List[string]
    $registryPaths = @(
        'HKCU:\Software\Valve\Steam',
        'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam',
        'HKLM:\SOFTWARE\Valve\Steam'
    )

    foreach ($registryPath in $registryPaths) {
        try {
            $props = Get-ItemProperty -Path $registryPath -ErrorAction Stop
            foreach ($name in @('SteamPath', 'InstallPath')) {
                $path = [string]$props.$name
                if (-not [string]::IsNullOrWhiteSpace($path)) {
                    $candidates.Add($path)
                }
            }
            $steamExe = [string]$props.SteamExe
            if (-not [string]::IsNullOrWhiteSpace($steamExe)) {
                $parent = Split-Path -Parent $steamExe
                if (-not [string]::IsNullOrWhiteSpace($parent)) {
                    $candidates.Add($parent)
                }
            }
        }
        catch {}
    }

    $defaultPaths = @(
        (Join-Path ${env:ProgramFiles(x86)} 'Steam'),
        (Join-Path $env:ProgramFiles 'Steam')
    )
    foreach ($path in $defaultPaths) {
        if (-not [string]::IsNullOrWhiteSpace($path)) {
            $candidates.Add($path)
        }
    }

    foreach ($path in @($candidates | Select-Object -Unique)) {
        if ($path -and (Test-Path -LiteralPath $path -PathType Container)) {
            return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($path)
        }
    }

    return $null
}

function Get-OSDisplayName {
    try {
        $cv = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop
        $build = [int]$cv.CurrentBuildNumber
        $name = if ($build -ge 22000) { 'Windows 11' } else { 'Windows 10' }
        $version = if ($cv.DisplayVersion) { $cv.DisplayVersion } elseif ($cv.ReleaseId) { $cv.ReleaseId } else { $null }
        $ubr = if ($null -ne $cv.UBR) { ".{0}" -f $cv.UBR } else { '' }

        if ($version) {
            return ('{0} {1} (Build {2}{3})' -f $name, $version, $build, $ubr)
        }
        return ('{0} (Build {1}{2})' -f $name, $build, $ubr)
    }
    catch {
        return [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
    }
}

function Get-Variables {
    $steamPath = Get-SteamPath
    return @{
        APPDATA      = $env:APPDATA
        LOCALAPPDATA = $env:LOCALAPPDATA
        OS           = (Get-OSDisplayName)
        ProgramData  = $env:ProgramData
        ScriptRoot   = $scriptRoot
        SteamPath    = $steamPath
        TEMP         = $env:TEMP
        USERPROFILE  = $env:USERPROFILE
    }
}

function Read-Targets {
    return $EmbeddedTargetsJson | ConvertFrom-Json
}

# SteamSPA source module
# Edit this module, then run tools/build.ps1.

function Get-DefenderPreference {
    # Defender 模块在精简版 / Server / 第三方杀软接管时不存在。
    # 命令缺失抛的是 CommandNotFoundException（终止性错误，-ErrorAction 压不住），必须先用 Get-Command 探测。
    if ($script:DefenderPreferenceProbed) {
        return $script:DefenderPreferenceCache
    }

    $script:DefenderPreferenceProbed = $true
    $script:DefenderPreferenceCache = $null

    if (-not (Get-Command -Name Get-MpPreference -ErrorAction SilentlyContinue)) {
        return $null
    }

    try {
        $script:DefenderPreferenceCache = Get-MpPreference -ErrorAction Stop
    }
    catch {
        $script:DefenderPreferenceCache = $null
    }

    return $script:DefenderPreferenceCache
}

function Test-ValveSignedFile {
    # 官方文件保护：Steam 根目录里的 video.dll / SDL3.dll 等是 Valve 签名的客户端组件，
    # 规则里同名 DLL 只应命中未签名的注入副本。签名有效且签发者为 Valve 时一律不删。
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }

    $ext = [IO.Path]::GetExtension($Path).ToLowerInvariant()
    if (@('.dll', '.exe', '.sys', '.ocx', '.drv') -notcontains $ext) { return $false }

    if (-not $script:ValveSignCache) { $script:ValveSignCache = @{} }
    $key = $Path.ToLowerInvariant()
    if ($script:ValveSignCache.ContainsKey($key)) { return $script:ValveSignCache[$key] }

    $result = $false
    if (Get-Command -Name Get-AuthenticodeSignature -ErrorAction SilentlyContinue) {
        try {
            $sig = Get-AuthenticodeSignature -LiteralPath $Path -ErrorAction Stop
            if ($sig.Status -eq 'Valid' -and $sig.SignerCertificate) {
                if ([string]$sig.SignerCertificate.Subject -match '(^|,\s*)(O|CN)=Valve') {
                    $result = $true
                }
            }
        }
        catch {
            $result = $false
        }
    }

    $script:ValveSignCache[$key] = $result
    return $result
}

function Test-ProtectedOfficialFile {
    param($Action, [hashtable]$Variables)

    if ($Action.type -ne 'file') { return $false }
    $path = Resolve-Template -Text $Action.path -Variables $Variables
    return (Test-ValveSignedFile -Path $path)
}

function Normalize-DefenderPath {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return ''
    }

    $normalized = [Environment]::ExpandEnvironmentVariables($Path.Trim().Trim('"'))
    try {
        if (Test-Path -LiteralPath $normalized) {
            $normalized = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($normalized)
        }
    }
    catch {
    }

    return $normalized.TrimEnd('\', '/') -replace '/', '\'
}

function New-ScheduledTaskSnapshotItem {
    param(
        [string]$Name,
        [string]$Path,
        $Actions
    )

    $actionItems = @()
    foreach ($action in @($Actions)) {
        $actionItems += [pscustomobject]@{
            Execute   = [string]$action.Execute
            Arguments = [string]$action.Arguments
        }
    }

    return [pscustomobject]@{
        Name     = $Name
        Path     = $Path
        TaskName = $Name
        TaskPath = $Path
        Actions  = @($actionItems)
    }
}

function ConvertTo-ScheduledTaskFolderPath {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return '\'
    }

    $trimmed = $Path.Trim()
    if ($trimmed -eq '\') {
        return '\'
    }

    # COM returns the full task path; Get-ScheduledTask returns the folder path.
    $parent = Split-Path -Parent $trimmed
    if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq '\') {
        return '\'
    }

    return $parent.TrimEnd('\') + '\'
}

function Add-ScheduledTaskFolderSnapshot {
    param($Folder, $Items)

    foreach ($task in @($Folder.GetTasks(1))) {
        try {
            $definition = $task.Definition
            $taskFolderPath = ConvertTo-ScheduledTaskFolderPath -Path ([string]$task.Path)
            $taskItem = New-ScheduledTaskSnapshotItem -Name ([string]$task.Name) -Path $taskFolderPath -Actions $definition.Actions
            $Items.Add($taskItem)
        }
        catch {
        }
    }

    foreach ($child in @($Folder.GetFolders(1))) {
        try {
            Add-ScheduledTaskFolderSnapshot -Folder $child -Items $Items
        }
        catch {
        }
    }
}

function Get-ScheduledTaskSnapshot {
    param([switch]$Refresh)

    if (-not $Refresh -and $script:ScheduledTaskSnapshotLoaded) {
        return @($script:ScheduledTaskSnapshot)
    }

    $items = New-Object System.Collections.Generic.List[object]
    $loadedFromCom = $false

    try {
        $service = New-Object -ComObject Schedule.Service
        $service.Connect()
        $rootFolder = $service.GetFolder('\')
        Add-ScheduledTaskFolderSnapshot -Folder $rootFolder -Items $items
        $loadedFromCom = $true
    }
    catch {
        $loadedFromCom = $false
    }

    if (-not $loadedFromCom -and (Get-Command -Name Get-ScheduledTask -ErrorAction SilentlyContinue)) {
        foreach ($task in @(Get-ScheduledTask -ErrorAction SilentlyContinue)) {
            $taskName = [string]$task.TaskName
            if ([string]::IsNullOrWhiteSpace($taskName)) {
                $taskName = [string]$task.Name
            }
            $taskPath = [string]$task.TaskPath
            if ([string]::IsNullOrWhiteSpace($taskPath)) {
                $taskPath = [string]$task.Path
            }
            $taskFolderPath = ConvertTo-ScheduledTaskFolderPath -Path $taskPath
            $items.Add((New-ScheduledTaskSnapshotItem -Name $taskName -Path $taskFolderPath -Actions $task.Actions))
        }
    }

    $script:ScheduledTaskSnapshot = $items.ToArray()
    $script:ScheduledTaskSnapshotLoaded = $true
    return $script:ScheduledTaskSnapshot
}

function Find-ScheduledTasksByContains {
    param([string]$Needle)

    if ([string]::IsNullOrWhiteSpace($Needle)) {
        return @()
    }

    return @(Get-ScheduledTaskSnapshot | Where-Object {
        $task = $_
        @($task.Actions) | Where-Object {
            $expandedExecute = [Environment]::ExpandEnvironmentVariables([string]$_.Execute)
            $expandedArguments = [Environment]::ExpandEnvironmentVariables([string]$_.Arguments)
            ($expandedExecute -like "*$Needle*") -or
            ($expandedArguments -like "*$Needle*")
        }
    })
}

function Test-ScheduledTaskExists {
    param([string]$Name)

    if ([string]::IsNullOrWhiteSpace($Name)) {
        return $false
    }

    return @(Get-ScheduledTaskSnapshot | Where-Object {
        [string]$_.Name -eq $Name
    }).Count -gt 0
}

function Test-ActionExists {
    param($Action, [hashtable]$Variables)

    switch ($Action.type) {
        'file' {
            $path = Resolve-Template -Text $Action.path -Variables $Variables
            if (-not (Test-Path -LiteralPath $path)) { return $false }
            return $true
        }
        'registry-key' {
            return [bool](Test-Path -Path $Action.path)
        }
        'registry-value' {
            if (-not (Test-Path -Path $Action.path)) { return $false }
            return $null -ne (Get-ItemProperty -Path $Action.path -Name $Action.name -ErrorAction SilentlyContinue)
        }
        'defender-exclusion-path' {
            $pref = Get-DefenderPreference
            if (-not $pref) { return $false }
            $path = Resolve-Template -Text $Action.path -Variables $Variables
            $target = Normalize-DefenderPath -Path $path
            foreach ($existing in @($pref.ExclusionPath)) {
                if ((Normalize-DefenderPath -Path $existing) -eq $target) {
                    return $true
                }
            }
            return $false
        }
        'defender-exclusion-extension' {
            $pref = Get-DefenderPreference
            return $pref -and ($pref.ExclusionExtension -contains $Action.name)
        }
        'defender-exclusion-process' {
            $pref = Get-DefenderPreference
            return $pref -and ($pref.ExclusionProcess -contains $Action.name)
        }
        'process' {
            return $null -ne (Get-Process -Name ([System.IO.Path]::GetFileNameWithoutExtension($Action.name)) -ErrorAction SilentlyContinue)
        }
        'service' {
            return $null -ne (Get-Service -Name $Action.name -ErrorAction SilentlyContinue)
        }
        'task' {
            return (Test-ScheduledTaskExists -Name $Action.name)
        }
        'task-contains' {
            $needle = Resolve-Template -Text $Action.contains -Variables $Variables
            return (@(Find-ScheduledTasksByContains -Needle $needle).Count -gt 0)
        }
        default {
            return $false
        }
    }
}

# SteamSPA source module
# Edit this module, then run tools/build.ps1.

function Remove-DefenderExclusion {
    param(
        [ValidateSet('path', 'extension', 'process')][string]$Kind,
        [string]$Value
    )

    if (-not (Get-Command -Name Remove-MpPreference -ErrorAction SilentlyContinue)) {
        return $false
    }

    try {
        switch ($Kind) {
            'path' { Remove-MpPreference -ExclusionPath $Value -ErrorAction Stop }
            'extension' { Remove-MpPreference -ExclusionExtension $Value -ErrorAction Stop }
            'process' { Remove-MpPreference -ExclusionProcess $Value -ErrorAction Stop }
        }
        return $true
    }
    catch {
        return $false
    }
}

function Remove-Action {
    param(
        $Action,
        [hashtable]$Variables,
        [string]$BackupRoot,
        [switch]$NoBackup
    )

    switch ($Action.type) {
        'file' {
            $path = Resolve-Template -Text $Action.path -Variables $Variables
            if (-not (Test-Path -LiteralPath $path)) { return 'skipped' }
            if (Test-ValveSignedFile -Path $path) { return 'protected' }
            if (-not $NoBackup) {
                $backupName = Join-Path $BackupRoot (ConvertTo-SafeName $path)
                $parent = Split-Path -Parent $backupName
                if ($parent -and -not (Test-Path -LiteralPath $parent)) {
                    New-Item -ItemType Directory -Path $parent -Force | Out-Null
                }
                Copy-Item -LiteralPath $path -Destination $backupName -Recurse -Force -ErrorAction SilentlyContinue
            }
            Remove-Item -LiteralPath $path -Force -Recurse:([bool]$Action.recurse)
            return 'removed'
        }
        'registry-key' {
            if (Test-Path -Path $Action.path) {
                Remove-Item -Path $Action.path -Force -Recurse:([bool]$Action.recurse)
                return 'removed'
            }
            return 'skipped'
        }
        'registry-value' {
            if ((Test-Path -Path $Action.path) -and ($null -ne (Get-ItemProperty -Path $Action.path -Name $Action.name -ErrorAction SilentlyContinue))) {
                Remove-ItemProperty -Path $Action.path -Name $Action.name -Force
                return 'removed'
            }
            return 'skipped'
        }
        'defender-exclusion-path' {
            $pref = Get-DefenderPreference
            if (-not $pref) { return 'skipped' }
            $path = Resolve-Template -Text $Action.path -Variables $Variables
            $target = Normalize-DefenderPath -Path $path
            $removed = $false
            foreach ($existing in @($pref.ExclusionPath)) {
                if ((Normalize-DefenderPath -Path $existing) -eq $target) {
                    if (Remove-DefenderExclusion -Kind 'path' -Value $existing) { $removed = $true }
                }
            }
            if ($removed) { return 'removed' }
            return 'skipped'
        }
        'defender-exclusion-extension' {
            if (-not (Remove-DefenderExclusion -Kind 'extension' -Value $Action.name)) { return 'skipped' }
            return 'removed'
        }
        'defender-exclusion-process' {
            if (-not (Remove-DefenderExclusion -Kind 'process' -Value $Action.name)) { return 'skipped' }
            return 'removed'
        }
        'process' {
            Get-Process -Name ([System.IO.Path]::GetFileNameWithoutExtension($Action.name)) -ErrorAction SilentlyContinue | Stop-Process -Force
            return 'removed'
        }
        'service' {
            Stop-Service -Name $Action.name -Force
            return 'removed'
        }
        'task' {
            Unregister-ScheduledTask -TaskName $Action.name -Confirm:$false
            Get-ScheduledTaskSnapshot -Refresh | Out-Null
            return 'removed'
        }
        'task-contains' {
            $needle = Resolve-Template -Text $Action.contains -Variables $Variables
            $matches = @(Find-ScheduledTasksByContains -Needle $needle)
            foreach ($task in $matches) {
                Unregister-ScheduledTask -TaskName $task.Name -TaskPath $task.Path -Confirm:$false
            }
            if ($matches.Count -gt 0) {
                Get-ScheduledTaskSnapshot -Refresh | Out-Null
                return 'removed'
            }
            return 'skipped'
        }
        default {
            throw (('不支持的动作类型: ') + $Action.type)
        }
    }
}

function Format-ActionLabel {
    param($Action, [hashtable]$Variables)

    switch ($Action.type) {
        'file' { return Resolve-Template -Text $Action.path -Variables $Variables }
        'registry-key' { return $Action.path }
        'registry-value' { return "$($Action.path)\$($Action.name)" }
        'defender-exclusion-path' {
            $path = Resolve-Template -Text $Action.path -Variables $Variables
            return $path
        }
        'defender-exclusion-extension' { return "扩展名: $($Action.name)" }
        'defender-exclusion-process' { return "排除进程: $($Action.name)" }
        'process' { return "进程: $($Action.name)" }
        'service' { return "服务: $($Action.name)" }
        'task' { return "计划任务: $($Action.name)" }
        'task-contains' { return "计划任务包含: $(Resolve-Template -Text $Action.contains -Variables $Variables)" }
        default { return $Action.type }
    }
}

function Get-ActionCategory {
    param($Action)

    switch ($Action.type) {
        'file' {
            $p = [string]$Action.path
            if ($p -match 'steam\.cfg|appdata\d*\.vdf|packageinfo\.vdf|localData\.vdf|package\\beta|opensteamtool\.toml|config\\lua') { return 'config' }
            return 'files'
        }
        'registry-key' { return 'registry' }
        'registry-value' { return 'registry' }
        'defender-exclusion-path' { return 'security' }
        'defender-exclusion-extension' { return 'security' }
        'defender-exclusion-process' { return 'security' }
        'process' { return 'process' }
        'service' { return 'startup' }
        'task' { return 'startup' }
        'task-contains' { return 'startup' }
        default { return 'other' }
    }
}

function Get-ActionIdentity {
    param($Action, [hashtable]$Variables)

    $target = [string](Format-ActionLabel -Action $Action -Variables $Variables)
    $target = $target.Trim().TrimEnd('\', '/')
    return ([string]$Action.type).ToLowerInvariant() + '|' + $target.ToLowerInvariant()
}

function Get-CategoryTitle {
    param([string]$Category)

    switch ($Category) {
        'files' { return '文件' }
        'config' { return '配置' }
        'registry' { return '注册表' }
        'startup' { return '启动项' }
        'security' { return '安全项' }
        'process' { return '进程' }
        default { return '其他' }
    }
}

# SteamSPA source module
# Edit this module, then run tools/build.ps1.

function Get-FakeLibraryHistoryClues {
    $historyPaths = New-Object System.Collections.Generic.List[string]

    try {
        $psReadLineOption = Get-PSReadLineOption -ErrorAction SilentlyContinue
        if ($psReadLineOption -and -not [string]::IsNullOrWhiteSpace($psReadLineOption.HistorySavePath)) {
            $historyPaths.Add($psReadLineOption.HistorySavePath)
        }
    }
    catch {
    }

    $fallbackPaths = @(
        (Join-Path $env:APPDATA 'Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt'),
        (Join-Path $env:APPDATA 'Microsoft\Windows\PowerShell\PSReadLine\Visual Studio Code Host_history.txt'),
        (Join-Path $env:APPDATA 'Microsoft\Windows\PowerShell\PSReadLine\Windows PowerShell ISE Host_history.txt')
    )
    foreach ($path in $fallbackPaths) {
        if (-not [string]::IsNullOrWhiteSpace($path)) {
            $historyPaths.Add($path)
        }
    }

    $suspiciousKeywords = @(
        'irm',
        'iwr',
        'iex',
        'Invoke-RestMethod',
        'Invoke-WebRequest',
        'steam.run',
        'steam.work',
        'cdk.ruku.run',
        'ruku.run',
        'steamcdkey.cn',
        'steamcn.cc',
        'steamcc.cn',
        'SDL3_voder',
        'sdl3_setup',
        'csu_install',
        'csu_lz_',
        'CSU_DIVA_HOST',
        'vfc88.cn',
        'vfc77.cn',
        '121.41.99.14',
        '139.196.146.200',
        'wanzi666',
        'kyeamu',
        'keymanifest',
        'sdko',
        'SdkoInjector',
        'stats.opensteamtool.com',
        'siyecao',
        'tfdl.net',
        'steamcdk',
        'steam-',
        'gitee.com',
        'githubusercontent.com',
        'lanzou',
        'lanzoui',
        'lanzoup',
        'Steamtools',
        'Stool'
    )

    $trustedPatterns = @(
        'raw.githubusercontent.com/ZERONE2077/SteamSPA',
        'cdn.jsdelivr.net/gh/ZERONE2077/SteamSPA'
    )

    $results = New-Object System.Collections.Generic.List[string]

    foreach ($historyPath in @($historyPaths | Select-Object -Unique)) {
        if ([string]::IsNullOrWhiteSpace($historyPath) -or -not (Test-Path -LiteralPath $historyPath)) {
            continue
        }

        $lines = @(Get-Content -LiteralPath $historyPath -Encoding UTF8 -ErrorAction SilentlyContinue)
        foreach ($line in $lines) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }

            $isSuspicious = $false
            foreach ($keyword in $suspiciousKeywords) {
                if ($line.IndexOf($keyword, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
                    $isSuspicious = $true
                    break
                }
            }
            if (-not $isSuspicious) { continue }

            $urlMatches = [regex]::Matches($line, '(?i)https?://[^\s''")<>|]+')
            if ($urlMatches.Count -gt 0) {
                foreach ($match in $urlMatches) {
                    $url = $match.Value.Trim()
                    $url = $url -replace '([?&](?:token|access_token|auth|key|pwd|password|sign|signature)=)[^&\s]+', '$1<redacted>'
                    $url = $url.TrimEnd('.', ',', ';')
                    $isTrusted = $false
                    foreach ($trustedPattern in $trustedPatterns) {
                        if ($url.IndexOf($trustedPattern, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
                            $isTrusted = $true
                            break
                        }
                    }
                    if ($isTrusted) { continue }
                    if (-not [string]::IsNullOrWhiteSpace($url)) {
                        $results.Add($url)
                    }
                }
                continue
            }

            $shortIrm = [regex]::Match($line, '(?i)\b(?:irm|iwr|Invoke-RestMethod|Invoke-WebRequest)\s+([A-Za-z0-9][A-Za-z0-9._:/-]{2,80})')
            if ($shortIrm.Success) {
                $results.Add(($shortIrm.Value -replace '\s+', ' ').Trim())
                continue
            }

            $trimmed = ($line -replace '\s+', ' ').Trim()
            if ($trimmed.Length -gt 140) {
                $trimmed = $trimmed.Substring(0, 137) + '...'
            }
            $results.Add($trimmed)
        }
    }

    return @($results | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
}

function Write-FakeLibraryHistoryClues {
    param([string[]]$Clues)

    if (-not $Clues -or $Clues.Count -eq 0) {
        return
    }

    Write-Section '🧭 历史线索'
    Write-Status '  发现以下可能的假入库脚本线索（仅本机显示，不会上传）：' WarningSoft
    $index = 1
    foreach ($clue in @($Clues)) {
        Write-Status ('    {0}. ' -f $index) Muted -NoNewline
        Write-Status $clue Path
        $index++
    }
    Write-Blank
}

# Application entry point
Clear-Host
$host.UI.RawUI.WindowTitle = 'STEAM SPA 清理工具'
Write-Blank
Write-GradientText '  ███████ ████████ ███████  █████  ███    ███     ███████ ██████   █████  '
Write-GradientText '  ██         ██    ██      ██   ██ ████  ████     ██      ██   ██ ██   ██ '
Write-GradientText '  ███████    ██    █████   ███████ ██ ████ ██     ███████ ██████  ███████ '
Write-GradientText '       ██    ██    ██      ██   ██ ██  ██  ██          ██ ██      ██   ██ '
Write-GradientText '  ███████    ██    ███████ ██   ██ ██      ██     ███████ ██      ██   ██ '
Write-Blank
Write-Status '  假入库清理/专杀工具：秒杀各种注入DLL/STEAM配置/注册表/启动项/系统服务/安全策略/后台进程等' Muted
Write-Status '  作者：万能小哥' Muted
Write-Status ('  最后更新：' + $SteamSPAUpdatedAt + ' · 版本：' + $SteamSPAReleaseVersion) Muted

$variables = Get-Variables
$targets = Read-Targets
$backupRoot = Join-Path $scriptRoot (Join-Path 'temp\backups' (Get-Date -Format 'yyyyMMdd-HHmmss'))
$logRoot = Join-Path $scriptRoot 'temp\logs'

$report = [ordered]@{
    startedAt = (Get-Date).ToString('o')
    mode      = 'scan-confirm-clean'
    targets   = @()
    summary   = [ordered]@{
        detected = 0
        removed  = 0
        failed   = 0
        skipped  = 0
        protected = 0
    }
}

$rules = @($targets.rules) | Where-Object {
    ($_.enabled -ne $false) -and
    ($Risk -contains $_.risk) -and
    (-not $Only -or $Only -contains $_.id)
}

$detectedItems = @()
$protectedItems = @()

$scanIdentities = New-Object System.Collections.Generic.List[string]
$scanIdentitySet = @{}
foreach ($rule in $rules) {
    foreach ($action in @($rule.actions)) {
        $identity = Get-ActionIdentity -Action $action -Variables $variables
        if (-not $scanIdentitySet.ContainsKey($identity)) {
            $scanIdentitySet[$identity] = $true
            $scanIdentities.Add($identity)
        }
    }
}

$scanTotal = [Math]::Max(1, $scanIdentities.Count)
$scanCurrent = 0
$scanResultCache = @{}
Write-Section '🖥️ 本机信息'
Write-KeyValue '操作系统' $variables.OS
if ($variables.SteamPath) {
    Write-KeyValue 'STEAM路径' $variables.SteamPath
}
else {
    Write-KeyValue 'STEAM路径' '未检测到' Warning
}

$historyClues = Get-FakeLibraryHistoryClues
Write-FakeLibraryHistoryClues -Clues $historyClues

Write-Section '🔍 扫描'
Write-ProgressLine -Current 0 -Total $scanTotal -Status '扫描中'

foreach ($rule in $rules) {
    $ruleReport = [ordered]@{
        id      = $rule.id
        title   = $rule.title
        risk    = $rule.risk
        actions = @()
    }

    foreach ($action in @($rule.actions)) {
        $label = Format-ActionLabel -Action $action -Variables $variables
        $identity = Get-ActionIdentity -Action $action -Variables $variables
        if ($scanResultCache.ContainsKey($identity)) {
            $cachedResult = $scanResultCache[$identity]
            $exists = [bool]$cachedResult.Exists
            $protected = [bool]$cachedResult.Protected
        }
        else {
            $exists = Test-ActionExists -Action $action -Variables $variables
            $protected = $exists -and (Test-ProtectedOfficialFile -Action $action -Variables $variables)
            $scanResultCache[$identity] = [pscustomobject]@{
                Exists    = [bool]$exists
                Protected = [bool]$protected
            }
            $scanCurrent++
            if ($scanCurrent -lt $scanTotal) {
                Write-ProgressLine -Current $scanCurrent -Total $scanTotal -Status '扫描中'
            }
        }

        if ($exists -and -not $protected) {
            $detectedItems += [pscustomobject]@{
                RuleId = $rule.id
                RuleTitle = $rule.title
                Risk = $rule.risk
                Confirm = ($rule.confirm -eq $true)
                Action = $action
                Label = $label
                Category = (Get-ActionCategory -Action $action)
            }
        }
        elseif ($protected) {
            $protectedItems += [pscustomobject]@{
                RuleId = $rule.id
                RuleTitle = $rule.title
                Label = $label
            }
        }

        $ruleReport.actions += [ordered]@{
            type   = $action.type
            target = $label
            exists = [bool]$exists
        }
    }

    $report.targets += $ruleReport
}

Write-ProgressLine -Current $scanTotal -Total $scanTotal -Status '扫描完成'

# Overlapping rules can resolve to the same physical target. Show and remove it once.
$uniqueItems = @()
$itemIndex = @{}
foreach ($item in $detectedItems) {
    $key = Get-ActionIdentity -Action $item.Action -Variables $variables
    if ($itemIndex.ContainsKey($key)) {
        $existing = $itemIndex[$key]
        if ($item.Action.recurse -eq $true) {
            $existing.Action | Add-Member -NotePropertyName recurse -NotePropertyValue $true -Force
        }
        continue
    }
    $itemIndex[$key] = $item
    $uniqueItems += $item
}
$detectedItems = @($uniqueItems)
$report.summary.detected = $detectedItems.Count

if ($detectedItems.Count -eq 0) {
    Write-Result '✓' '安全' '未发现需要清理的项目。' Success
    Write-KeyValue '已扫描到' '0 项' Success
    Write-ProtectedItems -Items $protectedItems
}
else {
    $categoryOrder = @('files', 'config', 'registry', 'startup', 'security', 'process', 'other')
    foreach ($category in $categoryOrder) {
        $items = @($detectedItems | Where-Object { $_.Category -eq $category })
        if ($items.Count -eq 0) { continue }

        Write-Status ("  {0} ({1})" -f (Get-CategoryTitle -Category $category), $items.Count) Accent
        $index = 1
        foreach ($item in $items) {
            Write-Status ('    {0,2}. ' -f $index) Muted -NoNewline
            Write-Status $item.Label Path
            $index++
        }
        Write-Blank
    }
    Write-KeyValue '已扫描到' ($detectedItems.Count.ToString() + ' 项') Danger

    Write-ProtectedItems -Items $protectedItems

    Write-Section '⚠️ 注意事项'
    Write-Status '    1. 此工具不影响游戏、存档、创意工坊、MOD，请放心使用~' WarningSoft
    Write-Status '    2. 清理后可能需要重新登录 STEAM !' WarningSoft
    Write-Status '    3. 请确保还记得账户名称、邮箱、密码、手机令牌!' WarningSoft
    Write-Status '    4. 如清理失败，请退出杀毒软件后重试!' WarningSoft
    Write-Status '    5. 清理后首次打开 STEAM 可能较慢，建议提前开启加速器，等待几分钟或重启后通常会恢复!' WarningSoft

    $confirmed = Read-CleanupConfirmation

    if (-not $confirmed) {
        $report.summary.skipped += $detectedItems.Count
        Write-Result '–' '取消' '已取消清理，未删除任何项目。' Warning
    }
    else {
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $isAdmin) {
            throw ('清理需要以管理员身份运行 PowerShell。请右键 PowerShell，选择“以管理员身份运行”，然后重新执行命令。')
        }

        Write-Blank
        Write-Rule '开始清理'
        foreach ($item in $detectedItems) {
            try {
                $result = Remove-Action -Action $item.Action -Variables $variables -BackupRoot $backupRoot -NoBackup:$NoBackup
                if ($result -eq 'removed') {
                    $report.summary.removed++
                    Write-Result '✓' '已删除' $item.Label Success
                }
                elseif ($result -eq 'protected') {
                    $report.summary.protected++
                    Write-Result '🛡' '官方文件' ($item.Label + ' (Valve 数字签名，已保护)') Success
                }
                else {
                    $report.summary.skipped++
                    Write-Result '·' '跳过' $item.Label Muted
                }
            }
            catch {
                $report.summary.failed++
                Write-Result '×' '失败' ($item.Label + ' - ' + $_.Exception.Message) Danger
            }
        }
    }
}

Write-Blank
Write-Section '🎉 完成'
if ($report.summary.failed -gt 0) {
    Write-Result '×' '清理状态' '部分项目清理失败' Danger
}
elseif ($report.summary.removed -gt 0) {
    Write-Result '✓' '清理状态' '清理完成' Success
}
elseif ($report.summary.detected -gt 0) {
    Write-Result '–' '清理状态' '未执行清理' Warning
}
else {
    Write-Result '✓' '清理状态' '无需清理' Success
}
Write-KeyValue '发现' $report.summary.detected
Write-KeyValue '删除' $report.summary.removed Success
Write-KeyValue '失败' $report.summary.failed Danger
Write-KeyValue '跳过' $report.summary.skipped Muted

if ($report.summary.removed -gt 0 -and -not $NoBackup) {
    Write-KeyValue '备份' $backupRoot Path
}

Write-Blank
if (-not $NoPause) {
    Write-Blank
    Write-Status '  按回车退出...' Accent -NoNewline
    if (-not [Console]::IsInputRedirected) {
        Read-Host | Out-Null
    }
}
