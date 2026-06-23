# SteamSPA

SteamSPA 是一个用于扫描 / 清理 Steam 假入库、解锁脚本残留的 PowerShell 单文件工具。

现在对外只需要维护和分发一个文件：

```text
uninstall.ps1
```

清理规则已经内置在 `uninstall.ps1` 里面，不再需要单独的 `targets.json`。

## 远程一键扫描

默认只扫描，不删除任何内容：

```powershell
irm https://raw.githubusercontent.com/ZERONE2077/SteamSPA/refs/heads/main/uninstall.ps1 | iex
```

## 远程一键清理

清理需要管理员 PowerShell：

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/ZERONE2077/SteamSPA/refs/heads/main/uninstall.ps1))) -Clean
```

如果不想结束时暂停：

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/ZERONE2077/SteamSPA/refs/heads/main/uninstall.ps1))) -Clean -NoPause
```

如果 GitHub raw 刚更新后有缓存，可以临时加随机参数绕过缓存：

```powershell
irm "https://raw.githubusercontent.com/ZERONE2077/SteamSPA/refs/heads/main/uninstall.ps1?$(Get-Random)" | iex
```

## 本地运行

扫描：

```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1
```

清理：

```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1 -Clean
```

## 参数

- `-Clean`：清理扫描到的残留；不加时只扫描。
- `-Risk low,medium,high`：选择扫描 / 清理的风险级别，默认 `low,medium`。
- `-Only <规则ID>`：只处理指定规则 ID。
- `-NoBackup`：清理前不备份文件。
- `-NoPause`：结束后不等待按 Enter。

## 维护方式

以后新增识别 / 清理项时，只改 `uninstall.ps1` 里的内置规则即可。

建议流程：

1. 把新的第三方脚本样本放进 `scripts/` 对应目录，作为分析留档。
2. 分析它新增了哪些文件、注册表、计划任务、Defender 排除项等。
3. 把确认后的规则维护进 `uninstall.ps1` 的 `$EmbeddedTargetsJson`。
4. 本地测试扫描模式。
5. 再提交推送到 GitHub。

## 目录说明

```text
SteamSPA/
  uninstall.ps1     # 唯一对外分发和维护的清理脚本
  README.md         # 使用说明
  scripts/          # 第三方脚本样本留档，方便以后分析
  docs/             # 分析记录 / 需求记录
  dev/              # 自用分析工具
  temp/             # 运行报告和备份，不入库
```