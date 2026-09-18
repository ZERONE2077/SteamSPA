Clear-Host
$host.UI.RawUI.WindowTitle = 'STEAM SPA 清理工具'
Write-Blank
Write-GradientText '  ███████ ████████ ███████  █████  ███    ███     ███████ ██████   █████  '
Write-GradientText '  ██         ██    ██      ██   ██ ████  ████     ██      ██   ██ ██   ██ '
Write-GradientText '  ███████    ██    █████   ███████ ██ ████ ██     ███████ ██████  ███████ '
Write-GradientText '       ██    ██    ██      ██   ██ ██  ██  ██          ██ ██      ██   ██ '
Write-GradientText '  ███████    ██    ███████ ██   ██ ██      ██     ███████ ██      ██   ██ '
Write-Blank
Write-Status '  假入库清理/专杀工具：秒杀各种注入DLL/STEAM配置/注册表/启动项/系统服务/安全策略/后台进程等' Muted
Write-Status '  作者：万能小哥' Muted
Write-Status ('  最后更新：' + $SteamSPAUpdatedAt + ' · 版本：' + $SteamSPAReleaseVersion) Muted

$variables = Get-Variables
$targets = Read-Targets
$backupRoot = Join-Path $scriptRoot (Join-Path 'temp\backups' (Get-Date -Format 'yyyyMMdd-HHmmss'))
$logRoot = Join-Path $scriptRoot 'temp\logs'

$report = [ordered]@{
    startedAt = (Get-Date).ToString('o')
    mode      = 'scan-confirm-clean'
    targets   = @()
    summary   = [ordered]@{
        detected = 0
        removed  = 0
        failed   = 0
        skipped  = 0
        protected = 0
    }
}

$rules = @($targets.rules) | Where-Object {
    ($_.enabled -ne $false) -and
    ($Risk -contains $_.risk) -and
    (-not $Only -or $Only -contains $_.id)
}

$detectedItems = @()
$protectedItems = @()

$scanTotal = [Math]::Max(1, @($rules).Count)
$scanCurrent = 0
Write-Section '🖥️ 本机信息'
Write-KeyValue '操作系统' $variables.OS
if ($variables.SteamPath) {
    Write-KeyValue 'STEAM路径' $variables.SteamPath
}
else {
    Write-KeyValue 'STEAM路径' '未检测到' Warning
}

$historyClues = Get-FakeLibraryHistoryClues
Write-FakeLibraryHistoryClues -Clues $historyClues

Write-Section '🔍 扫描'
Write-ProgressLine -Current 0 -Total $scanTotal -Status '扫描中'

foreach ($rule in $rules) {
    $ruleReport = [ordered]@{
        id      = $rule.id
        title   = $rule.title
        risk    = $rule.risk
        actions = @()
    }

    $detectedActions = @()
    foreach ($action in @($rule.actions)) {
        $label = Format-ActionLabel -Action $action -Variables $variables
        $exists = Test-ActionExists -Action $action -Variables $variables
        if ($exists) {
            $report.summary.detected++
            $detectedActions += $action
            $detectedItems += [pscustomobject]@{
                RuleId = $rule.id
                RuleTitle = $rule.title
                Risk = $rule.risk
                Confirm = ($rule.confirm -eq $true)
                Action = $action
                Label = $label
                Category = (Get-ActionCategory -Action $action)
            }
        }
        elseif (Test-ProtectedOfficialFile -Action $action -Variables $variables) {
            $protectedItems += [pscustomobject]@{
                RuleId = $rule.id
                RuleTitle = $rule.title
                Label = $label
            }
        }

        $ruleReport.actions += [ordered]@{
            type   = $action.type
            target = $label
            exists = [bool]$exists
        }
    }

    $report.targets += $ruleReport
    $scanCurrent++
    if ($scanCurrent -lt $scanTotal) {
        Write-ProgressLine -Current $scanCurrent -Total $scanTotal -Status '扫描中'
    }
}

Write-ProgressLine -Current $scanTotal -Total $scanTotal -Status '扫描完成'

if ($detectedItems.Count -eq 0) {
    Write-Result '✓' '安全' '未发现需要清理的项目。' Success
    Write-KeyValue '已扫描到' '0 项' Success
}
else {
    $categoryOrder = @('exe', 'dll', 'steam-config', 'registry', 'startup', 'security', 'process', 'file', 'other')
    foreach ($category in $categoryOrder) {
        $items = @($detectedItems | Where-Object { $_.Category -eq $category })
        if ($items.Count -eq 0) { continue }

        Write-Status ("  {0} ({1})" -f (Get-CategoryTitle -Category $category), $items.Count) Accent
        $index = 1
        foreach ($item in $items) {
            Write-Status ('    {0,2}. ' -f $index) Muted -NoNewline
            Write-Status $item.RuleTitle Danger -NoNewline
            Write-Status '  ·  ' Dim -NoNewline
            Write-Status $item.Action.type Muted
            Write-Status ("        {0}" -f $item.Label) Path
            $index++
        }
        Write-Blank
    }
    Write-KeyValue '已扫描到' ($detectedItems.Count.ToString() + ' 项') Danger

    if (@($protectedItems).Count -gt 0) {
        Write-Blank
        Write-Status ('  🛡️ 官方文件保护：{0} 项 Valve 数字签名文件已自动跳过（Steam 官方组件，不清理）' -f @($protectedItems).Count) Success
        foreach ($p in @($protectedItems) | Select-Object -Unique -Property Label) {
            Write-Status ('        · ' + $p.Label) Muted
        }
        Write-Blank
    }

    Write-Section '⚠️ 注意事项'
    Write-Status '    1. 此工具不影响游戏、存档、创意工坊、MOD，请放心使用~' WarningSoft
    Write-Status '    2. 清理后可能需要重新登录 STEAM !' WarningSoft
    Write-Status '    3. 请确保还记得账户名称、邮箱、密码、手机令牌!' WarningSoft
    Write-Status '    4. 如清理失败，请退出杀毒软件后重试!' WarningSoft
    Write-Status '    5. 清理后首次打开 STEAM 可能较慢，建议提前开启加速器，等待几分钟或重启后通常会恢复!' WarningSoft

    $confirmed = Read-CleanupConfirmation

    if (-not $confirmed) {
        $report.summary.skipped += $detectedItems.Count
        Write-Result '–' '取消' '已取消清理，未删除任何项目。' Warning
    }
    else {
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $isAdmin) {
            throw ('清理需要以管理员身份运行 PowerShell。请右键 PowerShell，选择“以管理员身份运行”，然后重新执行命令。')
        }

        Write-Blank
        Write-Rule '开始清理'
        foreach ($item in $detectedItems) {
            try {
                $result = Remove-Action -Action $item.Action -Variables $variables -BackupRoot $backupRoot -NoBackup:$NoBackup
                if ($result -eq 'removed') {
                    $report.summary.removed++
                    Write-Result '✓' '已删除' $item.Label Success
                }
                elseif ($result -eq 'protected') {
                    $report.summary.protected++
                    Write-Result '🛡' '官方文件' ($item.Label + ' (Valve 数字签名，已保护)') Success
                }
                else {
                    $report.summary.skipped++
                    Write-Result '·' '跳过' $item.Label Muted
                }
            }
            catch {
                $report.summary.failed++
                Write-Result '×' '失败' ($item.Label + ' - ' + $_.Exception.Message) Danger
            }
        }
    }
}

Write-Blank
$textReportPath = $null
if ($report.summary.removed -gt 0 -and $report.summary.failed -eq 0) {
    $textReportPath = Save-DesktopTextReport -Report $report -DetectedItems $detectedItems -BackupPath $(if (-not $NoBackup) { $backupRoot } else { '' })
}

Write-Section '🎉 完成'
if ($report.summary.failed -gt 0) {
    Write-Result '×' '清理状态' '部分项目清理失败' Danger
}
elseif ($report.summary.removed -gt 0) {
    Write-Result '✓' '清理状态' '清理完成' Success
}
elseif ($report.summary.detected -gt 0) {
    Write-Result '–' '清理状态' '未执行清理' Warning
}
else {
    Write-Result '✓' '清理状态' '无需清理' Success
}
Write-KeyValue '发现' $report.summary.detected
Write-KeyValue '删除' $report.summary.removed Success
Write-KeyValue '失败' $report.summary.failed Danger
Write-KeyValue '跳过' $report.summary.skipped Muted
if ($textReportPath) {
    Write-KeyValue 'TXT 报告' $textReportPath Path
}

if ($report.summary.removed -gt 0 -and -not $NoBackup) {
    Write-KeyValue '备份' $backupRoot Path
}

Write-Blank
if (-not $NoPause) {
    Write-Blank
    Write-Status '  按回车退出...' Accent -NoNewline
    if (-not [Console]::IsInputRedirected) {
        Read-Host | Out-Null
    }
}
