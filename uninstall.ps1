<#
.SYNOPSIS
    SteamSPA clean engine.
.DESCRIPTION
    Scans SteamSPA leftovers first, then asks for confirmation before cleanup.
#>
# NOTE: Chinese UI text is kept as plain UTF-8 for easy editing. Save this file as UTF-8 without BOM.
Clear-Host
$host.UI.RawUI.WindowTitle = 'STEAM SPA 假入库清杀工具'
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

$EmbeddedTargetsJson = @'
{
    "$schema":  "./targets.schema.json",
    "version":  1,
    "meta":  {
                 "project":  "SteamSPA",
                 "description":  "STEAM 假入库残留清理清单。每条规则描述一个来源脚本所留下的痕迹。"
             },
    "rules":  [
                  {
                      "id":  "steam-inject-dlls",
                      "title":  "STEAM 目录注入 DLL",
                      "sources":  [
                                      "scripts/steam-run.com/142785900.001.ps1",
                                      "scripts/steam-run.com/steam-run.com.001.ps1",
                                      "scripts/steam-run.com/steam-run.com.002.ps1",
                                      "scripts/steam-run.com/steam-run.com.003.ps1",
                                      "scripts/steam-run.com/steam-run.com.004.ps1",
                                      "scripts/steam.run/cdks.run.001.ps1",
                                      "scripts/steam.run/steam.run.001.ps1",
                                      "scripts/steam.run/steam.run.002.ps1",
                                      "scripts/steam.work/steam.icu.001.ps1",
                                      "scripts/steam-run.com/steamcdkey.cn.001.ps1"
                                  ],
                      "enabled":  true,
                      "risk":  "low",
                      "actions":  [
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\dwmapi.dll"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\xinput1_4.dll"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\xinput1_4.dll.old"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\xinput1_4.log"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\xinput1_42.dll"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\xinput1_43.dll"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\dwmapi.log"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\dwmapi1.dll"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\dwmapi2.dll"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\dwmapi3.dll"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\hid.dll"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\hid.vdf"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\hid.log"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\zlib1.dll"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\zlib1.vdf"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\zlib1.txt"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\zlib1.log"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\version.dll"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\user32.dll"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\User32.dll"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\User32.vdf"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\wtsapi32.dll"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\simulator.dll"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\steam_api.dll"
                                      }
                                  ]
                  },
                  {
                      "id":  "steam-config-files",
                      "title":  "STEAM 配置文件 / Beta 标志 / appdata 缓存",
                      "sources":  [
                                      "scripts/steam-run.com/142785900.001.ps1",
                                      "scripts/steam-run.com/steam-run.com.001.ps1",
                                      "scripts/steam-run.com/steam-run.com.002.ps1",
                                      "scripts/steam-run.com/steam-run.com.003.ps1",
                                      "scripts/steam-run.com/steam-run.com.004.ps1",
                                      "scripts/steam.work/steam.icu.001.ps1"
                                  ],
                      "enabled":  true,
                      "risk":  "low",
                      "actions":  [
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\steam.cfg"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\package\\beta"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\config\\appdata.vdf"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\appcache\\appdata.vdf"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\appcache\\appdata64.vdf"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\appdata.vdf"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\appdata64.vdf"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\appdata64.dll"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\appcache\\packageinfo.vdf"
                                      }
                                  ]
                  },
                  {
                      "id":  "registry-steamtools",
                      "title":  "注册表 HKCU\\Software\\Valve\\Steamtools",
                      "sources":  [
                                      "scripts/steam-run.com/142785900.001.ps1",
                                      "scripts/steam-run.com/steam-run.com.001.ps1",
                                      "scripts/steam-run.com/steam-run.com.002.ps1",
                                      "scripts/steam-run.com/steam-run.com.003.ps1",
                                      "scripts/steam-run.com/steam-run.com.004.ps1",
                                      "scripts/steam.run/cdks.run.001.ps1",
                                      "scripts/steam.run/steam.run.001.ps1",
                                      "scripts/steam.run/steam.run.002.ps1"
                                  ],
                      "enabled":  true,
                      "risk":  "low",
                      "actions":  [
                                      {
                                          "type":  "registry-value",
                                          "path":  "HKCU:\\Software\\Valve\\Steamtools",
                                          "name":  "packageinfo"
                                      },
                                      {
                                          "type":  "registry-value",
                                          "path":  "HKCU:\\Software\\Valve\\Steamtools",
                                          "name":  "steamclient"
                                      },
                                      {
                                          "type":  "registry-value",
                                          "path":  "HKCU:\\Software\\Valve\\Steamtools",
                                          "name":  "s"
                                      },
                                      {
                                          "type":  "registry-value",
                                          "path":  "HKCU:\\Software\\Valve\\Steamtools",
                                          "name":  "c"
                                      },
                                      {
                                          "type":  "registry-value",
                                          "path":  "HKCU:\\Software\\Valve\\Steamtools",
                                          "name":  "iscdkey"
                                      },
                                      {
                                          "type":  "registry-value",
                                          "path":  "HKCU:\\Software\\Valve\\Steamtools",
                                          "name":  "ActivateUnlockMode"
                                      },
                                      {
                                          "type":  "registry-value",
                                          "path":  "HKCU:\\Software\\Valve\\Steamtools",
                                          "name":  "AlwaysStayUnlocked"
                                      },
                                      {
                                          "type":  "registry-value",
                                          "path":  "HKCU:\\Software\\Valve\\Steamtools",
                                          "name":  "notUnlockDepot"
                                      },
                                      {
                                          "type":  "registry-key",
                                          "path":  "HKCU:\\Software\\Valve\\Steamtools",
                                          "recurse":  true
                                      }
                                  ]
                  },
                  {
                      "id":  "appdata-stool",
                      "title":  "%APPDATA%\\Stool 工具目录",
                      "sources":  [
                                      "scripts/steam-run.com/142785900.001.ps1",
                                      "scripts/steam-run.com/steam-run.com.001.ps1",
                                      "scripts/steam-run.com/steam-run.com.002.ps1",
                                      "scripts/steam-run.com/steam-run.com.003.ps1",
                                      "scripts/steam-run.com/steam-run.com.004.ps1",
                                      "https://gitee.com/mrsiyecao/powershell2"
                                  ],
                      "enabled":  true,
                      "risk":  "low",
                      "actions":  [
                                      {
                                          "type":  "file",
                                          "path":  "${APPDATA}\\Stool",
                                          "recurse":  true
                                      }
                                  ]
                  },
                  {
                      "id":  "localappdata-steam",
                      "title":  "%LOCALAPPDATA%\\steam 目录 (需确认)",
                      "sources":  [
                                      "scripts/steam.run/cdks.run.001.ps1",
                                      "scripts/steam.run/steam.run.001.ps1",
                                      "scripts/steam.run/steam.run.002.ps1"
                                  ],
                      "enabled":  true,
                      "risk":  "medium",
                      "confirm":  true,
                      "actions":  [
                                      {
                                          "type":  "file",
                                          "path":  "${LOCALAPPDATA}\\steam",
                                          "recurse":  true
                                      }
                                  ]
                  },
                  {
                      "id":  "localdata-vdf",
                      "title":  "%LOCALAPPDATA%\\Steam\\localData.vdf",
                      "sources":  [
                                      "scripts/steam.work/steam.icu.001.ps1"
                                  ],
                      "enabled":  true,
                      "risk":  "low",
                      "actions":  [
                                      {
                                          "type":  "file",
                                          "path":  "${LOCALAPPDATA}\\Steam\\localData.vdf"
                                      }
                                  ]
                  },
                  {
                      "id":  "tencent-cache",
                      "title":  "%LOCALAPPDATA%\\Microsoft\\Tencent 缓存",
                      "sources":  [
                                      "scripts/steam.run/cdks.run.001.ps1",
                                      "scripts/steam.run/steam.run.001.ps1",
                                      "scripts/steam.run/steam.run.002.ps1"
                                  ],
                      "enabled":  true,
                      "risk":  "medium",
                      "actions":  [
                                      {
                                          "type":  "file",
                                          "path":  "${LOCALAPPDATA}\\Microsoft\\Tencent",
                                          "recurse":  true
                                      }
                                  ]
                  },
                  {
                      "id":  "temp-scripts",
                      "title":  "下载用的临时脚本",
                      "sources":  [
                                      "scripts/steam-run.com/142785900.001.ps1",
                                      "scripts/steam-run.com/steam-run.com.001.ps1",
                                      "scripts/steam-run.com/steam-run.com.002.ps1",
                                      "scripts/steam-run.com/steam-run.com.003.ps1",
                                      "scripts/steam-run.com/steam-run.com.004.ps1",
                                      "scripts/steam.run/cdks.run.001.ps1",
                                      "scripts/steam.run/steam.run.001.ps1",
                                      "scripts/steam.run/steam.run.002.ps1",
                                      "scripts/cdk.ruku.run/cdk.ruku.run.ps1"
                                  ],
                      "enabled":  true,
                      "risk":  "low",
                      "actions":  [
                                      {
                                          "type":  "file",
                                          "path":  "${USERPROFILE}\\get.ps1"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${ScriptRoot}\\a.ps1"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${TEMP}\\1.ps1"
                                      }
                                  ]
                  },
                  {
                      "id":  "defender-exclusions",
                      "title":  "Windows Defender 排除项 (需确认)",
                      "sources":  [
                                      "scripts/steam-run.com/142785900.001.ps1",
                                      "scripts/steam-run.com/steam-run.com.001.ps1",
                                      "scripts/steam-run.com/steam-run.com.002.ps1",
                                      "scripts/steam-run.com/steam-run.com.003.ps1",
                                      "scripts/steam-run.com/steam-run.com.004.ps1",
                                      "scripts/steam.work/steam.icu.001.ps1",
                                      "scripts/cdk.ruku.run/a.ps1",
                                      "scripts/cdk.ruku.run/cdk.ruku.run.ps1",
                                      "scripts/steam.run/cdks.run.001.ps1",
                                      "scripts/steam.run/steam.run.001.ps1",
                                      "scripts/steam.run/steam.run.002.ps1",
                                      "scripts/steam-run.com/steamcdkey.cn.001.ps1"
                                  ],
                      "enabled":  true,
                      "risk":  "high",
                      "confirm":  true,
                      "actions":  [
                                      {
                                          "type":  "defender-exclusion-path",
                                          "path":  "${SteamPath}"
                                      },
                                      {
                                          "type":  "defender-exclusion-path",
                                          "path":  "${APPDATA}\\Stool"
                                      },
                                      {
                                          "type":  "defender-exclusion-extension",
                                          "name":  "exe"
                                      },
                                      {
                                          "type":  "defender-exclusion-extension",
                                          "name":  "dll"
                                      },
                                      {
                                          "name":  ".exe",
                                          "type":  "defender-exclusion-extension"
                                      },
                                      {
                                          "name":  ".dll",
                                          "type":  "defender-exclusion-extension"
                                      },
                                      {
                                          "type":  "defender-exclusion-path",
                                          "path":  "${SteamPath}\\xinput1_4.dll"
                                      },
                                      {
                                          "type":  "defender-exclusion-path",
                                          "path":  "${SteamPath}\\dwmapi.dll"
                                      },
                                      {
                                          "type":  "defender-exclusion-path",
                                          "path":  "${SteamPath}\\hid.dll"
                                      },
                                      {
                                          "type":  "defender-exclusion-path",
                                          "path":  "${SteamPath}\\steamcdk.exe"
                                      }
                                  ]
                  },
                  {
                      "id":  "smartscreen-ci-policy-registry",
                      "title":  "SmartScreen / CI Policy 相关注册表改动 (需确认)",
                      "sources":  [
                                      "scripts/cdk.ruku.run/a.ps1",
                                      "scripts/cdk.ruku.run/cdk.ruku.run.ps1"
                                  ],
                      "enabled":  true,
                      "risk":  "high",
                      "confirm":  true,
                      "actions":  [
                                      {
                                          "type":  "registry-value",
                                          "path":  "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\CI\\Policy",
                                          "name":  "VerifiedAndReputablePolicyState"
                                      },
                                      {
                                          "type":  "registry-value",
                                          "path":  "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer",
                                          "name":  "SmartScreenEnabled"
                                      },
                                      {
                                          "type":  "registry-value",
                                          "path":  "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\System",
                                          "name":  "EnableSmartScreen"
                                      },
                                      {
                                          "type":  "registry-value",
                                          "path":  "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows Defender\\SmartScreen",
                                          "name":  "ConfigureAppInstallControl"
                                      },
                                      {
                                          "type":  "registry-value",
                                          "path":  "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows Defender\\SmartScreen",
                                          "name":  "ConfigureAppInstallControlEnabled"
                                      },
                                      {
                                          "type":  "registry-value",
                                          "path":  "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows Defender\\SmartScreen",
                                          "name":  "EnableSmartScreenInShell"
                                      }
                                  ]
                  },
                  {
                      "id":  "startup-steamauthdaemon",
                      "title":  "启动项 SteamAuthDaemon (需确认)",
                      "sources":  [
                                      "scripts/cdk.ruku.run/a.ps1",
                                      "scripts/cdk.ruku.run/cdk.ruku.run.ps1"
                                  ],
                      "enabled":  true,
                      "risk":  "medium",
                      "confirm":  true,
                      "actions":  [
                                      {
                                          "type":  "registry-value",
                                          "path":  "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Run",
                                          "name":  "SteamAuthDaemon"
                                      }
                                  ]
                  },
                  {
                      "id":  "process-steam-auth",
                      "title":  "steam_auth 进程 (需确认)",
                      "sources":  [
                                      "scripts/cdk.ruku.run/a.ps1",
                                      "scripts/cdk.ruku.run/cdk.ruku.run.ps1"
                                  ],
                      "enabled":  true,
                      "risk":  "medium",
                      "confirm":  true,
                      "actions":  [
                                      {
                                          "type":  "process",
                                          "name":  "steam_auth"
                                      }
                                  ]
                  },
                  {
                      "id":  "downloaded-steamcdk-exe",
                      "title":  "STEAM 目录下载的 steamcdk.exe (需确认)",
                      "sources":  [
                                      "scripts/cdk.ruku.run/a.ps1",
                                      "scripts/cdk.ruku.run/cdk.ruku.run.ps1"
                                  ],
                      "enabled":  true,
                      "risk":  "high",
                      "confirm":  true,
                      "actions":  [
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\steamcdk.exe"
                                      }
                                  ]
                  },
                  {
                      "id":  "opensteamtool-root-files",
                      "title":  "OpenSteamTool 根目录文件",
                      "sources":  [
                                      "https://github.com/OpenSteam001/OpenSteamTool"
                                  ],
                      "enabled":  true,
                      "risk":  "low",
                      "actions":  [
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\OpenSteamTool.dll"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\dwmapi.dll"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\xinput1_4.dll"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\opensteamtool.toml"
                                      }
                                  ]
                  },
                  {
                      "id":  "opensteamtool-lua-config",
                      "title":  "OpenSteamTool Lua 配置目录 (需确认)",
                      "sources":  [
                                      "https://github.com/OpenSteam001/OpenSteamTool"
                                  ],
                      "enabled":  true,
                      "risk":  "medium",
                      "confirm":  true,
                      "actions":  [
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\config\\lua",
                                          "recurse":  true
                                      }
                                  ]
                  },
                  {
                      "id":  "steamking-installed-app",
                      "title":  "SteamKing 安装本体残留 (需确认)",
                      "sources":  [
                                      "D:/Downloads/SteamKing-Setup-1.5.3.exe"
                                  ],
                      "enabled":  true,
                      "risk":  "medium",
                      "confirm":  true,
                      "actions":  [
                                      {
                                          "type":  "process",
                                          "name":  "SteamKing"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "%ProgramFiles%\\SteamKing",
                                          "recurse":  true
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${LOCALAPPDATA}\\SteamKing",
                                          "recurse":  true
                                      },
                                      {
                                          "type":  "registry-key",
                                          "path":  "HKLM:\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\{A7C3E9F1-2B4D-4F6A-9C8E-1D5F7A3B2E90}_is1",
                                          "recurse":  true
                                      }
                                  ]
                  },
                  {
                      "id":  "steam-extra-exes",
                      "title":  "STEAM 目录新增可执行文件 (需确认)",
                      "sources":  [
                                      "scripts/steam-run.com/steamcdkey.cn.001.ps1"
                                  ],
                      "enabled":  true,
                      "risk":  "high",
                      "confirm":  true,
                      "actions":  [
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\steam-lucky.exe"
                                      }
                                  ]
                  },
                  {
                      "id":  "fake-library-team-steam-root-artifacts",
                      "title":  "假入库团队 powershell2 根目录残留 (需确认)",
                      "sources":  [
                                      "https://gitee.com/mrsiyecao/powershell2"
                                  ],
                      "enabled":  true,
                      "risk":  "high",
                      "confirm":  true,
                      "actions":  [
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\legit"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\legit64"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\legit64274"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\legit.zip"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\legit64.dll"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\legit197.vdf"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\legit200.vdf"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\legit203.vdf"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\legit206.vdf"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\legit214.vdf"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\legit215.vdf"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\legit218.vdf"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\2358721_143266280896848005.manifest"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\2358721_2985710911012900154.manifest"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\ANNO117.zip"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\ANNO117 - 副本.zip"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\anno1800.zip"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\ERN.zip"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\REPO.zip"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\ROTSP.zip"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\Grounded2"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\winhttp-log.txt"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\winhttp-log1.txt"
                                      }
                                  ]
                  },
                  {
                      "id":  "steam-apps-manifest-registry",
                      "title":  "STEAM Apps Manifest 注册表项 (需确认)",
                      "sources":  [
                                      "scripts/steam-run.com/steamcdkey.cn.001.ps1"
                                  ],
                      "enabled":  true,
                      "risk":  "high",
                      "confirm":  true,
                      "actions":  [
                                      {
                                          "type":  "registry-key",
                                          "path":  "HKCU:\\Software\\Valve\\Steam\\Apps\\3545990",
                                          "recurse":  true
                                      },
                                      {
                                          "type":  "registry-key",
                                          "path":  "HKCU:\\Software\\Valve\\Steam\\Apps\\2050650",
                                          "recurse":  true
                                      },
                                      {
                                          "type":  "registry-key",
                                          "path":  "HKCU:\\Software\\Valve\\Steam\\Apps\\3218580",
                                          "recurse":  true
                                      }
                                  ]
                  },
                  {
                      "id":  "windows-update-pause-policy",
                      "title":  "Windows Update 暂停更新策略 (需确认)",
                      "sources":  [
                                      "scripts/steam-run.com/steamcdkey.cn.001.ps1"
                                  ],
                      "enabled":  true,
                      "risk":  "high",
                      "confirm":  true,
                      "actions":  [
                                      {
                                          "type":  "registry-value",
                                          "path":  "HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings",
                                          "name":  "FlightSettingsMaxPauseDays"
                                      },
                                      {
                                          "type":  "registry-value",
                                          "path":  "HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings",
                                          "name":  "PauseFeatureUpdatesStartTime"
                                      },
                                      {
                                          "type":  "registry-value",
                                          "path":  "HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings",
                                          "name":  "PauseFeatureUpdatesEndTime"
                                      },
                                      {
                                          "type":  "registry-value",
                                          "path":  "HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings",
                                          "name":  "PauseQualityUpdatesStartTime"
                                      },
                                      {
                                          "type":  "registry-value",
                                          "path":  "HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings",
                                          "name":  "PauseQualityUpdatesEndTime"
                                      },
                                      {
                                          "type":  "registry-value",
                                          "path":  "HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings",
                                          "name":  "PauseUpdatesStartTime"
                                      },
                                      {
                                          "type":  "registry-value",
                                          "path":  "HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings",
                                          "name":  "PauseUpdatesExpiryTime"
                                      }
                                  ]
                  },
                  {
                      "id":  "stool-scheduled-tasks",
                      "title":  "%APPDATA%\\\\Stool 相关计划任务 (需确认)",
                      "sources":  [
                                      "scripts/steam-run.com/steamcdkey.cn.001.ps1"
                                  ],
                      "enabled":  true,
                      "risk":  "high",
                      "confirm":  true,
                      "actions":  [
                                      {
                                          "type":  "task-contains",
                                          "contains":  "${APPDATA}\\Stool"
                                      },
                                      {
                                          "type":  "task-contains",
                                          "contains":  "%APPDATA%\\Stool"
                                      }
                                  ]
                  }
              ]
}
'@

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

    $fallback = 'Gray'
    if ([enum]::TryParse([ConsoleColor], [string]$Color, $true, [ref]$fallback)) {
        Write-Host $Message -ForegroundColor $fallback -NoNewline:$NoNewline
    }
    else {
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
    Write-Status '  回车/Enter = 确认清理      |  ESC = 取消清理' Muted
    Write-Status '  选择: ' Accent -NoNewline

    if ([Console]::IsInputRedirected) {
        Write-Status '取消（非交互环境）' Warning
        return $false
    }

    $oldTreatControlCAsInput = $null
    try {
        $oldTreatControlCAsInput = [Console]::TreatControlCAsInput
        [Console]::TreatControlCAsInput = $true
    }
    catch {}

    try {
        while ($true) {
            $key = [Console]::ReadKey($true)
            if ($key.Key -eq 'Enter') {
                Write-Status '确认清理' Accent
                return $true
            }
            if ($key.Key -eq 'Escape' -or (($key.Modifiers -band [ConsoleModifiers]::Control) -and $key.Key -eq 'C')) {
                Write-Status '取消' Warning
                return $false
            }
        }
    }
    finally {
        if ($null -ne $oldTreatControlCAsInput) {
            try { [Console]::TreatControlCAsInput = $oldTreatControlCAsInput } catch {}
        }
    }
}


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
    try {
        $path = (Get-ItemProperty -Path 'HKCU:\Software\Valve\Steam' -ErrorAction Stop).SteamPath
        if ($path -and (Test-Path -LiteralPath $path -PathType Container)) {
            return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($path)
        }
    }
    catch {}

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

function Test-ActionExists {
    param($Action, [hashtable]$Variables)

    switch ($Action.type) {
        'file' {
            $path = Resolve-Template -Text $Action.path -Variables $Variables
            return [bool](Test-Path -LiteralPath $path)
        }
        'registry-key' {
            return [bool](Test-Path -Path $Action.path)
        }
        'registry-value' {
            if (-not (Test-Path -Path $Action.path)) { return $false }
            return $null -ne (Get-ItemProperty -Path $Action.path -Name $Action.name -ErrorAction SilentlyContinue)
        }
        'defender-exclusion-path' {
            $pref = Get-MpPreference -ErrorAction SilentlyContinue
            if (-not $pref) { return $false }
            $path = Resolve-Template -Text $Action.path -Variables $Variables
            return $pref.ExclusionPath -contains $path
        }
        'defender-exclusion-extension' {
            $pref = Get-MpPreference -ErrorAction SilentlyContinue
            return $pref -and ($pref.ExclusionExtension -contains $Action.name)
        }
        'process' {
            return $null -ne (Get-Process -Name ([System.IO.Path]::GetFileNameWithoutExtension($Action.name)) -ErrorAction SilentlyContinue)
        }
        'service' {
            return $null -ne (Get-Service -Name $Action.name -ErrorAction SilentlyContinue)
        }
        'task' {
            return $null -ne (Get-ScheduledTask -TaskName $Action.name -ErrorAction SilentlyContinue)
        }
        'task-contains' {
            $needle = Resolve-Template -Text $Action.contains -Variables $Variables
            $matches = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
                $task = $_
                @($task.Actions) | Where-Object {
                    ([string]$_.Execute -like "*$needle*") -or ([string]$_.Arguments -like "*$needle*")
                }
            }
            return $null -ne (@($matches)[0])
        }
        default {
            return $false
        }
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
            $path = Resolve-Template -Text $Action.path -Variables $Variables
            Remove-MpPreference -ExclusionPath $path
            return 'removed'
        }
        'defender-exclusion-extension' {
            Remove-MpPreference -ExclusionExtension $Action.name
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
            return 'removed'
        }
        'task-contains' {
            $needle = Resolve-Template -Text $Action.contains -Variables $Variables
            $matches = @(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
                $task = $_
                @($task.Actions) | Where-Object {
                    ([string]$_.Execute -like "*$needle*") -or ([string]$_.Arguments -like "*$needle*")
                }
            })
            foreach ($task in $matches) {
                Unregister-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -Confirm:$false
            }
            if ($matches.Count -gt 0) { return 'removed' }
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
        'defender-exclusion-path' { return "Defender Path: $(Resolve-Template -Text $Action.path -Variables $Variables)" }
        'defender-exclusion-extension' { return "Defender Extension: $($Action.name)" }
        'process' { return "Process: $($Action.name)" }
        'service' { return "Service: $($Action.name)" }
        'task' { return "Task: $($Action.name)" }
        'task-contains' { return "Task contains: $(Resolve-Template -Text $Action.contains -Variables $Variables)" }
        default { return $Action.type }
    }
}


function Get-ActionCategory {
    param($Action)

    switch ($Action.type) {
        'file' {
            $p = [string]$Action.path
            if ($p -match '\\.exe($|\\.)') { return 'exe' }
            if ($p -match '\\.dll($|\\.)') { return 'dll' }
            if ($p -match 'steam\.cfg|appdata\.vdf|packageinfo\.vdf|localData\.vdf|package\\\\beta|opensteamtool\.toml|config\\\\lua') { return 'steam-config' }
            return 'file'
        }
        'registry-key' { return 'registry' }
        'registry-value' { return 'registry' }
        'defender-exclusion-path' { return 'security' }
        'defender-exclusion-extension' { return 'security' }
        'process' { return 'process' }
        'service' { return 'startup' }
        'task' { return 'startup' }
        'task-contains' { return 'startup' }
        default { return 'other' }
    }
}

function Get-CategoryTitle {
    param([string]$Category)

    switch ($Category) {
        'exe' { return '可执行文件' }
        'dll' { return '注入 DLL' }
        'steam-config' { return 'STEAM 配置项' }
        'registry' { return '注册表' }
        'startup' { return '启动项 / 服务 / 计划任务' }
        'security' { return '安全排除项 / 系统策略' }
        'process' { return '后台驻留进程' }
        'file' { return '文件 / 目录残留' }
        default { return '其他' }
    }
}
function Save-DesktopTextReport {
    param(
        [object]$Report,
        [object[]]$DetectedItems,
        [string]$BackupPath
    )

    $desktop = [Environment]::GetFolderPath('Desktop')
    if ([string]::IsNullOrWhiteSpace($desktop) -or -not (Test-Path -LiteralPath $desktop)) {
        $desktop = $scriptRoot
    }

    $fileName = "SteamSPA-clean-report-{0}.txt" -f (Get-Date -Format 'yyyyMMdd-HHmmss')
    $path = Join-Path $desktop $fileName
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('SteamSPA 清理报告')
    $lines.Add(('生成时间: {0}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')))
    $lines.Add('')
    $lines.Add('清理状态')
    $lines.Add(('  发现: {0}' -f $Report.summary.detected))
    $lines.Add(('  删除: {0}' -f $Report.summary.removed))
    $lines.Add(('  失败: {0}' -f $Report.summary.failed))
    $lines.Add(('  跳过: {0}' -f $Report.summary.skipped))
    if (-not [string]::IsNullOrWhiteSpace($BackupPath)) {
        $lines.Add(('  备份目录: {0}' -f $BackupPath))
    }
    $lines.Add('')
    $lines.Add('残留明细')

    if (-not $DetectedItems -or $DetectedItems.Count -eq 0) {
        $lines.Add('  未发现需要清理的项目。')
    }
    else {
        $index = 1
        foreach ($item in $DetectedItems) {
            $lines.Add(('{0}. [{1}] {2}' -f $index, (Get-CategoryTitle -Category $item.Category), $item.RuleTitle))
            $lines.Add(('   规则: {0}' -f $item.RuleId))
            $lines.Add(('   类型: {0}' -f $item.Action.type))
            $lines.Add(('   目标: {0}' -f $item.Label))
            $lines.Add('')
            $index++
        }
    }

    try {
        $lines | Set-Content -LiteralPath $path -Encoding UTF8
    }
    catch {
        $path = Join-Path $scriptRoot $fileName
        $lines.Add('')
        $lines.Add(('注意: 桌面报告写入失败，已改为保存到脚本目录。原因: {0}' -f $_.Exception.Message))
        $lines | Set-Content -LiteralPath $path -Encoding UTF8
    }

    return $path
}

Clear-Host
$host.UI.RawUI.WindowTitle = 'STEAM SPA - 假入库清杀工具'
Write-Blank
Write-GradientText '  ███████ ████████ ███████  █████  ███    ███     ███████ ██████   █████  '
Write-GradientText '  ██         ██    ██      ██   ██ ████  ████     ██      ██   ██ ██   ██ '
Write-GradientText '  ███████    ██    █████   ███████ ██ ████ ██     ███████ ██████  ███████ '
Write-GradientText '       ██    ██    ██      ██   ██ ██  ██  ██          ██ ██      ██   ██ '
Write-GradientText '  ███████    ██    ███████ ██   ██ ██      ██     ███████ ██      ██   ██ '
Write-Blank
Write-Status '  假入库清理/专杀工具：秒杀各种注入DLL/STEAM配置/注册表/启动项/系统服务/安全策略/后台进程等' Muted
Write-Status '  作者：万能小哥' Muted

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
    }
}

$rules = @($targets.rules) | Where-Object {
    ($_.enabled -ne $false) -and
    ($Risk -contains $_.risk) -and
    (-not $Only -or $Only -contains $_.id)
}

$detectedItems = @()

$scanTotal = [Math]::Max(1, @($rules).Count)
$scanCurrent = 0
Write-Section '🖥️ 本机信息'
Write-KeyValue '操作系统' $variables.OS
if ($variables.SteamPath) {
    Write-KeyValue 'STEAM路径' $variables.SteamPath
}
else {
    Write-KeyValue 'STEAM路径' '未检测到' Warning
}

Write-Section '🔍 扫描'
Write-ProgressLine -Current 0 -Total $scanTotal -Status '扫描中'

foreach ($rule in $rules) {
    $ruleReport = [ordered]@{
        id      = $rule.id
        title   = $rule.title
        risk    = $rule.risk
        actions = @()
    }

    $detectedActions = @()
    foreach ($action in @($rule.actions)) {
        $label = Format-ActionLabel -Action $action -Variables $variables
        $exists = Test-ActionExists -Action $action -Variables $variables
        if ($exists) {
            $report.summary.detected++
            $detectedActions += $action
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

        $ruleReport.actions += [ordered]@{
            type   = $action.type
            target = $label
            exists = [bool]$exists
        }
    }

    $report.targets += $ruleReport
    $scanCurrent++
    if ($scanCurrent -lt $scanTotal) {
        Write-ProgressLine -Current $scanCurrent -Total $scanTotal -Status '扫描中'
    }
}

Write-ProgressLine -Current $scanTotal -Total $scanTotal -Status '扫描完成'

if ($detectedItems.Count -eq 0) {
    Write-Result '✓' '安全' '未发现需要清理的项目。' Success
    Write-KeyValue '已扫描到' '0 项' Success
}
else {
    $categoryOrder = @('exe', 'dll', 'steam-config', 'registry', 'startup', 'security', 'process', 'file', 'other')
    foreach ($category in $categoryOrder) {
        $items = @($detectedItems | Where-Object { $_.Category -eq $category })
        if ($items.Count -eq 0) { continue }

        Write-Status ("  {0} ({1})" -f (Get-CategoryTitle -Category $category), $items.Count) Accent
        $index = 1
        foreach ($item in $items) {
            Write-Status ('    {0,2}. ' -f $index) Muted -NoNewline
            Write-Status $item.RuleTitle Danger -NoNewline
            Write-Status '  ·  ' Dim -NoNewline
            Write-Status $item.Action.type Muted
            Write-Status ("        {0}" -f $item.Label) Path
            $index++
        }
        Write-Blank
    }
    Write-KeyValue '已扫描到' ($detectedItems.Count.ToString() + ' 项') Danger

    Write-Section '⚠️ 注意事项'
    Write-Status '    1. 此工具不影响游戏、存档、创意工坊、MOD，请放心使用~' WarningSoft
    Write-Status '    2. 清理后可能需要重新登录 STEAM !' WarningSoft
    Write-Status '    3. 请确保还记得账户名称、邮箱、密码、手机令牌!' WarningSoft
    Write-Status '    4. 如清理失败，请退出杀毒软件后重试!' WarningSoft

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
$textReportPath = $null
if ($report.summary.removed -gt 0 -and $report.summary.failed -eq 0) {
    $textReportPath = Save-DesktopTextReport -Report $report -DetectedItems $detectedItems -BackupPath $(if (-not $NoBackup) { $backupRoot } else { '' })
}

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
if ($textReportPath) {
    Write-KeyValue 'TXT 报告' $textReportPath Path
}

if ($report.summary.removed -gt 0 -and -not $NoBackup) {
    Write-KeyValue '备份' $backupRoot Path
}

Write-Blank
if (-not $NoPause) {
    Write-Blank
    Write-Status '  按任意键退出...' Muted -NoNewline
    if (-not [Console]::IsInputRedirected) {
        [Console]::ReadKey($true) | Out-Null
    }
    else {
        Write-Host ''
    }
}
