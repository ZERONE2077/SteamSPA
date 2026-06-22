# 第三方脚本分析

> 用于记录每个别人脚本做了什么，最终浓缩进 `targets.json`。
> 新增脚本时只追加二级标题。

## 142785900

- 版本：`scripts/steam-run.com/142785900.001.ps1`
- 写入文件：
  - 删除历史临时脚本 `%USERPROFILE%\get.ps1`。
  - 创建 `%APPDATA%\Stool`，下载 `legit64` / `legit` 载荷和 `winhttp-log.txt` / `winhttp-log1.txt` 临时 DLL。
  - 64 位分支写入 `${SteamPath}\config\appdata.vdf`、`${SteamPath}\dwmapi.dll`、`${SteamPath}\xinput1_4.dll`。
  - 32 位分支写入 `${SteamPath}\appcache\appdata.vdf`、`${SteamPath}\hid.dll`、`${SteamPath}\zlib1.dll`。
  - 删除/替换 `${SteamPath}\steam.cfg`、`version.dll`、`user32.dll`、`wtsapi32.dll`。
- 注册表：
  - 读取 `HKCU:\Software\Valve\Steam` 的 `SteamPath`、`SteamExe`、`ActiveProcess\pid`。
  - 创建/写入 `HKCU:\Software\Valve\Steamtools`：`packageinfo`、`steamclient`、`s`、`c`。
  - 修改 `loginusers.vdf` 的 `WantsOfflineMode=0`，修改 `config.vdf` 的 `DisableShaderCache=1`。
- Defender：
  - 添加 `${SteamPath}`、`%APPDATA%\Stool`，以及扩展名 `exe`、`dll` 排除项。
- 备注：
  - 会停止 Steam ActiveProcess pid 和 `^steam` 相关进程。
  - 下载源包含 Gitee 和蓝奏云解析逻辑，下载后有 XOR 解码流程。
  - 最后通过 `steam://open/activateproduct` 拉起 Steam 激活产品界面。

## steam-run.com

- 版本：`scripts/steam-run.com/steam-run.com.001.ps1`
- 版本：`scripts/steam-run.com/steam-run.com.002.ps1`
- 版本：`scripts/steam-run.com/steam-run.com.003.ps1`
- 版本：`scripts/steam-run.com/steam-run.com.004.ps1`
- 写入文件：
  - `.001` 行为基本等同 `142785900.001.ps1`。
  - `.002` 额外创建 `%LOCALAPPDATA%\steam`，并可能写入 `%LOCALAPPDATA%\steam\localData.vdf`。
  - `.003` / `.004` 改用 GitHub 下载 `legit/legit64`、`appdata.vdf` 和 DLL 载荷。
  - 多版本都会写入或替换 `${SteamPath}\dwmapi.dll`、`xinput1_4.dll`、`hid.dll`、`zlib1.dll` 中的一组。
  - 多版本都会删除/替换 `${SteamPath}\steam.cfg`、`version.dll`、`user32.dll`、`wtsapi32.dll`。
- 注册表：
  - 读取 `HKCU:\Software\Valve\Steam` 的 Steam 路径和进程信息。
  - 创建/写入 `HKCU:\Software\Valve\Steamtools`：`packageinfo`、`steamclient`、`s`、`c`。
  - `.002` 的 `s` 值与其他版本不同，其余版本常见 `398a2323a3433bfb0aff3d45e27a379200`。
  - 修改 `loginusers.vdf` / `config.vdf` 的离线模式和 shader cache 配置。
- Defender：
  - 添加 `${SteamPath}`、`%APPDATA%\Stool`，以及 `exe`、`dll` 扩展名排除项。
- 备注：
  - 会停止 Steam ActiveProcess pid 和 Steam 相关进程。
  - 历史版本载荷来源、hash、落地点略有变化，`targets.json` 中 sources 应保留全部版本。

## steam-run

- 版本：`scripts/steam-run.com/steam-run.com.004.ps1`
- 写入文件：
  - 该节是 `steam-run.com.004.ps1` 的来源别名/历史记录；文件行为同 `steam-run.com.004.ps1`。
- 注册表：
  - 同 `.004`：写入 `HKCU:\Software\Valve\Steamtools` 的 `packageinfo`、`steamclient`、`s`、`c`。
- Defender：
  - 同 `.004`：添加 `${SteamPath}`、`%APPDATA%\Stool`，以及 `exe`、`dll` 排除项。
- 备注：
  - 保留该节用于记录来源命名差异；实际归档文件仍是 `scripts/steam-run.com/steam-run.com.004.ps1`。

## cdks.run

- 版本：`scripts/steam.run/cdks.run.001.ps1`
- 写入文件：
  - 删除 `%USERPROFILE%\get.ps1`。
  - 创建 `%LOCALAPPDATA%\steam`。
  - 删除 `${SteamPath}\xinput1_4.dll`、`${SteamPath}\steam.cfg`、`${SteamPath}\package\beta`、`${SteamPath}\version.dll`。
  - 删除 `%LOCALAPPDATA%\Microsoft\Tencent`。
  - 从 `https://update.wudrm.com/xinput1_4.dll` 下载到 `${SteamPath}\xinput1_4.dll`，并生成/覆盖 `${SteamPath}\xinput1_4.dll.old`。
- 注册表：
  - 读取 `HKCU:\Software\Valve\Steam` 的 `SteamPath`。
  - 创建/写入 `HKCU:\Software\Valve\Steamtools`。
  - 删除 `ActivateUnlockMode`、`AlwaysStayUnlocked`、`notUnlockDepot`，写入 `iscdkey=true`。
- Defender：
  - 尝试添加 `${SteamPath}\xinput1_4.dll` 为 Defender 排除路径。
- 备注：
  - 会强制停止 `steam`，必要时调用 `taskkill /f /im steam.exe`。
  - 最后启动 `${SteamPath}\steam.exe steam://open/activateproduct`。

## steam.run

- 版本：`scripts/steam.run/steam.run.001.ps1`
- 版本：`scripts/steam.run/steam.run.002.ps1`
- 写入文件：
  - 两个版本都会删除 `%USERPROFILE%\get.ps1`，创建 `%LOCALAPPDATA%\steam`。
  - 都会删除 `${SteamPath}\xinput1_4.dll`、`${SteamPath}\steam.cfg`、`${SteamPath}\package\beta`、`${SteamPath}\version.dll`、`%LOCALAPPDATA%\Microsoft\Tencent`。
  - `.001` 下载/替换 `${SteamPath}\xinput1_4.dll`。
  - `.002` 额外删除 `${SteamPath}\user32.dll`，并下载/替换 `${SteamPath}\dwmapi.dll`。
  - 两个版本都可能生成 `.old` 备份名。
- 注册表：
  - 读取 `HKCU:\Software\Valve\Steam` 的 `SteamPath`。
  - 创建/写入 `HKCU:\Software\Valve\Steamtools`。
  - 删除 `ActivateUnlockMode`、`AlwaysStayUnlocked`、`notUnlockDepot`，写入 `iscdkey=true`。
- Defender：
  - `.001` 添加 `${SteamPath}\xinput1_4.dll` 排除路径。
  - `.002` 还添加 `${SteamPath}\dwmapi.dll` 排除路径。
- 备注：
  - 会强制停止 `steam`，必要时调用 `taskkill`。
  - 这组更偏单 DLL 注入/替换，但仍留下 LocalAppData、Steamtools 注册表和 Defender 排除痕迹。

## steam.icu

- 版本：`scripts/steam.work/steam.icu.001.ps1`
- 写入文件：
  - 删除 `${SteamPath}\steam.cfg`、`version.dll`、`user32.dll`、`hid.dll`、`appcache\packageinfo.vdf`、`package\beta`、`wtsapi32.dll`、`xinput1_4.dll`。
  - 下载到 `${SteamPath}\xinput1_4`，随后重命名为 `${SteamPath}\xinput1_4.dll`。
  - 下载 `%LOCALAPPDATA%\Steam\localData.vdf`。
- 注册表：
  - 读取 `HKCU:\Software\Valve\Steam` 的 `SteamPath`。
- Defender：
  - 添加 `${SteamPath}` 为 Defender 排除路径。
- 备注：
  - 会停止 `steam*` 进程。
  - 与 `steam.work.001.ps1` 逻辑接近，但下载源为脚本内 POST 接口。

## steam.work

- 版本：`scripts/steam.work/steam.work.001.ps1`
- 写入文件：
  - 删除 `${SteamPath}\steam.cfg`、`version.dll`、`user32.dll`、`hid.dll`、`appcache\packageinfo.vdf`、`package\beta`、`wtsapi32.dll`、`xinput1_4.dll`。
  - 从 Gitee 下载到 `${SteamPath}\xinput1_4`，随后重命名为 `${SteamPath}\xinput1_4.dll`。
  - 从 Gitee 下载 `%LOCALAPPDATA%\Steam\localData.vdf`。
- 注册表：
  - 读取 `HKCU:\Software\Valve\Steam` 的 `SteamPath`。
- Defender：
  - 添加 `${SteamPath}` 为 Defender 排除路径。
- 备注：
  - 会停止 `steam*` 进程。

## steamcdkey.cn

- 版本：`scripts/steam-run.com/steamcdkey.cn.001.ps1`
- 写入文件：
  - 删除 `%USERPROFILE%\get.ps1`。
  - 创建 `%APPDATA%\Stool`，下载 `legit64` 载荷。
  - 清理 `${SteamPath}` 下的 `steam.cfg`、`version.dll`、`user32.dll`、`simulator.dll`、`hid.dll`、`steam-lucky.exe`、`zlib1.dll`、`steam_api.dll`。
  - 写入 `${SteamPath}\config\appdata.vdf`。
  - 下载 DLL 临时到 `${SteamPath}\dwmapi.log`、`%APPDATA%\Stool\dwmapi.dll` 等位置后重命名为 `${SteamPath}\dwmapi.dll`、`${SteamPath}\xinput1_4.dll`。
- 注册表：
  - 修改 `HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy\VerifiedAndReputablePolicyState=0`。
  - 写入多个 Steam depot/config 路径下的 `manifests` 值。
  - 写入 `HKCU:\Software\Valve\Steamtools`：`packageinfo`、`s`、`c`，并设置 `steamclient=bin\diversion.dll`。
  - 修改 `HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings` 多个暂停更新字段，把功能/质量/总更新暂停到 2037 年。
  - 修改 `loginusers.vdf` / `config.vdf` 的离线模式和 shader cache 配置。
- Defender：
  - 添加 `${SteamPath}`、`%APPDATA%\Stool`，以及扩展名 `exe`、`dll` 排除项。
- 备注：
  - 会检测/过滤指向 `%APPDATA%\Stool` 的计划任务参数。
  - 会停止 Steam ActiveProcess pid 和 Steam 相关进程。
  - 行为比早期 `steam-run.com` 更宽：除 Steam 注入 DLL 外，还包含 CI Policy、Windows Update 暂停、Steam depot manifest 注册表写入等。

## cdk.steamcdk.run

- 版本：`scripts/steam-run.com/cdk.steamcdk.run.001.ps1`
- 写入文件：无。当前归档文件长度为 0。
- 注册表：无。
- Defender：无。
- 备注：
  - 当前只能记录为空文件；若后续补到真实历史版本，需要重新分析并同步到 `targets.json`。

## cdk.steamcdk.uninstall

- 版本：`scripts/cdk.ruku.run/cdk.ruku.run.ps1`
- 写入文件：
  - 下载远程 `a.ps1` 到 `%TEMP%\1.ps1`。
- 注册表：
  - 无直接注册表写入；实际注册表改动发生在下载后执行的 `a.ps1`。
- Defender：
  - 无直接 Defender 操作；实际排除项添加发生在 `a.ps1`。
- 备注：
  - 这是包装器/下载器：从 `https://d10.tfdl.net/public/2026-06-13/ad7e81b6-533b-4189-95ed-2ce62b9aecbc/a.ps1` 下载后执行。
  - 业务注释指向 `https://ruku.run`。

## cdk.ruku.run/a.ps1

- 版本：`scripts/cdk.ruku.run/a.ps1`
- 入口/关联：`scripts/cdk.ruku.run/cdk.ruku.run.ps1` 下载远程 `a.ps1` 到 `%TEMP%\1.ps1` 后以 `powershell.exe -NoProfile -ExecutionPolicy Bypass -File` 执行。
- 写入文件：
  - 非管理员且从内存/定义执行时，可能把自身写入 `%TEMP%\a-elevate-<guid>.ps1` 后提权重跑。
  - 下载 `steamcdk.exe` 到 `${SteamPath}\steamcdk.exe`，随后 `Unblock-File` 并启动。
  - 修改 `${SteamPath}\config\loginusers.vdf` 的 `WantsOfflineMode=0`，修改 `${SteamPath}\config\config.vdf` 的 `DisableShaderCache=1`。
- 注册表：
  - 读取 `HKCU:\Software\Valve\Steam` 的 `SteamPath`，备用读取 `HKLM:\SOFTWARE\WOW6432Node\Valve\Steam` / `HKLM:\SOFTWARE\Valve\Steam` 的 `InstallPath`。
  - 写入/关闭 SmartScreen 与 CI Policy：
    - `HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy\VerifiedAndReputablePolicyState=0`
    - `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\SmartScreenEnabled=Off`
    - `HKLM:\SOFTWARE\Policies\Microsoft\Windows\System\EnableSmartScreen=0`
    - `HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\SmartScreen` 下 `ConfigureAppInstallControl`、`ConfigureAppInstallControlEnabled`、`EnableSmartScreenInShell` 均置 `0`。
  - 删除 `HKCU:\Software\Microsoft\Windows\CurrentVersion\Run\SteamAuthDaemon`。
- Defender：
  - 若 `windefend` 正在运行，添加 `${SteamPath}` 排除项和扩展名 `.dll`、`.exe`。
- 备注：
  - 检测 `360Tray*`、`360Safe*` / `360sd*`、`QQPCTray*`，循环提示退出后才继续。
  - 检查管理员权限；非管理员时通过 `Start-Process powershell.exe ... -Verb RunAs` 自我提权。
  - 强制停止 `steam_auth`、Steam ActiveProcess pid，以及匹配 `^steam` 且非 `steam++` 的进程。
  - 下载地址：`https://d7.tfdl.net/public/2026-06-13/0bb3c800-1cde-481d-87bd-90a915d28884/steamcdk.exe`。
  - 已同步到 `targets.json`：SmartScreen/CI Policy 注册表值、`SteamAuthDaemon` 启动项、`steam_auth` 进程、`${SteamPath}\steamcdk.exe`、`%TEMP%\1.ps1`、Defender 扩展名 `.dll`/`.exe`。

## OpenSteamTool

- 来源：`https://github.com/OpenSteam001/OpenSteamTool`
- 写入文件：
  - README/使用方式要求把生成的 `OpenSteamTool.dll`、`dwmapi.dll`、`xinput1_4.dll` 放到 Steam 目录。
  - README/使用方式要求把 `opensteamtool.example.toml` 重命名为 `opensteamtool.toml` 并放到 Steam 目录。
  - 默认 Lua 插件/配置目录为 `${SteamPath}\config\lua`，用户会把 `.lua` 脚本放入该目录。
- 注册表：
  - 项目功能涉及游戏 AppTicket / ETicket 等授权数据模拟/注入；实际写入通常与具体 AppID 有关，无法从固定清单安全推导。
  - 暂不自动清理 `HKCU:\Software\Valve\Steam\Apps` 下的泛化 AppID 项，避免误删 Steam 正常数据。
- Defender：
  - 仓库本身未作为安装步骤要求添加 Defender 排除项；若用户运行其他安装脚本导致排除项存在，已有 `defender-exclusions` 规则覆盖 Steam 目录 / DLL / EXE 排除项。
- 备注：
  - 已同步到 `targets.json`：`${SteamPath}\OpenSteamTool.dll`、`${SteamPath}\dwmapi.dll`、`${SteamPath}\xinput1_4.dll`、`${SteamPath}\opensteamtool.toml`。
  - `${SteamPath}\config\lua` 作为中风险确认项处理，因为里面可能包含用户自写脚本，不应无提示删除。
  - 没有把整个 `HKCU:\Software\Valve\Steam\Apps` 加入自动清理，原因是范围过宽，可能影响正常 Steam 记录。

## SteamKing

- 来源：`D:\Downloads\SteamKing-Setup-1.5.3.exe`
- 类型：
  - 入口类型：一键 GUI 软件 / Inno Setup 安装包。
  - 技术类型：OpenSteamTool 部署器 + Manifest 管理 + Steam API 启动辅助。
- 基本信息：
  - 安装包：`SteamKing-Setup-1.5.3.exe`
  - 版本：`1.5.3`
  - 签名：未签名
  - SHA256：`6D8AFCFB9317A2DFE5A671AF58FA13C7ABD14A9DC18BAC0A88D40C376F2658FF`
- 安装痕迹：
  - `C:\Program Files\SteamKing`
  - `%LOCALAPPDATA%\SteamKing`
  - `HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\{A7C3E9F1-2B4D-4F6A-9C8E-1D5F7A3B2E90}_is1`
- 写入文件：
  - 主程序：`C:\Program Files\SteamKing\SteamKing.exe`
  - 主逻辑：`C:\Program Files\SteamKing\SteamKing.dll`
  - 用户配置/缓存：`%LOCALAPPDATA%\SteamKing\settings.json`、`%LOCALAPPDATA%\SteamKing\name_cache.json`
- 注册表：
  - Inno Setup 卸载项：`HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\{A7C3E9F1-2B4D-4F6A-9C8E-1D5F7A3B2E90}_is1`
  - 未发现启动项。
  - 未发现计划任务。
- Steam 影响：
  - 主逻辑包含 `DeployOpenTool` / `DeployOpenConfig`。
  - 可部署/管理 `OpenSteamTool.dll`、`dwmapi.dll`、`xinput1_4.dll`、`opensteamtool.toml`、`config\lua`、`steamtools.lua`。
  - 可扫描/管理 `depotcache`、`*.manifest`、`libraryfolders.vdf`、`steamapps`。
  - 可处理 `steam_api.dll`、`steam_api64.dll`、`steam_appid.txt`、`Spacewar` 启动模式。
- Defender：
  - 当前静态分析未发现 SteamKing 本体直接添加 Defender 排除项。
  - 如果通过它部署了 OpenSteamTool，相关 Steam 根目录文件已由 OpenSteamTool 规则覆盖。
- 备注：
  - 已同步到 `targets.json`：`SteamKing` 进程、`%ProgramFiles%\SteamKing`、`%LOCALAPPDATA%\SteamKing`、Inno 卸载注册表项。
  - 未把 `steam_api.dll`、`steam_api64.dll`、`steam_appid.txt`、`appmanifest_*.acf`、`depotcache\*.manifest` 自动加入清理；这些可能位于具体游戏目录，需要具体路径/AppID 才能安全清理。
