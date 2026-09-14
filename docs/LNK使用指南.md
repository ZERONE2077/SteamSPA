# Windows `.lnk` 远程执行从 0 到 1 指南

> 维护对象：SteamSPA 远程清理脚本快捷方式。  
> 目标：给普通用户一个可以双击运行的 `.lnk`，自动拉取最新 PowerShell 脚本、请求管理员权限、避免缓存、失败不闪退，并尽量保证窗口显示好看。

---

## 0. 先说结论

SteamSPA 建议保留两套快捷方式：

```text
SteamSPA-Remote.lnk       # 兼容版：cmd.exe + powershell.exe + pause
SteamSPA-Remote-WT.lnk    # 美观版：cmd.exe start wt.exe + Windows Terminal
```

推荐策略：

- 不确定用户环境：发 `SteamSPA-Remote.lnk`
- 确认用户有 Windows Terminal / Win+R 能运行 `wt.exe`：发 `SteamSPA-Remote-WT.lnk`
- 自己调 UI、字体、窗口效果：优先测试 WT 版
- 真正清理：建议管理员权限

---

## 1. `.lnk` 到底是什么

`.lnk` 是 Windows 快捷方式，本质上只是一个启动器。它不会自己执行脚本，而是启动某个程序，并把参数传给它。

常用字段：

| 字段 | 作用 | 示例 |
|---|---|---|
| TargetPath | 启动哪个程序 | `cmd.exe` / `powershell.exe` / `wt.exe` |
| Arguments | 传给程序的参数 | `/c ...` / `-EncodedCommand ...` |
| WorkingDirectory | 工作目录 | `C:\Windows\System32` |
| IconLocation | 图标 | `powershell.exe,0` |
| WindowStyle | 窗口状态 | 普通 / 最小化 |
| RunAs flag | 是否请求管理员 | `.lnk` 二进制第 `0x15` 位 |

关键点：

- `.lnk` 负责启动。
- `cmd.exe` / `powershell.exe` / `wt.exe` 负责执行。
- 出错是否闪退、字体是否好看、是否管理员，都取决于启动方式。

---

## 2. 最基础：PowerShell 直接远程执行

最短写法：

```text
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "irm https://example.com/main.ps1 | iex"
```

对应 PowerShell：

```powershell
irm https://example.com/main.ps1 | iex
```

说明：

- `irm` 是 `Invoke-RestMethod` 的别名，用来下载远程脚本内容。
- `iex` 是 `Invoke-Expression` 的别名，用来执行下载到的文本。
- `-ExecutionPolicy Bypass` 只影响当前进程，方便用户机器上执行。
- `-NoProfile` 避免加载用户自己的 PowerShell Profile，减少干扰。

缺点：

- 报错后窗口可能一闪而过。
- 多层引号容易写错。
- 如果远程脚本带 UTF-8 BOM，可能报 `﻿<# 无法识别`。
- 传统管理员 PowerShell 字体可能变丑。

---

## 3. 不闪退：加 `-NoExit` 或 `pause`

### 3.1 PowerShell 方式

```text
powershell.exe -NoProfile -NoExit -ExecutionPolicy Bypass -Command "irm https://example.com/main.ps1 | iex"
```

`-NoExit` 的作用：执行完成后不关闭窗口。

### 3.2 cmd 包裹方式

```text
cmd.exe /c "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ""irm https://example.com/main.ps1 | iex"" & pause"
```

`pause` 的作用：PowerShell 退出后，cmd 窗口停住，用户能截图错误。

SteamSPA 更推荐 `cmd.exe + pause`，因为给普通用户排错更直观。

---

## 4. 避免缓存：给 URL 加随机参数

远程执行时，GitHub Raw、CDN、代理或本机缓存可能返回旧脚本。解决方法：每次 URL 后面加随机 query。

常见写法：

```powershell
irm "https://example.com/main.ps1?$(Get-Random)" | iex
```

更推荐 GUID：

```powershell
$u = 'https://example.com/main.ps1?' + [guid]::NewGuid().ToString('N')
iex (irm $u)
```

SteamSPA 使用的逻辑：

```powershell
$ProgressPreference = 'SilentlyContinue'
$u = 'https://raw.githubusercontent.com/ZERONE2077/SteamSPA/main/uninstall.ps1?' + [guid]::NewGuid().ToString('N')
iex (irm $u)
```

`$ProgressPreference='SilentlyContinue'` 可以减少下载进度条干扰。

---

## 5. 远程脚本必须 UTF-8 无 BOM

我们实际踩过这个坑：

```text
﻿<# : 无法将“﻿<#”项识别为 cmdlet、函数、脚本文件或可运行程序的名称
```

原因：

- `uninstall.ps1` 文件开头有 UTF-8 BOM。
- `iex(irm(...))` 把 BOM 当成脚本正文的一部分。
- 脚本第一行如果是 `<#` 注释，可能变成 `﻿<#`，PowerShell 不认识。

解决：

- 保存远程脚本为 UTF-8 无 BOM。
- 仓库里的 `uninstall.ps1` 应保持无 BOM。

检查首字节：

```powershell
$bytes = [IO.File]::ReadAllBytes('.\uninstall.ps1')
($bytes[0..2] | ForEach-Object { '{0:X2}' -f $_ }) -join ' '
```

如果输出是：

```text
EF BB BF
```

说明有 BOM。无 BOM 的 PowerShell 脚本通常会直接以 `<#` 开头：

```text
3C 23 ...
```

---

## 6. 管理员权限：为什么需要

SteamSPA 是清理工具，不只是扫描。很多动作普通权限做不了：

- 删除 `C:\Program Files` / `C:\Program Files (x86)` 下文件
- 清理 HKLM 注册表
- 处理 Defender 排除项
- 停止部分进程 / 服务
- 删除系统级残留

所以正式清理建议管理员运行。

### 6.1 `.lnk` 直接设置管理员

可以通过修改 `.lnk` 二进制设置 RunAs flag：

```powershell
$bytes = [System.IO.File]::ReadAllBytes('D:\Dev\SteamSPA\SteamSPA-Remote.lnk')
$bytes[0x15] = $bytes[0x15] -bor 0x20
[System.IO.File]::WriteAllBytes('D:\Dev\SteamSPA\SteamSPA-Remote.lnk', $bytes)
```

优点：

- 用户双击就弹 UAC。
- 命令本身不用再自提权。

缺点：

- 传统管理员 PowerShell 字体可能变丑。

### 6.2 PowerShell 自提权

你以前测试过：

```text
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -Command "Start-Process PowerShell -Verb RunAs -ArgumentList 'Set-ExecutionPolicy Bypass -Scope Process -Force; irm 142785900 | iex'"
```

这个思路是：普通 PowerShell 启动管理员 PowerShell。

缺点：

- 引号很复杂。
- 外层和内层是两个进程。
- 不如直接给 `.lnk` 设置管理员稳定。

### 6.3 脚本内部也要检测管理员

`#Requires -RunAsAdministrator` 对本地 `.ps1` 文件有效，但 `irm ... | iex` 是字符串执行，不能完全依赖它。

建议脚本内部显式检测：

```powershell
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host '请右键以管理员身份运行，或使用带管理员权限的 SteamSPA-Remote.lnk。' -ForegroundColor Red
    Write-Host 'Press Enter to exit...'
    [void][Console]::ReadLine()
    return
}
```

---

## 7. 脚本开头推荐环境设置

别人脚本里常见：

```powershell
Clear-Host
#Requires -RunAsAdministrator
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "SilentlyContinue"
```

含义：

| 写法 | 含义 |
|---|---|
| `Clear-Host` | 清屏，让界面干净 |
| `#Requires -RunAsAdministrator` | 本地脚本要求管理员运行 |
| `$OutputEncoding = ...UTF8` | PowerShell 管道/外部命令输出编码设为 UTF-8 |
| `[Console]::OutputEncoding = ...UTF8` | 控制台输出编码设为 UTF-8 |
| `$ErrorActionPreference = 'SilentlyContinue'` | 默认隐藏非终止错误 |

SteamSPA 当前建议：

```powershell
#Requires -RunAsAdministrator
Clear-Host
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'SilentlyContinue'
```

注意：

- 调试阶段可以不用 `Clear-Host`，方便看历史错误。
- 发布版可以清屏，让用户看到干净界面。
- `SilentlyContinue` 适合清理大量“可能不存在”的路径/注册表项。

---

## 8. cmd.exe 包裹 PowerShell：兼容版推荐

你给过这个思路：

```text
C:\Windows\System32\cmd.exe /c "title STEAM❤️... & powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://gitee.com/SteamWorks/sas/raw/main/main.ps1 | iex" & pause"
```

方向是对的，但直接嵌套引号容易炸。更稳的是：

- 外层用 `cmd.exe /c`
- 中间用 `pause` 防闪退
- PowerShell 复杂逻辑用 `-EncodedCommand`

推荐结构：

```text
TargetPath:
C:\Windows\System32\cmd.exe

Arguments:
/c "title STEAM SPA Remote & ""C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"" -NoProfile -ExecutionPolicy Bypass -EncodedCommand <BASE64> & echo. & pause"
```

`<BASE64>` 是 UTF-16LE 编码后的 PowerShell 命令。PowerShell 的 `-EncodedCommand` 要求 Unicode / UTF-16LE，不是 UTF-8。

生成 Base64：

```powershell
$psCommand = '$ProgressPreference=''SilentlyContinue''; $u=''https://raw.githubusercontent.com/ZERONE2077/SteamSPA/main/uninstall.ps1?'' + [guid]::NewGuid().ToString(''N''); iex (irm $u)'
$encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($psCommand))
```

优点：

- 兼容性好。
- 没有 Windows Terminal 也能用。
- 失败后 `pause` 停住。
- `-EncodedCommand` 避免多层引号问题。

缺点：

- 管理员模式下传统 Console Host 字体可能变丑。
- `cmd title` 对 emoji 不稳定，建议用 ASCII 标题。

---

## 9. Windows Terminal 版：美观版推荐

我们测试后发现：

- Win+R 能运行 `wt.exe`。
- 管理员模式下传统 PowerShell 字体会变丑。
- WT 版字体走 Windows Terminal Profile，显示效果明显更好。

所以可以做美观版：

```text
SteamSPA-Remote-WT.lnk
```

推荐结构：

```text
TargetPath:
C:\Windows\System32\cmd.exe

Arguments:
/c start "" wt.exe -w 0 nt --title "STEAM SPA Remote" powershell.exe -NoProfile -ExecutionPolicy Bypass -EncodedCommand <BASE64>
```

为什么不是直接 `TargetPath = wt.exe`？

因为 `wt.exe` 很多时候是 App Execution Alias：

- Win+R 可以运行。
- 但 WScript / COM 直接保存 `TargetPath = 'wt.exe'` 时，可能解析成奇怪路径。
- 通过 `cmd.exe /c start "" wt.exe ...` 更接近 Win+R 行为，更稳。

WT 版 PowerShell 逻辑建议：

```powershell
$ProgressPreference='SilentlyContinue'
$u='https://raw.githubusercontent.com/ZERONE2077/SteamSPA/main/uninstall.ps1?' + [guid]::NewGuid().ToString('N')
iex (irm $u)
Write-Host
Read-Host 'Press Enter to exit'
```

优点：

- 字体好看。
- 管理员模式下也走 Windows Terminal 字体配置。
- 支持 WT 主题、透明度、字体等设置。
- `Read-Host` 防止窗口关闭。

缺点：

- 依赖用户机器有 Windows Terminal。
- 如果 App Execution Alias 被禁用，会失败。
- 不如纯 `cmd.exe + powershell.exe` 兼容。

判断用户有没有 WT：

```text
Win + R -> wt.exe
```

能打开就基本可用。

---

## 10. Hidden 窗口写法：不推荐给普通用户

你之前测试过：

```text
C:\Windows\System32\cmd.exe /c "powershell -W Hidden -c "saps powershell -V RunAs -Args 'irm steam.run|iex'""
```

```text
C:\Windows\System32\cmd.exe /c "powershell -W Hidden -c "saps powershell -V RunAs -Args 'irm 142785900|iex'""
```

缩写含义：

| 缩写 | 完整写法 |
|---|---|
| `-W Hidden` | `-WindowStyle Hidden` |
| `saps` | `Start-Process` |
| `-V RunAs` | `-Verb RunAs` |
| `-Args` | `-ArgumentList` |

为什么不推荐：

- 用户看不到发生了什么。
- 安全软件更容易拦截。
- 出错无法截图。
- 分发透明度差。

SteamSPA 是清理工具，建议保持可见窗口。

---

## 11. 字体问题总结

我们实际发现：

- `LocalTest.lnk` 普通模式字体正常。
- 一旦开启管理员模式，传统 PowerShell 字体变丑。
- 这是 Windows Console Host 管理员窗口和普通窗口配置不同导致的。
- 复制 `.lnk` 模板不一定能保留字体，因为 WScript 保存快捷方式时可能重写 Console ExtraData。
- 二进制原位替换参数可以保留部分 ExtraData，但管理员模式仍可能使用另一套控制台配置。
- WT 版可以绕过这个问题，因为字体走 Windows Terminal Profile。

推荐：

```text
LocalTest.lnk             # 本地 UI 调试，可以不用管理员
SteamSPA-Remote.lnk       # 兼容正式版，管理员，可能字体一般
SteamSPA-Remote-WT.lnk    # 美观正式版，管理员，字体更好
```

---

## 12. Raw 地址选择

GitHub Raw：

```powershell
irm 'https://raw.githubusercontent.com/ZERONE2077/SteamSPA/main/uninstall.ps1' | iex
```

jsDelivr（`irm` 会乱码，必须按字节取回再按 UTF-8 解，见第 18 节）：

```powershell
iex ([Text.Encoding]::UTF8.GetString((iwr 'https://cdn.jsdelivr.net/gh/ZERONE2077/SteamSPA@main/uninstall.ps1' -UseBasicParsing).RawContentStream.ToArray()))
```

Gitee Raw：

```powershell
irm 'https://gitee.com/SteamWorks/sas/raw/main/main.ps1' | iex
```

国内可用的 jsDelivr 镜像（实测 2026-09-11）：

| 地址 | 说明 |
|---|---|
| `https://jsd.onmicrosoft.cn/gh/ZERONE2077/SteamSPA@main/uninstall.ps1` | 国内 jsDelivr 镜像，最快 |
| `https://cdn.jsdmirror.com/gh/ZERONE2077/SteamSPA@main/uninstall.ps1` | 国内 jsDelivr 镜像 |
| `https://fastly.jsdelivr.net/gh/ZERONE2077/SteamSPA@main/uninstall.ps1` | jsDelivr 官方 Fastly 节点 |
| `https://gcore.jsdelivr.net/gh/ZERONE2077/SteamSPA@main/uninstall.ps1` | jsDelivr 官方 Gcore 节点 |
| `https://cdn.jsdelivr.net/gh/ZERONE2077/SteamSPA@main/uninstall.ps1` | jsDelivr 主站 |

镜像列表与回退逻辑已固化进 `SteamSPA-Remote-JSD.lnk` / `SteamSPA-Remote-JSD-WT.lnk`，见第 17 节。

短链接 / 短码：

```powershell
irm 142785900 | iex
```

建议：

- 给普通用户分发时，最好使用透明 URL。
- 短链接方便，但用户看不出来源。
- 每次都建议加随机参数防缓存。

---

## 13. 生成兼容版 `.lnk` 示例

```powershell
$ErrorActionPreference = 'Stop'

$outPath = 'D:\Dev\SteamSPA\SteamSPA-Remote.lnk'
$url = 'https://raw.githubusercontent.com/ZERONE2077/SteamSPA/main/uninstall.ps1'
$title = 'STEAM SPA Remote'

$cmdExe = 'C:\Windows\System32\cmd.exe'
$powershellExe = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'

$psCommand = '$ProgressPreference=''SilentlyContinue''; $u=''' + $url + '?'' + [guid]::NewGuid().ToString(''N''); iex (irm $u)'
$encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($psCommand))

$arguments = '/c "title ' + $title + ' & ""' + $powershellExe + '"" -NoProfile -ExecutionPolicy Bypass -EncodedCommand ' + $encodedCommand + ' & echo. & pause"'

$ws = New-Object -ComObject WScript.Shell
$link = $ws.CreateShortcut($outPath)
$link.TargetPath = $cmdExe
$link.Arguments = $arguments
$link.WorkingDirectory = 'C:\Windows\System32'
$link.IconLocation = "$powershellExe,0"
$link.Save()

$bytes = [System.IO.File]::ReadAllBytes($outPath)
$bytes[0x15] = $bytes[0x15] -bor 0x20
[System.IO.File]::WriteAllBytes($outPath, $bytes)
```

---

## 14. 生成 WT 美观版 `.lnk` 示例

```powershell
$ErrorActionPreference = 'Stop'

$outPath = 'D:\Dev\SteamSPA\SteamSPA-Remote-WT.lnk'
$url = 'https://raw.githubusercontent.com/ZERONE2077/SteamSPA/main/uninstall.ps1'
$title = 'STEAM SPA Remote'

$cmdExe = 'C:\Windows\System32\cmd.exe'
$powershellExe = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'

$psCommand = '$ProgressPreference=''SilentlyContinue''; $u=''' + $url + '?'' + [guid]::NewGuid().ToString(''N''); iex (irm $u); Write-Host; Read-Host ''Press Enter to exit'''
$encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($psCommand))

$wtArguments = '-w 0 nt --title "' + $title + '" powershell.exe -NoProfile -ExecutionPolicy Bypass -EncodedCommand ' + $encodedCommand
$arguments = '/c start "" wt.exe ' + $wtArguments

$ws = New-Object -ComObject WScript.Shell
$link = $ws.CreateShortcut($outPath)
$link.TargetPath = $cmdExe
$link.Arguments = $arguments
$link.WorkingDirectory = 'C:\Windows\System32'
$link.WindowStyle = 7
$link.IconLocation = "$powershellExe,0"
$link.Save()

$bytes = [System.IO.File]::ReadAllBytes($outPath)
$bytes[0x15] = $bytes[0x15] -bor 0x20
[System.IO.File]::WriteAllBytes($outPath, $bytes)
```

---

## 15. 当前仓库文件对应关系

```text
uninstall.ps1                          # 远程执行的主脚本
SteamSPA-Remote.lnk                    # 兼容版快捷方式（GitHub Raw）
SteamSPA-Remote-WT.lnk                 # Windows Terminal 美观版（GitHub Raw）
SteamSPA-Remote-JSD.lnk                # 兼容版，payload 换成 6 源回退 + 字节级 UTF-8 解码
SteamSPA-Remote-JSD-WT.lnk             # WT 美观版，同上
一键清杀假入库.lnk                      # 对外分发的 WT 版（本地文件，不入库）
docs/LNK使用指南.md                    # 本文档
```

`SteamSPA-Remote` 与 `SteamSPA-Remote-WT` 除启动方式外其余字段一致；两个 JSD 版本是它们的克隆，**只替换了 `ARGS` 段**（标题、图标、工作目录、`RunAs` 标志全部继承）：

| 快捷方式 | 启动方式 | URL |
|---|---|---|
| `SteamSPA-Remote` | `cmd.exe /c "title … & powershell -EncodedCommand … & echo. & pause"` | `raw.githubusercontent.com/ZERONE2077/SteamSPA/main/uninstall.ps1` |
| `SteamSPA-Remote-WT` | `cmd.exe /c start "" wt.exe -w 0 nt --title … powershell -EncodedCommand …` | 同上 |
| `SteamSPA-Remote-JSD` | 同 `SteamSPA-Remote` | 6 源回退：jsd.onmicrosoft.cn → cdn.jsdmirror.com → fastly → gcore → cdn.jsdelivr → raw github |
| `SteamSPA-Remote-JSD-WT` | 同 `SteamSPA-Remote-WT` | 同上 |

> 注：`scripts/New-RemoteShortcut.ps1` / `scripts/New-RemoteShortcut-WT.ps1` 已删除，生成快捷方式的写法见第 13、14、17 节。

---

## 16. 最终分发建议

1. 脚本保持 UTF-8 无 BOM。
2. 远程 URL 带随机 GUID 防缓存。
3. `.lnk` 设置管理员权限。
4. 保留窗口，不要默认 Hidden。
5. 兼容版和 WT 版都保留。
6. 用户不知道有没有 WT：发兼容版。
7. 用户有 WT 且在意字体：发 WT 版。
8. 出问题让用户截图窗口内容，不要一闪而过。
9. **jsDelivr 系来源必须按字节取回再按 UTF-8 解**，否则中文全乱码（第 18 节）。

---

## 17. 国内 CDN 版快捷方式（jsDelivr）

给国内无代理用户用。与 13/14 节结构完全相同，**唯一区别是把 payload 里的 URL 换掉**：

```powershell
# GitHub Raw 版
$ProgressPreference='SilentlyContinue'; $u='https://raw.githubusercontent.com/ZERONE2077/SteamSPA/main/uninstall.ps1?' + [guid]::NewGuid().ToString('N'); iex (irm $u)

# jsDelivr 版（必须按字节取回再按 UTF-8 解，理由见第 18 节）
$ProgressPreference='SilentlyContinue'
$u='https://cdn.jsdelivr.net/gh/ZERONE2077/SteamSPA@main/uninstall.ps1?' + [guid]::NewGuid().ToString('N')
iex ([Text.Encoding]::UTF8.GetString((iwr $u -UseBasicParsing).RawContentStream.ToArray()).TrimStart([char]0xFEFF))
```

WT 版同理，只换取回方式：

```powershell
try{iex([Text.Encoding]::UTF8.GetString((iwr('https://cdn.jsdelivr.net/gh/ZERONE2077/SteamSPA@main/uninstall.ps1?'+(Get-Random)) -UseBasicParsing).RawContentStream.ToArray()))}catch{$_;pause}
```

`SteamSPA-Remote-JSD.lnk` / `-JSD-WT.lnk` 里固化的 payload 比上面多一层**多源回退**：`$spaSources` 依次尝试 jsd.onmicrosoft.cn → cdn.jsdmirror.com → fastly → gcore → cdn.jsdelivr → raw github，成功即 `break`；变量统一加 `$spa` 前缀，避免污染 `iex` 作用域。想单源、失败就报错，把循环换成上面那三行即可。

### 改法：克隆现有 `.lnk` + 原位替换 ARGS 段

不要用 `WScript.Shell` COM 重建快捷方式——沙箱里 `New-Object -ComObject` 会被安全中心拦截；克隆法还能顺带保住 ExtraData（控制台字体/颜色）和 `RunAs` 标记。

`COMMAND_LINE_ARGUMENTS`（`StringData` 段内）是 UTF-16LE 的：

```text
/c "title STEAM SPA - 假入库清杀工具 & ""<powershell.exe>"" -NoProfile -ExecutionPolicy Bypass -EncodedCommand <BASE64> & echo. & pause"
```

`<BASE64>` 解码后是 UTF-16LE 的 PowerShell 命令。步骤：

1. 找到 `/c `（UTF-16LE）的起始位置，往前 2 字节就是该字段的 `CountCharacters`。
2. `CountCharacters` 解码出的字符数 **不含**结尾 NUL，WScript 实际也不写 NUL——所以字段就是紧跟其后的 `count` 个字符。
3. 解 Base64 → 替换 URL → 重新编码 → 回写，并同步改 `CountCharacters`。
4. `StringData` 之前（头 / IDList / LinkInfo）和之后（ICON_LOCATION / ExtraData）**一个字都不用动**，后续内容整体平移。

WT 版把 Arguments 换成（结尾多三行防闪退，见 14 节）：

```text
/c start "" wt.exe -w 0 nt --title "STEAM SPA - 假入库清杀工具" powershell.exe -NoProfile -ExecutionPolicy Bypass -EncodedCommand <BASE64>
```

`RunAs` 标志在 `.lnk` 二进制第 `0x15` 字节的 bit `0x20`，克隆时自动继承，无需再设置。

参考脚本：`temp/read_lnk.py`（按字节解析所有 `.lnk` 的参数与 Base64）、`temp/patch2.py`（克隆 + 换 URL）。

关于缓存：URL 带 `[guid]::NewGuid()` 时每次都回源 jsDelivr，拿到的一定是最新版；去掉它才能吃到镜像缓存，但 `@main` 分支最长陈旧 12 小时。分发场景默认保留防缓存参数。

---

## 18. jsDelivr 的编码坑：`irm` 会把中文变成乱码

**现象**：用 jsDelivr / 国内镜像跑脚本，界面和 TXT 报告里中文全变成 `æ«æ`、`âââ`、`ð¥¸` 这种，但扫描和清理本身跑得完（2026-09-11 有客户实机中招）。

**原因**：编码是 UTF-8 的文件被按 ISO-8859-1（≈CP1252）解了一遍。UTF-8 的「扫」是 `E6 89 AB`，按 Latin-1 逐字节解出来就是 `æ‰«`——`æ`、`â`、`ð` 这族字符一出现就基本可以判定是 UTF-8→Latin-1。

**触发条件**：`Invoke-RestMethod` / `Invoke-WebRequest` 在 **Windows PowerShell 5.1** 下，若响应头 `Content-Type` 不带 `charset`，默认按 ISO-8859-1 解码。实测各来源：

| 来源 | Content-Type（实测 2026-09-11） | PS 5.1 `irm` | PS 7 `irm` |
|---|---|---|---|
| `cdn.jsdelivr.net` | `application/octet-stream` | ❌ 乱码（80637 字符 = 逐字节） | ✅ |
| `fastly.jsdelivr.net` | `application/octet-stream` | ❌ 乱码 | ✅ |
| `gcore.jsdelivr.net` | `application/octet-stream` | ❌ 乱码 | ✅ |
| `jsd.onmicrosoft.cn` | `application/octet-stream` | ❌ 乱码 | ✅ |
| `cdn.jsdmirror.com` | `application/octet-stream` | ❌ 乱码 | ✅ |
| `raw.githubusercontent.com` | `text/plain; charset=utf-8` | ✅ 正常 | ✅ |

PowerShell 7 默认 UTF-8，所以本地用 pwsh 测不出来——**必须用 `powershell.exe`（5.1）复测**。

**正确写法**（5.1 / 7 都正常，实测）：

```powershell
$u = 'https://cdn.jsdelivr.net/gh/ZERONE2077/SteamSPA@main/uninstall.ps1?' + [guid]::NewGuid().ToString('N')
$r = Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 30
$t = [System.Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()).TrimStart([char]0xFEFF)
iex $t
```

同效的等价写法（各有代价）：

| 写法 | 5.1 | 7 | 说明 |
|---|---|---|---|
| `iwr … -OutFile f` + `Get-Content f -Raw -Encoding UTF8` | ✅ | ✅ | 稳，但落盘 |
| `(New-Object Net.WebClient).Encoding=[Text.Encoding]::UTF8` + `DownloadString` | ✅ | ✅ | 稳，但 WebClient 已过时 |
| `New-Object System.Net.Http.HttpClient` | ❌ 找不到类型 | ✅ | 5.1 需先 Add-Type 加载程序集 |
| `[Text.Encoding]::UTF8.GetString($r.Content)` | ❌ | ❌ | `$r.Content` 已是错误解码后的结果，救不回来 |

`TrimStart([char]0xFEFF)` 是为了顺手吃掉 BOM——见第 5 节，`iex` 遇到 BOM 会报 `﻿<# 无法识别`。

**功能影响（不只是显示）**：脚本里唯一带中文的“数据”是这条路径——

```json
"path":  "${SteamPath}\\ANNO117 - 副本.zip"
```

乱码后该字符串不再等于真实文件名，这条残留检测会失效（其余规则路径全是 ASCII，不受影响）。所以乱码不是纯显示问题，仍应修掉。

**防呆**：payload 里加了 `$spaText.Contains('SteamSPA')` 的长度/内容校验，避免镜像返回 200 的 HTML 错误页被直接喂给 `iex`。
