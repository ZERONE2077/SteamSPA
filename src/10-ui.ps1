# SteamSPA · 终端输出层
# 只有这个文件直接调用 Write-Host / Read-Host。其余模块只返回数据。
# 支持真彩色时用 24 位 ANSI；老控制台退回 ConsoleColor；输出被重定向时纯文本。

function Initialize-SpaConsole {
    $redirected = [Console]::IsOutputRedirected
    # 重定向时也要切 UTF-8：publish.ps1 / 测试通过管道读取中文输出。
    try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch {}

    $ansi = $false
    if (-not $redirected -and -not $env:NO_COLOR) {
        try { $ansi = [bool]$Host.UI.SupportsVirtualTerminal } catch {}
        if ($env:WT_SESSION) { $ansi = $true }
    }

    $Spa.Ui = @{
        Redirected      = $redirected
        InputRedirected = [Console]::IsInputRedirected
        Ansi            = $ansi
        Color           = (-not $redirected -and -not $env:NO_COLOR)
    }
}

function Get-UiRgb {
    param([string]$Role)
    switch ($Role) {
        'Muted'   { '148;163;184' }
        'Dim'     { '100;116;139' }
        'Accent'  { '125;211;252' }
        'Success' { '134;239;172' }
        'Warning' { '253;224;71' }
        'Danger'  { '252;165;165' }
        'Path'    { '186;230;253' }
        default   { '229;231;235' }
    }
}

function Write-Ui {
    param([string]$Text = '', [string]$Role = 'Ink', [switch]$NoNewline)

    $ui = $Spa.Ui
    if ($ui -and $ui.Ansi) {
        $esc = [char]27
        Write-Host ("$esc[38;2;$(Get-UiRgb $Role)m$Text$esc[0m") -NoNewline:$NoNewline
        return
    }
    if ($ui -and $ui.Color) {
        $color = switch ($Role) {
            'Muted'   { 'Gray' }
            'Dim'     { 'DarkGray' }
            'Accent'  { 'Cyan' }
            'Success' { 'Green' }
            'Warning' { 'Yellow' }
            'Danger'  { 'Red' }
            'Path'    { 'White' }
            default   { 'White' }
        }
        Write-Host $Text -ForegroundColor $color -NoNewline:$NoNewline
        return
    }
    Write-Host $Text -NoNewline:$NoNewline
}

# 艺术字：逐字符从青色渐变到绿色；不支持真彩色时整行用青色。
function Write-UiBanner {
    param([string[]]$Lines)
    $from = @(45, 212, 255)
    $to = @(110, 231, 183)
    $esc = [char]27
    foreach ($line in $Lines) {
        if (-not ($Spa.Ui -and $Spa.Ui.Ansi)) { Write-Ui $line Accent; continue }
        $sb = New-Object System.Text.StringBuilder
        $steps = [Math]::Max(1, $line.Length - 1)
        for ($i = 0; $i -lt $line.Length; $i++) {
            $t = $i / $steps
            $r = [int]($from[0] + ($to[0] - $from[0]) * $t)
            $g = [int]($from[1] + ($to[1] - $from[1]) * $t)
            $b = [int]($from[2] + ($to[2] - $from[2]) * $t)
            [void]$sb.Append("$esc[38;2;$r;$g;${b}m").Append($line[$i])
        }
        [void]$sb.Append("$esc[0m")
        Write-Host $sb.ToString()
    }
}

# 中文在终端里占两列，按字符数补空格会错位。
function Get-DisplayWidth {
    param([string]$Text)
    $width = 0
    foreach ($ch in ([string]$Text).ToCharArray()) {
        $c = [int]$ch
        if (($c -ge 0x1100 -and $c -le 0x115F) -or ($c -ge 0x2E80 -and $c -le 0xA4CF) -or
            ($c -ge 0xAC00 -and $c -le 0xD7A3) -or ($c -ge 0xF900 -and $c -le 0xFAFF) -or
            ($c -ge 0xFE30 -and $c -le 0xFE4F) -or ($c -ge 0xFF00 -and $c -le 0xFF60) -or
            ($c -ge 0xFFE0 -and $c -le 0xFFE6)) {
            $width += 2
        }
        else {
            $width += 1
        }
    }
    return $width
}

function Format-PadRight {
    param([string]$Text, [int]$Width)
    return $Text + (' ' * [Math]::Max(0, $Width - (Get-DisplayWidth $Text)))
}

# 章节标题：  ◆ 标题   说明
function Write-UiSection {
    param([string]$Title, [string]$Hint = '', [string]$HintRole = 'Muted')
    Write-Host ''
    Write-Ui '  ◆ ' Accent -NoNewline
    if ($Hint) {
        Write-Ui $Title Ink -NoNewline
        Write-Ui ('   ' + $Hint) $HintRole
    }
    else {
        Write-Ui $Title Ink
    }
}

function Write-UiKeyValue {
    param([string]$Key, [string]$Value, [string]$Role = 'Ink')
    Write-Ui ('    ' + (Format-PadRight $Key 12)) Muted -NoNewline
    Write-Ui $Value $Role
}

# 一行结果：  标签      内容
function Write-UiResult {
    param([string]$Tag, [string]$Text, [string]$Role = 'Ink')
    Write-Ui ('    ' + (Format-PadRight $Tag 10)) $Role -NoNewline
    Write-Ui $Text $Role
}

# 提示行：  !  内容（Warning）或  ·  内容（Muted）
function Write-UiNote {
    param([string]$Text, [switch]$Important)
    if ($Important) {
        Write-Ui '    !  ' Warning -NoNewline
        Write-Ui $Text Warning
    }
    else {
        Write-Ui '    ·  ' Dim -NoNewline
        Write-Ui $Text Muted
    }
}

# 菜单项：    [Y]  说明
function Write-UiOption {
    param([string]$Key, [string]$Text, [string]$Role = 'Ink')
    Write-Ui ('    ' + (Format-PadRight ('[' + $Key + ']') 8)) Accent -NoNewline
    Write-Ui $Text $Role
}

function Write-UiProgress {
    param([int]$Current, [int]$Total)
    if ($Spa.Ui -and $Spa.Ui.Redirected) { return }
    if ($Total -le 0) { $Total = 1 }
    $percent = [int][Math]::Floor($Current * 100 / $Total)
    $width = 30
    $filled = [int][Math]::Floor($percent * $width / 100)
    # 用 ASCII 画进度条：█ 在部分中文字体里是双宽，进度条会折行。
    $bar = ('=' * $filled) + (' ' * ($width - $filled))
    Write-Ui ("`r    扫描中 [{0}] {1,3}%" -f $bar, $percent) Accent -NoNewline
}

function Clear-UiProgress {
    if ($Spa.Ui -and $Spa.Ui.Redirected) { return }
    Write-Host ("`r" + (' ' * 60) + "`r") -NoNewline
}

# 读取一个选项。空输入或输入流结束时返回默认值（默认值应当是安全选项）。
function Read-UiChoice {
    param([string]$Prompt, [string[]]$Allowed, [string]$Default)
    while ($true) {
        Write-Host ''
        Write-Ui ('    ' + $Prompt + ' ') Accent -NoNewline
        $raw = Read-Host
        if ($null -eq $raw) { return $Default }
        $value = $raw.Trim().ToUpperInvariant()
        if ($value -eq '') { return $Default }
        if ($Allowed -contains $value) { return $value }
        if ($Spa.Ui -and $Spa.Ui.InputRedirected) { return $Default }
        Write-Ui ('    请输入 ' + ($Allowed -join ' / ') + '，或直接回车') Warning
    }
}

function Wait-UiExit {
    if ($Spa.Ui -and $Spa.Ui.InputRedirected) { return }
    Write-Host ''
    Write-Ui '    按回车退出...' Accent -NoNewline
    Read-Host | Out-Null
}
