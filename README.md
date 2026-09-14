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
> 注意：清理后 Steam 第一次打开可能会比较慢，因为客户端需要重新生成/拉取部分 appcache、包信息和库元数据；如果网络环境一般，建议提前开启 Steam 加速器，等待几分钟或重启 Steam 后通常会恢复正常。

## 推荐方式：GitHub Raw

```powershell
irm https://raw.githubusercontent.com/ZERONE2077/SteamSPA/main/uninstall.ps1 | iex
```

## CDN 方式：jsDelivr

如果 GitHub Raw 访问慢，可以尝试 jsDelivr CDN。

> ⚠️ jsDelivr 返回的 `Content-Type` 是 `application/octet-stream`，Windows PowerShell 5.1 的 `irm` 对不带 charset 的响应按 ISO-8859-1 解码，会让脚本里的中文全部乱码（清理逻辑本身能跑完，但界面和 TXT 报告都成了 `æ«æ...` 这种）。所以 jsDelivr 必须显式按 UTF-8 解码：

```powershell
iex ([Text.Encoding]::UTF8.GetString((iwr 'https://cdn.jsdelivr.net/gh/ZERONE2077/SteamSPA@main/uninstall.ps1' -UseBasicParsing).RawContentStream.ToArray()))
```

国内可用的 jsDelivr 镜像（写法相同，只换域名）：`jsd.onmicrosoft.cn`、`cdn.jsdmirror.com`。

## 绕过缓存

GitHub Raw（返回 `text/plain; charset=utf-8`，`irm` 可以直接用）：

```powershell
irm "https://raw.githubusercontent.com/ZERONE2077/SteamSPA/main/uninstall.ps1?$(Get-Random)" | iex
```

jsDelivr：

```powershell
$u = "https://cdn.jsdelivr.net/gh/ZERONE2077/SteamSPA@main/uninstall.ps1?$(Get-Random)"
iex ([Text.Encoding]::UTF8.GetString((iwr $u -UseBasicParsing).RawContentStream.ToArray()))
```

## 本地运行

如果你已经下载了 `uninstall.ps1`，也可以本地运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1
```

本地运行同样是先扫描，再询问是否清理。

## 可选参数

一般用户不需要参数。

- `-Risk low,medium,high`：选择扫描 / 清理的风险级别，默认 `low,medium,high`。
- `-Only <规则ID>`：只处理指定规则 ID。
- `-NoBackup`：清理前不备份文件。
- `-NoPause`：结束后不等待按 Enter。

远程带参数示例：

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/ZERONE2077/SteamSPA/main/uninstall.ps1))) -Only steam-inject-dlls
```

## 仓库结构

```text
uninstall.ps1      # 唯一对外产物：扫描 + 清理脚本
*.lnk              # 启动/分发用的快捷方式（本地、GitHub Raw、jsDelivr 三组）
docs/              # 说明文档：维护笔记 / LNK 使用指南 / UI 文案 / 商品信息 / 实机报告样例
data/              # 数据表格：痕迹总表（唯一数据源，md 人读 + csv 喂 AI / Excel）
scripts/           # 第三方假入库脚本样本，按来源域名分目录留档
tools/             # 辅助分析脚本：样本扫描、写入点提取、md<->csv 转换
```

规则变更流程：拿到新样本 → 放进 `scripts/<来源>/` → 用 `tools/` 里的脚本扫描写入点 → 更新 `data/痕迹总表` → 最后改 `uninstall.ps1` 的规则 JSON。