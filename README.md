# SteamSPA

SteamSPA 是一个 Windows PowerShell 工具，用于识别、展示并清理 Steam 假入库 / 解锁脚本留下的残留。

## 使用

### jsDelivr 镜像（国内推荐）

jsDelivr 在国内更快，但它把 `.ps1` 当二进制返回（`Content-Type: application/octet-stream`，不带 charset），**Windows PowerShell 5.1 的 `irm` 会按 ISO-8859-1 解码，中文全部乱码**。必须按字节取回再按 UTF-8 解：

```powershell
$u = 'https://cdn.jsdelivr.net/gh/ZERONE2077/SteamSPA@main/uninstall.ps1?' + [guid]::NewGuid().ToString('N')
iex ([Text.Encoding]::UTF8.GetString((iwr $u -UseBasicParsing).RawContentStream.ToArray()).TrimStart([char]0xFEFF))
```

PowerShell 7 默认 UTF-8，用 `irm ... | iex` 也正常。

浏览器直链：

https://cdn.jsdelivr.net/gh/ZERONE2077/SteamSPA@main/uninstall.ps1

`@main` 会被 CDN 缓存几个小时，刚发布的新版可能要等一会儿才生效。

### GitHub Raw

```powershell
irm https://raw.githubusercontent.com/ZERONE2077/SteamSPA/main/uninstall.ps1 | iex
```

本地运行（`-File` 在 5.1 下会按 ANSI 解码导致中文乱码，改用显式 UTF-8 读取）：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((Get-Content .\uninstall.ps1 -Raw -Encoding UTF8)))"
```

## 参数

- `-ScanOnly`：只扫描并列出，不询问、不删除
- `-Risk low,medium,high`：只处理指定风险级别的规则
- `-Only rule-id,...`：只处理指定规则
- `-NoPause`：结束时不等待按键
- `-Help`：显示帮助

退出码（仅文件方式运行时）：0 正常，1 部分失败，2 参数错误，4 用户取消，5 需要管理员。

## 运行流程

1. 显示本机信息；不是管理员时询问是否以管理员身份重新打开（脚本自身源码写到临时文件后提权运行，不重新下载）。
2. 列出 PowerShell 历史里的可疑下载命令（仅显示，不作为删除依据）。
3. 扫描所有规则（只读），同一目标在多条规则里出现只算一次。
4. 按类别列出发现项，标出 `[需确认]` 项；Valve 签名文件和受保护目录单独列出且不删除。
5. 确认：`Y` 全部清理，`S` 只清理常规项（跳过 `[需确认]`），`N` 或回车取消。
6. STEAM 正在运行时先关闭；先结束进程、删计划任务，再删文件和注册表。清理对象都是非官方残留，不做备份。
7. 汇总结果。

## 架构

```text
data/rules.json + data/version.json
      ↓
src/10-ui.ps1        终端输出（唯一调用 Write-Host 的地方）
src/20-context.ps1   参数、权限、STEAM 路径、路径模板、删除安全边界、提权
src/30-targets.ps1   每种规则类型的“查找 / 删除”
src/50-history.ps1   PowerShell 历史线索
src/90-main.ps1      主流程
      ↓
tools/build.ps1  →  uninstall.ps1（唯一对外分发产物，整体包在 & { } 里运行）
```

`data/rules.json` 是运行规则的唯一数据源。支持的动作类型：`file`、`registry-key`、`registry-value`、
`defender-exclusion-path`、`defender-exclusion-extension`、`defender-exclusion-process`、`process`、`task`、`task-contains`。
修改规则或源码后执行 `tools/build.ps1`，再执行 `tests/SmokeTests.ps1`。

新商家样本的分析、规则更新和发布流程见 `research/README.md`。

## 发布

修改规则或源码后执行 `tools/publish.ps1`。脚本会先构建并运行冒烟测试（含生成物只扫描试运行），
全部通过后才提交并推送 `origin/main`，最后核对线上版本。

## 安全设计

- 扫描阶段只读，不修改系统；清理前必须明确确认，默认选项是取消。
- 路径模板里的变量缺失（例如没找到 STEAM）时直接跳过该规则，不会拼出残缺路径。
- 硬性边界：不删磁盘根目录、系统和用户根目录、STEAM 根目录及 config/bin/steamapps/userdata 等，
  `steamapps`（游戏）和 `userdata`（存档）下的任何内容都不碰。
- Valve 有效数字签名文件自动保护。
- 非空目录、带子项的注册表项只在规则写明 `recurse` 时才整体删除。
- Defender 不可用或无权读取时安全跳过并提示。

## 目录

```text
uninstall.ps1        生成物，唯一对外分发的文件
src/                 源码模块
data/                rules.json（规则）、rules.schema.json、version.json
tools/               build.ps1 / publish.ps1 / launch.ps1
tests/               SmokeTests.ps1
research/            维护流程、样本分析脚本、痕迹总表（样本和笔记本地保留，不上传）
```

Windows PowerShell 5.1+，无需第三方 PowerShell 模块。
