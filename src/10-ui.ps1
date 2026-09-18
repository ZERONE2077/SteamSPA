# SteamSPA source module
# Edit this module, then run tools/build.ps1.

function Get-ThemeColor {
    param([string]$Name)

    switch ($Name) {
        # Calm, terminal-native palette inspired by Claude/Gemini CLI:
        # warm semantic accents, low-contrast borders, no saturated rainbow colors.
        'Ink'       { return '229;231;235' }
        'Muted'     { return '148;163;184' }
        'Dim'       { return '100;116;139' }
        'Border'    { return '51;65;85' }
        'Accent'    { return '125;211;252' }
        'Accent2'   { return '196;181;253' }
        'Success'   { return '134;239;172' }
        'Warning'   { return '253;224;71' }
        'WarningSoft' { return '254;240;138' }
        'Danger'    { return '252;165;165' }
        'Title'     { return '56;189;248' }
        'Path'      { return '186;230;253' }
        'Code'      { return '203;213;225' }
        default     { return $null }
    }
}

function ConvertTo-ThemeRole {
    param($Color)

    switch ([string]$Color) {
        'Black'       { return 'Dim' }
        'DarkBlue'    { return 'Accent2' }
        'DarkGreen'   { return 'Success' }
        'DarkCyan'    { return 'Border' }
        'DarkRed'     { return 'Danger' }
        'DarkMagenta' { return 'Accent2' }
        'DarkYellow'  { return 'Warning' }
        'Gray'        { return 'Ink' }
        'DarkGray'    { return 'Muted' }
        'Blue'        { return 'Accent2' }
        'Green'       { return 'Success' }
        'Cyan'        { return 'Accent' }
        'Red'         { return 'Danger' }
        'Magenta'     { return 'Accent2' }
        'Yellow'      { return 'Warning' }
        'White'       { return 'Ink' }
        default       { return [string]$Color }
    }
}

function Get-Ansi {
    param($Color)

    if ($env:NO_COLOR) { return '' }
    $role = ConvertTo-ThemeRole $Color
    $rgb = Get-ThemeColor $role
    if (-not $rgb) { return '' }
    return "$([char]27)[38;2;${rgb}m"
}

function Write-Status {
    param([string]$Message = '', $Color = 'Ink', [switch]$NoNewline)

    $ansi = Get-Ansi $Color
    if ($ansi) {
        $reset = "$([char]27)[0m"
        if ($NoNewline) {
            Write-Host ($ansi + $Message + $reset) -NoNewline
        }
        else {
            Write-Host ($ansi + $Message + $reset)
        }
        return
    }

    $fallback = 'Gray'
    if ([enum]::TryParse([ConsoleColor], [string]$Color, $true, [ref]$fallback)) {
        Write-Host $Message -ForegroundColor $fallback -NoNewline:$NoNewline
    }
    else {
        Write-Host $Message -NoNewline:$NoNewline
    }
}

function Write-GradientText {
    param(
        [string]$Text,
        [int[]]$From = @(45, 212, 255),
        [int[]]$To = @(110, 231, 183)
    )

    if ($env:NO_COLOR) {
        Write-Host $Text
        return
    }

    $chars = $Text.ToCharArray()
    $steps = [Math]::Max(1, $chars.Count - 1)
    for ($i = 0; $i -lt $chars.Count; $i++) {
        $t = $i / $steps
        $r = [int]($From[0] + (($To[0] - $From[0]) * $t))
        $g = [int]($From[1] + (($To[1] - $From[1]) * $t))
        $b = [int]($From[2] + (($To[2] - $From[2]) * $t))
        Write-Host "$([char]27)[38;2;$r;$g;${b}m$($chars[$i])$([char]27)[0m" -NoNewline
    }
    Write-Host ''
}

function Write-Blank {
    Write-Host ''
}

function Write-Rule {
    param([string]$Title, $Color = 'Border')
    Write-Status '────────────────────────────────────────────────────────────' $Color
    if (-not [string]::IsNullOrWhiteSpace($Title)) {
        Write-Status ("  {0}" -f $Title) Accent
        Write-Status '────────────────────────────────────────────────────────────' $Color
    }
}

function Get-TextDisplayWidth {
    param([string]$Text)

    if ([string]::IsNullOrEmpty($Text)) { return 0 }

    $width = 0
    foreach ($ch in $Text.ToCharArray()) {
        $code = [int][char]$ch
        if (
            ($code -ge 0x1100 -and $code -le 0x11FF) -or
            ($code -ge 0x2E80 -and $code -le 0xA4CF) -or
            ($code -ge 0xAC00 -and $code -le 0xD7A3) -or
            ($code -ge 0xF900 -and $code -le 0xFAFF) -or
            ($code -ge 0xFE10 -and $code -le 0xFE6F) -or
            ($code -ge 0xFF00 -and $code -le 0xFF60) -or
            ($code -ge 0xFFE0 -and $code -le 0xFFE6)
        ) {
            $width += 2
        }
        else {
            $width += 1
        }
    }
    return $width
}

function Format-DisplayPadRight {
    param([string]$Text, [int]$Width)

    $displayWidth = Get-TextDisplayWidth $Text
    $padding = [Math]::Max(0, $Width - $displayWidth)
    return $Text + (' ' * $padding)
}

function Write-KeyValue {
    param([string]$Key, [string]$Value, $ValueColor = 'Ink')
    Write-Status ('  ' + (Format-DisplayPadRight $Key 18)) Muted -NoNewline
    Write-Status $Value $ValueColor
}

function Write-Section {
    param([string]$Title)
    Write-Blank
    Write-Status ("  {0}" -f $Title) Accent
    Write-Status '  ────────────────────────────────────────────────────────' Border
}

function Write-ProgressLine {
    param(
        [int]$Current,
        [int]$Total,
        [string]$Status = '扫描中'
    )

    $width = 28
    if ($Total -le 0) { $Total = 1 }
    $percent = [Math]::Min(100, [Math]::Max(0, [int](($Current / $Total) * 100)))
    $filled = [Math]::Min($width, [Math]::Max(0, [int][Math]::Round(($percent / 100) * $width)))
    $bar = ('█' * $filled) + ('░' * ($width - $filled))
    $line = "  {0,-8} [{1}] {2,3}%" -f $Status, $bar, $percent

    if ([Console]::IsOutputRedirected -or $env:NO_COLOR) {
        if ($Current -eq 0 -or $Current -ge $Total) {
            Write-Status $line Accent
        }
        return
    }

    Write-Status ($line + "`r") Accent -NoNewline
    if ($Current -ge $Total) {
        Write-Host ''
    }
}

function Write-Step {
    param([string]$Label, [string]$Value = '', $ValueColor = 'Ink')
    Write-Status '  ◆ ' Accent -NoNewline
    Write-Status $Label Muted -NoNewline
    if (-not [string]::IsNullOrWhiteSpace($Value)) {
        Write-Status $Value $ValueColor
    }
    else {
        Write-Host ''
    }
}

function Write-Result {
    param([string]$Icon, [string]$Label, [string]$Text, $Color = 'Ink')
    Write-Status ("  {0} " -f $Icon) $Color -NoNewline
    Write-Status ("{0,-8}" -f $Label) Muted -NoNewline
    Write-Status $Text $Color
}

function Get-RiskText {
    param([string]$Risk)
    switch ($Risk) {
        'low' { return '低风险' }
        'medium' { return '中风险' }
        'high' { return '高风险' }
        default { return $Risk }
    }
}

function Get-RiskColor {
    param([string]$Risk)
    switch ($Risk) {
        'low' { return 'Muted' }
        'medium' { return 'Warning' }
        'high' { return 'Danger' }
        default { return 'Ink' }
    }
}

function Read-CleanupConfirmation {
    Write-Blank
    Write-Section '✅ 确认清理？'
    Write-Status '  输入 Y 并回车 = 确认清理      |  其他任何输入 = 取消' Muted
    $choice = Read-Host '  请选择'
    if ($choice.Trim().ToUpperInvariant() -eq 'Y') {
        Write-Status '确认清理' Accent
        return $true
    }

    Write-Status '取消' Warning
    return $false
}
