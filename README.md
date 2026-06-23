# SteamSPA

SteamSPA 是一个用于识别和清理 Steam 假入库 / 解锁脚本残留的 PowerShell 单文件工具。

对外只维护和分发一个文件：`uninstall.ps1`。

## 使用前说明

脚本不是直接删除，而是：

1. 先扫描残留，不会立即删除任何内容。
2. 显示检测到的文件、注册表、进程等项目。
3. 询问是否清理。
4. 只有输入 `Y` 并回车后，才会开始清理。
5. 其他输入都会取消清理。

建议使用“管理员 PowerShell”运行，因为清理 `Program Files`、`HKLM` 注册表、Defender 排除项等内容时需要管理员权限。

## 推荐方式：GitHub Raw

```powershell
irm https://raw.githubusercontent.com/ZERONE2077/SteamSPA/refs/heads/main/uninstall.ps1 | iex
```

## CDN 方式：jsDelivr

如果 GitHub Raw 访问慢，可以尝试 jsDelivr CDN：

```powershell
irm https://cdn.jsdelivr.net/gh/ZERONE2077/SteamSPA@main/uninstall.ps1 | iex
```

## 绕过缓存

GitHub Raw：

```powershell
irm "https://raw.githubusercontent.com/ZERONE2077/SteamSPA/refs/heads/main/uninstall.ps1?$(Get-Random)" | iex
```

jsDelivr：

```powershell
irm "https://cdn.jsdelivr.net/gh/ZERONE2077/SteamSPA@main/uninstall.ps1?$(Get-Random)" | iex
```

## 本地运行

如果你已经下载了 `uninstall.ps1`，也可以本地运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1
```

本地运行同样是先扫描，再询问是否清理。

## 可选参数

一般用户不需要参数。

- `-Risk low,medium,high`：选择扫描 / 清理的风险级别，默认 `low,medium`。
- `-Only <规则ID>`：只处理指定规则 ID。
- `-NoBackup`：清理前不备份文件。
- `-NoPause`：结束后不等待按 Enter。

远程带参数示例：

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/ZERONE2077/SteamSPA/refs/heads/main/uninstall.ps1))) -Only steam-inject-dlls
```

## 维护方式

普通用户只需要使用 `uninstall.ps1`。

为了避免换电脑或本地文件丢失，仓库会保留维护资料：

```text
README.md          # 使用说明
uninstall.ps1      # 对外执行脚本
docs/              # 维护笔记 / 归纳记录
scripts/           # 第三方脚本样本留档
dev/               # 自用分析工具
```

以后新增假入库识别 / 清理项时，最终只需要更新 `uninstall.ps1`；`docs/`、`scripts/`、`dev/` 用于备份和辅助分析。