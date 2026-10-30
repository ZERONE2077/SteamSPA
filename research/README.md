# SteamSPA 维护流程

日常只有一件事：收到新的假入库商家 `irm` 指令 → 分析它会留下什么 → 补进规则 → 重新生成并发布 `uninstall.ps1`。

## 1. 取回样本（只下载，不执行）

按来源和日期归档：

```text
research/samples/<来源>/<YYYY-MM-DD>/
```

至少保留：原始 PowerShell 脚本、它下载的压缩包或载荷、`SHA256SUMS.txt`。
多段 `irm` 套娃的，每一段都存下来。样本只做静态分析，不直接执行。
`research/samples/` 和 `research/docs/` 被 `.gitignore` 排除，不会上传。

## 2. 分析写入点

```powershell
python .\research\tools\scan_writes.py     # 写入类操作（落盘、复制、注册表、计划任务、Defender…），带行号
python .\research\tools\scan_samples.py    # 全部路径线索 + 与现有规则的覆盖比对（仅供参考）
```

输出在 `temp/steamcn/`（已忽略）。人工确认这几项就够写规则：

- 脚本从哪里下载，落到哪里？
- 新建、覆盖、删除了哪些文件？
- 是否有注册表、Defender、计划任务、进程动作？
- 哪些是已有家族的痕迹，哪些是真正新增？

`research/tools/fetch-page.ps1 -Url <落地页>` 只用来抓商家网页留档，抓下来的不是样本。

## 3. 更新规则

`data/rules.json` 是唯一规则源（结构见 `data/rules.schema.json`）：

- 优先复用已有规则，新样本追加到对应规则的 `sources`。
- 只写样本实际写入或替换的精确路径，不写 `${SteamPath}\bin`、`config\lua` 这类整目录。
- 旧规则 ID 不要改，避免破坏 `-Only` 参数。
- 没有明确证据的路径、不确定的通用 DLL 名，只记录，不加进删除列表。

`research/痕迹总表.md` 是可选的人读索引，想同步时改完再跑
`python .\research\tools\md2csv.py` 生成 CSV。

## 4. 生成、验证、发布

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\build.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\SmokeTests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\publish.ps1 -Message "rules: 新增 <来源>"
```

- `build.ps1` 把 `src/` + `data/` 拼成 `uninstall.ps1`，并把 `data/version.json` 的 `updatedAt` 改成当天。
- `SmokeTests.ps1` 检查语法、生成物一致性、规则库、样本引用、沙盒删除和只扫描试运行。
- `publish.ps1` 再构建一次、跑冒烟测试，通过后提交并推送 `origin/main`，最后核对线上 `uninstall.ps1` 的版本和日期。

`uninstall.ps1` 是生成物，不要手工修改。

## 5. 本机试跑

根目录的 `.lnk`（不进仓库）都调用 `tools/launch.ps1`：

- `-Source Local`：跑本地 `uninstall.ps1`
- `-Source GitHub`：从 raw.githubusercontent.com 取最新版
- `-Source Mirror`：从 jsDelivr 取最新提交（绕过 `@main` 的 CDN 缓存），和用户拿到的一样
