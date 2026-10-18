# SteamSPA source module
# Edit this module, then run tools/build.ps1.

function Remove-DefenderExclusion {
    param(
        [ValidateSet('path', 'extension', 'process')][string]$Kind,
        [string]$Value
    )

    if (-not (Get-Command -Name Remove-MpPreference -ErrorAction SilentlyContinue)) {
        return $false
    }

    try {
        switch ($Kind) {
            'path' { Remove-MpPreference -ExclusionPath $Value -ErrorAction Stop }
            'extension' { Remove-MpPreference -ExclusionExtension $Value -ErrorAction Stop }
            'process' { Remove-MpPreference -ExclusionProcess $Value -ErrorAction Stop }
        }
        return $true
    }
    catch {
        return $false
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
            if (Test-ValveSignedFile -Path $path) { return 'protected' }
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
            $pref = Get-DefenderPreference
            if (-not $pref) { return 'skipped' }
            $path = Resolve-Template -Text $Action.path -Variables $Variables
            $target = Normalize-DefenderPath -Path $path
            $removed = $false
            foreach ($existing in @($pref.ExclusionPath)) {
                if ((Normalize-DefenderPath -Path $existing) -eq $target) {
                    if (Remove-DefenderExclusion -Kind 'path' -Value $existing) { $removed = $true }
                }
            }
            if ($removed) { return 'removed' }
            return 'skipped'
        }
        'defender-exclusion-extension' {
            if (-not (Remove-DefenderExclusion -Kind 'extension' -Value $Action.name)) { return 'skipped' }
            return 'removed'
        }
        'defender-exclusion-process' {
            if (-not (Remove-DefenderExclusion -Kind 'process' -Value $Action.name)) { return 'skipped' }
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
            Get-ScheduledTaskSnapshot -Refresh | Out-Null
            return 'removed'
        }
        'task-contains' {
            $needle = Resolve-Template -Text $Action.contains -Variables $Variables
            $matches = @(Find-ScheduledTasksByContains -Needle $needle)
            foreach ($task in $matches) {
                Unregister-ScheduledTask -TaskName $task.Name -TaskPath $task.Path -Confirm:$false
            }
            if ($matches.Count -gt 0) {
                Get-ScheduledTaskSnapshot -Refresh | Out-Null
                return 'removed'
            }
            return 'skipped'
        }
        default {
            throw (('不支持的动作类型: ') + $Action.type)
        }
    }
}

function Format-ActionLabel {
    param($Action, [hashtable]$Variables)

    switch ($Action.type) {
        'file' { return Resolve-Template -Text $Action.path -Variables $Variables }
        'registry-key' { return $Action.path }
        'registry-value' { return "$($Action.path)\$($Action.name)" }
        'defender-exclusion-path' {
            $path = Resolve-Template -Text $Action.path -Variables $Variables
            return $path
        }
        'defender-exclusion-extension' { return "扩展名: $($Action.name)" }
        'defender-exclusion-process' { return "排除进程: $($Action.name)" }
        'process' { return "进程: $($Action.name)" }
        'service' { return "服务: $($Action.name)" }
        'task' { return "计划任务: $($Action.name)" }
        'task-contains' { return "计划任务包含: $(Resolve-Template -Text $Action.contains -Variables $Variables)" }
        default { return $Action.type }
    }
}

function Get-ActionCategory {
    param($Action)

    switch ($Action.type) {
        'file' {
            $p = [string]$Action.path
            if ($p -match 'steam\.cfg|appdata\d*\.vdf|packageinfo\.vdf|localData\.vdf|package\\beta|opensteamtool\.toml|config\\lua') { return 'config' }
            return 'files'
        }
        'registry-key' { return 'registry' }
        'registry-value' { return 'registry' }
        'defender-exclusion-path' { return 'security' }
        'defender-exclusion-extension' { return 'security' }
        'defender-exclusion-process' { return 'security' }
        'process' { return 'process' }
        'service' { return 'startup' }
        'task' { return 'startup' }
        'task-contains' { return 'startup' }
        default { return 'other' }
    }
}

function Get-ActionIdentity {
    param($Action, [hashtable]$Variables)

    $target = [string](Format-ActionLabel -Action $Action -Variables $Variables)
    $target = $target.Trim().TrimEnd('\', '/')
    return ([string]$Action.type).ToLowerInvariant() + '|' + $target.ToLowerInvariant()
}

function Get-CategoryTitle {
    param([string]$Category)

    switch ($Category) {
        'files' { return '文件' }
        'config' { return '配置' }
        'registry' { return '注册表' }
        'startup' { return '启动项' }
        'security' { return '安全项' }
        'process' { return '进程' }
        default { return '其他' }
    }
}
