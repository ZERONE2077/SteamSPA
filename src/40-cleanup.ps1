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
            return 'removed'
        }
        'task-contains' {
            $needle = Resolve-Template -Text $Action.contains -Variables $Variables
            $matches = @(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
                $task = $_
                @($task.Actions) | Where-Object {
                    ([string]$_.Execute -like "*$needle*") -or ([string]$_.Arguments -like "*$needle*")
                }
            })
            foreach ($task in $matches) {
                Unregister-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -Confirm:$false
            }
            if ($matches.Count -gt 0) { return 'removed' }
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
            $kind = if (Test-Path -LiteralPath $path -PathType Container) { 'Folder' } elseif (Test-Path -LiteralPath $path -PathType Leaf) { 'File' } else { 'Path' }
            return "Defender ${kind}: $path"
        }
        'defender-exclusion-extension' { return "Defender Extension: $($Action.name)" }
        'defender-exclusion-process' { return "Defender Process: $($Action.name)" }
        'process' { return "Process: $($Action.name)" }
        'service' { return "Service: $($Action.name)" }
        'task' { return "Task: $($Action.name)" }
        'task-contains' { return "Task contains: $(Resolve-Template -Text $Action.contains -Variables $Variables)" }
        default { return $Action.type }
    }
}

function Get-ActionCategory {
    param($Action)

    switch ($Action.type) {
        'file' {
            $p = [string]$Action.path
            if ($p -match '\\.exe($|\\.)') { return 'exe' }
            if ($p -match '\\.dll($|\\.)') { return 'dll' }
            if ($p -match 'steam\.cfg|appdata\.vdf|packageinfo\.vdf|localData\.vdf|package\\\\beta|opensteamtool\.toml|config\\\\lua') { return 'steam-config' }
            return 'file'
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

function Get-CategoryTitle {
    param([string]$Category)

    switch ($Category) {
        'exe' { return '可执行文件' }
        'dll' { return '注入 DLL' }
        'steam-config' { return 'STEAM 配置项' }
        'registry' { return '注册表' }
        'startup' { return '启动项 / 服务 / 计划任务' }
        'security' { return '安全排除项 / 系统策略' }
        'process' { return '后台驻留进程' }
        'file' { return '文件 / 目录残留' }
        default { return '其他' }
    }
}
