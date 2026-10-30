# SteamSPA · 清理目标
# 每种规则动作类型在这里实现两件事：
#   Find-SpaActionTargets  把规则动作解析成本机上真实存在的目标（只读）
#   Remove-SpaTarget       删除一个目标
# 同一个物理目标在多条规则里出现时，用 Key 去重，只显示和删除一次。

function Get-SpaSupportedTypes {
    return @('file', 'registry-key', 'registry-value', 'defender-exclusion-path',
        'defender-exclusion-extension', 'defender-exclusion-process', 'process', 'task', 'task-contains')
}

function New-SpaTarget {
    param([string]$Type, [string]$Key, [string]$Label, [string]$Category,
        [hashtable]$Data, [string]$State = 'present', [string]$Note = '')
    return [pscustomobject]@{
        Type       = $Type
        Key        = ($Type + '|' + $Key).ToLowerInvariant()
        Label      = $Label
        Category   = $Category
        Data       = $Data
        State      = $State      # present / protected
        Note       = $Note
        Recurse    = [bool]$Data.Recurse
        RuleIds    = New-Object System.Collections.Generic.List[string]
        Risk       = 'low'
        Confirm    = $false
        Status     = ''          # removed / failed / skipped
        Message    = ''
    }
}

# ---------- Defender ----------

function Get-SpaDefenderState {
    param([switch]$Refresh)
    if ($Spa.Defender -and -not $Refresh) { return $Spa.Defender }

    $state = @{ Available = $false; Readable = $false; Path = @(); Extension = @(); Process = @() }
    if (Get-Command -Name Get-MpPreference -ErrorAction SilentlyContinue) {
        try {
            $pref = Get-MpPreference -ErrorAction Stop
            $state.Available = $true
            $state.Path = @($pref.ExclusionPath | Where-Object { $_ })
            $state.Extension = @($pref.ExclusionExtension | Where-Object { $_ })
            $state.Process = @($pref.ExclusionProcess | Where-Object { $_ })
            # 非管理员读到的是 "N/A: Must be an administrator to view exclusions"。
            $state.Readable = -not (@($state.Path + $state.Extension + $state.Process) | Where-Object { "$_" -like 'N/A*' })
        }
        catch {
            # 第三方杀软接管时 Defender 不可用，跳过即可。
        }
    }
    $Spa.Defender = $state
    return $state
}

function Find-SpaDefenderTargets {
    param([string]$Kind, [string]$Value)

    $state = Get-SpaDefenderState
    if (-not $state.Available) { return @() }
    if (-not $state.Readable) { $Spa.DefenderHidden = $true; return @() }

    switch ($Kind) {
        'path' {
            $want = ConvertTo-SpaComparablePath $Value
            $hits = @($state.Path | Where-Object { (ConvertTo-SpaComparablePath $_) -eq $want })
            $label = 'Defender 排除路径: ' + $Value
            $key = $want
        }
        'extension' {
            $want = $Value.TrimStart('.').ToLowerInvariant()
            $hits = @($state.Extension | Where-Object { ([string]$_).TrimStart('.').ToLowerInvariant() -eq $want })
            $label = 'Defender 排除扩展名: .' + $want
            $key = $want
        }
        'process' {
            $want = $Value.ToLowerInvariant()
            $hits = @($state.Process | Where-Object { ([string]$_).ToLowerInvariant() -eq $want })
            $label = 'Defender 排除进程: ' + $Value
            $key = $want
        }
    }
    if ($hits.Count -eq 0) { return @() }
    return (New-SpaTarget -Type ('defender-' + $Kind) -Key $key -Label $label -Category 'security' -Data @{ Kind = $Kind; Values = $hits })
}

# ---------- 计划任务 ----------

function Get-SpaTaskSnapshot {
    if ($null -ne $Spa.Tasks) { return $Spa.Tasks }

    $list = New-Object System.Collections.Generic.List[object]
    try {
        $service = New-Object -ComObject Schedule.Service
        $service.Connect()
        $folders = New-Object System.Collections.Stack
        $folders.Push($service.GetFolder('\'))
        while ($folders.Count -gt 0) {
            $folder = $folders.Pop()
            foreach ($task in @($folder.GetTasks(1))) {
                try {
                    $parts = @()
                    foreach ($action in @($task.Definition.Actions)) {
                        if ($action.Type -eq 0) { $parts += @($action.Path, $action.Arguments, $action.WorkingDirectory) }
                    }
                    $list.Add([pscustomobject]@{
                            Name       = [string]$task.Name
                            Path       = [string]$task.Path
                            Folder     = [string]$folder.Path
                            ActionText = [Environment]::ExpandEnvironmentVariables(($parts -join ' '))
                        })
                }
                catch {}
            }
            foreach ($child in @($folder.GetFolders(0))) { $folders.Push($child) }
        }
    }
    catch {
        $Spa.Warnings.Add('无法读取计划任务列表，已跳过计划任务检查。')
    }
    $Spa.Tasks = $list.ToArray()
    return $Spa.Tasks
}

function New-SpaTaskTarget {
    param($Task)
    return New-SpaTarget -Type 'task' -Key $Task.Path -Label ('计划任务: ' + $Task.Path) -Category 'startup' -Data @{ Name = $Task.Name; Path = $Task.Path; Folder = $Task.Folder }
}

# ---------- 文件签名 ----------

# Steam 根目录里的 video.dll 等是 Valve 签名的官方组件；规则里的同名 DLL
# 只应命中未签名的注入副本。签名有效且签发者是 Valve 的一律不删。
function Test-SpaValveSigned {
    param([string]$Path)
    $ext = [IO.Path]::GetExtension($Path).ToLowerInvariant()
    if (@('.dll', '.exe', '.sys') -notcontains $ext) { return $false }
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }
    try {
        $sig = Get-AuthenticodeSignature -LiteralPath $Path -ErrorAction Stop
        return ($sig.Status -eq 'Valid' -and [string]$sig.SignerCertificate.Subject -match '(^|,\s*)(O|CN)="?Valve')
    }
    catch {
        return $false
    }
}

function Get-SpaFileCategory {
    param([string]$Path)
    if ($Path -match 'steam\.cfg|appdata\d*\.vdf|packageinfo\.vdf|localData\.vdf|package\\beta|opensteamtool\.toml|config\\lua') { return 'config' }
    return 'files'
}

function Get-SpaRegistryCategory {
    param([string]$Path)
    if ($Path -match '\\CurrentVersion\\Run') { return 'startup' }
    if ($Path -match 'Policies|SmartScreen|\\CI\\Policy|WindowsUpdate') { return 'security' }
    return 'registry'
}

# ---------- 解析：规则动作 -> 本机目标 ----------

function Find-SpaActionTargets {
    param($Action, [hashtable]$Variables)

    switch ([string]$Action.type) {
        'file' {
            $path = Resolve-SpaTemplate -Text $Action.path -Variables $Variables
            if (-not $path -or -not (Test-Path -LiteralPath $path)) { return @() }
            $data = @{ Path = $path; Recurse = [bool]$Action.recurse }
            $target = New-SpaTarget -Type 'file' -Key $path -Label $path -Category (Get-SpaFileCategory $path) -Data $data
            $reason = Get-SpaUnsafePathReason -Path $path -Variables $Variables
            if ($reason) {
                $target.State = 'protected'; $target.Note = $reason
            }
            elseif (Test-SpaValveSigned $path) {
                $target.State = 'protected'; $target.Note = 'Valve 官方签名文件'
            }
            return $target
        }
        'registry-key' {
            $path = [string]$Action.path
            if (-not (Test-Path -LiteralPath $path)) { return @() }
            return (New-SpaTarget -Type 'registry-key' -Key $path -Label $path -Category (Get-SpaRegistryCategory $path) -Data @{ Path = $path; Recurse = [bool]$Action.recurse })
        }
        'registry-value' {
            $path = [string]$Action.path
            $name = [string]$Action.name
            $props = Get-ItemProperty -LiteralPath $path -ErrorAction SilentlyContinue
            if (-not $props -or -not ($props.PSObject.Properties.Name -contains $name)) { return @() }
            return (New-SpaTarget -Type 'registry-value' -Key ($path + '|' + $name) -Label ($path + ' : ' + $name) -Category (Get-SpaRegistryCategory $path) -Data @{ Path = $path; Name = $name })
        }
        'defender-exclusion-path' {
            $path = Resolve-SpaTemplate -Text $Action.path -Variables $Variables
            if (-not $path) { return @() }
            return Find-SpaDefenderTargets -Kind 'path' -Value $path
        }
        'defender-exclusion-extension' { return Find-SpaDefenderTargets -Kind 'extension' -Value ([string]$Action.name) }
        'defender-exclusion-process' { return Find-SpaDefenderTargets -Kind 'process' -Value ([string]$Action.name) }
        'process' {
            $name = [IO.Path]::GetFileNameWithoutExtension([string]$Action.name)
            if (-not (Get-Process -Name $name -ErrorAction SilentlyContinue)) { return @() }
            return (New-SpaTarget -Type 'process' -Key $name -Label ('进程: ' + $name) -Category 'process' -Data @{ Name = $name })
        }
        'task' {
            $name = [string]$Action.name
            return @(Get-SpaTaskSnapshot | Where-Object { $_.Name -eq $name } | ForEach-Object { New-SpaTaskTarget $_ })
        }
        'task-contains' {
            $needle = Resolve-SpaTemplate -Text $Action.contains -Variables $Variables
            if (-not $needle) { return @() }
            return @(Get-SpaTaskSnapshot | Where-Object { $_.ActionText.IndexOf($needle, [StringComparison]::OrdinalIgnoreCase) -ge 0 } | ForEach-Object { New-SpaTaskTarget $_ })
        }
    }
    return @()
}

# ---------- 删除 ----------

function Get-SpaErrorText {
    param($ErrorRecord)
    $ex = $ErrorRecord.Exception
    while ($ex.InnerException) { $ex = $ex.InnerException }
    if ($ex -is [UnauthorizedAccessException] -or $ex -is [Security.SecurityException]) {
        return '权限不足或被杀毒软件拦截'
    }
    if ($ex -is [IO.IOException]) { return '文件正在被占用' }
    return $ex.Message.Trim()
}

function Set-SpaResult {
    param($Target, [string]$Status, [string]$Message = '')
    $Target.Status = $Status
    $Target.Message = $Message
}

function Remove-SpaTarget {
    param($Target, [hashtable]$Variables)

    $d = $Target.Data
    try {
        if ($Target.Type -eq 'file') {
            # 再次检查边界，防止规则或变量在扫描后被篡改。
            $reason = Get-SpaUnsafePathReason -Path $d.Path -Variables $Variables
            if ($reason) { return Set-SpaResult $Target 'skipped' $reason }
            if (-not (Test-Path -LiteralPath $d.Path)) { return Set-SpaResult $Target 'skipped' '已不存在' }
            $isDir = Test-Path -LiteralPath $d.Path -PathType Container
            if ($isDir -and -not $Target.Recurse -and @(Get-ChildItem -LiteralPath $d.Path -Force -ErrorAction SilentlyContinue).Count -gt 0) {
                return Set-SpaResult $Target 'skipped' '目录非空，规则未允许整目录删除'
            }
        }
        if ($Target.Type -eq 'registry-key' -and -not $Target.Recurse) {
            $key = Get-Item -LiteralPath $d.Path -ErrorAction SilentlyContinue
            if ($key -and $key.SubKeyCount -gt 0) { return Set-SpaResult $Target 'skipped' '含子项，规则未允许整项删除' }
        }

        switch ($Target.Type) {
            'file' {
                Remove-Item -LiteralPath $d.Path -Force -Recurse:$Target.Recurse -ErrorAction Stop
                if (Test-Path -LiteralPath $d.Path) { return Set-SpaResult $Target 'failed' '文件正在被占用' }
            }
            'registry-key' {
                Remove-Item -LiteralPath $d.Path -Force -Recurse -ErrorAction Stop
            }
            'registry-value' {
                Remove-ItemProperty -LiteralPath $d.Path -Name $d.Name -Force -ErrorAction Stop
            }
            { $_ -like 'defender-*' } {
                switch ($d.Kind) {
                    'path' { Remove-MpPreference -ExclusionPath $d.Values -ErrorAction Stop }
                    'extension' { Remove-MpPreference -ExclusionExtension $d.Values -ErrorAction Stop }
                    'process' { Remove-MpPreference -ExclusionProcess $d.Values -ErrorAction Stop }
                }
            }
            'process' {
                Get-Process -Name $d.Name -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction Stop
                Start-Sleep -Milliseconds 300
                if (Get-Process -Name $d.Name -ErrorAction SilentlyContinue) { return Set-SpaResult $Target 'failed' '进程未能结束' }
            }
            'task' {
                $service = New-Object -ComObject Schedule.Service
                $service.Connect()
                $service.GetFolder($d.Folder).DeleteTask($d.Name, 0)
            }
        }
        Set-SpaResult $Target 'removed'
    }
    catch {
        Set-SpaResult $Target 'failed' (Get-SpaErrorText $_)
    }
}
