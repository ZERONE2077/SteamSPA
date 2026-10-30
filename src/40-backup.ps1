# SteamSPA · 清理前备份
# 备份目录：%LOCALAPPDATA%\SteamSPA\backups\<时间>\
#   files\C\...       被删文件/目录的原样副本
#   registry\*.reg    被删注册表项（或值所在项）的 reg export
#   tasks\*.xml       被删计划任务的定义
#   manifest.json     清单
#   restore.ps1       一键恢复（文件、注册表、计划任务；Defender 排除项只记录不恢复）

function New-SpaBackup {
    param([bool]$Enabled)
    $base = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { $env:TEMP }
    return @{
        Enabled  = $Enabled
        Root     = Join-Path $base ('SteamSPA\backups\' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
        Entries  = New-Object System.Collections.Generic.List[object]
        Exported = @{}
        Counter  = 0
    }
}

function Get-SpaBackupFile {
    param([hashtable]$Backup, [string]$Folder, [string]$Extension)
    $Backup.Counter++
    $dir = Join-Path $Backup.Root $Folder
    [IO.Directory]::CreateDirectory($dir) | Out-Null
    return Join-Path $Folder ('{0:D3}{1}' -f $Backup.Counter, $Extension)
}

function Export-SpaRegistryKey {
    param([hashtable]$Backup, [string]$Path, [string]$Label)
    $key = $Path -replace '^(HK[A-Z_]+):\\?', '$1\'
    if ($Backup.Exported.ContainsKey($key)) { return $true }
    $relative = Get-SpaBackupFile -Backup $Backup -Folder 'registry' -Extension '.reg'
    & reg.exe export $key (Join-Path $Backup.Root $relative) /y 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { return $false }
    $Backup.Exported[$key] = $true
    $Backup.Entries.Add([ordered]@{ type = 'registry'; label = $Label; key = $key; file = $relative })
    return $true
}

# 返回 $true 表示可以继续删除（已备份，或无需/未启用备份）。
function Save-SpaBackupItem {
    param([hashtable]$Backup, $Target)
    if (-not $Backup.Enabled) { return $true }

    $d = $Target.Data
    try {
        switch -Wildcard ($Target.Type) {
            'file' {
                $relative = Join-Path 'files' ($d.Path -replace '^([A-Za-z]):\\', '$1\')
                $dest = Join-Path $Backup.Root $relative
                [IO.Directory]::CreateDirectory((Split-Path -Parent $dest)) | Out-Null
                Copy-Item -LiteralPath $d.Path -Destination $dest -Recurse -Force -ErrorAction Stop
                $Backup.Entries.Add([ordered]@{ type = 'file'; label = $Target.Label; source = $d.Path; file = $relative })
            }
            'registry-*' {
                if (-not (Export-SpaRegistryKey -Backup $Backup -Path $d.Path -Label $Target.Label)) { return $false }
            }
            'defender-*' {
                $Backup.Entries.Add([ordered]@{ type = 'defender'; label = $Target.Label; kind = $d.Kind; values = @($d.Values) })
            }
            'task' {
                $service = New-Object -ComObject Schedule.Service
                $service.Connect()
                $xml = $service.GetFolder($d.Folder).GetTask($d.Name).Xml
                $relative = Get-SpaBackupFile -Backup $Backup -Folder 'tasks' -Extension '.xml'
                [IO.File]::WriteAllText((Join-Path $Backup.Root $relative), $xml, [Text.Encoding]::Unicode)
                $Backup.Entries.Add([ordered]@{ type = 'task'; label = $Target.Label; name = $d.Path; file = $relative })
            }
        }
        return $true
    }
    catch {
        return $false
    }
}

function Complete-SpaBackup {
    param([hashtable]$Backup)
    if (-not $Backup.Enabled -or $Backup.Entries.Count -eq 0) { return $null }

    $utf8 = New-Object System.Text.UTF8Encoding($true)
    $manifest = [ordered]@{
        tool      = 'SteamSPA'
        version   = $SteamSPAReleaseVersion
        createdAt = (Get-Date).ToString('o')
        entries   = $Backup.Entries.ToArray()   # PS 5.1 下 @(List) 放进 [ordered] 会抛 Argument types do not match
    }
    [IO.File]::WriteAllText((Join-Path $Backup.Root 'manifest.json'), ($manifest | ConvertTo-Json -Depth 5), $utf8)
    [IO.File]::WriteAllText((Join-Path $Backup.Root 'restore.ps1'), (Get-SpaRestoreScript), $utf8)
    return $Backup.Root
}

function Get-SpaRestoreScript {
    return @'
# SteamSPA 恢复脚本：把本目录里备份的文件、注册表、计划任务放回原处。
# 用法：右键 -> 使用 PowerShell 运行（需要管理员权限恢复系统注册表和计划任务）。
# Defender 排除项不会自动恢复，清单里有记录，如确有需要请手动添加。
$base = Split-Path -Parent $MyInvocation.MyCommand.Path
$manifest = Get-Content -LiteralPath (Join-Path $base 'manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($e in @($manifest.entries)) {
    try {
        if ($e.type -eq 'file') {
            if (Test-Path -LiteralPath $e.source) { Write-Host ('已存在，跳过: ' + $e.source); continue }
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $e.source) | Out-Null
            Copy-Item -LiteralPath (Join-Path $base $e.file) -Destination $e.source -Recurse -Force -ErrorAction Stop
        }
        elseif ($e.type -eq 'registry') {
            & reg.exe import (Join-Path $base $e.file) 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) { throw 'reg import 失败' }
        }
        elseif ($e.type -eq 'task') {
            & schtasks.exe /Create /TN $e.name /XML (Join-Path $base $e.file) /F 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) { throw 'schtasks 失败' }
        }
        else { Write-Host ('未自动恢复: ' + $e.label); continue }
        Write-Host ('已恢复: ' + $e.label)
    }
    catch {
        Write-Host ('恢复失败: ' + $e.label + ' - ' + $_.Exception.Message) -ForegroundColor Red
    }
}
Read-Host '完成，按回车退出' | Out-Null
'@
}
