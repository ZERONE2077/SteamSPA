# SteamSPA · STEAM 假入库残留清理工具
# 单文件：规则和程序都在这里。新增痕迹改下面的 JSON，然后跑 tests/SmokeTests.ps1。
# 整个程序包在 & { } 里运行：irm | iex 时不会在用户会话里留下函数和变量。
& {
$SteamSPAReleaseVersion = '4.0'
$SteamSPAUpdatedAt = '2026-10-30'

# 规则库：id 不要改（-Only 参数用它）；路径只写样本实际写入的精确位置。
$EmbeddedTargetsJson = @'
{
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

# SteamSPA · 终端输出层
# 只有这个文件直接调用 Write-Host / Read-Host。其余模块只返回数据。
# 支持真彩色时用 24 位 ANSI；老控制台退回 ConsoleColor；输出被重定向时纯文本。

function Initialize-SpaConsole {
    $redirected = [Console]::IsOutputRedirected
    # 重定向时也要切 UTF-8：publish.ps1 / 测试通过管道读取中文输出。
    try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch {}

    $ansi = $false
    if (-not $redirected -and -not $env:NO_COLOR) {
        try { $ansi = [bool]$Host.UI.SupportsVirtualTerminal } catch {}
        if ($env:WT_SESSION) { $ansi = $true }
    }

    $Spa.Ui = @{
        Redirected      = $redirected
        InputRedirected = [Console]::IsInputRedirected
        Ansi            = $ansi
        Color           = (-not $redirected -and -not $env:NO_COLOR)
    }
}

function Get-UiRgb {
    param([string]$Role)
    switch ($Role) {
        'Muted'   { '148;163;184' }
        'Dim'     { '100;116;139' }
        'Accent'  { '125;211;252' }
        'Success' { '134;239;172' }
        'Warning' { '253;224;71' }
        'Danger'  { '252;165;165' }
        'Path'    { '186;230;253' }
        default   { '229;231;235' }
    }
}

function Write-Ui {
    param([string]$Text = '', [string]$Role = 'Ink', [switch]$NoNewline)

    $ui = $Spa.Ui
    if ($ui -and $ui.Ansi) {
        $esc = [char]27
        Write-Host ("$esc[38;2;$(Get-UiRgb $Role)m$Text$esc[0m") -NoNewline:$NoNewline
        return
    }
    if ($ui -and $ui.Color) {
        $color = switch ($Role) {
            'Muted'   { 'Gray' }
            'Dim'     { 'DarkGray' }
            'Accent'  { 'Cyan' }
            'Success' { 'Green' }
            'Warning' { 'Yellow' }
            'Danger'  { 'Red' }
            'Path'    { 'White' }
            default   { 'White' }
        }
        Write-Host $Text -ForegroundColor $color -NoNewline:$NoNewline
        return
    }
    Write-Host $Text -NoNewline:$NoNewline
}

# 艺术字：逐字符从青色渐变到绿色；不支持真彩色时整行用青色。
function Write-UiBanner {
    param([string[]]$Lines)
    $from = @(45, 212, 255)
    $to = @(110, 231, 183)
    $esc = [char]27
    foreach ($line in $Lines) {
        if (-not ($Spa.Ui -and $Spa.Ui.Ansi)) { Write-Ui $line Accent; continue }
        $sb = New-Object System.Text.StringBuilder
        $steps = [Math]::Max(1, $line.Length - 1)
        for ($i = 0; $i -lt $line.Length; $i++) {
            $t = $i / $steps
            $r = [int]($from[0] + ($to[0] - $from[0]) * $t)
            $g = [int]($from[1] + ($to[1] - $from[1]) * $t)
            $b = [int]($from[2] + ($to[2] - $from[2]) * $t)
            [void]$sb.Append("$esc[38;2;$r;$g;${b}m").Append($line[$i])
        }
        [void]$sb.Append("$esc[0m")
        Write-Host $sb.ToString()
    }
}

# 中文在终端里占两列，按字符数补空格会错位。
function Get-DisplayWidth {
    param([string]$Text)
    $width = 0
    foreach ($ch in ([string]$Text).ToCharArray()) {
        $c = [int]$ch
        if (($c -ge 0x1100 -and $c -le 0x115F) -or ($c -ge 0x2E80 -and $c -le 0xA4CF) -or
            ($c -ge 0xAC00 -and $c -le 0xD7A3) -or ($c -ge 0xF900 -and $c -le 0xFAFF) -or
            ($c -ge 0xFE30 -and $c -le 0xFE4F) -or ($c -ge 0xFF00 -and $c -le 0xFF60) -or
            ($c -ge 0xFFE0 -and $c -le 0xFFE6)) {
            $width += 2
        }
        else {
            $width += 1
        }
    }
    return $width
}

function Format-PadRight {
    param([string]$Text, [int]$Width)
    return $Text + (' ' * [Math]::Max(0, $Width - (Get-DisplayWidth $Text)))
}

# 章节标题：  ◆ 标题   说明
function Write-UiSection {
    param([string]$Title, [string]$Hint = '', [string]$HintRole = 'Muted')
    Write-Host ''
    Write-Ui '  ◆ ' Accent -NoNewline
    if ($Hint) {
        Write-Ui $Title Ink -NoNewline
        Write-Ui ('   ' + $Hint) $HintRole
    }
    else {
        Write-Ui $Title Ink
    }
}

function Write-UiKeyValue {
    param([string]$Key, [string]$Value, [string]$Role = 'Ink')
    Write-Ui ('    ' + (Format-PadRight $Key 12)) Muted -NoNewline
    Write-Ui $Value $Role
}

# 一行结果：  标签      内容
function Write-UiResult {
    param([string]$Tag, [string]$Text, [string]$Role = 'Ink')
    Write-Ui ('    ' + (Format-PadRight $Tag 10)) $Role -NoNewline
    Write-Ui $Text $Role
}

# 提示行：  !  内容（Warning）或  ·  内容（Muted）
function Write-UiNote {
    param([string]$Text, [switch]$Important)
    if ($Important) {
        Write-Ui '    !  ' Warning -NoNewline
        Write-Ui $Text Warning
    }
    else {
        Write-Ui '    ·  ' Dim -NoNewline
        Write-Ui $Text Muted
    }
}

# 菜单项：    [Y]  说明
function Write-UiOption {
    param([string]$Key, [string]$Text, [string]$Role = 'Ink')
    Write-Ui ('    ' + (Format-PadRight ('[' + $Key + ']') 8)) Accent -NoNewline
    Write-Ui $Text $Role
}

function Write-UiProgress {
    param([int]$Current, [int]$Total)
    if ($Spa.Ui -and $Spa.Ui.Redirected) { return }
    if ($Total -le 0) { $Total = 1 }
    $percent = [int][Math]::Floor($Current * 100 / $Total)
    $width = 30
    $filled = [int][Math]::Floor($percent * $width / 100)
    # 用 ASCII 画进度条：█ 在部分中文字体里是双宽，进度条会折行。
    $bar = ('=' * $filled) + (' ' * ($width - $filled))
    Write-Ui ("`r    扫描中 [{0}] {1,3}%" -f $bar, $percent) Accent -NoNewline
}

function Clear-UiProgress {
    if ($Spa.Ui -and $Spa.Ui.Redirected) { return }
    Write-Host ("`r" + (' ' * 60) + "`r") -NoNewline
}

# 读取一个选项。空输入或输入流结束时返回默认值（默认值应当是安全选项）。
function Read-UiChoice {
    param([string]$Prompt, [string[]]$Allowed, [string]$Default)
    while ($true) {
        Write-Host ''
        Write-Ui ('    ' + $Prompt + ' ') Accent -NoNewline
        $raw = Read-Host
        if ($null -eq $raw) { return $Default }
        $value = $raw.Trim().ToUpperInvariant()
        if ($value -eq '') { return $Default }
        if ($Allowed -contains $value) { return $value }
        if ($Spa.Ui -and $Spa.Ui.InputRedirected) { return $Default }
        Write-Ui ('    请输入 ' + ($Allowed -join ' / ') + '，或直接回车') Warning
    }
}

function Wait-UiExit {
    if ($Spa.Ui -and $Spa.Ui.InputRedirected) { return }
    Write-Host ''
    Write-Ui '    按回车退出...' Accent -NoNewline
    Read-Host | Out-Null
}

# SteamSPA · 运行环境：参数、权限、STEAM 路径、路径模板、删除安全边界

function ConvertFrom-SpaArguments {
    param([object[]]$Arguments)

    $options = @{
        Risk     = @('low', 'medium', 'high')
        Only     = @()
        NoPause  = $false
        ScanOnly = $false
        Help     = $false
        Elevated = $false
        Errors   = @()
    }
    $list = @($Arguments)

    for ($i = 0; $i -lt $list.Count; $i++) {
        $name = [string]$list[$i]
        if ($name -match '^-(NoPause|ScanOnly|Help|Elevated)$') {
            $options[$Matches[1]] = $true
        }
        elseif ($name -eq '-NoBackup') {
            # 已不再备份，仍接受这个参数以兼容旧命令。
        }
        elseif ($name -match '^[-/](\?|h)$') {
            $options.Help = $true
        }
        elseif ($name -match '^-(Risk|Only)$') {
            $key = $Matches[1]
            $i++
            if ($i -ge $list.Count) { $options.Errors += "$name 缺少参数值"; break }
            $values = @(@($list[$i]) | ForEach-Object { ([string]$_) -split ',' } |
                    ForEach-Object { $_.Trim() } | Where-Object { $_ })
            if ($key -eq 'Risk') {
                $bad = @($values | Where-Object { @('low', 'medium', 'high') -notcontains $_ })
                if ($bad.Count -gt 0 -or $values.Count -eq 0) {
                    $options.Errors += '-Risk 只接受 low,medium,high'
                    continue
                }
            }
            $options[$key] = $values
        }
        else {
            $options.Errors += "未知参数: $name"
        }
    }
    return $options
}

# 把选项还原成命令行参数（提权重启时使用）。
function ConvertTo-SpaArgumentList {
    param([hashtable]$Options)
    $out = @()
    if ($Options.Risk.Count -lt 3) { $out += '-Risk'; $out += ($Options.Risk -join ',') }
    if ($Options.Only.Count -gt 0) { $out += '-Only'; $out += ($Options.Only -join ',') }
    if ($Options.NoPause) { $out += '-NoPause' }
    return $out
}

function Test-SpaAdmin {
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Find-SteamPath {
    $candidates = New-Object System.Collections.Generic.List[string]
    # HKLM 的 InstallPath 大小写规范，先用它；HKCU 的 SteamPath 是全小写加正斜杠。
    foreach ($key in @('HKLM:\SOFTWARE\WOW6432Node\Valve\Steam', 'HKLM:\SOFTWARE\Valve\Steam', 'HKCU:\Software\Valve\Steam')) {
        $props = Get-ItemProperty -LiteralPath $key -ErrorAction SilentlyContinue
        if (-not $props) { continue }
        foreach ($value in @($props.SteamPath, $props.InstallPath)) {
            if ($value) { $candidates.Add([string]$value) }
        }
        if ($props.SteamExe) { $candidates.Add((Split-Path -Parent ([string]$props.SteamExe))) }
    }
    foreach ($root in @(${env:ProgramFiles(x86)}, $env:ProgramFiles)) {
        if ($root) { $candidates.Add((Join-Path $root 'Steam')) }
    }

    $existing = @()
    foreach ($path in $candidates) {
        $full = ([string]$path).Replace('/', '\').TrimEnd('\')
        if ($full -and (Test-Path -LiteralPath $full -PathType Container)) { $existing += $full }
    }
    # 优先选真的有 steam.exe 的目录。
    foreach ($path in $existing) {
        if (Test-Path -LiteralPath (Join-Path $path 'steam.exe') -PathType Leaf) { return $path }
    }
    if ($existing.Count -gt 0) { return $existing[0] }
    return $null
}

function Get-SpaOSName {
    try {
        $cv = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop
        $build = [int]$cv.CurrentBuildNumber
        $name = if ($build -ge 22000) { 'Windows 11' } else { 'Windows 10' }
        $version = if ($cv.DisplayVersion) { ' ' + $cv.DisplayVersion } elseif ($cv.ReleaseId) { ' ' + $cv.ReleaseId } else { '' }
        $ubr = if ($null -ne $cv.UBR) { '.' + $cv.UBR } else { '' }
        return ('{0}{1} (Build {2}{3})' -f $name, $version, $build, $ubr)
    }
    catch {
        return [Environment]::OSVersion.VersionString
    }
}

function Get-SpaVariables {
    return @{
        APPDATA      = $env:APPDATA
        LOCALAPPDATA = $env:LOCALAPPDATA
        ProgramData  = $env:ProgramData
        TEMP         = $env:TEMP
        USERPROFILE  = $env:USERPROFILE
        SteamPath    = (Find-SteamPath)
    }
}

# 展开 ${Name} 和 %ENV%。任何变量缺失都返回 $null，而不是拼出一个
# 残缺路径（例如没找到 STEAM 时 "${SteamPath}\hid.dll" 会变成盘符根目录下的 "\hid.dll"）。
function Resolve-SpaTemplate {
    param([string]$Text, [hashtable]$Variables)

    if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
    $result = $Text
    foreach ($match in [regex]::Matches($Text, '\$\{(\w+)\}')) {
        $value = [string]$Variables[$match.Groups[1].Value]
        if ([string]::IsNullOrWhiteSpace($value)) { return $null }
        $result = $result.Replace($match.Value, $value.TrimEnd('\'))
    }
    $result = [Environment]::ExpandEnvironmentVariables($result)
    if ($result -match '%[^%\\]+%') { return $null }
    return $result
}

function ConvertTo-SpaComparablePath {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return '' }
    $p = [Environment]::ExpandEnvironmentVariables($Path.Trim().Trim('"')).Replace('/', '\')
    return $p.TrimEnd('\').ToLowerInvariant()
}

# 删除前的硬性边界：只删完整的绝对路径；绝不删系统/用户根目录、STEAM 根目录，
# 也绝不碰游戏 (steamapps) 和存档 (userdata)。返回拒绝原因，允许则返回 $null。
function Get-SpaUnsafePathReason {
    param([string]$Path, [hashtable]$Variables)

    if ($Path -notmatch '^[A-Za-z]:\\.+') { return '不是完整的绝对路径' }
    $target = ConvertTo-SpaComparablePath $Path
    if ($target -match '\\\.\.(\\|$)') { return '路径包含 ..' }

    $steam = ConvertTo-SpaComparablePath ([string]$Variables.SteamPath)
    $roots = @($env:SystemRoot, $env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:ProgramData,
        $env:USERPROFILE, $env:APPDATA, $env:LOCALAPPDATA, $env:TEMP, $Variables.SteamPath)
    if ($steam) {
        $roots += @('config', 'bin', 'steamapps', 'userdata', 'package', 'appcache') | ForEach-Object { Join-Path $Variables.SteamPath $_ }
    }
    foreach ($root in $roots) {
        if ($root -and $target -eq (ConvertTo-SpaComparablePath $root)) { return '受保护的系统或 STEAM 目录' }
    }
    if ($target -match '^[a-z]:$') { return '磁盘根目录' }
    if ($target -match '\\(steamapps|userdata)(\\|$)') { return '游戏或存档目录' }
    return $null
}

# 以管理员身份在新窗口重新运行。脚本源码取自当前调用，
# 所以 irm | iex 和本地文件两种方式都能用，不需要重新下载。
function Start-SpaElevated {
    param([string]$SelfText, [hashtable]$Options)

    if ([string]::IsNullOrWhiteSpace($SelfText)) { return $false }
    try {
        $dir = Join-Path $env:TEMP 'SteamSPA'
        [IO.Directory]::CreateDirectory($dir) | Out-Null
        $file = Join-Path $dir ('SteamSPA-' + [guid]::NewGuid().ToString('N') + '.ps1')
        [IO.File]::WriteAllText($file, $SelfText, (New-Object System.Text.UTF8Encoding($true)))

        $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"' + $file + '"'), '-Elevated')
        $argList += @(ConvertTo-SpaArgumentList $Options | ForEach-Object { '"' + $_ + '"' })
        Start-Process -FilePath 'powershell.exe' -ArgumentList $argList -Verb RunAs -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# SteamSPA · 清理目标
# 每种规则动作类型在这里实现两件事：
#   Find-SpaActionTargets  把规则动作解析成本机上真实存在的目标（只读）
#   Remove-SpaTarget       删除一个目标
# 同一个物理目标在多条规则里出现时，用 Key 去重，只显示和删除一次。

function Get-SpaSupportedTypes {
    return @('file', 'registry-key', 'registry-value', 'defender-exclusion-path',
        'defender-exclusion-extension', 'defender-exclusion-process', 'process', 'task', 'task-contains')
}

function New-SpaTarget {
    param([string]$Type, [string]$Key, [string]$Label, [string]$Category,
        [hashtable]$Data, [string]$State = 'present', [string]$Note = '')
    return [pscustomobject]@{
        Type       = $Type
        Key        = ($Type + '|' + $Key).ToLowerInvariant()
        Label      = $Label
        Category   = $Category
        Data       = $Data
        State      = $State      # present / protected
        Note       = $Note
        Recurse    = [bool]$Data.Recurse
        RuleIds    = New-Object System.Collections.Generic.List[string]
        Risk       = 'low'
        Confirm    = $false
        Status     = ''          # removed / failed / skipped
        Message    = ''
    }
}

# ---------- Defender ----------

function Get-SpaDefenderState {
    param([switch]$Refresh)
    if ($Spa.Defender -and -not $Refresh) { return $Spa.Defender }

    $state = @{ Available = $false; Readable = $false; Path = @(); Extension = @(); Process = @() }
    if (Get-Command -Name Get-MpPreference -ErrorAction SilentlyContinue) {
        try {
            $pref = Get-MpPreference -ErrorAction Stop
            $state.Available = $true
            $state.Path = @($pref.ExclusionPath | Where-Object { $_ })
            $state.Extension = @($pref.ExclusionExtension | Where-Object { $_ })
            $state.Process = @($pref.ExclusionProcess | Where-Object { $_ })
            # 非管理员读到的是 "N/A: Must be an administrator to view exclusions"。
            $state.Readable = -not (@($state.Path + $state.Extension + $state.Process) | Where-Object { "$_" -like 'N/A*' })
        }
        catch {
            # 第三方杀软接管时 Defender 不可用，跳过即可。
        }
    }
    $Spa.Defender = $state
    return $state
}

function Find-SpaDefenderTargets {
    param([string]$Kind, [string]$Value)

    $state = Get-SpaDefenderState
    if (-not $state.Available) { return @() }
    if (-not $state.Readable) { $Spa.DefenderHidden = $true; return @() }

    switch ($Kind) {
        'path' {
            $want = ConvertTo-SpaComparablePath $Value
            $hits = @($state.Path | Where-Object { (ConvertTo-SpaComparablePath $_) -eq $want })
            $label = 'Defender 排除路径: ' + $Value
            $key = $want
        }
        'extension' {
            $want = $Value.TrimStart('.').ToLowerInvariant()
            $hits = @($state.Extension | Where-Object { ([string]$_).TrimStart('.').ToLowerInvariant() -eq $want })
            $label = 'Defender 排除扩展名: .' + $want
            $key = $want
        }
        'process' {
            $want = $Value.ToLowerInvariant()
            $hits = @($state.Process | Where-Object { ([string]$_).ToLowerInvariant() -eq $want })
            $label = 'Defender 排除进程: ' + $Value
            $key = $want
        }
    }
    if ($hits.Count -eq 0) { return @() }
    return (New-SpaTarget -Type ('defender-' + $Kind) -Key $key -Label $label -Category 'security' -Data @{ Kind = $Kind; Values = $hits })
}

# ---------- 计划任务 ----------

function Get-SpaTaskSnapshot {
    if ($null -ne $Spa.Tasks) { return $Spa.Tasks }

    $list = New-Object System.Collections.Generic.List[object]
    try {
        $service = New-Object -ComObject Schedule.Service
        $service.Connect()
        $folders = New-Object System.Collections.Stack
        $folders.Push($service.GetFolder('\'))
        while ($folders.Count -gt 0) {
            $folder = $folders.Pop()
            foreach ($task in @($folder.GetTasks(1))) {
                try {
                    $parts = @()
                    foreach ($action in @($task.Definition.Actions)) {
                        if ($action.Type -eq 0) { $parts += @($action.Path, $action.Arguments, $action.WorkingDirectory) }
                    }
                    $list.Add([pscustomobject]@{
                            Name       = [string]$task.Name
                            Path       = [string]$task.Path
                            Folder     = [string]$folder.Path
                            ActionText = [Environment]::ExpandEnvironmentVariables(($parts -join ' '))
                        })
                }
                catch {}
            }
            foreach ($child in @($folder.GetFolders(0))) { $folders.Push($child) }
        }
    }
    catch {
        $Spa.Warnings.Add('无法读取计划任务列表，已跳过计划任务检查。')
    }
    $Spa.Tasks = $list.ToArray()
    return $Spa.Tasks
}

function New-SpaTaskTarget {
    param($Task)
    return New-SpaTarget -Type 'task' -Key $Task.Path -Label ('计划任务: ' + $Task.Path) -Category 'startup' -Data @{ Name = $Task.Name; Path = $Task.Path; Folder = $Task.Folder }
}

# ---------- 文件签名 ----------

# Steam 根目录里的 video.dll 等是 Valve 签名的官方组件；规则里的同名 DLL
# 只应命中未签名的注入副本。签名有效且签发者是 Valve 的一律不删。
function Test-SpaValveSigned {
    param([string]$Path)
    $ext = [IO.Path]::GetExtension($Path).ToLowerInvariant()
    if (@('.dll', '.exe', '.sys') -notcontains $ext) { return $false }
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }
    try {
        $sig = Get-AuthenticodeSignature -LiteralPath $Path -ErrorAction Stop
        return ($sig.Status -eq 'Valid' -and [string]$sig.SignerCertificate.Subject -match '(^|,\s*)(O|CN)="?Valve')
    }
    catch {
        return $false
    }
}

function Get-SpaFileCategory {
    param([string]$Path)
    if ($Path -match 'steam\.cfg|appdata\d*\.vdf|packageinfo\.vdf|localData\.vdf|package\\beta|opensteamtool\.toml|config\\lua') { return 'config' }
    return 'files'
}

function Get-SpaRegistryCategory {
    param([string]$Path)
    if ($Path -match '\\CurrentVersion\\Run') { return 'startup' }
    if ($Path -match 'Policies|SmartScreen|\\CI\\Policy|WindowsUpdate') { return 'security' }
    return 'registry'
}

# ---------- 解析：规则动作 -> 本机目标 ----------

function Find-SpaActionTargets {
    param($Action, [hashtable]$Variables)

    switch ([string]$Action.type) {
        'file' {
            $path = Resolve-SpaTemplate -Text $Action.path -Variables $Variables
            if (-not $path -or -not (Test-Path -LiteralPath $path)) { return @() }
            $data = @{ Path = $path; Recurse = [bool]$Action.recurse }
            $target = New-SpaTarget -Type 'file' -Key $path -Label $path -Category (Get-SpaFileCategory $path) -Data $data
            $reason = Get-SpaUnsafePathReason -Path $path -Variables $Variables
            if ($reason) {
                $target.State = 'protected'; $target.Note = $reason
            }
            elseif (Test-SpaValveSigned $path) {
                $target.State = 'protected'; $target.Note = 'Valve 官方签名文件'
            }
            return $target
        }
        'registry-key' {
            $path = [string]$Action.path
            if (-not (Test-Path -LiteralPath $path)) { return @() }
            return (New-SpaTarget -Type 'registry-key' -Key $path -Label $path -Category (Get-SpaRegistryCategory $path) -Data @{ Path = $path; Recurse = [bool]$Action.recurse })
        }
        'registry-value' {
            $path = [string]$Action.path
            $name = [string]$Action.name
            $props = Get-ItemProperty -LiteralPath $path -ErrorAction SilentlyContinue
            if (-not $props -or -not ($props.PSObject.Properties.Name -contains $name)) { return @() }
            return (New-SpaTarget -Type 'registry-value' -Key ($path + '|' + $name) -Label ($path + ' : ' + $name) -Category (Get-SpaRegistryCategory $path) -Data @{ Path = $path; Name = $name })
        }
        'defender-exclusion-path' {
            $path = Resolve-SpaTemplate -Text $Action.path -Variables $Variables
            if (-not $path) { return @() }
            return Find-SpaDefenderTargets -Kind 'path' -Value $path
        }
        'defender-exclusion-extension' { return Find-SpaDefenderTargets -Kind 'extension' -Value ([string]$Action.name) }
        'defender-exclusion-process' { return Find-SpaDefenderTargets -Kind 'process' -Value ([string]$Action.name) }
        'process' {
            $name = [IO.Path]::GetFileNameWithoutExtension([string]$Action.name)
            if (-not (Get-Process -Name $name -ErrorAction SilentlyContinue)) { return @() }
            return (New-SpaTarget -Type 'process' -Key $name -Label ('进程: ' + $name) -Category 'process' -Data @{ Name = $name })
        }
        'task' {
            $name = [string]$Action.name
            return @(Get-SpaTaskSnapshot | Where-Object { $_.Name -eq $name } | ForEach-Object { New-SpaTaskTarget $_ })
        }
        'task-contains' {
            $needle = Resolve-SpaTemplate -Text $Action.contains -Variables $Variables
            if (-not $needle) { return @() }
            return @(Get-SpaTaskSnapshot | Where-Object { $_.ActionText.IndexOf($needle, [StringComparison]::OrdinalIgnoreCase) -ge 0 } | ForEach-Object { New-SpaTaskTarget $_ })
        }
    }
    return @()
}

# ---------- 删除 ----------

function Get-SpaErrorText {
    param($ErrorRecord)
    $ex = $ErrorRecord.Exception
    while ($ex.InnerException) { $ex = $ex.InnerException }
    if ($ex -is [UnauthorizedAccessException] -or $ex -is [Security.SecurityException]) {
        return '权限不足或被杀毒软件拦截'
    }
    if ($ex -is [IO.IOException]) { return '文件正在被占用' }
    return $ex.Message.Trim()
}

function Set-SpaResult {
    param($Target, [string]$Status, [string]$Message = '')
    $Target.Status = $Status
    $Target.Message = $Message
}

function Remove-SpaTarget {
    param($Target, [hashtable]$Variables)

    $d = $Target.Data
    try {
        if ($Target.Type -eq 'file') {
            # 再次检查边界，防止规则或变量在扫描后被篡改。
            $reason = Get-SpaUnsafePathReason -Path $d.Path -Variables $Variables
            if ($reason) { return Set-SpaResult $Target 'skipped' $reason }
            if (-not (Test-Path -LiteralPath $d.Path)) { return Set-SpaResult $Target 'skipped' '已不存在' }
            $isDir = Test-Path -LiteralPath $d.Path -PathType Container
            if ($isDir -and -not $Target.Recurse -and @(Get-ChildItem -LiteralPath $d.Path -Force -ErrorAction SilentlyContinue).Count -gt 0) {
                return Set-SpaResult $Target 'skipped' '目录非空，规则未允许整目录删除'
            }
        }
        if ($Target.Type -eq 'registry-key' -and -not $Target.Recurse) {
            $key = Get-Item -LiteralPath $d.Path -ErrorAction SilentlyContinue
            if ($key -and $key.SubKeyCount -gt 0) { return Set-SpaResult $Target 'skipped' '含子项，规则未允许整项删除' }
        }

        switch ($Target.Type) {
            'file' {
                Remove-Item -LiteralPath $d.Path -Force -Recurse:$Target.Recurse -ErrorAction Stop
                if (Test-Path -LiteralPath $d.Path) { return Set-SpaResult $Target 'failed' '文件正在被占用' }
            }
            'registry-key' {
                Remove-Item -LiteralPath $d.Path -Force -Recurse -ErrorAction Stop
            }
            'registry-value' {
                Remove-ItemProperty -LiteralPath $d.Path -Name $d.Name -Force -ErrorAction Stop
            }
            { $_ -like 'defender-*' } {
                switch ($d.Kind) {
                    'path' { Remove-MpPreference -ExclusionPath $d.Values -ErrorAction Stop }
                    'extension' { Remove-MpPreference -ExclusionExtension $d.Values -ErrorAction Stop }
                    'process' { Remove-MpPreference -ExclusionProcess $d.Values -ErrorAction Stop }
                }
            }
            'process' {
                Get-Process -Name $d.Name -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction Stop
                Start-Sleep -Milliseconds 300
                if (Get-Process -Name $d.Name -ErrorAction SilentlyContinue) { return Set-SpaResult $Target 'failed' '进程未能结束' }
            }
            'task' {
                $service = New-Object -ComObject Schedule.Service
                $service.Connect()
                $service.GetFolder($d.Folder).DeleteTask($d.Name, 0)
            }
        }
        Set-SpaResult $Target 'removed'
    }
    catch {
        Set-SpaResult $Target 'failed' (Get-SpaErrorText $_)
    }
}

# SteamSPA · PowerShell 历史线索
# 只在本机显示，不上传，也不作为删除依据。

function Get-SpaHistoryLines {
    $files = @()
    try {
        $option = Get-PSReadLineOption -ErrorAction Stop
        if ($option.HistorySavePath) { $files += $option.HistorySavePath }
    }
    catch {}
    $dir = Join-Path $env:APPDATA 'Microsoft\Windows\PowerShell\PSReadLine'
    if (Test-Path -LiteralPath $dir) {
        $files += @(Get-ChildItem -LiteralPath $dir -Filter '*_history.txt' -File -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
    }

    $lines = @()
    foreach ($file in @($files | Select-Object -Unique)) {
        if (Test-Path -LiteralPath $file -PathType Leaf) {
            $lines += @(Get-Content -LiteralPath $file -Encoding UTF8 -ErrorAction SilentlyContinue)
        }
    }
    return $lines
}

# 一行算线索的条件（任一）：
#   1. 命中已知假入库域名/IP/文件特征；
#   2. 出现非 Valve 官方的 steam*.xxx 域名（steamfn.com、steamcc.cn 这类）；
#   3. "下载并直接执行"且目标是不带 https:// 的裸域名/IP（irm xxx.run | iex 是假入库的典型写法，
#      正规安装命令一般是完整 https 地址，不算线索）。
# 只命中 irm 之类的单词不算（"confirm" 里也有 irm）。
function Find-SpaHistoryClues {
    param([string[]]$Lines, [int]$Limit = 15)

    $indicators = @(
        'steam.run', 'steam.work', 'steam.icu', 'steam-run.com', 'cdks.run', 'ruku.run', 'steamcdkey.cn',
        'steamcn.cc', 'steamcc.cn', 'vfc88.cn', 'vfc77.cn', 'tfdl.net', 'siyecao', 'wanzi666', 'kyeamu',
        '121.41.99.14', '139.196.146.200', '47.100.121.251', '47.98.148.132', 'opensteamtool',
        'keymanifest', 'SdkoInjector', 'sdko.dll', 'SDL3_voder', 'sdl3_setup', 'csu_install', 'CSU_DIVA_HOST',
        'steamcdk', 'Steamtools', 'lanzou'
    )
    $trusted = @('ZERONE2077/SteamSPA')
    $steamDomain = '\bsteam[\w-]*\.(run|cn|cc|icu|work|top|xyz|com|net|vip|fun|site|shop)\b'
    $valveDomain = '\bsteam(powered|community|static|content|games|usercontent|server)\.(com|net)\b'
    $netCommand = '\b(irm|iwr|Invoke-RestMethod|Invoke-WebRequest|curl|wget|iex|Invoke-Expression|DownloadString|DownloadFile|Start-BitsTransfer)\b|https?://'
    $bareFetch ='\b(irm|iwr|Invoke-RestMethod|Invoke-WebRequest)\s+["'']?(?!https?://)[\w-]+(\.[\w-]+)+'

    $clues = New-Object System.Collections.Generic.List[string]
    foreach ($line in @($Lines)) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $isTrusted = $false
        foreach ($t in $trusted) { if ($line.IndexOf($t, [StringComparison]::OrdinalIgnoreCase) -ge 0) { $isTrusted = $true } }
        if ($isTrusted) { continue }

        # 只看"联网/执行"类命令，避免 Move-Item D:\Dev\SteamCDK 这种普通文件操作被当成线索。
        if ($line -notmatch $netCommand) { continue }
        $hit = ($line -match $bareFetch) -or (($line -replace $valveDomain, '') -match $steamDomain)
        if (-not $hit) {
            foreach ($i in $indicators) {
                if ($line.IndexOf($i, [StringComparison]::OrdinalIgnoreCase) -ge 0) { $hit = $true; break }
            }
        }
        if (-not $hit) { continue }

        $urls = @([regex]::Matches($line, '(?i)https?://[^\s''"()<>|;“”‘’，]+') | ForEach-Object { $_.Value.TrimEnd('.', ',') })
        if ($urls.Count -gt 0) {
            foreach ($url in $urls) {
                $clues.Add(($url -replace '(?i)([?&](token|access_token|auth|key|pwd|password|sign|signature)=)[^&]+', '$1***'))
            }
        }
        else {
            $text = ($line -replace '\s+', ' ').Trim()
            if ($text.Length -gt 120) { $text = $text.Substring(0, 117) + '...' }
            $clues.Add($text)
        }
    }

    # 历史文件按时间顺序追加，保留最近的若干条。
    $unique = @($clues | Select-Object -Unique)
    if ($unique.Count -gt $Limit) { $unique = $unique[($unique.Count - $Limit)..($unique.Count - 1)] }
    return $unique
}

# SteamSPA · 主流程
#   本机信息 -> 扫描（只读）-> 扫描结果 -> 历史线索
#   -> 没发现：结束（普通权限时可选"以管理员身份完整检查"）
#   -> 发现了：普通权限 -> 打开管理员窗口重新扫描
#              管理员   -> 清理前须知 -> 一次确认 -> 关闭 STEAM -> 清理 -> 汇总
#   -> 结束（关闭过 STEAM 时可选"重新打开 STEAM"）

function Show-SpaHelp {
    Write-Ui '用法：uninstall.ps1 [-ScanOnly] [-Risk low,medium,high] [-Only 规则ID,...] [-NoPause]'
    Write-Ui ''
    Write-Ui '  -ScanOnly   只扫描并列出，不询问、不删除'
    Write-Ui '  -Risk       只处理指定风险级别的规则（默认全部）'
    Write-Ui '  -Only       只处理指定 ID 的规则'
    Write-Ui '  -NoPause    结束时不等待回车'
    Write-Ui ''
    Write-Ui '退出码：0 正常  1 部分失败  2 参数错误  4 用户取消  5 需要管理员'
}

function Show-SpaHeader {
    Write-Host ''
    Write-UiBanner @(
        '  ███████ ████████ ███████  █████  ███    ███     ███████ ██████   █████  '
        '  ██         ██    ██      ██   ██ ████  ████     ██      ██   ██ ██   ██ '
        '  ███████    ██    █████   ███████ ██ ████ ██     ███████ ██████  ███████ '
        '       ██    ██    ██      ██   ██ ██  ██  ██          ██ ██      ██   ██ '
        '  ███████    ██    ███████ ██   ██ ██      ██     ███████ ██      ██   ██ '
    )
    Write-Host ''
    Write-Ui '  假入库清理 / 专杀工具：注入 DLL · STEAM 配置 · 注册表 · 启动项 · 系统服务 · 安全策略 · 后台进程' Muted
    Write-Ui ('  作者：万能小哥    版本：v{0}    最后更新：{1}' -f $SteamSPAReleaseVersion, $SteamSPAUpdatedAt) Dim
}

# STEAM 目录下的路径显示成 STEAM\...，列表更短更好读（完整路径在本机信息里）。
function Format-SpaLabel {
    param([string]$Label)
    $steam = [string]$Spa.SteamPath
    if (-not $steam) { return $Label }
    return [regex]::Replace($Label, [regex]::Escape($steam.TrimEnd('\')), 'STEAM', 'IgnoreCase')
}

function Get-SteamProcess {
    return @(Get-Process -Name 'steam', 'steamwebhelper' -ErrorAction SilentlyContinue)
}

# 先请 STEAM 自己退出，15 秒后还没退就强制结束。返回是否已全部退出。
function Stop-Steam {
    param([string]$SteamPath)
    $exe = if ($SteamPath) { Join-Path $SteamPath 'steam.exe' } else { $null }
    if ($exe -and (Test-Path -LiteralPath $exe -PathType Leaf)) {
        try { Start-Process -FilePath $exe -ArgumentList '-shutdown' -ErrorAction Stop } catch {}
    }
    $deadline = (Get-Date).AddSeconds(15)
    while ((Get-Date) -lt $deadline -and (Get-SteamProcess).Count -gt 0) { Start-Sleep -Milliseconds 500 }
    Get-SteamProcess | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 800
    return ((Get-SteamProcess).Count -eq 0)
}

function Get-SpaRiskRank {
    param([string]$Risk)
    switch ($Risk) { 'high' { 3 } 'medium' { 2 } default { 1 } }
}

function Select-SpaRules {
    param($Database, [hashtable]$Options)
    $all = @($Database.rules)
    foreach ($id in $Options.Only) {
        if (-not ($all | Where-Object { $_.id -eq $id })) { $Spa.Warnings.Add('未找到规则 ID: ' + $id) }
    }
    return @($all | Where-Object {
            $_.enabled -ne $false -and
            $Options.Risk -contains $_.risk -and
            ($Options.Only.Count -eq 0 -or $Options.Only -contains $_.id)
        })
}

# 扫描所有规则，合并指向同一目标的动作。只读，不修改系统。
function Invoke-SpaScan {
    param([object[]]$Rules, [hashtable]$Variables)

    $started = Get-Date
    $byKey = @{}
    $targets = New-Object System.Collections.Generic.List[object]
    $total = 0
    foreach ($rule in $Rules) { $total += @($rule.actions).Count }
    $done = 0

    foreach ($rule in $Rules) {
        foreach ($action in @($rule.actions)) {
            $done++
            Write-UiProgress -Current $done -Total $total
            foreach ($found in @(Find-SpaActionTargets -Action $action -Variables $Variables)) {
                $target = $byKey[$found.Key]
                if (-not $target) {
                    $target = $found
                    $byKey[$found.Key] = $target
                    $targets.Add($target)
                }
                elseif ($found.Recurse) {
                    $target.Recurse = $true
                }
                if (-not $target.RuleIds.Contains($rule.id)) { $target.RuleIds.Add($rule.id) }
                if ((Get-SpaRiskRank $rule.risk) -gt (Get-SpaRiskRank $target.Risk)) { $target.Risk = $rule.risk }
                if ($rule.confirm -eq $true) { $target.Confirm = $true }
            }
        }
    }
    Clear-UiProgress
    Write-UiResult '扫描完成' ('共检查 {0} 个位置，用时 {1:N1} 秒' -f $total, ((Get-Date) - $started).TotalSeconds) Success
    return $targets.ToArray()
}

function Show-SpaEnvironment {
    param([hashtable]$Variables, [bool]$IsAdmin, [bool]$SteamRunning)
    Write-UiSection '本机信息'
    Write-UiKeyValue '系统' (Get-SpaOSName)
    if ($Variables.SteamPath) { Write-UiKeyValue 'STEAM' $Variables.SteamPath Path }
    else { Write-UiKeyValue 'STEAM' '未检测到安装目录（STEAM 目录相关检查将跳过）' Warning }
    if ($SteamRunning) { Write-UiKeyValue 'STEAM 状态' '正在运行' Warning }
    else { Write-UiKeyValue 'STEAM 状态' '未运行' Muted }
    if ($IsAdmin) { Write-UiKeyValue '权限' '管理员' Success }
    else { Write-UiKeyValue '权限' '普通用户（清理时会请求管理员权限）' Muted }
}

function Show-SpaFindings {
    param([object[]]$Items, [object[]]$Protected)

    if ($Items.Count -eq 0) {
        Write-UiSection '扫描结果' '未发现假入库残留' Success
    }
    else {
        $flagged = @($Items | Where-Object { $_.Confirm }).Count
        $hint = '发现 {0} 项残留' -f $Items.Count
        if ($flagged -gt 0) { $hint += '（其中 {0} 项涉及系统设置，标为"需确认"）' -f $flagged }
        Write-UiSection '扫描结果' $hint Danger
    }

    $titles = [ordered]@{ files = '文件'; config = 'STEAM 配置'; registry = '注册表'; startup = '启动项 / 计划任务'; security = '系统安全设置'; process = '后台进程' }
    $n = 0
    foreach ($category in $titles.Keys) {
        $group = @($Items | Where-Object { $_.Category -eq $category })
        if ($group.Count -eq 0) { continue }
        Write-Host ''
        Write-Ui ('    {0}  ' -f $titles[$category]) Accent -NoNewline
        Write-Ui ([string]$group.Count) Dim
        foreach ($item in $group) {
            $n++
            Write-Ui ('    {0,4}  ' -f $n) Dim -NoNewline
            Write-Ui (Format-SpaLabel $item.Label) Path -NoNewline
            if ($item.Confirm) { Write-Ui '  需确认' Warning } else { Write-Host '' }
        }
    }

    if ($Protected.Count -gt 0) {
        Write-Host ''
        Write-Ui ('    已保护  {0} 项，不会删除' -f $Protected.Count) Success
        foreach ($item in $Protected) {
            Write-Ui ('          {0}  ' -f (Format-SpaLabel $item.Label)) Muted -NoNewline
            Write-Ui $item.Note Dim
        }
    }
    foreach ($w in $Spa.Warnings) { Write-UiNote $w -Important }
}

function Show-SpaClues {
    $clues = @(Find-SpaHistoryClues -Lines (Get-SpaHistoryLines))
    if ($clues.Count -eq 0) { return }
    Write-UiSection '历史线索' '在 PowerShell 历史里找到的可疑下载命令，仅供参考，不作为删除依据'
    $i = 0
    foreach ($clue in $clues) {
        $i++
        Write-Ui ('    {0,4}  ' -f $i) Dim -NoNewline
        Write-Ui $clue Muted
    }
}

# 普通权限下：以管理员身份重开。成功返回 $true（本窗口随后直接结束，不再等回车）。
function Request-SpaElevation {
    param([string]$Reason, [string]$Action, [string]$SelfText)
    Write-UiSection '需要管理员权限' $Reason Warning
    Write-UiOption 'Y' $Action
    Write-UiOption 'N' '退出'
    if ((Read-UiChoice -Prompt '请选择 [Y/N]，回车 = Y:' -Allowed @('Y', 'N') -Default 'Y') -ne 'Y') { return $false }
    if (Start-SpaElevated -SelfText $SelfText -Options $Spa.Options) {
        Write-UiResult '已打开' '已在新的管理员窗口中继续，本窗口可以关闭。' Success
        $Spa.Paused = $true
        return $true
    }
    Write-UiResult '未提权' '没有获得管理员权限（可能在 UAC 提示里选了"否"）。' Warning
    Write-UiNote '也可以右键开始菜单，选择"终端(管理员)"，再运行同一条命令。'
    return $false
}

# 清理前须知 + 一次确认。返回要清理的目标；取消返回 $null。
function Read-SpaCleanupDecision {
    param([object[]]$Items, [bool]$SteamRunning)

    Write-UiSection '清理前请注意'
    if ($SteamRunning) { Write-UiNote 'STEAM 正在运行，清理时会被强制关闭。' -Important }
    Write-UiNote '请先保存游戏进度、退出正在运行的游戏，并暂停 STEAM 下载和更新。' -Important
    Write-UiNote '清理后可能需要重新登录 STEAM：请确认记得账号、密码，手机令牌可用。' -Important
    Write-UiNote '不影响游戏本体、存档、创意工坊和 MOD（这些目录被硬性排除）。'
    Write-UiNote '清理失败时，请暂时退出杀毒软件后重试。'
    Write-UiNote '清理后首次打开 STEAM 可能较慢，建议开启加速器，耐心等几分钟。'

    $regular = @($Items | Where-Object { -not $_.Confirm })
    $flagged = @($Items | Where-Object { $_.Confirm })
    $verb = if ($SteamRunning) { '关闭 STEAM 并清理' } else { '清理' }

    Write-UiSection '是否清理？'
    Write-UiOption 'Y' ('{0}全部 {1} 项' -f $verb, $Items.Count)
    $allowed = @('Y', 'N')
    if ($regular.Count -gt 0 -and $flagged.Count -gt 0) {
        Write-UiOption 'S' ('{0}常规的 {1} 项，跳过 {2} 项"需确认"' -f $verb, $regular.Count, $flagged.Count)
        $allowed = @('Y', 'S', 'N')
    }
    Write-UiOption 'N' '取消，不做任何修改'
    $choice = Read-UiChoice -Prompt ('请选择 [' + ($allowed -join '/') + ']，回车 = 取消:') -Allowed $allowed -Default 'N'

    if ($choice -eq 'N') { return $null }
    if ($choice -eq 'S') {
        foreach ($t in $flagged) { Set-SpaResult $t 'skipped' '用户选择跳过' }
        return $regular
    }
    return $Items
}

function Invoke-SpaCleanup {
    param([object[]]$Selected, [hashtable]$Variables, [bool]$SteamRunning)

    Write-UiSection '清理'
    if ($SteamRunning) {
        Write-Ui '    正在关闭 STEAM...' Muted
        if (Stop-Steam -SteamPath $Variables.SteamPath) { Write-UiResult '已关闭' 'STEAM' Success }
        else { Write-UiResult '注意' 'STEAM 没有完全退出，部分文件可能删除失败' Warning }
    }

    # 先结束进程、删计划任务，避免它们在清理过程中把文件写回来。
    $order = @{ process = 0; task = 1; file = 2; 'registry-key' = 3; 'registry-value' = 4 }
    $ordered = @($Selected | Sort-Object { if ($order.ContainsKey($_.Type)) { $order[$_.Type] } else { 5 } })
    foreach ($t in $ordered) {
        Remove-SpaTarget -Target $t -Variables $Variables
        $label = Format-SpaLabel $t.Label
        switch ($t.Status) {
            'removed' { Write-UiResult $(if ($t.Type -eq 'process') { '已结束' } else { '已清理' }) $label Success }
            'skipped' { Write-UiResult '跳过' ($label + '  (' + $t.Message + ')') Muted }
            default { Write-UiResult '失败' ($label + '  (' + $t.Message + ')') Danger }
        }
    }
}

function Show-SpaSummary {
    param([object[]]$Items, [datetime]$StartedAt)

    $removed = @($Items | Where-Object { $_.Status -eq 'removed' }).Count
    $failed = @($Items | Where-Object { $_.Status -eq 'failed' }).Count
    $skipped = @($Items | Where-Object { $_.Status -eq 'skipped' -or -not $_.Status }).Count

    if ($failed -gt 0) { Write-UiSection '完成' ('{0} 项清理失败，请暂时退出杀毒软件后再运行一次' -f $failed) Danger }
    elseif ($removed -gt 0) { Write-UiSection '完成' '清理成功' Success }
    else { Write-UiSection '完成' '没有删除任何项目' Warning }
    Write-UiKeyValue '已清理' ([string]$removed) Success
    if ($failed) { Write-UiKeyValue '失败' ([string]$failed) Danger }
    if ($skipped) { Write-UiKeyValue '跳过' ([string]$skipped) Muted }
    Write-UiKeyValue '耗时' ('{0:N1} 秒' -f ((Get-Date) - $StartedAt).TotalSeconds) Muted
}

# 结束：关闭过 STEAM 时可以顺手重新打开。
function Read-SpaExit {
    param([string]$SteamPath, [bool]$OfferSteam)
    $Spa.Paused = $true
    if ($Spa.Options.NoPause -or ($Spa.Ui -and $Spa.Ui.InputRedirected)) { return }
    $exe = if ($SteamPath) { Join-Path $SteamPath 'steam.exe' } else { $null }
    if ($OfferSteam -and $exe -and (Test-Path -LiteralPath $exe -PathType Leaf)) {
        Write-Host ''
        Write-UiOption 'R' '重新打开 STEAM'
        Write-UiOption '回车' '退出'
        if ((Read-UiChoice -Prompt '请选择:' -Allowed @('R') -Default '') -eq 'R') {
            try { Start-Process -FilePath $exe -ErrorAction Stop } catch { Write-UiResult '失败' '无法启动 STEAM，请手动打开' Danger }
        }
        return
    }
    Wait-UiExit
}

function Invoke-SpaMain {
    param([hashtable]$Options, [string]$SelfText)

    $startedAt = Get-Date
    if ($Options.Help) { Show-SpaHelp; return 0 }
    if ($Options.Errors.Count -gt 0) {
        foreach ($e in $Options.Errors) { Write-UiResult '参数错误' $e Danger }
        Write-Host ''
        Show-SpaHelp
        return 2
    }

    try { $Host.UI.RawUI.WindowTitle = 'STEAM SPA 清理工具' } catch {}
    if (-not $Spa.Ui.Redirected) { try { Clear-Host } catch {} }
    Show-SpaHeader

    # ---- 本机信息 ----
    $variables = Get-SpaVariables
    $Spa.SteamPath = $variables.SteamPath
    $isAdmin = Test-SpaAdmin
    $steamRunning = (Get-SteamProcess).Count -gt 0
    Show-SpaEnvironment -Variables $variables -IsAdmin $isAdmin -SteamRunning $steamRunning

    # ---- 扫描（只读）----
    Write-UiSection '扫描' $(if ($Options.Elevated) { '已切换到管理员权限，重新完整扫描' } else { '' })
    $rules = Select-SpaRules -Database ($EmbeddedTargetsJson | ConvertFrom-Json) -Options $Options
    $all = @(Invoke-SpaScan -Rules $rules -Variables $variables)
    $items = @($all | Where-Object { $_.State -eq 'present' })
    $protected = @($all | Where-Object { $_.State -eq 'protected' })
    if ($Spa.DefenderHidden) { $Spa.Warnings.Add('Defender 排除项需要管理员权限才能检查，本次未检查。') }
    Show-SpaFindings -Items $items -Protected $protected
    Show-SpaClues

    $canAsk = -not $Options.ScanOnly -and -not $Spa.Ui.InputRedirected

    # ---- 没发现 ----
    if ($items.Count -eq 0) {
        if ($canAsk -and -not $isAdmin -and $Spa.DefenderHidden) {
            [void](Request-SpaElevation -Reason '普通权限看不到 Defender 排除项等系统设置' -Action '以管理员身份完整检查一遍' -SelfText $SelfText)
        }
        return 0
    }
    if ($Options.ScanOnly) { return 0 }

    # ---- 发现了，但不是管理员 ----
    if (-not $isAdmin) {
        if ($canAsk -and (Request-SpaElevation -Reason '清理需要管理员权限' -Action '以管理员身份打开并继续（会重新扫描，包含 Defender 排除项）' -SelfText $SelfText)) {
            return 0
        }
        if (-not $canAsk) { Write-UiNote '清理需要管理员权限：请以管理员身份重新运行。' -Important }
        return 5
    }

    # ---- 确认并清理 ----
    $steamRunning = (Get-SteamProcess).Count -gt 0
    $selected = Read-SpaCleanupDecision -Items $items -SteamRunning $steamRunning
    if ($null -eq $selected) {
        Write-UiSection '已取消' '已取消清理，没有做任何修改' Warning
        return 4
    }
    Invoke-SpaCleanup -Selected @($selected) -Variables $variables -SteamRunning $steamRunning
    Show-SpaSummary -Items $items -StartedAt $startedAt
    Read-SpaExit -SteamPath $variables.SteamPath -OfferSteam $steamRunning
    if (@($items | Where-Object { $_.Status -eq 'failed' }).Count -gt 0) { return 1 }
    return 0
}

# ---- 入口 ----
$Spa = @{
    Ui             = $null
    Options        = $null
    SteamPath      = $null
    Defender       = $null
    DefenderHidden = $false
    Tasks          = $null
    Paused         = $false
    Warnings       = New-Object System.Collections.Generic.List[string]
}
$spaSelfText = "& {`r`n" + $MyInvocation.MyCommand.ScriptBlock.ToString() + "`r`n} @args`r`n"
$spaOptions = ConvertFrom-SpaArguments -Arguments $args
$Spa.Options = $spaOptions
$spaEncoding = $null
try { $spaEncoding = [Console]::OutputEncoding } catch {}
$spaExitCode = 1
try {
    Initialize-SpaConsole
    $spaExitCode = [int](@(Invoke-SpaMain -Options $spaOptions -SelfText $spaSelfText)[-1])
}
catch {
    Write-UiResult '错误' ('运行出错：' + $_.Exception.Message) Danger
}
finally {
    if (-not $spaOptions.NoPause -and -not $Spa.Paused) { Wait-UiExit }
    if ($spaOptions.Elevated -and $PSCommandPath -and $PSCommandPath -like (Join-Path $env:TEMP 'SteamSPA\SteamSPA-*.ps1')) {
        Remove-Item -LiteralPath $PSCommandPath -Force -ErrorAction SilentlyContinue
    }
    if ($spaEncoding) { try { [Console]::OutputEncoding = $spaEncoding } catch {} }
}
# 只有以文件方式运行时才设置退出码；irm | iex 下 exit 会关掉用户的窗口。
if ($PSCommandPath) { exit $spaExitCode }

} @args
