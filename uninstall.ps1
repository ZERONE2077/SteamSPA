#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    SteamSPA clean engine.
.DESCRIPTION
    Reads targets.json and performs scan or cleanup for leftover traces.
    Default mode is scan. Add -Clean to remove detected targets.
#>
[CmdletBinding()]
param(
    [switch]$Clean,
    [switch]$NoBackup,
    [switch]$NoPause,
    [string[]]$Only,
    [ValidateSet('low', 'medium', 'high')]
    [string[]]$Risk = @('low', 'medium'),
    [string]$TargetsPath
)

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Stop'

$scriptRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptRoot)) {
    $scriptRoot = Split-Path -Parent $PSCommandPath
}
if ([string]::IsNullOrWhiteSpace($scriptRoot)) {
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}
if ([string]::IsNullOrWhiteSpace($TargetsPath)) {
    $TargetsPath = Join-Path $scriptRoot 'targets.json'
}

function Write-Status {
    param([string]$Message, [ConsoleColor]$Color = 'Gray')
    Write-Host $Message -ForegroundColor $Color
}

function Resolve-Template {
    param(
        [string]$Text,
        [hashtable]$Variables
    )

    $resolved = $Text
    foreach ($key in $Variables.Keys) {
        $resolved = $resolved.Replace('${' + $key + '}', [string]$Variables[$key])
    }

    return [Environment]::ExpandEnvironmentVariables($resolved)
}

function ConvertTo-SafeName {
    param([string]$Text)
    $safe = $Text
    foreach ($char in [System.IO.Path]::GetInvalidFileNameChars()) {
        $safe = $safe.Replace($char, '_')
    }
    return $safe.Trim().TrimEnd('.')
}

function Get-SteamPath {
    try {
        $path = (Get-ItemProperty -Path 'HKCU:\Software\Valve\Steam' -ErrorAction Stop).SteamPath
        if ($path -and (Test-Path -LiteralPath $path -PathType Container)) {
            return $path
        }
    }
    catch {}

    return $null
}

function Get-Variables {
    return @{
        APPDATA      = $env:APPDATA
        LOCALAPPDATA = $env:LOCALAPPDATA
        ProgramData  = $env:ProgramData
        ScriptRoot   = $scriptRoot
        SteamPath    = (Get-SteamPath)
        TEMP         = $env:TEMP
        USERPROFILE  = $env:USERPROFILE
    }
}

function Read-Targets {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "未找到 targets.json: $Path"
    }

    return Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Test-ActionExists {
    param($Action, [hashtable]$Variables)

    switch ($Action.type) {
        'file' {
            $path = Resolve-Template -Text $Action.path -Variables $Variables
            return [bool](Test-Path -LiteralPath $path)
        }
        'registry-key' {
            return [bool](Test-Path -Path $Action.path)
        }
        'registry-value' {
            if (-not (Test-Path -Path $Action.path)) { return $false }
            return $null -ne (Get-ItemProperty -Path $Action.path -Name $Action.name -ErrorAction SilentlyContinue)
        }
        'defender-exclusion-path' {
            $pref = Get-MpPreference -ErrorAction SilentlyContinue
            if (-not $pref) { return $false }
            $path = Resolve-Template -Text $Action.path -Variables $Variables
            return $pref.ExclusionPath -contains $path
        }
        'defender-exclusion-extension' {
            $pref = Get-MpPreference -ErrorAction SilentlyContinue
            return $pref -and ($pref.ExclusionExtension -contains $Action.name)
        }
        'process' {
            return $null -ne (Get-Process -Name ([System.IO.Path]::GetFileNameWithoutExtension($Action.name)) -ErrorAction SilentlyContinue)
        }
        'service' {
            return $null -ne (Get-Service -Name $Action.name -ErrorAction SilentlyContinue)
        }
        'task' {
            return $null -ne (Get-ScheduledTask -TaskName $Action.name -ErrorAction SilentlyContinue)
        }
        default {
            return $false
        }
    }
}

function Remove-Action {
    param(
        $Action,
        [hashtable]$Variables,
        [string]$BackupRoot,
        [switch]$NoBackup
    )

    switch ($Action.type) {
        'file' {
            $path = Resolve-Template -Text $Action.path -Variables $Variables
            if (-not (Test-Path -LiteralPath $path)) { return 'skipped' }
            if (-not $NoBackup) {
                $backupName = Join-Path $BackupRoot (ConvertTo-SafeName $path)
                $parent = Split-Path -Parent $backupName
                if ($parent -and -not (Test-Path -LiteralPath $parent)) {
                    New-Item -ItemType Directory -Path $parent -Force | Out-Null
                }
                Copy-Item -LiteralPath $path -Destination $backupName -Recurse -Force -ErrorAction SilentlyContinue
            }
            Remove-Item -LiteralPath $path -Force -Recurse:([bool]$Action.recurse)
            return 'removed'
        }
        'registry-key' {
            if (Test-Path -Path $Action.path) {
                Remove-Item -Path $Action.path -Force -Recurse:([bool]$Action.recurse)
                return 'removed'
            }
            return 'skipped'
        }
        'registry-value' {
            if ((Test-Path -Path $Action.path) -and ($null -ne (Get-ItemProperty -Path $Action.path -Name $Action.name -ErrorAction SilentlyContinue))) {
                Remove-ItemProperty -Path $Action.path -Name $Action.name -Force
                return 'removed'
            }
            return 'skipped'
        }
        'defender-exclusion-path' {
            $path = Resolve-Template -Text $Action.path -Variables $Variables
            Remove-MpPreference -ExclusionPath $path
            return 'removed'
        }
        'defender-exclusion-extension' {
            Remove-MpPreference -ExclusionExtension $Action.name
            return 'removed'
        }
        'process' {
            Get-Process -Name ([System.IO.Path]::GetFileNameWithoutExtension($Action.name)) -ErrorAction SilentlyContinue | Stop-Process -Force
            return 'removed'
        }
        'service' {
            Stop-Service -Name $Action.name -Force
            return 'removed'
        }
        'task' {
            Unregister-ScheduledTask -TaskName $Action.name -Confirm:$false
            return 'removed'
        }
        default {
            throw "不支持的动作类型: $($Action.type)"
        }
    }
}

function Format-ActionLabel {
    param($Action, [hashtable]$Variables)

    switch ($Action.type) {
        'file' { return Resolve-Template -Text $Action.path -Variables $Variables }
        'registry-key' { return $Action.path }
        'registry-value' { return "$($Action.path)\$($Action.name)" }
        'defender-exclusion-path' { return "Defender Path: $(Resolve-Template -Text $Action.path -Variables $Variables)" }
        'defender-exclusion-extension' { return "Defender Extension: $($Action.name)" }
        'process' { return "Process: $($Action.name)" }
        'service' { return "Service: $($Action.name)" }
        'task' { return "Task: $($Action.name)" }
        default { return $Action.type }
    }
}

function Save-Report {
    param(
        [object]$Report,
        [string]$Root
    )

    if (-not (Test-Path -LiteralPath $Root)) {
        New-Item -ItemType Directory -Path $Root -Force | Out-Null
    }

    $path = Join-Path $Root ("report-{0}.json" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
    $Report | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $path -Encoding UTF8
    return $path
}

Clear-Host
Write-Status '========================================' Cyan
Write-Status '  SteamSPA 假入库残留扫描 / 清理' Cyan
Write-Status '========================================' Cyan
Write-Host ''

if ($Clean) {
    Write-Status '当前模式: 清理' Yellow
}
else {
    Write-Status '当前模式: 扫描（不会删除任何内容）' Yellow
}

$variables = Get-Variables
if ($variables.SteamPath) {
    Write-Status "Steam 目录: $($variables.SteamPath)" Green
}
else {
    Write-Status '未检测到 Steam 目录。' Yellow
}

$targets = Read-Targets -Path $TargetsPath
$backupRoot = Join-Path $scriptRoot (Join-Path 'temp\backups' (Get-Date -Format 'yyyyMMdd-HHmmss'))
$logRoot = Join-Path $scriptRoot 'temp\logs'

$report = [ordered]@{
    startedAt = (Get-Date).ToString('o')
    mode      = if ($Clean) { 'clean' } else { 'scan' }
    targets   = @()
    summary   = [ordered]@{
        detected = 0
        removed  = 0
        failed   = 0
        skipped  = 0
    }
}

$rules = @($targets.rules) | Where-Object {
    ($_.enabled -ne $false) -and
    ($Risk -contains $_.risk) -and
    (-not $Only -or $Only -contains $_.id)
}

Write-Host ''
Write-Status "加载规则: $($rules.Count) 条" Cyan
Write-Host ''

$detectedItems = @()

foreach ($rule in $rules) {
    Write-Status "[$($rule.id)] $($rule.title)" Yellow
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
            }
            Write-Status "  [发现] $label" Green
        }
        else {
            Write-Status "  [不存在] $label" DarkGray
        }

        $ruleReport.actions += [ordered]@{
            type   = $action.type
            target = $label
            exists = [bool]$exists
        }
    }

    $report.targets += $ruleReport
    Write-Host ''
}

if ($Clean) {
    Write-Status '========================================' Cyan
    Write-Status '  待清理项目汇总' Cyan
    Write-Status '========================================' Cyan

    if ($detectedItems.Count -eq 0) {
        Write-Status '未发现需要清理的项目。' Green
    }
    else {
        $index = 1
        foreach ($item in $detectedItems) {
            $riskColor = switch ($item.Risk) {
                'high' { 'Red' }
                'medium' { 'Yellow' }
                default { 'Gray' }
            }
            Write-Host ("[{0}] " -f $index) -NoNewline -ForegroundColor Cyan
            Write-Host ("{0} / {1} / {2}" -f $item.RuleId, $item.Action.type, $item.Risk) -ForegroundColor $riskColor
            Write-Status ("    {0}" -f $item.Label) Gray
            $index++
        }

        Write-Host ''
        Write-Status '上面是本次检测到的全部残留项。' Yellow
        Write-Status '按 Enter 确认删除以上项目；输入 N 后回车取消。' Yellow
        $answer = Read-Host '确认'

        if ($answer -eq 'N' -or $answer -eq 'n') {
            $report.summary.skipped += $detectedItems.Count
            Write-Status '已取消清理，未删除任何项目。' Yellow
        }
        else {
            Write-Host ''
            Write-Status '开始清理...' Cyan
            foreach ($item in $detectedItems) {
                try {
                    $result = Remove-Action -Action $item.Action -Variables $variables -BackupRoot $backupRoot -NoBackup:$NoBackup
                    if ($result -eq 'removed') {
                        $report.summary.removed++
                        Write-Status "  [已删除] $($item.Label)" Green
                    }
                    else {
                        $report.summary.skipped++
                        Write-Status "  [跳过] $($item.Label)" DarkGray
                    }
                }
                catch {
                    $report.summary.failed++
                    Write-Status "  [失败] $($item.Label) - $($_.Exception.Message)" Red
                }
            }
        }
    }

    Write-Host ''
}

$reportPath = Save-Report -Report $report -Root $logRoot

Write-Status '========================================' Cyan
Write-Status '  完成' Cyan
Write-Status '========================================' Cyan
Write-Status "发现: $($report.summary.detected)" Gray
Write-Status "删除: $($report.summary.removed)" Gray
Write-Status "失败: $($report.summary.failed)" Gray
Write-Status "跳过: $($report.summary.skipped)" Gray
Write-Status "报告: $reportPath" Gray

if ($Clean -and -not $NoBackup) {
    Write-Status "备份: $backupRoot" Gray
}

Write-Host ''
Write-Status '建议后续在 Steam 中验证游戏文件完整性，并重启 Steam。' Yellow

if (-not $NoPause) {
    Read-Host '按 Enter 键退出'
}
