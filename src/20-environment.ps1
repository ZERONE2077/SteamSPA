# SteamSPA source module
# Edit this module, then run tools/build.ps1.

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
    $candidates = New-Object System.Collections.Generic.List[string]
    $registryPaths = @(
        'HKCU:\Software\Valve\Steam',
        'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam',
        'HKLM:\SOFTWARE\Valve\Steam'
    )

    foreach ($registryPath in $registryPaths) {
        try {
            $props = Get-ItemProperty -Path $registryPath -ErrorAction Stop
            foreach ($name in @('SteamPath', 'InstallPath')) {
                $path = [string]$props.$name
                if (-not [string]::IsNullOrWhiteSpace($path)) {
                    $candidates.Add($path)
                }
            }
            $steamExe = [string]$props.SteamExe
            if (-not [string]::IsNullOrWhiteSpace($steamExe)) {
                $parent = Split-Path -Parent $steamExe
                if (-not [string]::IsNullOrWhiteSpace($parent)) {
                    $candidates.Add($parent)
                }
            }
        }
        catch {}
    }

    $defaultPaths = @(
        (Join-Path ${env:ProgramFiles(x86)} 'Steam'),
        (Join-Path $env:ProgramFiles 'Steam')
    )
    foreach ($path in $defaultPaths) {
        if (-not [string]::IsNullOrWhiteSpace($path)) {
            $candidates.Add($path)
        }
    }

    foreach ($path in @($candidates | Select-Object -Unique)) {
        if ($path -and (Test-Path -LiteralPath $path -PathType Container)) {
            return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($path)
        }
    }

    return $null
}

function Get-OSDisplayName {
    try {
        $cv = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop
        $build = [int]$cv.CurrentBuildNumber
        $name = if ($build -ge 22000) { 'Windows 11' } else { 'Windows 10' }
        $version = if ($cv.DisplayVersion) { $cv.DisplayVersion } elseif ($cv.ReleaseId) { $cv.ReleaseId } else { $null }
        $ubr = if ($null -ne $cv.UBR) { ".{0}" -f $cv.UBR } else { '' }

        if ($version) {
            return ('{0} {1} (Build {2}{3})' -f $name, $version, $build, $ubr)
        }
        return ('{0} (Build {1}{2})' -f $name, $build, $ubr)
    }
    catch {
        return [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
    }
}

function Get-Variables {
    $steamPath = Get-SteamPath
    return @{
        APPDATA      = $env:APPDATA
        LOCALAPPDATA = $env:LOCALAPPDATA
        OS           = (Get-OSDisplayName)
        ProgramData  = $env:ProgramData
        ScriptRoot   = $scriptRoot
        SteamPath    = $steamPath
        TEMP         = $env:TEMP
        USERPROFILE  = $env:USERPROFILE
    }
}

function Read-Targets {
    return $EmbeddedTargetsJson | ConvertFrom-Json
}
