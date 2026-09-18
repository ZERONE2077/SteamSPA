# SteamSPA source module
# Edit this module, then run tools/build.ps1.

function Save-DesktopTextReport {
    param(
        [object]$Report,
        [object[]]$DetectedItems,
        [string]$BackupPath
    )

    $desktop = [Environment]::GetFolderPath('Desktop')
    if ([string]::IsNullOrWhiteSpace($desktop) -or -not (Test-Path -LiteralPath $desktop)) {
        $desktop = $scriptRoot
    }

    $fileName = "SteamSPA-clean-report-{0}.txt" -f (Get-Date -Format 'yyyyMMdd-HHmmss')
    $path = Join-Path $desktop $fileName
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('SteamSPA 清理报告')
    $lines.Add(('生成时间: {0}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')))
    $lines.Add('')
    $lines.Add('清理状态')
    $lines.Add(('  发现: {0}' -f $Report.summary.detected))
    $lines.Add(('  删除: {0}' -f $Report.summary.removed))
    $lines.Add(('  失败: {0}' -f $Report.summary.failed))
    $lines.Add(('  跳过: {0}' -f $Report.summary.skipped))
    if (-not [string]::IsNullOrWhiteSpace($BackupPath)) {
        $lines.Add(('  备份目录: {0}' -f $BackupPath))
    }
    $lines.Add('')
    $lines.Add('残留明细')

    if (-not $DetectedItems -or $DetectedItems.Count -eq 0) {
        $lines.Add('  未发现需要清理的项目。')
    }
    else {
        $index = 1
        foreach ($item in $DetectedItems) {
            $lines.Add(('{0}. [{1}] {2}' -f $index, (Get-CategoryTitle -Category $item.Category), $item.RuleTitle))
            $lines.Add(('   规则: {0}' -f $item.RuleId))
            $lines.Add(('   类型: {0}' -f $item.Action.type))
            $lines.Add(('   目标: {0}' -f $item.Label))
            $lines.Add('')
            $index++
        }
    }

    try {
        $lines | Set-Content -LiteralPath $path -Encoding UTF8
    }
    catch {
        $path = Join-Path $scriptRoot $fileName
        $lines.Add('')
        $lines.Add(('注意: 桌面报告写入失败，已改为保存到脚本目录。原因: {0}' -f $_.Exception.Message))
        $lines | Set-Content -LiteralPath $path -Encoding UTF8
    }

    return $path
}
