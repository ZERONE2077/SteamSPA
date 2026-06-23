<#
.SYNOPSIS
    SteamSPA clean engine.
.DESCRIPTION
    Uses embedded targets and performs scan or cleanup for leftover traces.
    Default mode is scan. Add -Clean to remove detected targets.
#>
# NOTE:
# This script intentionally avoids a script-level param() block so it can be
# executed by `irm <raw-url> | iex` reliably. Arguments are parsed from $args
# for normal `-File` usage.
$Clean = $false
$NoBackup = $false
$NoPause = $false
$Only = @()
$Risk = @('low', 'medium')
$TargetsPath = $null

for ($i = 0; $i -lt $args.Count; $i++) {
    switch -Regex ($args[$i]) {
        '^-Clean$' { $Clean = $true; continue }
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
                if (-not $Risk -or $Risk.Count -eq 0) { $Risk = @('low', 'medium') }
            }
            continue
        }
        '^-TargetsPath$' {
            $i++
            if ($i -lt $args.Count) { $TargetsPath = [string]$args[$i] }
            continue
        }
    }
}

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSVersion -lt [version]'5.1') {
    throw 'SteamSPA uninstall.ps1 requires Windows PowerShell 5.1 or later.'
}

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($Clean -and -not $isAdmin) {
    throw '清理模式需要以管理员身份运行 PowerShell。请右键 PowerShell，选择“以管理员身份运行”，然后重新执行命令。'
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
                 "description":  "Steam 假入库残留清理清单。每条规则描述一个来源脚本所留下的痕迹。"
             },
    "rules":  [
                  {
                      "id":  "steam-inject-dlls",
                      "title":  "Steam 目录注入 DLL",
                      "sources":  [
                                      "scripts/steam-run.com/142785900.001.ps1",
                                      "scripts/steam-run.com/steam-run.com.001.ps1",
                                      "scripts/steam-run.com/steam-run.com.002.ps1",
                                      "scripts/steam-run.com/steam-run.com.003.ps1",
                                      "scripts/steam-run.com/steam-run.com.004.ps1",
                                      "scripts/steam.run/cdks.run.001.ps1",
                                      "scripts/steam.run/steam.run.001.ps1",
                                      "scripts/steam.run/steam.run.002.ps1",
                                      "scripts/steam.work/steam.icu.001.ps1"
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
                                          "path":  "${SteamPath}\\dwmapi.log"
                                      },
                                      {
                                          "type":  "file",
                                          "path":  "${SteamPath}\\hid.dll"
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
                                          "path":  "${SteamPath}\\wtsapi32.dll"
                                      }
                                  ]
                  },
                  {
                      "id":  "steam-config-files",
                      "title":  "Steam 配置文件 / Beta 标志 / appdata 缓存",
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
                                      "scripts/steam-run.com/steam-run.com.004.ps1"
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
                                      "scripts/cdk.ruku.run/a.ps1"
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
                                      }
                                  ]
                  },
                  {
                      "id":  "smartscreen-ci-policy-registry",
                      "title":  "SmartScreen / CI Policy 相关注册表改动 (需确认)",
                      "sources":  [
                                      "scripts/cdk.ruku.run/a.ps1"
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
                                      "scripts/cdk.ruku.run/a.ps1"
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
                                      "scripts/cdk.ruku.run/a.ps1"
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
                      "title":  "Steam 目录下载的 steamcdk.exe (需确认)",
                      "sources":  [
                                      "scripts/cdk.ruku.run/a.ps1"
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
                  }
              ]
}

'@

function Write-Status {
    param([string]$Message, [ConsoleColor]$Color = 'Gray')
    Write-Host $Message -ForegroundColor $Color
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
            return $path
        }
    }
    catch {}

    return $null
}

function Get-Variables {
    return @{
        APPDATA      = $env:APPDATA
        LOCALAPPDATA = $env:LOCALAPPDATA
        ProgramData  = $env:ProgramData
        ScriptRoot   = $scriptRoot
        SteamPath    = (Get-SteamPath)
        TEMP         = $env:TEMP
        USERPROFILE  = $env:USERPROFILE
    }
}

function Read-Targets {
    param([string]$Path)

    if (-not [string]::IsNullOrWhiteSpace($Path)) {
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
            throw "未找到 targets.json: $Path"
        }
        return Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    }

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
        default {
            throw "不支持的动作类型: $($Action.type)"
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
        default { return $Action.type }
    }
}

function Save-Report {
    param(
        [object]$Report,
        [string]$Root
    )

    if (-not (Test-Path -LiteralPath $Root)) {
        New-Item -ItemType Directory -Path $Root -Force | Out-Null
    }

    $path = Join-Path $Root ("report-{0}.json" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
    $Report | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $path -Encoding UTF8
    return $path
}

Clear-Host
Write-Status '========================================' Cyan
Write-Status '  SteamSPA 假入库残留扫描 / 清理' Cyan
Write-Status '========================================' Cyan
Write-Host ''

if ($Clean) {
    Write-Status '当前模式: 清理' Yellow
}
else {
    Write-Status '当前模式: 扫描（不会删除任何内容）' Yellow
}

$variables = Get-Variables
if ($variables.SteamPath) {
    Write-Status "Steam 目录: $($variables.SteamPath)" Green
}
else {
    Write-Status '未检测到 Steam 目录。' Yellow
}

$targets = Read-Targets -Path $TargetsPath
$backupRoot = Join-Path $scriptRoot (Join-Path 'temp\backups' (Get-Date -Format 'yyyyMMdd-HHmmss'))
$logRoot = Join-Path $scriptRoot 'temp\logs'

$report = [ordered]@{
    startedAt = (Get-Date).ToString('o')
    mode      = if ($Clean) { 'clean' } else { 'scan' }
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

Write-Host ''
Write-Status "加载规则: $($rules.Count) 条" Cyan
Write-Host ''

$detectedItems = @()

foreach ($rule in $rules) {
    Write-Status "[$($rule.id)] $($rule.title)" Yellow
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
            }
            Write-Status "  [发现] $label" Green
        }
        else {
            Write-Status "  [不存在] $label" DarkGray
        }

        $ruleReport.actions += [ordered]@{
            type   = $action.type
            target = $label
            exists = [bool]$exists
        }
    }

    $report.targets += $ruleReport
    Write-Host ''
}

if ($Clean) {
    Write-Status '========================================' Cyan
    Write-Status '  待清理项目汇总' Cyan
    Write-Status '========================================' Cyan

    if ($detectedItems.Count -eq 0) {
        Write-Status '未发现需要清理的项目。' Green
    }
    else {
        $index = 1
        foreach ($item in $detectedItems) {
            $riskColor = switch ($item.Risk) {
                'high' { 'Red' }
                'medium' { 'Yellow' }
                default { 'Gray' }
            }
            Write-Host ("[{0}] " -f $index) -NoNewline -ForegroundColor Cyan
            Write-Host ("{0} / {1} / {2}" -f $item.RuleId, $item.Action.type, $item.Risk) -ForegroundColor $riskColor
            Write-Status ("    {0}" -f $item.Label) Gray
            $index++
        }

        Write-Host ''
        Write-Status '上面是本次检测到的全部残留项。' Yellow
        Write-Status '按 Enter 确认删除以上项目；输入 N 后回车取消。' Yellow
        $answer = Read-Host '确认'

        if ($answer -eq 'N' -or $answer -eq 'n') {
            $report.summary.skipped += $detectedItems.Count
            Write-Status '已取消清理，未删除任何项目。' Yellow
        }
        else {
            Write-Host ''
            Write-Status '开始清理...' Cyan
            foreach ($item in $detectedItems) {
                try {
                    $result = Remove-Action -Action $item.Action -Variables $variables -BackupRoot $backupRoot -NoBackup:$NoBackup
                    if ($result -eq 'removed') {
                        $report.summary.removed++
                        Write-Status "  [已删除] $($item.Label)" Green
                    }
                    else {
                        $report.summary.skipped++
                        Write-Status "  [跳过] $($item.Label)" DarkGray
                    }
                }
                catch {
                    $report.summary.failed++
                    Write-Status "  [失败] $($item.Label) - $($_.Exception.Message)" Red
                }
            }
        }
    }

    Write-Host ''
}

$reportPath = Save-Report -Report $report -Root $logRoot

Write-Status '========================================' Cyan
Write-Status '  完成' Cyan
Write-Status '========================================' Cyan
Write-Status "发现: $($report.summary.detected)" Gray
Write-Status "删除: $($report.summary.removed)" Gray
Write-Status "失败: $($report.summary.failed)" Gray
Write-Status "跳过: $($report.summary.skipped)" Gray
Write-Status "报告: $reportPath" Gray

if ($Clean -and -not $NoBackup) {
    Write-Status "备份: $backupRoot" Gray
}

Write-Host ''
Write-Status '建议后续在 Steam 中验证游戏文件完整性，并重启 Steam。' Yellow

if (-not $NoPause) {
    Read-Host '按 Enter 键退出'
}


