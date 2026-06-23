#Requires -Version 5.1
<#
.SYNOPSIS
    自用：扫描 scripts/ 下按团队归档的第三方脚本，提取可能写入的痕迹。
.DESCRIPTION
    本脚本只做静态文本扫描，不执行别人的脚本。
    输出候选的：文件路径、注册表路径、计划任务、Defender 排除项、扩展名。
    用于手动确认后写入 targets.json。
.PARAMETER Path
    第三方脚本目录，默认 ../scripts，并递归扫描子目录
.PARAMETER Out
    输出 JSON 路径，默认打印到控制台
#>
[CmdletBinding()]
param(
    [string]$Path = (Join-Path $PSScriptRoot '..\scripts'),
    [string]$Out
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Path)) {
    throw "目录不存在: $Path"
}

$patterns = @{
    File            = '([A-Za-z]:\\[^"''<>|\r\n]+|\$env:[A-Za-z_]+\\[^"''<>|\r\n]+)'
    RegistryKey     = '(HK(?:CU|LM|CR|U|CC):\\[^\s"'']+)'
    DefenderPath    = 'ExclusionPath\s+["'']?([^"''\r\n]+)'
    DefenderExt     = 'ExclusionExtension\s+["'']?([^"''\r\n]+)'
    ScheduledTask   = 'New-ScheduledTask|Register-ScheduledTask'
    Process         = 'Stop-Process\s+-Name\s+["'']?([^"''\s]+)'
}

$results = @{}
$rootPath = (Resolve-Path -LiteralPath $Path).Path

Get-ChildItem -LiteralPath $Path -Filter '*.ps1' -File -Recurse | ForEach-Object {
    $file = $_.FullName
    $key = $_.FullName.Substring($rootPath.Length).TrimStart('\', '/') -replace '\\', '/'
    $text = Get-Content -LiteralPath $file -Raw -Encoding UTF8
    $info = [ordered]@{
        files                  = @()
        registryKeys           = @()
        defenderPaths          = @()
        defenderExtensions     = @()
        scheduledTaskMentions  = 0
        processes              = @()
    }

    $info.files = [regex]::Matches($text, $patterns.File) |
        ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
    $info.registryKeys = [regex]::Matches($text, $patterns.RegistryKey) |
        ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
    $info.defenderPaths = [regex]::Matches($text, $patterns.DefenderPath) |
        ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
    $info.defenderExtensions = [regex]::Matches($text, $patterns.DefenderExt) |
        ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
    $info.scheduledTaskMentions = ([regex]::Matches($text, $patterns.ScheduledTask)).Count
    $info.processes = [regex]::Matches($text, $patterns.Process) |
        ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique

    $results[$key] = $info
}

$json = $results | ConvertTo-Json -Depth 6

if ($Out) {
    $json | Set-Content -LiteralPath $Out -Encoding UTF8
    Write-Host "已写入 $Out" -ForegroundColor Green
} else {
    $json
}
