# SteamSPA 样本与规则维护

以后只维护三件事：

1. 保存原始样本。
2. 把确认过的痕迹写入 `data/rules.json`。
3. 重新生成并验证 `uninstall.ps1`。

`data/痕迹总表.md` 是可选索引，不需要每来一个样本就同步一遍。  
`research/docs/` 是旧的本地分析记录，不是规则源。

## 1. 保存样本

按来源和日期归档：

```text
research/samples/<来源>/<YYYY-MM-DD>/
```

至少保留：

- 原始 PowerShell 脚本
- 下载的压缩包或载荷
- `SHA256SUMS.txt`

样本只做静态分析，不直接执行。归档目录已被 `.gitignore` 忽略，不会上传。

## 2. 更新规则

`data/rules.json` 是唯一规则源。优先复用已有规则，只补样本实际写入或替换的精确路径：

- 新样本追加到对应规则的 `sources`。
- 新的文件痕迹写精确文件路径，不写 `${SteamPath}\bin`、`config\lua` 这类整目录。
- 旧的规则 ID 不要改，避免破坏 `-Only` 参数。
- 确认后再改；不确定的通用 DLL 名只记录，不直接加入删除列表。

`uninstall.ps1` 是生成物，不要手工修改。

## 3. 生成与验证

在仓库根目录执行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\build.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\SmokeTests.ps1
python .\tools\validate-rules.py
```

看到 `SteamSPA build is up to date`、`SteamSPA validation passed` 和
`ALL CHECKS PASSED` 即可。

正常执行 `tools/build.ps1` 会把 `data/version.json` 的 `updatedAt` 自动写成当天日期，
并重新生成 `uninstall.ps1`；`-Check` 只校验生成物，不会改日期。

## 4. 发布

构建、冒烟测试、规则校验和生成脚本试运行全部通过后，执行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\publish.ps1 -Message "Update SteamSPA"
```

发布脚本只提交 `README.md`、`uninstall.ps1`、`data/`、`src/`、`tools/`、`tests/`、
`schemas/` 和 `research/README.md`，不会提交 `research/samples/`、`research/docs/`
或本地压缩包。推送后会核对远端提交，以及线上 `uninstall.ps1` 的版本和日期。

## 新增样本时的人工检查

只回答下面几项，够写规则就停：

- 脚本从哪里下载，落到哪里？
- 新建、覆盖、删除了哪些文件？
- 是否有注册表、Defender、计划任务、进程动作？
- 哪些是本家族已有痕迹，哪些是真正新增？

没有明确证据的路径不写入删除规则。
