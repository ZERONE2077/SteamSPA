# SteamSPA · 运行环境：参数、权限、STEAM 路径、路径模板、删除安全边界

function ConvertFrom-SpaArguments {
    param([object[]]$Arguments)

    $options = @{
        Risk     = @('low', 'medium', 'high')
        Only     = @()
        NoPause  = $false
        ScanOnly = $false
        Help     = $false
        Elevated = $false
        Errors   = @()
    }
    $list = @($Arguments)

    for ($i = 0; $i -lt $list.Count; $i++) {
        $name = [string]$list[$i]
        if ($name -match '^-(NoPause|ScanOnly|Help|Elevated)$') {
            $options[$Matches[1]] = $true
        }
        elseif ($name -eq '-NoBackup') {
            # 已不再备份，仍接受这个参数以兼容旧命令。
        }
        elseif ($name -match '^[-/](\?|h)$') {
            $options.Help = $true
        }
        elseif ($name -match '^-(Risk|Only)$') {
            $key = $Matches[1]
            $i++
            if ($i -ge $list.Count) { $options.Errors += "$name 缺少参数值"; break }
            $values = @(@($list[$i]) | ForEach-Object { ([string]$_) -split ',' } |
                    ForEach-Object { $_.Trim() } | Where-Object { $_ })
            if ($key -eq 'Risk') {
                $bad = @($values | Where-Object { @('low', 'medium', 'high') -notcontains $_ })
                if ($bad.Count -gt 0 -or $values.Count -eq 0) {
                    $options.Errors += '-Risk 只接受 low,medium,high'
                    continue
                }
            }
            $options[$key] = $values
        }
        else {
            $options.Errors += "未知参数: $name"
        }
    }
    return $options
}

# 把选项还原成命令行参数（提权重启时使用）。
function ConvertTo-SpaArgumentList {
    param([hashtable]$Options)
    $out = @()
    if ($Options.Risk.Count -lt 3) { $out += '-Risk'; $out += ($Options.Risk -join ',') }
    if ($Options.Only.Count -gt 0) { $out += '-Only'; $out += ($Options.Only -join ',') }
    if ($Options.NoPause) { $out += '-NoPause' }
    return $out
}

function Test-SpaAdmin {
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Find-SteamPath {
    $candidates = New-Object System.Collections.Generic.List[string]
    # HKLM 的 InstallPath 大小写规范，先用它；HKCU 的 SteamPath 是全小写加正斜杠。
    foreach ($key in @('HKLM:\SOFTWARE\WOW6432Node\Valve\Steam', 'HKLM:\SOFTWARE\Valve\Steam', 'HKCU:\Software\Valve\Steam')) {
        $props = Get-ItemProperty -LiteralPath $key -ErrorAction SilentlyContinue
        if (-not $props) { continue }
        foreach ($value in @($props.SteamPath, $props.InstallPath)) {
            if ($value) { $candidates.Add([string]$value) }
        }
        if ($props.SteamExe) { $candidates.Add((Split-Path -Parent ([string]$props.SteamExe))) }
    }
    foreach ($root in @(${env:ProgramFiles(x86)}, $env:ProgramFiles)) {
        if ($root) { $candidates.Add((Join-Path $root 'Steam')) }
    }

    $existing = @()
    foreach ($path in $candidates) {
        $full = ([string]$path).Replace('/', '\').TrimEnd('\')
        if ($full -and (Test-Path -LiteralPath $full -PathType Container)) { $existing += $full }
    }
    # 优先选真的有 steam.exe 的目录。
    foreach ($path in $existing) {
        if (Test-Path -LiteralPath (Join-Path $path 'steam.exe') -PathType Leaf) { return $path }
    }
    if ($existing.Count -gt 0) { return $existing[0] }
    return $null
}

function Get-SpaOSName {
    try {
        $cv = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop
        $build = [int]$cv.CurrentBuildNumber
        $name = if ($build -ge 22000) { 'Windows 11' } else { 'Windows 10' }
        $version = if ($cv.DisplayVersion) { ' ' + $cv.DisplayVersion } elseif ($cv.ReleaseId) { ' ' + $cv.ReleaseId } else { '' }
        $ubr = if ($null -ne $cv.UBR) { '.' + $cv.UBR } else { '' }
        return ('{0}{1} (Build {2}{3})' -f $name, $version, $build, $ubr)
    }
    catch {
        return [Environment]::OSVersion.VersionString
    }
}

function Get-SpaVariables {
    return @{
        APPDATA      = $env:APPDATA
        LOCALAPPDATA = $env:LOCALAPPDATA
        ProgramData  = $env:ProgramData
        TEMP         = $env:TEMP
        USERPROFILE  = $env:USERPROFILE
        SteamPath    = (Find-SteamPath)
    }
}

# 展开 ${Name} 和 %ENV%。任何变量缺失都返回 $null，而不是拼出一个
# 残缺路径（例如没找到 STEAM 时 "${SteamPath}\hid.dll" 会变成盘符根目录下的 "\hid.dll"）。
function Resolve-SpaTemplate {
    param([string]$Text, [hashtable]$Variables)

    if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
    $result = $Text
    foreach ($match in [regex]::Matches($Text, '\$\{(\w+)\}')) {
        $value = [string]$Variables[$match.Groups[1].Value]
        if ([string]::IsNullOrWhiteSpace($value)) { return $null }
        $result = $result.Replace($match.Value, $value.TrimEnd('\'))
    }
    $result = [Environment]::ExpandEnvironmentVariables($result)
    if ($result -match '%[^%\\]+%') { return $null }
    return $result
}

function ConvertTo-SpaComparablePath {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return '' }
    $p = [Environment]::ExpandEnvironmentVariables($Path.Trim().Trim('"')).Replace('/', '\')
    return $p.TrimEnd('\').ToLowerInvariant()
}

# 删除前的硬性边界：只删完整的绝对路径；绝不删系统/用户根目录、STEAM 根目录，
# 也绝不碰游戏 (steamapps) 和存档 (userdata)。返回拒绝原因，允许则返回 $null。
function Get-SpaUnsafePathReason {
    param([string]$Path, [hashtable]$Variables)

    if ($Path -notmatch '^[A-Za-z]:\\.+') { return '不是完整的绝对路径' }
    $target = ConvertTo-SpaComparablePath $Path
    if ($target -match '\\\.\.(\\|$)') { return '路径包含 ..' }

    $steam = ConvertTo-SpaComparablePath ([string]$Variables.SteamPath)
    $roots = @($env:SystemRoot, $env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:ProgramData,
        $env:USERPROFILE, $env:APPDATA, $env:LOCALAPPDATA, $env:TEMP, $Variables.SteamPath)
    if ($steam) {
        $roots += @('config', 'bin', 'steamapps', 'userdata', 'package', 'appcache') | ForEach-Object { Join-Path $Variables.SteamPath $_ }
    }
    foreach ($root in $roots) {
        if ($root -and $target -eq (ConvertTo-SpaComparablePath $root)) { return '受保护的系统或 STEAM 目录' }
    }
    if ($target -match '^[a-z]:$') { return '磁盘根目录' }
    if ($target -match '\\(steamapps|userdata)(\\|$)') { return '游戏或存档目录' }
    return $null
}

# 以管理员身份在新窗口重新运行。脚本源码取自当前调用，
# 所以 irm | iex 和本地文件两种方式都能用，不需要重新下载。
function Start-SpaElevated {
    param([string]$SelfText, [hashtable]$Options)

    if ([string]::IsNullOrWhiteSpace($SelfText)) { return $false }
    try {
        $dir = Join-Path $env:TEMP 'SteamSPA'
        [IO.Directory]::CreateDirectory($dir) | Out-Null
        $file = Join-Path $dir ('SteamSPA-' + [guid]::NewGuid().ToString('N') + '.ps1')
        [IO.File]::WriteAllText($file, $SelfText, (New-Object System.Text.UTF8Encoding($true)))

        $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"' + $file + '"'), '-Elevated')
        $argList += @(ConvertTo-SpaArgumentList $Options | ForEach-Object { '"' + $_ + '"' })
        Start-Process -FilePath 'powershell.exe' -ArgumentList $argList -Verb RunAs -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}
