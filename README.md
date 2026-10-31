# SteamSPA

SteamSPA 是一个 Windows PowerShell 工具，用于识别、展示并清理 Steam 假入库 / 解锁脚本留下的残留。

## 使用

做法统一是“下载成文件 → 运行文件”。不用 `-EncodedCommand`，也不用 `irm | iex`，
这两种写法和木马的常见套路一样，会被杀软报毒。

### 快捷方式（推荐给普通用户）

`tools/make-link.ps1` 生成 `Steam Spa 清理工具.lnk`，双击即可。命令是明文：
依次尝试国内镜像和 GitHub，下载到 `%TEMP%\SteamSPA.ps1` 后运行。
快捷方式不用勾"以管理员身份运行"，需要时脚本会自己申请。

### 复制到 PowerShell 运行

```powershell
$f = "$env:TEMP\SteamSPA.ps1"; iwr https://fastly.jsdelivr.net/gh/ZERONE2077/SteamSPA@main/uninstall.ps1 -OutFile $f -UseBasicParsing; powershell -NoProfile -ExecutionPolicy Bypass -File $f
```

能访问 GitHub 时把地址换成 `https://raw.githubusercontent.com/ZERONE2077/SteamSPA/main/uninstall.ps1`。
`publish.ps1` 发布后会刷新 jsDelivr 官方节点的缓存；第三方镜像（jsdmirror 等）刷新不了，可能一天内还是旧版，只做备用。

### 本地运行

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\uninstall.ps1
```

文件带 UTF-8 BOM，5.1 用 `-File` 运行中文正常；`-OutFile` 按原始字节保存，BOM 不会丢。

## 参数

- `-ScanOnly`：只扫描并列出，不询问、不删除
- `-Risk low,medium,high`：只处理指定风险级别的规则
- `-Only rule-id,...`：只处理指定规则
- `-NoPause`：结束时不等待按键
- `-Help`：显示帮助

退出码（仅文件方式运行时）：0 正常，1 部分失败，2 参数错误，4 用户取消，5 需要管理员。

## 运行流程

1. 显示本机信息；不是管理员时询问是否以管理员身份重新打开（脚本自身源码写到临时文件后提权运行，不重新下载）。
2. 列出 PowerShell 历史里的可疑下载命令（仅显示，不作为删除依据）。
3. 扫描所有规则（只读），同一目标在多条规则里出现只算一次。
4. 按类别列出发现项；Valve 签名文件和受保护目录单独列出且不删除。
5. 确认：`Y` 或回车全部清理，`N` 取消。
6. STEAM 正在运行时先关闭；先结束进程、删计划任务，再删文件和注册表。清理对象都是非官方残留，不做备份。
7. 汇总结果。

## 维护

整个工具就是一个文件 `uninstall.ps1`，规则以 JSON 形式内嵌在开头的 `$EmbeddedTargetsJson` 里。

收到新的假入库 `irm` 指令时：

1. 逐段下载脚本和载荷到本机 `research/samples/<来源>/<日期>/`（只下载不执行，该目录不上传）。
2. 找出它写入或替换的文件、注册表、Defender 排除、计划任务、进程。
3. 补进规则：优先追加到已有规则；只写精确路径，不写整目录；不改已有规则 id；没有证据的不加。
4. 运行 `tests/SmokeTests.ps1` 验证，然后 `tools/publish.ps1 -Message "rules: 新增 <来源>"` 发布。

支持的动作类型：`file`、`registry-key`、`registry-value`、`defender-exclusion-path`、
`defender-exclusion-extension`、`defender-exclusion-process`、`process`、`task`、`task-contains`。

`publish.ps1` 会把脚本里的更新日期改成当天，测试通过后提交推送，并核对线上版本。
根目录的 `.lnk`（不进仓库）通过 `tools/launch.ps1` 分别试跑本地、GitHub、jsDelivr 三种来源。

## 安全设计

- 扫描阶段只读，不修改系统；清理前列出全部目标，确认一次（回车 = 清理）。
- 路径模板里的变量缺失（例如没找到 STEAM）时直接跳过该规则，不会拼出残缺路径。
- 硬性边界：不删磁盘根目录、系统和用户根目录、STEAM 根目录及 config/bin/steamapps/userdata 等，
  `steamapps`（游戏）和 `userdata`（存档）下的任何内容都不碰。
- Valve 有效数字签名文件自动保护。
- 非空目录、带子项的注册表项只在规则写明 `recurse` 时才整体删除。
- Defender 不可用或无权读取时安全跳过并提示。

## 目录

```text
uninstall.ps1        整个工具（程序 + 规则），唯一对外分发的文件
tests/SmokeTests.ps1 冒烟测试
tools/publish.ps1    发布
tools/launch.ps1     本机试跑
tools/make-link.ps1  生成对外分发的快捷方式
```

Windows PowerShell 5.1+，无需第三方模块。
