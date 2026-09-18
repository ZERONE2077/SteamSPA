# SteamSPA

SteamSPA 是一个 Windows PowerShell 工具，用于识别、展示并清理 Steam 假入库 / 解锁脚本留下的残留。

## 使用

### GitHub Raw

```powershell
irm https://raw.githubusercontent.com/ZERONE2077/SteamSPA/main/uninstall.ps1 | iex
```

### jsDelivr CDN

当 GitHub Raw 访问慢、缓存异常或 Windows PowerShell 5.1 出现编码问题时，可使用 jsDelivr：

```powershell
irm https://cdn.jsdelivr.net/gh/ZERONE2077/SteamSPA@main/uninstall.ps1 | iex
```

浏览器直链：

https://cdn.jsdelivr.net/gh/ZERONE2077/SteamSPA@main/uninstall.ps1

本地运行：
```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1
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
research/
```

Windows PowerShell 5.1+，无需第三方 PowerShell 模块。
