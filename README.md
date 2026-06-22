# SteamSPA

清理 Steam 假入库 / 解锁脚本留下的痕迹。

## 一句话

分析常见的 Steam 假入库脚本，把它们写入的文件、注册表、Defender 排除项等汇总成清单 [`targets.json`](targets.json)，再用一个 [`uninstall.ps1`](uninstall.ps1) 扫描并清理。

## 目录结构

```text
SteamSPA/
  uninstall.ps1          # 对外：扫描 + 清理
  targets.json           # 清理清单（数据）
  targets.schema.json    # 清单结构校验

  docs/
    requirements.md      # 需求
    research.md          # 第三方脚本分析笔记
    假入库类型分类.md     # 假入库 / 解锁工具类型分类和新增软件分析模板
    notes/               # 杂记

  scripts/
    cdk.ruku.run/        # 第三方脚本原件，按团队 / 来源归档
    steam-run.com/
    steam.run/
    steam.work/

  dev/
    analyze.ps1          # 自用：静态扫描第三方脚本，输出候选项

  temp/                  # 运行时产物（备份、日志），不入库
```

## 使用

以管理员身份运行：

```powershell
./uninstall.ps1
```

默认只扫描，不删除任何内容。确认结果后再执行清理：

```powershell
./uninstall.ps1 -Clean
```

常用参数：

- `-Clean`：清理扫描到的目标
- `-Risk low,medium,high`：选择要扫描 / 清理的风险级别，默认 `low,medium`
- `-Only steam-inject-dlls`：只处理指定规则 ID
- `-NoBackup`：清理前不备份文件
- `-NoPause`：结束后不等待按 Enter

运行报告写入 `temp/logs/`，文件备份写入 `temp/backups/`。

## 快捷方式

如果你想生成不同来源的 `.lnk`，先运行：

```powershell
./dev/create-shortcuts.ps1 `
  -GitHubRawBaseUrl 'https://raw.githubusercontent.com/你的账号/你的仓库/分支' `
  -GiteeRawBaseUrl 'https://gitee.com/你的账号/你的仓库/raw/分支'
```

默认会生成：

- `SteamSPA-local.lnk`
- `SteamSPA-github-raw.lnk`
- `SteamSPA-gitee-raw.lnk`

本地版直接指向仓库里的 `uninstall.ps1` 和 `targets.json`。在线版会先下载这两个文件到 `%TEMP%\SteamSPA\<source>`，再执行它们。

你之前那种命令本质上也是本地版的等价形式，例如：

```powershell
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File "D:\Dev\Powershell\uninstall.ps1"
```

现在可以统一由生成器生成到 `.lnk` 里，不用手工维护目标路径。

如果本地脚本不在当前仓库，也可以指定路径：

```powershell
./dev/create-shortcuts.ps1 `
  -LocalScriptPath 'D:\Dev\Powershell\uninstall.ps1' `
  -LocalTargetsPath 'D:\Dev\Powershell\targets.json'
```

## 开发流程

1. 新的第三方脚本放进对应的 `scripts/<团队>/` 目录
2. 运行 [`dev/analyze.ps1`](dev/analyze.ps1) 提取候选项
3. 在 [`docs/research.md`](docs/research.md) 写分析结论
4. 把确认无误的清理项写入 [`targets.json`](targets.json)
5. 测试 [`uninstall.ps1`](uninstall.ps1)

## 对外交付

只需要：

- `uninstall.ps1`
- `targets.json`
- `README.md`
