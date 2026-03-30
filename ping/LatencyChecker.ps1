# 强制使用 UTF8 编码处理输出
$OutputEncoding = [System.Text.Encoding]::UTF8

# 1. 定义节点列表
$nodes = @(
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

Write-Host "`n[Scanner] Scanning node latency... (Parallel Mode)" -ForegroundColor Cyan
Write-Host "--------------------------------------------------"

# 2. 并行执行 Ping 测试 (需 PowerShell 7+ 性能更佳，系统自带 5.1 亦可兼容)
$results = $nodes | ForEach-Object -Parallel {
    $target = $_
    $res = [PSCustomObject]@{
        Target  = $target
        Latency = 9999
        Status  = "[-] DOWN"
    }

    try {
        # 发送 1 个包，超时时间 1 秒
        $ping = Test-Connection -ComputerName $target -Count 1 -ErrorAction SilentlyContinue
        if ($null -ne $ping) {
            $res.Latency = $ping.ResponseTime
            $res.Status = "[+] LIVE"
        }
    }
    catch { }
    
    $res # 返回对象
} | Sort-Object Latency

# 3. 格式化输出结果
foreach ($r in $results) {
    $color = if ($r.Status -eq "[+] LIVE") { "Green" } else { "Red" }
    $latencyStr = if ($r.Latency -eq 9999) { "TIMEOUT" } else { "$($r.Latency)ms" }
    
    Write-Host ("{0,-10} | {1,-20} | {2}" -f $r.Status, $r.Target, $latencyStr) -ForegroundColor $color
}

Write-Host "--------------------------------------------------"
$best = $results | Where-Object { $_.Latency -lt 9999 } | Select-Object -First 1

if ($best) {
    Write-Host "RECOMMENDED: $($best.Target) ($($best.Latency)ms)" -ForegroundColor Cyan
}
else {
    Write-Host "ALERT: No active nodes detected!" -ForegroundColor Yellow
}
Write-Host ""