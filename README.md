# SteamSPA

SteamSPA 是一个 Windows PowerShell 工具，用于识别、展示并清理 Steam 假入库 / 解锁脚本留下的残留。

## 使用

### GitHub Raw

```powershell
irm https://raw.githubusercontent.com/ZERONE2077/SteamSPA/main/uninstall.ps1 | iex
```

### jsDelivr CDN

jsDelivr 在国内更快，但它把 `.ps1` 当二进制返回（`Content-Type: application/octet-stream`，不带 charset），**Windows PowerShell 5.1 的 `irm` 会按 ISO-8859-1 解码，中文全部乱码**。必须按字节取回再按 UTF-8 解：

```powershell
$u = 'https://cdn.jsdelivr.net/gh/ZERONE2077/SteamSPA@main/uninstall.ps1?' + [guid]::NewGuid().ToString('N')
iex ([Text.Encoding]::UTF8.GetString((iwr $u -UseBasicParsing).RawContentStream.ToArray()).TrimStart([char]0xFEFF))
```

PowerShell 7 默认 UTF-8，用 `irm ... | iex` 也正常。

浏览器直链：

https://cdn.jsdelivr.net/gh/ZERONE2077/SteamSPA@main/uninstall.ps1

本地运行（`-File` 在 5.1 下会按 ANSI 解码导致中文乱码，改用显式 UTF-8 读取）：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((Get-Content .\uninstall.ps1 -Raw -Encoding UTF8)))"
```

## 参数

- `-Risk low,medium,high`：选择风险级别
- `-Only rule-id`：只处理指定规则
- `-NoBackup`：不创建清理备份
- `-NoPause`：结束时不等待按键

## 架构

```text
data/rules.json
      ↓
src/*.ps1
      ↓
tools/build.ps1
      ↓
uninstall.ps1  ← 唯一对外分发产物
```

`data/rules.json` 是运行规则的唯一数据源。修改规则或源码后执行 `tools/build.ps1`。

样本归档、规则更新和验证步骤见 `research/README.md`。

## 安全设计

- 扫描阶段不删除文件。
- 清理前必须明确确认。
- Valve 有效数字签名文件自动保护。
- Defender 模块不存在时安全跳过相关动作。
- DNS、代理等可能是用户主动配置的设置默认只报告。
- PowerShell 历史记录只作为线索，不单独作为删除依据。
- 默认创建清理备份，不在桌面生成报告。

## 目录

```text
uninstall.ps1
data/rules.json
src/
tools/
tests/
schemas/
```

Windows PowerShell 5.1+，无需第三方 PowerShell 模块。
