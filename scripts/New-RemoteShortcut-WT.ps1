$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$outPath = Join-Path $repoRoot 'SteamSPA-Remote-WT.lnk'
$urls = @(
    'https://raw.githubusercontent.com/ZERONE2077/SteamSPA/main/uninstall.ps1',
    'https://cdn.jsdelivr.net/gh/ZERONE2077/SteamSPA@main/uninstall.ps1'
)
$title = 'STEAM SPA - 假入库清杀工具'

$cmdExe = Join-Path $env:WINDIR 'System32\cmd.exe'
$powershellExe = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'

# Windows Terminal is usually exposed as an App Execution Alias (wt.exe).
# Launch it through cmd.exe /c start so the alias resolves like Win+R does.
$urlList = "@('" + ($urls -join "','") + "')"
$psCommand = "[Net.ServicePointManager]::SecurityProtocol=3072;`$ok=0;foreach(`$u in $urlList){try{iex(irm(`$u+'?'+(Get-Random)));`$ok=1;break}catch{`$e=`$_}};if(!`$ok){`$e;pause}"
#
# Use -EncodedCommand so Windows Terminal will not treat PowerShell semicolons
# as WT command separators. Keep the encoded script short to avoid .lnk
# argument truncation.
$encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($psCommand))
$wtArguments = '-w 0 nt --title "' + $title + '" powershell.exe -NoProfile -ExecutionPolicy Bypass -EncodedCommand ' + $encodedCommand
$arguments = '/c start "" wt.exe ' + $wtArguments

$ws = New-Object -ComObject WScript.Shell
$link = $ws.CreateShortcut($outPath)
$link.TargetPath = $cmdExe
$link.Arguments = $arguments
$link.WorkingDirectory = Split-Path -Parent $cmdExe
$link.WindowStyle = 7
$link.IconLocation = "$powershellExe,0"
$link.Description = 'SteamSPA remote runner via Windows Terminal. Requires wt.exe.'
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



