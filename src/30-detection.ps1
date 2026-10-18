# SteamSPA source module
# Edit this module, then run tools/build.ps1.

function Get-DefenderPreference {
    # Defender 模块在精简版 / Server / 第三方杀软接管时不存在。
    # 命令缺失抛的是 CommandNotFoundException（终止性错误，-ErrorAction 压不住），必须先用 Get-Command 探测。
    if ($script:DefenderPreferenceProbed) {
        return $script:DefenderPreferenceCache
    }

    $script:DefenderPreferenceProbed = $true
    $script:DefenderPreferenceCache = $null

    if (-not (Get-Command -Name Get-MpPreference -ErrorAction SilentlyContinue)) {
        return $null
    }

    try {
        $script:DefenderPreferenceCache = Get-MpPreference -ErrorAction Stop
    }
    catch {
        $script:DefenderPreferenceCache = $null
    }

    return $script:DefenderPreferenceCache
}

function Test-ValveSignedFile {
    # 官方文件保护：Steam 根目录里的 video.dll / SDL3.dll 等是 Valve 签名的客户端组件，
    # 规则里同名 DLL 只应命中未签名的注入副本。签名有效且签发者为 Valve 时一律不删。
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }

    $ext = [IO.Path]::GetExtension($Path).ToLowerInvariant()
    if (@('.dll', '.exe', '.sys', '.ocx', '.drv') -notcontains $ext) { return $false }

    if (-not $script:ValveSignCache) { $script:ValveSignCache = @{} }
    $key = $Path.ToLowerInvariant()
    if ($script:ValveSignCache.ContainsKey($key)) { return $script:ValveSignCache[$key] }

    $result = $false
    if (Get-Command -Name Get-AuthenticodeSignature -ErrorAction SilentlyContinue) {
        try {
            $sig = Get-AuthenticodeSignature -LiteralPath $Path -ErrorAction Stop
            if ($sig.Status -eq 'Valid' -and $sig.SignerCertificate) {
                if ([string]$sig.SignerCertificate.Subject -match '(^|,\s*)(O|CN)=Valve') {
                    $result = $true
                }
            }
        }
        catch {
            $result = $false
        }
    }

    $script:ValveSignCache[$key] = $result
    return $result
}

function Test-ProtectedOfficialFile {
    param($Action, [hashtable]$Variables)

    if ($Action.type -ne 'file') { return $false }
    $path = Resolve-Template -Text $Action.path -Variables $Variables
    return (Test-ValveSignedFile -Path $path)
}

function Normalize-DefenderPath {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return ''
    }

    $normalized = [Environment]::ExpandEnvironmentVariables($Path.Trim().Trim('"'))
    try {
        if (Test-Path -LiteralPath $normalized) {
            $normalized = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($normalized)
        }
    }
    catch {
    }

    return $normalized.TrimEnd('\', '/') -replace '/', '\'
}

function New-ScheduledTaskSnapshotItem {
    param(
        [string]$Name,
        [string]$Path,
        $Actions
    )

    $actionItems = @()
    foreach ($action in @($Actions)) {
        $actionItems += [pscustomobject]@{
            Execute   = [string]$action.Execute
            Arguments = [string]$action.Arguments
        }
    }

    return [pscustomobject]@{
        Name     = $Name
        Path     = $Path
        TaskName = $Name
        TaskPath = $Path
        Actions  = @($actionItems)
    }
}

function ConvertTo-ScheduledTaskFolderPath {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return '\'
    }

    $trimmed = $Path.Trim()
    if ($trimmed -eq '\') {
        return '\'
    }

    # COM returns the full task path; Get-ScheduledTask returns the folder path.
    $parent = Split-Path -Parent $trimmed
    if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq '\') {
        return '\'
    }

    return $parent.TrimEnd('\') + '\'
}

function Add-ScheduledTaskFolderSnapshot {
    param($Folder, $Items)

    foreach ($task in @($Folder.GetTasks(1))) {
        try {
            $definition = $task.Definition
            $taskFolderPath = ConvertTo-ScheduledTaskFolderPath -Path ([string]$task.Path)
            $taskItem = New-ScheduledTaskSnapshotItem -Name ([string]$task.Name) -Path $taskFolderPath -Actions $definition.Actions
            $Items.Add($taskItem)
        }
        catch {
        }
    }

    foreach ($child in @($Folder.GetFolders(1))) {
        try {
            Add-ScheduledTaskFolderSnapshot -Folder $child -Items $Items
        }
        catch {
        }
    }
}

function Get-ScheduledTaskSnapshot {
    param([switch]$Refresh)

    if (-not $Refresh -and $script:ScheduledTaskSnapshotLoaded) {
        return @($script:ScheduledTaskSnapshot)
    }

    $items = New-Object System.Collections.Generic.List[object]
    $loadedFromCom = $false

    try {
        $service = New-Object -ComObject Schedule.Service
        $service.Connect()
        $rootFolder = $service.GetFolder('\')
        Add-ScheduledTaskFolderSnapshot -Folder $rootFolder -Items $items
        $loadedFromCom = $true
    }
    catch {
        $loadedFromCom = $false
    }

    if (-not $loadedFromCom -and (Get-Command -Name Get-ScheduledTask -ErrorAction SilentlyContinue)) {
        foreach ($task in @(Get-ScheduledTask -ErrorAction SilentlyContinue)) {
            $taskName = [string]$task.TaskName
            if ([string]::IsNullOrWhiteSpace($taskName)) {
                $taskName = [string]$task.Name
            }
            $taskPath = [string]$task.TaskPath
            if ([string]::IsNullOrWhiteSpace($taskPath)) {
                $taskPath = [string]$task.Path
            }
            $taskFolderPath = ConvertTo-ScheduledTaskFolderPath -Path $taskPath
            $items.Add((New-ScheduledTaskSnapshotItem -Name $taskName -Path $taskFolderPath -Actions $task.Actions))
        }
    }

    $script:ScheduledTaskSnapshot = $items.ToArray()
    $script:ScheduledTaskSnapshotLoaded = $true
    return $script:ScheduledTaskSnapshot
}

function Find-ScheduledTasksByContains {
    param([string]$Needle)

    if ([string]::IsNullOrWhiteSpace($Needle)) {
        return @()
    }

    return @(Get-ScheduledTaskSnapshot | Where-Object {
        $task = $_
        @($task.Actions) | Where-Object {
            $expandedExecute = [Environment]::ExpandEnvironmentVariables([string]$_.Execute)
            $expandedArguments = [Environment]::ExpandEnvironmentVariables([string]$_.Arguments)
            ($expandedExecute -like "*$Needle*") -or
            ($expandedArguments -like "*$Needle*")
        }
    })
}

function Test-ScheduledTaskExists {
    param([string]$Name)

    if ([string]::IsNullOrWhiteSpace($Name)) {
        return $false
    }

    return @(Get-ScheduledTaskSnapshot | Where-Object {
        [string]$_.Name -eq $Name
    }).Count -gt 0
}

function Test-ActionExists {
    param($Action, [hashtable]$Variables)

    switch ($Action.type) {
        'file' {
            $path = Resolve-Template -Text $Action.path -Variables $Variables
            if (-not (Test-Path -LiteralPath $path)) { return $false }
            return $true
        }
        'registry-key' {
            return [bool](Test-Path -Path $Action.path)
        }
        'registry-value' {
            if (-not (Test-Path -Path $Action.path)) { return $false }
            return $null -ne (Get-ItemProperty -Path $Action.path -Name $Action.name -ErrorAction SilentlyContinue)
        }
        'defender-exclusion-path' {
            $pref = Get-DefenderPreference
            if (-not $pref) { return $false }
            $path = Resolve-Template -Text $Action.path -Variables $Variables
            $target = Normalize-DefenderPath -Path $path
            foreach ($existing in @($pref.ExclusionPath)) {
                if ((Normalize-DefenderPath -Path $existing) -eq $target) {
                    return $true
                }
            }
            return $false
        }
        'defender-exclusion-extension' {
            $pref = Get-DefenderPreference
            return $pref -and ($pref.ExclusionExtension -contains $Action.name)
        }
        'defender-exclusion-process' {
            $pref = Get-DefenderPreference
            return $pref -and ($pref.ExclusionProcess -contains $Action.name)
        }
        'process' {
            return $null -ne (Get-Process -Name ([System.IO.Path]::GetFileNameWithoutExtension($Action.name)) -ErrorAction SilentlyContinue)
        }
        'service' {
            return $null -ne (Get-Service -Name $Action.name -ErrorAction SilentlyContinue)
        }
        'task' {
            return (Test-ScheduledTaskExists -Name $Action.name)
        }
        'task-contains' {
            $needle = Resolve-Template -Text $Action.contains -Variables $Variables
            return (@(Find-ScheduledTasksByContains -Needle $needle).Count -gt 0)
        }
        default {
            return $false
        }
    }
}
