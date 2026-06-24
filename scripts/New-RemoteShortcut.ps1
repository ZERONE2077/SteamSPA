$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$outPath = Join-Path $repoRoot 'SteamSPA-Remote.lnk'
$url = 'https://raw.githubusercontent.com/ZERONE2077/SteamSPA/main/uninstall.ps1'
$title = 'STEAM SPA Remote'

$cmdExe = Join-Path $env:WINDIR 'System32\cmd.exe'
$powershellExe = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'

# Encode the PowerShell payload so cmd.exe does not need to parse nested quotes.
# Runtime cache-busting: every double-click appends a fresh GUID query string.
$psCommand = '$ProgressPreference=''SilentlyContinue''; $u=''' + $url + '?'' + [guid]::NewGuid().ToString(''N''); iex (irm $u)'
$encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($psCommand))

# cmd.exe wrapper: set title, run PowerShell, then pause so errors do not flash away.
$arguments = '/c "title ' + $title + ' & ""' + $powershellExe + '"" -NoProfile -ExecutionPolicy Bypass -EncodedCommand ' + $encodedCommand + ' & echo. & pause"'

$ws = New-Object -ComObject WScript.Shell
$link = $ws.CreateShortcut($outPath)
$link.TargetPath = $cmdExe
$link.Arguments = $arguments
$link.WorkingDirectory = Split-Path -Parent $cmdExe
$link.WindowStyle = 1
$link.IconLocation = "$powershellExe,0"
$link.Description = 'SteamSPA remote runner via cmd.exe wrapper: sets title, downloads latest script with cache-busting, runs it, then pauses.'
$link.Save()

# Set Run as administrator flag in the .lnk header.
$bytes = [System.IO.File]::ReadAllBytes($outPath)
if ($bytes.Length -gt 0x15) {
    $bytes[0x15] = $bytes[0x15] -bor 0x20
    [System.IO.File]::WriteAllBytes($outPath, $bytes)
}

Write-Host "Created: $outPath"
Write-Host "Target: $cmdExe"
Write-Host "Arguments: $arguments"
Write-Host "PowerShell: $psCommand"
