# SteamSPA Codex 交接摘要

## 项目目标

SteamSPA 用来分析网上各种 Steam 假入库 / 解锁脚本，记录它们写入、下载、注册、修改过的痕迹，并最终提供一个对外可用的清理脚本。

核心原则：不是只识别最新版脚本，而是所有历史脚本版本产生过的东西都要汇总到清理列表里。

## 当前目录结构

```text
SteamSPA/
  uninstall.ps1              # 对外入口：读取 targets.json，扫描 / 清理
  targets.json               # 清理规则数据，汇总历史脚本版本产生过的残留
  targets.schema.json        # 清理规则 JSON schema
  README.md

  scripts/                   # 第三方脚本原件，按团队 / 来源归档
    cdk.ruku.run/
    steam-run.com/
    steam.run/
    steam.work/

  dev/
    analyze.ps1              # 自用：递归扫描 scripts/，输出候选痕迹
    create-shortcuts.ps1     # 自用：生成本地 / GitHub Raw / Gitee Raw .lnk

  docs/
    requirements.md          # 需求说明
    research.md              # 第三方脚本分析笔记
    规划                     # 阶段规划
    codex-handoff.md         # 本文件

  temp/                      # 运行时产物，日志 / 备份 / 测试快捷方式
```

## 第三方脚本归档规则

第三方脚本按团队目录归档，不再使用 `scripts/third-party/`。

文件命名采用：

```text
来源名.三位编号.ps1
```

示例：

```text
scripts/steam-run.com/steam-run.com.001.ps1
scripts/steam-run.com/steam-run.com.002.ps1
scripts/steam.run/steam.run.001.ps1
scripts/steam.work/steam.icu.001.ps1
```

编号表示收集到的历史版本顺序，不代表只分析最新版本。

## 当前已归档脚本

```text
scripts/cdk.ruku.run/a.ps1
scripts/cdk.ruku.run/cdk.ruku.run.ps1
scripts/steam-run.com/142785900.001.ps1
scripts/steam-run.com/cdk.steamcdk.run.001.ps1
scripts/steam-run.com/steam-run.com.001.ps1
scripts/steam-run.com/steam-run.com.002.ps1
scripts/steam-run.com/steam-run.com.003.ps1
scripts/steam-run.com/steam-run.com.004.ps1
scripts/steam-run.com/steamcdkey.cn.001.ps1
scripts/steam.run/cdks.run.001.ps1
scripts/steam.run/steam.run.001.ps1
scripts/steam.run/steam.run.002.ps1
scripts/steam.work/steam.icu.001.ps1
scripts/steam.work/steam.work.001.ps1
```

注意：`scripts/cdk.ruku.run/a.ps1` 注释里有乱码，应该是原脚本编码/保存链路导致，不一定是本仓库问题。分析时重点看实际行为，不要急着修原件注释。

## 清理规则设计

`targets.json` 是唯一清理规则来源。

每条规则包含：

- `id`：规则 ID
- `title`：规则说明
- `sources`：产生该痕迹的历史脚本版本，使用仓库相对路径
- `enabled`：是否启用
- `risk`：`low` / `medium` / `high`
- `confirm`：是否需要二次确认
- `actions`：实际扫描 / 清理动作

重要约定：`sources` 应记录所有相关历史脚本版本，例如 `steam-run.com.001.ps1` 到 `.004.ps1` 都要列入，而不是只列最新版。

## uninstall.ps1 状态

`uninstall.ps1` 已改成数据驱动引擎：

- 默认扫描，不删除
- 加 `-Clean` 才执行清理
- 默认风险级别：`low,medium`
- 支持 `-Only <ruleId>` 只处理指定规则
- 支持 `-NoBackup` 跳过文件备份
- 支持 `-NoPause` 结束不等待 Enter
- 报告写入 `temp/logs/`
- 文件备份写入 `temp/backups/`

常用命令：

```powershell
./uninstall.ps1
./uninstall.ps1 -Clean
./uninstall.ps1 -Risk low,medium,high
./uninstall.ps1 -Only steam-inject-dlls
```

## dev/analyze.ps1 状态

`dev/analyze.ps1` 已适配团队目录结构：

- 默认扫描 `../scripts`
- 递归扫描所有团队目录
- 只做静态文本扫描，不执行第三方脚本
- 输出候选文件路径、注册表路径、Defender 排除项、计划任务、进程名
- 输出 key 使用相对路径，避免不同团队同名脚本互相覆盖

命令：

```powershell
./dev/analyze.ps1
./dev/analyze.ps1 -Out temp/analyze.json
```

## dev/create-shortcuts.ps1 状态

用于生成运行快捷方式 `.lnk`。

支持：

- 本地版：直接运行本地 `uninstall.ps1` 和 `targets.json`
- GitHub Raw 版：先下载 `uninstall.ps1`、`targets.json` 到 `%TEMP%\SteamSPA\github` 再运行
- Gitee Raw 版：先下载到 `%TEMP%\SteamSPA\gitee` 再运行

常用命令：

```powershell
./dev/create-shortcuts.ps1 `
  -GitHubRawBaseUrl 'https://raw.githubusercontent.com/你的账号/你的仓库/分支' `
  -GiteeRawBaseUrl 'https://gitee.com/你的账号/你的仓库/raw/分支'
```

默认生成：

```text
SteamSPA-local.lnk
SteamSPA-github-raw.lnk
SteamSPA-gitee-raw.lnk
```

也支持指定本地脚本路径，例如旧命令等价的本地版：

```powershell
./dev/create-shortcuts.ps1 `
  -LocalScriptPath 'D:\Dev\Powershell\uninstall.ps1' `
  -LocalTargetsPath 'D:\Dev\Powershell\targets.json'
```

## 当前已知分析发现

从已有脚本中已归纳到的清理项包括：

- Steam 目录注入 DLL：`dwmapi.dll`、`xinput1_4.dll`、`hid.dll`、`zlib1.dll`、`version.dll`、`user32.dll`、`wtsapi32.dll` 等
- Steam 配置 / 缓存：`steam.cfg`、`package\beta`、`config\appdata.vdf`、`appcache\appdata.vdf`、`appcache\packageinfo.vdf`
- 注册表：`HKCU:\Software\Valve\Steamtools` 及其值
- AppData：`%APPDATA%\Stool`
- LocalAppData：`%LOCALAPPDATA%\steam`、`%LOCALAPPDATA%\Steam\localData.vdf`、`%LOCALAPPDATA%\Microsoft\Tencent`
- 临时脚本：`%USERPROFILE%\get.ps1`、`${ScriptRoot}\a.ps1`
- Defender 排除项：Steam 路径、`%APPDATA%\Stool`、`exe`、`dll`

`a.ps1` 还出现了更敏感的行为，需要继续纳入分析：

- 修改 SmartScreen / CI Policy 相关注册表
- 删除启动项 `HKCU:\Software\Microsoft\Windows\CurrentVersion\Run\SteamAuthDaemon`
- 停止进程 `steam_auth`
- 下载 `steamcdk.exe` 到 Steam 目录并启动
- 添加 Defender 排除项

## 已做验证

已验证过：

- `targets.json` 合法
- `targets.json` 中所有 `sources` 都能找到真实文件
- `dev/analyze.ps1` 能递归扫描新 `scripts/<团队>/` 结构
- 项目中旧 `scripts/third-party` 文案已清理
- `dev/create-shortcuts.ps1` 能实际生成本地测试快捷方式
- `uninstall.ps1` 语法解析通过

## 后续建议

1. 优先继续分析 `scripts/cdk.ruku.run/a.ps1` 和 `cdk.ruku.run.ps1`。
2. 把新发现的行为先写入 `docs/research.md`，再同步到 `targets.json`。
3. 对 SmartScreen、CI Policy、Defender、启动项、进程、下载 exe 这类动作标记为 `medium` 或 `high`，并设置 `confirm: true`。
4. 若新增 action 类型，例如 SmartScreen 恢复、启动项删除、下载文件清理，需要同时更新：
   - `targets.schema.json`
   - `uninstall.ps1` 的 `Test-ActionExists` / `Remove-Action` / `Format-ActionLabel`
5. 发布前在虚拟机或干净环境运行扫描模式，再确认是否执行 `-Clean`。
