# SteamSPA 需求

## 一句话

分析网上常见的 Steam 假入库 / 解锁脚本，识别它们写入的文件、注册表、Defender 排除项等痕迹，并提供一个对外可用的清理脚本。

## 范围

- 输入：`scripts/` 下按团队 / 来源归档的历史脚本
- 数据：`targets.json` 汇总所有历史脚本版本产生过的清理规则，不只记录最新版
- 输出（对外）：`uninstall.ps1`
- 输出（自用）：`dev/analyze.ps1` 静态扫描候选项

## 非目标

- 不还原 Steam 客户端被破解前的状态（如游戏数据、登录态等）
- 不分析 Steam 本身的更新或非清理类问题
- 不做 GUI

## 安全原则

- 默认必须支持 `-DryRun`
- 高风险动作（删除 LocalAppData\steam、Defender 排除项）需要二次确认
- 删除前自动备份到 `temp/backups/<timestamp>/`
- 所有动作要写入 `temp/logs/<timestamp>.json`
