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

function Test-ActionExists {
    param($Action, [hashtable]$Variables)

    switch ($Action.type) {
        'file' {
            $path = Resolve-Template -Text $Action.path -Variables $Variables
            if (-not (Test-Path -LiteralPath $path)) { return $false }
            if (Test-ValveSignedFile -Path $path) { return $false }
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
            return $null -ne (Get-ScheduledTask -TaskName $Action.name -ErrorAction SilentlyContinue)
        }
        'task-contains' {
            $needle = Resolve-Template -Text $Action.contains -Variables $Variables
            $matches = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
                $task = $_
                @($task.Actions) | Where-Object {
                    ([string]$_.Execute -like "*$needle*") -or ([string]$_.Arguments -like "*$needle*")
                }
            }
            return $null -ne (@($matches)[0])
        }
        default {
            return $false
        }
    }
}
