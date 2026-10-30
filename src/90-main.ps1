# SteamSPA · 主流程
#   本机信息 -> 扫描（只读）-> 扫描结果 -> 历史线索
#   -> 没发现：结束（普通权限时可选"以管理员身份完整检查"）
#   -> 发现了：普通权限 -> 打开管理员窗口重新扫描
#              管理员   -> 清理前须知 -> 一次确认 -> 关闭 STEAM -> 备份并清理 -> 汇总
#   -> 结束（关闭过 STEAM 时可选"重新打开 STEAM"）

function Show-SpaHelp {
    Write-Ui '用法：uninstall.ps1 [-ScanOnly] [-Risk low,medium,high] [-Only 规则ID,...] [-NoBackup] [-NoPause]'
    Write-Ui ''
    Write-Ui '  -ScanOnly   只扫描并列出，不询问、不删除'
    Write-Ui '  -Risk       只处理指定风险级别的规则（默认全部）'
    Write-Ui '  -Only       只处理指定 ID 的规则'
    Write-Ui '  -NoBackup   清理前不备份（不推荐）'
    Write-Ui '  -NoPause    结束时不等待回车'
    Write-Ui ''
    Write-Ui '退出码：0 正常  1 部分失败  2 参数错误  4 用户取消  5 需要管理员'
}

function Show-SpaHeader {
    Write-Host ''
    Write-UiBanner @(
        '  ███████ ████████ ███████  █████  ███    ███     ███████ ██████   █████  '
        '  ██         ██    ██      ██   ██ ████  ████     ██      ██   ██ ██   ██ '
        '  ███████    ██    █████   ███████ ██ ████ ██     ███████ ██████  ███████ '
        '       ██    ██    ██      ██   ██ ██  ██  ██          ██ ██      ██   ██ '
        '  ███████    ██    ███████ ██   ██ ██      ██     ███████ ██      ██   ██ '
    )
    Write-Host ''
    Write-Ui '  假入库清理 / 专杀工具：注入 DLL · STEAM 配置 · 注册表 · 启动项 · 系统服务 · 安全策略 · 后台进程' Muted
    Write-Ui ('  作者：万能小哥    版本：v{0}    最后更新：{1}' -f $SteamSPAReleaseVersion, $SteamSPAUpdatedAt) Dim
}

# STEAM 目录下的路径显示成 STEAM\...，列表更短更好读（完整路径在本机信息里）。
function Format-SpaLabel {
    param([string]$Label)
    $steam = [string]$Spa.SteamPath
    if (-not $steam) { return $Label }
    return [regex]::Replace($Label, [regex]::Escape($steam.TrimEnd('\')), 'STEAM', 'IgnoreCase')
}

function Get-SteamProcess {
    return @(Get-Process -Name 'steam', 'steamwebhelper' -ErrorAction SilentlyContinue)
}

# 先请 STEAM 自己退出，15 秒后还没退就强制结束。返回是否已全部退出。
function Stop-Steam {
    param([string]$SteamPath)
    $exe = if ($SteamPath) { Join-Path $SteamPath 'steam.exe' } else { $null }
    if ($exe -and (Test-Path -LiteralPath $exe -PathType Leaf)) {
        try { Start-Process -FilePath $exe -ArgumentList '-shutdown' -ErrorAction Stop } catch {}
    }
    $deadline = (Get-Date).AddSeconds(15)
    while ((Get-Date) -lt $deadline -and (Get-SteamProcess).Count -gt 0) { Start-Sleep -Milliseconds 500 }
    Get-SteamProcess | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 800
    return ((Get-SteamProcess).Count -eq 0)
}

function Get-SpaRiskRank {
    param([string]$Risk)
    switch ($Risk) { 'high' { 3 } 'medium' { 2 } default { 1 } }
}

function Select-SpaRules {
    param($Database, [hashtable]$Options)
    $all = @($Database.rules)
    foreach ($id in $Options.Only) {
        if (-not ($all | Where-Object { $_.id -eq $id })) { $Spa.Warnings.Add('未找到规则 ID: ' + $id) }
    }
    return @($all | Where-Object {
            $_.enabled -ne $false -and
            $Options.Risk -contains $_.risk -and
            ($Options.Only.Count -eq 0 -or $Options.Only -contains $_.id)
        })
}

# 扫描所有规则，合并指向同一目标的动作。只读，不修改系统。
function Invoke-SpaScan {
    param([object[]]$Rules, [hashtable]$Variables)

    $started = Get-Date
    $byKey = @{}
    $targets = New-Object System.Collections.Generic.List[object]
    $total = 0
    foreach ($rule in $Rules) { $total += @($rule.actions).Count }
    $done = 0

    foreach ($rule in $Rules) {
        foreach ($action in @($rule.actions)) {
            $done++
            Write-UiProgress -Current $done -Total $total
            foreach ($found in @(Find-SpaActionTargets -Action $action -Variables $Variables)) {
                $target = $byKey[$found.Key]
                if (-not $target) {
                    $target = $found
                    $byKey[$found.Key] = $target
                    $targets.Add($target)
                }
                elseif ($found.Recurse) {
                    $target.Recurse = $true
                }
                if (-not $target.RuleIds.Contains($rule.id)) { $target.RuleIds.Add($rule.id) }
                if ((Get-SpaRiskRank $rule.risk) -gt (Get-SpaRiskRank $target.Risk)) { $target.Risk = $rule.risk }
                if ($rule.confirm -eq $true) { $target.Confirm = $true }
            }
        }
    }
    Clear-UiProgress
    Write-UiResult '扫描完成' ('共检查 {0} 个位置，用时 {1:N1} 秒' -f $total, ((Get-Date) - $started).TotalSeconds) Success
    return $targets.ToArray()
}

function Show-SpaEnvironment {
    param([hashtable]$Variables, [bool]$IsAdmin, [bool]$SteamRunning)
    Write-UiSection '本机信息'
    Write-UiKeyValue '系统' (Get-SpaOSName)
    if ($Variables.SteamPath) { Write-UiKeyValue 'STEAM' $Variables.SteamPath Path }
    else { Write-UiKeyValue 'STEAM' '未检测到安装目录（STEAM 目录相关检查将跳过）' Warning }
    if ($SteamRunning) { Write-UiKeyValue 'STEAM 状态' '正在运行' Warning }
    else { Write-UiKeyValue 'STEAM 状态' '未运行' Muted }
    if ($IsAdmin) { Write-UiKeyValue '权限' '管理员' Success }
    else { Write-UiKeyValue '权限' '普通用户（清理时会请求管理员权限）' Muted }
}

function Show-SpaFindings {
    param([object[]]$Items, [object[]]$Protected)

    if ($Items.Count -eq 0) {
        Write-UiSection '扫描结果' '未发现假入库残留' Success
    }
    else {
        $flagged = @($Items | Where-Object { $_.Confirm }).Count
        $hint = '发现 {0} 项残留' -f $Items.Count
        if ($flagged -gt 0) { $hint += '（其中 {0} 项涉及系统设置，标为"需确认"）' -f $flagged }
        Write-UiSection '扫描结果' $hint Danger
    }

    $titles = [ordered]@{ files = '文件'; config = 'STEAM 配置'; registry = '注册表'; startup = '启动项 / 计划任务'; security = '系统安全设置'; process = '后台进程' }
    $n = 0
    foreach ($category in $titles.Keys) {
        $group = @($Items | Where-Object { $_.Category -eq $category })
        if ($group.Count -eq 0) { continue }
        Write-Host ''
        Write-Ui ('    {0}  ' -f $titles[$category]) Accent -NoNewline
        Write-Ui ([string]$group.Count) Dim
        foreach ($item in $group) {
            $n++
            Write-Ui ('    {0,4}  ' -f $n) Dim -NoNewline
            Write-Ui (Format-SpaLabel $item.Label) Path -NoNewline
            if ($item.Confirm) { Write-Ui '  需确认' Warning } else { Write-Host '' }
        }
    }

    if ($Protected.Count -gt 0) {
        Write-Host ''
        Write-Ui ('    已保护  {0} 项，不会删除' -f $Protected.Count) Success
        foreach ($item in $Protected) {
            Write-Ui ('          {0}  ' -f (Format-SpaLabel $item.Label)) Muted -NoNewline
            Write-Ui $item.Note Dim
        }
    }
    foreach ($w in $Spa.Warnings) { Write-UiNote $w -Important }
}

function Show-SpaClues {
    $clues = @(Find-SpaHistoryClues -Lines (Get-SpaHistoryLines))
    if ($clues.Count -eq 0) { return }
    Write-UiSection '历史线索' '在 PowerShell 历史里找到的可疑下载命令，仅供参考，不作为删除依据'
    $i = 0
    foreach ($clue in $clues) {
        $i++
        Write-Ui ('    {0,4}  ' -f $i) Dim -NoNewline
        Write-Ui $clue Muted
    }
}

# 普通权限下：以管理员身份重开。成功返回 $true（本窗口随后直接结束，不再等回车）。
function Request-SpaElevation {
    param([string]$Reason, [string]$Action, [string]$SelfText)
    Write-UiSection '需要管理员权限' $Reason Warning
    Write-UiOption 'Y' $Action
    Write-UiOption 'N' '退出'
    if ((Read-UiChoice -Prompt '请选择 [Y/N]，回车 = Y:' -Allowed @('Y', 'N') -Default 'Y') -ne 'Y') { return $false }
    if (Start-SpaElevated -SelfText $SelfText -Options $Spa.Options) {
        Write-UiResult '已打开' '已在新的管理员窗口中继续，本窗口可以关闭。' Success
        $Spa.Paused = $true
        return $true
    }
    Write-UiResult '未提权' '没有获得管理员权限（可能在 UAC 提示里选了"否"）。' Warning
    Write-UiNote '也可以右键开始菜单，选择"终端(管理员)"，再运行同一条命令。'
    return $false
}

# 清理前须知 + 一次确认。返回要清理的目标；取消返回 $null。
function Read-SpaCleanupDecision {
    param([object[]]$Items, [bool]$SteamRunning)

    Write-UiSection '清理前请注意'
    if ($SteamRunning) { Write-UiNote 'STEAM 正在运行，清理时会被强制关闭。' -Important }
    Write-UiNote '请先保存游戏进度、退出正在运行的游戏，并暂停 STEAM 下载和更新。' -Important
    Write-UiNote '清理后可能需要重新登录 STEAM：请确认记得账号、密码，手机令牌可用。' -Important
    Write-UiNote '不影响游戏本体、存档、创意工坊和 MOD（这些目录被硬性排除）。'
    Write-UiNote '每一项删除前都会备份，出问题可以一键恢复。'
    Write-UiNote '清理失败时，请暂时退出杀毒软件后重试。'
    Write-UiNote '清理后首次打开 STEAM 可能较慢，建议开启加速器，耐心等几分钟。'

    $regular = @($Items | Where-Object { -not $_.Confirm })
    $flagged = @($Items | Where-Object { $_.Confirm })
    $verb = if ($SteamRunning) { '关闭 STEAM 并清理' } else { '清理' }

    Write-UiSection '是否清理？'
    Write-UiOption 'Y' ('{0}全部 {1} 项' -f $verb, $Items.Count)
    $allowed = @('Y', 'N')
    if ($regular.Count -gt 0 -and $flagged.Count -gt 0) {
        Write-UiOption 'S' ('{0}常规的 {1} 项，跳过 {2} 项"需确认"' -f $verb, $regular.Count, $flagged.Count)
        $allowed = @('Y', 'S', 'N')
    }
    Write-UiOption 'N' '取消，不做任何修改'
    $choice = Read-UiChoice -Prompt ('请选择 [' + ($allowed -join '/') + ']，回车 = 取消:') -Allowed $allowed -Default 'N'

    if ($choice -eq 'N') { return $null }
    if ($choice -eq 'S') {
        foreach ($t in $flagged) { Set-SpaResult $t 'skipped' '用户选择跳过' }
        return $regular
    }
    return $Items
}

function Invoke-SpaCleanup {
    param([object[]]$Selected, [hashtable]$Variables, [bool]$SteamRunning)

    Write-UiSection '清理'
    if ($SteamRunning) {
        Write-Ui '    正在关闭 STEAM...' Muted
        if (Stop-Steam -SteamPath $Variables.SteamPath) { Write-UiResult '已关闭' 'STEAM' Success }
        else { Write-UiResult '注意' 'STEAM 没有完全退出，部分文件可能删除失败' Warning }
    }

    # 先结束进程、删计划任务，避免它们在清理过程中把文件写回来。
    $order = @{ process = 0; task = 1; file = 2; 'registry-key' = 3; 'registry-value' = 4 }
    $ordered = @($Selected | Sort-Object { if ($order.ContainsKey($_.Type)) { $order[$_.Type] } else { 5 } })
    $backup = New-SpaBackup -Enabled (-not $Spa.Options.NoBackup)
    foreach ($t in $ordered) {
        Remove-SpaTarget -Target $t -Backup $backup -Variables $Variables
        $label = Format-SpaLabel $t.Label
        switch ($t.Status) {
            'removed' { Write-UiResult $(if ($t.Type -eq 'process') { '已结束' } else { '已清理' }) $label Success }
            'skipped' { Write-UiResult '跳过' ($label + '  (' + $t.Message + ')') Muted }
            default { Write-UiResult '失败' ($label + '  (' + $t.Message + ')') Danger }
        }
    }
    return (Complete-SpaBackup -Backup $backup)
}

function Show-SpaSummary {
    param([object[]]$Items, [string]$BackupPath, [datetime]$StartedAt)

    $removed = @($Items | Where-Object { $_.Status -eq 'removed' }).Count
    $failed = @($Items | Where-Object { $_.Status -eq 'failed' }).Count
    $skipped = @($Items | Where-Object { $_.Status -eq 'skipped' -or -not $_.Status }).Count

    if ($failed -gt 0) { Write-UiSection '完成' ('{0} 项清理失败，请暂时退出杀毒软件后再运行一次' -f $failed) Danger }
    elseif ($removed -gt 0) { Write-UiSection '完成' '清理成功' Success }
    else { Write-UiSection '完成' '没有删除任何项目' Warning }
    Write-UiKeyValue '已清理' ([string]$removed) Success
    if ($failed) { Write-UiKeyValue '失败' ([string]$failed) Danger }
    if ($skipped) { Write-UiKeyValue '跳过' ([string]$skipped) Muted }
    if ($BackupPath) {
        Write-UiKeyValue '备份' $BackupPath Path
        Write-UiKeyValue '恢复' '运行备份目录里的 restore.ps1' Muted
    }
    Write-UiKeyValue '耗时' ('{0:N1} 秒' -f ((Get-Date) - $StartedAt).TotalSeconds) Muted
}

# 结束：关闭过 STEAM 时可以顺手重新打开。
function Read-SpaExit {
    param([string]$SteamPath, [bool]$OfferSteam)
    $Spa.Paused = $true
    if ($Spa.Options.NoPause -or ($Spa.Ui -and $Spa.Ui.InputRedirected)) { return }
    $exe = if ($SteamPath) { Join-Path $SteamPath 'steam.exe' } else { $null }
    if ($OfferSteam -and $exe -and (Test-Path -LiteralPath $exe -PathType Leaf)) {
        Write-Host ''
        Write-UiOption 'R' '重新打开 STEAM'
        Write-UiOption '回车' '退出'
        if ((Read-UiChoice -Prompt '请选择:' -Allowed @('R') -Default '') -eq 'R') {
            try { Start-Process -FilePath $exe -ErrorAction Stop } catch { Write-UiResult '失败' '无法启动 STEAM，请手动打开' Danger }
        }
        return
    }
    Wait-UiExit
}

function Invoke-SpaMain {
    param([hashtable]$Options, [string]$SelfText)

    $startedAt = Get-Date
    if ($Options.Help) { Show-SpaHelp; return 0 }
    if ($Options.Errors.Count -gt 0) {
        foreach ($e in $Options.Errors) { Write-UiResult '参数错误' $e Danger }
        Write-Host ''
        Show-SpaHelp
        return 2
    }

    try { $Host.UI.RawUI.WindowTitle = 'STEAM SPA 清理工具' } catch {}
    if (-not $Spa.Ui.Redirected) { try { Clear-Host } catch {} }
    Show-SpaHeader

    # ---- 本机信息 ----
    $variables = Get-SpaVariables
    $Spa.SteamPath = $variables.SteamPath
    $isAdmin = Test-SpaAdmin
    $steamRunning = (Get-SteamProcess).Count -gt 0
    Show-SpaEnvironment -Variables $variables -IsAdmin $isAdmin -SteamRunning $steamRunning

    # ---- 扫描（只读）----
    Write-UiSection '扫描' $(if ($Options.Elevated) { '已切换到管理员权限，重新完整扫描' } else { '' })
    $rules = Select-SpaRules -Database ($EmbeddedTargetsJson | ConvertFrom-Json) -Options $Options
    $all = @(Invoke-SpaScan -Rules $rules -Variables $variables)
    $items = @($all | Where-Object { $_.State -eq 'present' })
    $protected = @($all | Where-Object { $_.State -eq 'protected' })
    if ($Spa.DefenderHidden) { $Spa.Warnings.Add('Defender 排除项需要管理员权限才能检查，本次未检查。') }
    Show-SpaFindings -Items $items -Protected $protected
    Show-SpaClues

    $canAsk = -not $Options.ScanOnly -and -not $Spa.Ui.InputRedirected

    # ---- 没发现 ----
    if ($items.Count -eq 0) {
        if ($canAsk -and -not $isAdmin -and $Spa.DefenderHidden) {
            [void](Request-SpaElevation -Reason '普通权限看不到 Defender 排除项等系统设置' -Action '以管理员身份完整检查一遍' -SelfText $SelfText)
        }
        return 0
    }
    if ($Options.ScanOnly) { return 0 }

    # ---- 发现了，但不是管理员 ----
    if (-not $isAdmin) {
        if ($canAsk -and (Request-SpaElevation -Reason '清理需要管理员权限' -Action '以管理员身份打开并继续（会重新扫描，包含 Defender 排除项）' -SelfText $SelfText)) {
            return 0
        }
        if (-not $canAsk) { Write-UiNote '清理需要管理员权限：请以管理员身份重新运行。' -Important }
        return 5
    }

    # ---- 确认并清理 ----
    $steamRunning = (Get-SteamProcess).Count -gt 0
    $selected = Read-SpaCleanupDecision -Items $items -SteamRunning $steamRunning
    if ($null -eq $selected) {
        Write-UiSection '已取消' '已取消清理，没有做任何修改' Warning
        return 4
    }
    $backupPath = Invoke-SpaCleanup -Selected @($selected) -Variables $variables -SteamRunning $steamRunning
    Show-SpaSummary -Items $items -BackupPath $backupPath -StartedAt $startedAt
    Read-SpaExit -SteamPath $variables.SteamPath -OfferSteam $steamRunning
    if (@($items | Where-Object { $_.Status -eq 'failed' }).Count -gt 0) { return 1 }
    return 0
}

# ---- 入口 ----
$Spa = @{
    Ui             = $null
    Options        = $null
    SteamPath      = $null
    Defender       = $null
    DefenderHidden = $false
    Tasks          = $null
    Paused         = $false
    Warnings       = New-Object System.Collections.Generic.List[string]
}
$spaSelfText = "& {`r`n" + $MyInvocation.MyCommand.ScriptBlock.ToString() + "`r`n} @args`r`n"
$spaOptions = ConvertFrom-SpaArguments -Arguments $args
$Spa.Options = $spaOptions
$spaEncoding = $null
try { $spaEncoding = [Console]::OutputEncoding } catch {}
$spaExitCode = 1
try {
    Initialize-SpaConsole
    $spaExitCode = [int](@(Invoke-SpaMain -Options $spaOptions -SelfText $spaSelfText)[-1])
}
catch {
    Write-UiResult '错误' ('运行出错：' + $_.Exception.Message) Danger
}
finally {
    if (-not $spaOptions.NoPause -and -not $Spa.Paused) { Wait-UiExit }
    if ($spaOptions.Elevated -and $PSCommandPath -and $PSCommandPath -like (Join-Path $env:TEMP 'SteamSPA\SteamSPA-*.ps1')) {
        Remove-Item -LiteralPath $PSCommandPath -Force -ErrorAction SilentlyContinue
    }
    if ($spaEncoding) { try { [Console]::OutputEncoding = $spaEncoding } catch {} }
}
# 只有以文件方式运行时才设置退出码；irm | iex 下 exit 会关掉用户的窗口。
if ($PSCommandPath) { exit $spaExitCode }
