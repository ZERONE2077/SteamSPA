$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$templatePath = Join-Path $repoRoot 'LocalTest.lnk'
$outPath = Join-Path $repoRoot 'SteamSPA-Remote.lnk'
$url = 'https://raw.githubusercontent.com/ZERONE2077/SteamSPA/main/uninstall.ps1'

if (-not (Test-Path -LiteralPath $templatePath)) {
    throw "Template not found: $templatePath"
}

$ws = New-Object -ComObject WScript.Shell
$template = $ws.CreateShortcut($templatePath)
$oldArgs = $template.Arguments

# Keep this shorter than LocalTest.lnk arguments so we can replace it in-place.
# In-place replacement preserves console shortcut ExtraData (font/colors/window) that
# WScript.Shell can drop or rewrite when saving a shortcut.
$newArgs = '-NoP -NoExit -EP Bypass -C "iex(irm(''' + $url + '?''+[guid]::NewGuid()))"'
if ($newArgs.Length -gt $oldArgs.Length) {
    throw "New arguments are longer than template arguments. Old=$($oldArgs.Length), New=$($newArgs.Length)"
}

Copy-Item -LiteralPath $templatePath -Destination $outPath -Force

$bytes = [System.IO.File]::ReadAllBytes($outPath)
$oldText = [System.Text.Encoding]::Unicode.GetBytes($oldArgs)
$newText = [System.Text.Encoding]::Unicode.GetBytes($newArgs.PadRight($oldArgs.Length))

$offset = -1
for ($i = 0; $i -le $bytes.Length - $oldText.Length; $i++) {
    $match = $true
    for ($j = 0; $j -lt $oldText.Length; $j++) {
        if ($bytes[$i + $j] -ne $oldText[$j]) { $match = $false; break }
    }
    if ($match) { $offset = $i; break }
}
if ($offset -lt 0) {
    throw 'Could not find template arguments in LocalTest.lnk binary.'
}

[Array]::Copy($newText, 0, $bytes, $offset, $newText.Length)

# Set Run as administrator flag in the .lnk header.
if ($bytes.Length -gt 0x15) {
    $bytes[0x15] = $bytes[0x15] -bor 0x20
}

[System.IO.File]::WriteAllBytes($outPath, $bytes)

$result = $ws.CreateShortcut($outPath)
Write-Host "Created: $outPath"
Write-Host "Arguments: $($result.Arguments)"
Write-Host "ReplacedAt: 0x$($offset.ToString('X'))"

