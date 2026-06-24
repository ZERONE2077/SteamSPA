$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$outPath = Join-Path $repoRoot 'SteamSPA-Remote.lnk'
$templatePath = Join-Path $repoRoot 'LocalTest.lnk'
$url = 'https://raw.githubusercontent.com/ZERONE2077/SteamSPA/main/uninstall.ps1'

$target = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'

# Runtime cache-busting: every double-click downloads a fresh URL.
$remoteCommand = @"
`$ProgressPreference='SilentlyContinue'; `$u='$url' + '?cacheBust=' + [guid]::NewGuid().ToString('N'); & ([scriptblock]::Create((irm `$u)))
"@.Trim()
$arguments = "-NoProfile -ExecutionPolicy Bypass -Command `"$remoteCommand`""

# Use LocalTest.lnk as a template when present. This preserves console shortcut
# settings such as font, colors and window size better than creating a blank .lnk.
if (Test-Path -LiteralPath $templatePath) {
    Copy-Item -LiteralPath $templatePath -Destination $outPath -Force
}

$ws = New-Object -ComObject WScript.Shell
$link = $ws.CreateShortcut($outPath)
$link.TargetPath = $target
$link.Arguments = $arguments
$link.WorkingDirectory = Split-Path -Parent $target
$link.WindowStyle = 1
$link.IconLocation = "$target,0"
$link.Description = 'SteamSPA remote runner (downloads latest uninstall.ps1 from GitHub Raw with cache-busting and executes it)'
$link.Save()

# Set Run as administrator flag in the .lnk extra data block.
$bytes = [System.IO.File]::ReadAllBytes($outPath)
if ($bytes.Length -gt 0x15) {
    $bytes[0x15] = $bytes[0x15] -bor 0x20
    [System.IO.File]::WriteAllBytes($outPath, $bytes)
}

Write-Host "Created: $outPath"
Write-Host "Arguments: $arguments"
