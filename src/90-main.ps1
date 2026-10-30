# SteamSPA · 主流程：环境 -> 扫描 -> 展示 -> 确认 -> 备份并清理 -> 汇总

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
    Write-Ui '  STEAM SPA 清理工具' Accent -NoNewline
    Write-Ui ('   v' + $SteamSPAReleaseVersion + ' · 更新于 ' + $SteamSPAUpdatedAt) Muted
    Write-Ui '  假入库清理/专杀：注入 DLL、STEAM 配置、注册表、启动项、计划任务、Defender 排除项、后台进程' Muted
    Write-Ui '  作者：万能小哥' Muted
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
    Write-UiResult '扫描完成' ('共检查 {0} 个位置' -f $total) Success
    return $targets.ToArray()
}

function Show-SpaFindings {
    param([object[]]$Items, [object[]]$Protected)

    $titles = [ordered]@{ files = '文件'; config = 'STEAM 配置'; registry = '注册表'; startup = '启动项 / 计划任务'; security = '安全设置'; process = '进程' }
    $n = 0
    foreach ($category in $titles.Keys) {
        $group = @($Items | Where-Object { $_.Category -eq $category })
        if ($group.Count -eq 0) { continue }
        Write-Host ''
        Write-Ui ('  {0} ({1})' -f $titles[$category], $group.Count) Accent
        foreach ($item in $group) {
            $n++
            Write-Ui ('  {0,4}. ' -f $n) Muted -NoNewline
            if ($item.Confirm) {
                Write-Ui $item.Label Path -NoNewline
                Write-Ui '  [需确认]' Warning
            }
            else {
                Write-Ui $item.Label Path
            }
        }
    }

    if ($Protected.Count -gt 0) {
        Write-Host ''
        Write-Ui ('  已自动保护 {0} 项（不会删除）' -f $Protected.Count) Success
        foreach ($item in $Protected) {
            Write-Ui ('        {0}  ({1})' -f $item.Label, $item.Note) Muted
        }
    }
}

function Show-SpaSummary {
    param([object[]]$Items, [string]$BackupPath, [datetime]$StartedAt)

    $removed = @($Items | Where-Object { $_.Status -eq 'removed' }).Count
    $failed = @($Items | Where-Object { $_.Status -eq 'failed' }).Count
    $skipped = @($Items | Where-Object { $_.Status -eq 'skipped' -or -not $_.Status }).Count

    Write-UiSection '完成'
    if ($failed -gt 0) { Write-UiResult '结果' '部分项目清理失败。请退出杀毒软件后重新运行一次。' Danger }
    elseif ($removed -gt 0) { Write-UiResult '结果' '清理完成' Success }
    else { Write-UiResult '结果' '没有删除任何项目' Warning }
    Write-UiKeyValue '发现' ([string]$Items.Count)
    Write-UiKeyValue '已清理' ([string]$removed) Success
    Write-UiKeyValue '失败' ([string]$failed) $(if ($failed) { 'Danger' } else { 'Muted' })
    Write-UiKeyValue '跳过' ([string]$skipped) Muted
    if ($BackupPath) {
        Write-UiKeyValue '备份位置' $BackupPath Path
        Write-UiKeyValue '恢复方法' '运行备份目录里的 restore.ps1' Muted
    }
    Write-UiKeyValue '耗时' ('{0:N1} 秒' -f ((Get-Date) - $StartedAt).TotalSeconds) Muted
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

    # ---- 环境 ----
    $variables = Get-SpaVariables
    $isAdmin = Test-SpaAdmin
    Write-UiSection '本机信息'
    Write-UiKeyValue '操作系统' (Get-SpaOSName)
    Write-UiKeyValue 'PowerShell' ([string]$PSVersionTable.PSVersion)
    if ($variables.SteamPath) { Write-UiKeyValue 'STEAM 路径' $variables.SteamPath Path }
    else { Write-UiKeyValue 'STEAM 路径' '未检测到（STEAM 目录相关规则将跳过）' Warning }
    Write-UiKeyValue '管理员权限' $(if ($isAdmin) { '是' } else { '否' }) $(if ($isAdmin) { 'Success' } else { 'Warning' })

    if (-not $isAdmin -and -not $Options.ScanOnly -and -not $Options.Elevated -and -not $Spa.Ui.InputRedirected) {
        Write-Host ''
        Write-Ui '  清理需要管理员权限；普通权限下也看不到 Defender 排除项等系统设置。' Warning
        if ((Read-UiChoice -Prompt '以管理员身份重新打开本工具？[Y/n]' -Allowed @('Y', 'N') -Default 'Y') -eq 'Y') {
            if (Start-SpaElevated -SelfText $SelfText -Options $Options) {
                Write-UiResult '已启动' '已在新的管理员窗口中运行，本窗口可以关闭。' Success
                return 0
            }
            Write-UiResult '未提权' '没有获得管理员权限（可能取消了 UAC 提示），继续以普通权限扫描。' Warning
        }
    }

    # ---- 历史线索 ----
    $clues = @(Find-SpaHistoryClues -Lines (Get-SpaHistoryLines))
    if ($clues.Count -gt 0) {
        Write-UiSection '历史线索'
        Write-Ui '  PowerShell 历史里有疑似假入库脚本的记录（仅本机显示，不上传）：' Warning
        $i = 0
        foreach ($clue in $clues) { $i++; Write-Ui ('  {0,4}. ' -f $i) Muted -NoNewline; Write-Ui $clue Path }
    }

    # ---- 扫描 ----
    Write-UiSection '扫描'
    $rules = Select-SpaRules -Database ($EmbeddedTargetsJson | ConvertFrom-Json) -Options $Options
    $all = @(Invoke-SpaScan -Rules $rules -Variables $variables)
    $items = @($all | Where-Object { $_.State -eq 'present' })
    $protected = @($all | Where-Object { $_.State -eq 'protected' })
    foreach ($w in $Spa.Warnings) { Write-UiResult '提示' $w Warning }
    if ($Spa.DefenderHidden) { Write-UiResult '提示' 'Defender 排除项需要管理员权限才能检查，本次已跳过。' Warning }

    if ($items.Count -eq 0) {
        Show-SpaFindings -Items @() -Protected $protected
        Write-Host ''
        Write-UiResult '安全' '未发现需要清理的项目。' Success
        return 0
    }

    Show-SpaFindings -Items $items -Protected $protected
    Write-Host ''
    Write-UiKeyValue '共发现' ('{0} 项' -f $items.Count) Danger
    if ($Options.ScanOnly) { return 0 }

    # ---- 确认 ----
    if (-not $isAdmin) {
        Write-UiSection '需要管理员权限'
        Write-Ui '  请右键开始菜单，选择"终端(管理员)"或"Windows PowerShell(管理员)"，再重新运行同一条命令。' Warning
        return 5
    }

    $steamRunning = (Get-SteamProcess).Count -gt 0
    Write-UiSection '注意事项'
    Write-Ui '    1. 不影响游戏、存档、创意工坊、MOD（这些目录被硬性排除）。' Warning
    Write-Ui '    2. 清理后可能需要重新登录 STEAM，请确认记得账号、邮箱、密码和手机令牌。' Warning
    Write-Ui '    3. 如清理失败，请退出杀毒软件后重试。' Warning
    Write-Ui '    4. 清理后首次打开 STEAM 可能较慢，建议提前开启加速器，等几分钟或重启电脑即可。' Warning
    if ($steamRunning) { Write-Ui '    5. STEAM 正在运行，清理前会自动关闭。' Warning }

    $regular = @($items | Where-Object { -not $_.Confirm })
    $flagged = @($items | Where-Object { $_.Confirm })
    Write-UiSection '确认清理？'
    Write-Ui ('    [Y] 清理全部 {0} 项' -f $items.Count)
    $allowed = @('Y', 'N')
    if ($regular.Count -gt 0 -and $flagged.Count -gt 0) {
        Write-Ui ('    [S] 只清理常规项 {0} 项，跳过 {1} 项 [需确认]' -f $regular.Count, $flagged.Count)
        $allowed = @('Y', 'S', 'N')
    }
    Write-Ui '    [N] 取消（默认）'
    $choice = Read-UiChoice -Prompt ('请选择 [' + ($allowed -join '/') + ']:') -Allowed $allowed -Default 'N'
    if ($choice -eq 'N') {
        Write-UiResult '已取消' '已取消清理，没有删除任何项目。' Warning
        return 4
    }
    $selected = if ($choice -eq 'S') { $regular } else { $items }
    foreach ($t in $items) { if ($selected -notcontains $t) { Set-SpaResult $t 'skipped' '用户选择跳过' } }

    # ---- 清理 ----
    Write-UiSection '清理'
    if ($steamRunning) {
        if (Stop-Steam -SteamPath $variables.SteamPath) { Write-UiResult '已关闭' 'STEAM' Success }
        else { Write-UiResult '注意' 'STEAM 没有完全退出，部分文件可能删除失败' Warning }
    }

    # 先结束进程、删计划任务，避免它们在清理过程中把文件写回来。
    $order = @{ process = 0; task = 1; file = 2; 'registry-key' = 3; 'registry-value' = 4 }
    $selected = @($selected | Sort-Object { if ($order.ContainsKey($_.Type)) { $order[$_.Type] } else { 5 } })
    $backup = New-SpaBackup -Enabled (-not $Options.NoBackup)
    foreach ($t in $selected) {
        Remove-SpaTarget -Target $t -Backup $backup -Variables $variables
        switch ($t.Status) {
            'removed' { Write-UiResult $(if ($t.Type -eq 'process') { '已结束' } else { '已清理' }) $t.Label Success }
            'skipped' { Write-UiResult '跳过' ($t.Label + '  (' + $t.Message + ')') Muted }
            default { Write-UiResult '失败' ($t.Label + '  (' + $t.Message + ')') Danger }
        }
    }
    $backupPath = Complete-SpaBackup -Backup $backup

    Show-SpaSummary -Items $items -BackupPath $backupPath -StartedAt $startedAt
    if (@($items | Where-Object { $_.Status -eq 'failed' }).Count -gt 0) { return 1 }
    return 0
}

# ---- 入口 ----
$Spa = @{
    Ui             = $null
    Defender       = $null
    DefenderHidden = $false
    Tasks          = $null
    Warnings       = New-Object System.Collections.Generic.List[string]
}
$spaSelfText = "& {`r`n" + $MyInvocation.MyCommand.ScriptBlock.ToString() + "`r`n} @args`r`n"
$spaOptions = ConvertFrom-SpaArguments -Arguments $args
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
    if (-not $spaOptions.NoPause) { Wait-UiExit }
    if ($spaOptions.Elevated -and $PSCommandPath -and $PSCommandPath -like (Join-Path $env:TEMP 'SteamSPA\SteamSPA-*.ps1')) {
        Remove-Item -LiteralPath $PSCommandPath -Force -ErrorAction SilentlyContinue
    }
    if ($spaEncoding) { try { [Console]::OutputEncoding = $spaEncoding } catch {} }
}
# 只有以文件方式运行时才设置退出码；irm | iex 下 exit 会关掉用户的窗口。
if ($PSCommandPath) { exit $spaExitCode }
