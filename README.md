# SteamSPA

SteamSPA 是一个用于识别和清理 Steam 假入库 / 解锁脚本残留的 PowerShell 单文件工具。

对外只维护和分发一个文件：

```text
uninstall.ps1
```

清理规则已经内置在 `uninstall.ps1` 里面，不需要额外的 `targets.json`。

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

如果 jsDelivr 有缓存，想强制刷新，可以在 URL 后面加随机参数：

```powershell
irm "https://cdn.jsdelivr.net/gh/ZERONE2077/SteamSPA@main/uninstall.ps1?$(Get-Random)" | iex
```

## 绕过 GitHub Raw 缓存

如果刚刚更新脚本，GitHub Raw 可能短时间返回旧缓存。可以临时这样测试：

```powershell
irm "https://raw.githubusercontent.com/ZERONE2077/SteamSPA/refs/heads/main/uninstall.ps1?$(Get-Random)" | iex
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

如果需要给远程脚本传参数，使用下面这种写法：

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/ZERONE2077/SteamSPA/refs/heads/main/uninstall.ps1))) -Only steam-inject-dlls
```

jsDelivr CDN 同样可以这样传参数：

```powershell
& ([scriptblock]::Create((irm https://cdn.jsdelivr.net/gh/ZERONE2077/SteamSPA@main/uninstall.ps1))) -Only steam-inject-dlls
```

普通用户不需要使用带参数写法。

## 维护方式

以后新增假入库识别 / 清理项时，只维护 `uninstall.ps1`。

建议流程：

1. 把新的第三方脚本样本放进 `scripts/` 对应目录，作为分析留档。
2. 总结它新增了哪些文件、注册表、计划任务、Defender 排除项等。
3. 把确认后的规则维护进 `uninstall.ps1` 的内置规则。
4. 测试扫描和确认清理流程。
5. 提交推送到 GitHub。

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