# ============================================================
# IRM 节点延迟检测工具 (仅检测，不执行任何 irm 命令)
# 兼容 PowerShell 5.1+
# ============================================================
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 将纯数字（32位整数）转换为点分十进制 IP
function ConvertTo-DottedIP {
    param([string]$Value)
    if ($Value -match '^\d+$') {
        $num = [uint32]$Value
        return "{0}.{1}.{2}.{3}" -f (($num -shr 24) -band 255),
        (($num -shr 16) -band 255),
        (($num -shr 8)  -band 255),
        ($num           -band 255)
    }
    return $Value
}

# 目标节点列表
$rawTargets = @(
    "steam-run.com",
    "1.steam-run.com",
    "steamcdkey.cn",
    "47.98.202.172",
    "121.41.70.40",
    "2.steam-run.com",
    "8.130.189.108",
    "2526944756",
    "142785900"
)

# 构建目标对象（注意：避开保留变量名 $host，改用 $addr）
$targets = @()
foreach ($raw in $rawTargets) {
    $addr = ConvertTo-DottedIP $raw
    $targets += [PSCustomObject]@{
        Raw     = $raw
        Addr    = $addr
        BaseUrl = "https://$addr"
    }
}

# ============================================================
# Banner
# ============================================================
Write-Host ""
Write-Host "  +======================================================+" -ForegroundColor DarkCyan
Write-Host "  |      IRM 节点延迟检测器  [仅检测 不执行]            |" -ForegroundColor Cyan
Write-Host "  +======================================================+" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  [*] 正在并行探测全部节点，请稍候..." -ForegroundColor Yellow
Write-Host ""

# ============================================================
# 使用 Start-Job 实现并行（兼容 PS 5.1）
# ============================================================
$jobs = @()
foreach ($item in $targets) {
    $job = Start-Job -ScriptBlock {
        param($raw, $addr, $baseUrl)

        $result = [PSCustomObject]@{
            Raw      = $raw
            Addr     = $addr
            Latency  = [long]9999
            Status   = "TIMEOUT"
            HttpCode = "-"
        }

        # 先尝试 HTTP HEAD 请求
        try {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $resp = Invoke-WebRequest -Uri $baseUrl `
                -UseBasicParsing `
                -TimeoutSec 5 `
                -Method Head `
                -ErrorAction SilentlyContinue
            $sw.Stop()
            if ($null -ne $resp) {
                $result.Latency = $sw.ElapsedMilliseconds
                $result.Status = "LIVE"
                $result.HttpCode = [string]$resp.StatusCode
            }
        }
        catch {
            # fallback：TCP 连接测试 443 端口
            try {
                $sw2 = [System.Diagnostics.Stopwatch]::StartNew()
                $tcp = New-Object System.Net.Sockets.TcpClient
                $conn = $tcp.BeginConnect($addr, 443, $null, $null)
                $ok = $conn.AsyncWaitHandle.WaitOne(3000)
                $sw2.Stop()
                if ($ok -and $tcp.Connected) {
                    $tcp.Close()
                    $result.Latency = $sw2.ElapsedMilliseconds
                    $result.Status = "TCP-OK"
                    $result.HttpCode = "TCP/443"
                }
            }
            catch { }
        }

        return $result
    } -ArgumentList $item.Raw, $item.Addr, $item.BaseUrl

    $jobs += $job
}

# 等待所有 Job 完成（最多等 15 秒）
$null = Wait-Job -Job $jobs -Timeout 15

# 收集结果
$results = @()
foreach ($job in $jobs) {
    $res = Receive-Job -Job $job -ErrorAction SilentlyContinue
    if ($null -ne $res) {
        $results += $res
    }
}
Remove-Job -Job $jobs -Force

# 按延迟排序
$results = $results | Sort-Object Latency

# ============================================================
# 格式化输出表格
# ============================================================
$wRaw = 22
$wAddr = 18
$wStat = 11
$wLat = 10
$wCode = 8
$sepLine = "  " + ("-" * ($wRaw + $wAddr + $wStat + $wLat + $wCode + 12))

Write-Host $sepLine -ForegroundColor DarkGray
Write-Host ("  {0,-$wRaw}  {1,-$wAddr}  {2,-$wStat}  {3,-$wLat}  {4}" -f "原始地址", "解析地址", "状态", "延迟", "HTTP") -ForegroundColor White
Write-Host $sepLine -ForegroundColor DarkGray

foreach ($r in $results) {
    $latStr = if ($r.Latency -ge 9999) { "TIMEOUT" } else { "$($r.Latency) ms" }

    switch ($r.Status) {
        "LIVE" { $color = "Green"; $icon = "[+]" }
        "TCP-OK" { $color = "Cyan"; $icon = "[~]" }
        default { $color = "Red"; $icon = "[-]" }
    }

    $statusText = "$icon $($r.Status)"
    $line = "  {0,-$wRaw}  {1,-$wAddr}  {2,-$wStat}  {3,-$wLat}  {4}" `
        -f $r.Raw, $r.Addr, $statusText, $latStr, $r.HttpCode

    Write-Host $line -ForegroundColor $color
}

Write-Host $sepLine -ForegroundColor DarkGray
Write-Host ""

# ============================================================
# 汇总推荐
# ============================================================
$best = $results | Where-Object { $_.Latency -lt 9999 } | Select-Object -First 1
$aliveCount = @($results | Where-Object { $_.Latency -lt 9999 }).Count

if ($best) {
    Write-Host "  [BEST] 最低延迟节点: " -NoNewline -ForegroundColor Yellow
    Write-Host "$($best.Addr)" -NoNewline -ForegroundColor Cyan
    Write-Host "  ($($best.Latency) ms)" -ForegroundColor Green
    Write-Host "  [INFO] 在线节点数量: $aliveCount / $($results.Count)" -ForegroundColor DarkGreen
}
else {
    Write-Host "  [WARN] 所有节点均无响应！" -ForegroundColor Red
}

Write-Host ""
Write-Host "  [提示] 以上检测仅用于延迟展示，不会执行任何 irm 命令。" -ForegroundColor DarkGray
Write-Host ""
