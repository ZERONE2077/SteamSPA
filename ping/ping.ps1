$servers = @(
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

$bestServer = $null
$lowestLatency = [int]::MaxValue

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "正在测速各节点并寻找最优线路，请稍等..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

foreach ($server in $servers) {
    # 使用 Windows 自带的 ping.exe，这样能完美解析如 2526944756 这种纯数字格式的 IP 
    # -n 1 表示只发送 1 个数据包，-w 1000 表示超时时间为 1000 毫秒（1秒）
    $result = ping.exe -n 1 -w 1000 $server 2>&1 | Out-String
    
    # 匹配中文系统的 "时间=xxms" 或 "时间<1ms"，以及英文系统的 "time=xxms" 或 "time<1ms"
    if ($result -match "(?:时间|time)[=<](\d+)\s*ms") {
        $latency = [int]$matches[1]
        Write-Host "节点 [$server] 的延迟为: ${latency}ms" -ForegroundColor Green
        
        if ($latency -lt $lowestLatency) {
            $lowestLatency = $latency
            $bestServer = $server
        }
    }
    else {
        Write-Host "节点 [$server] 超时或无法连通" -ForegroundColor DarkGray
    }
}

Write-Host "----------------------------------------" -ForegroundColor Cyan

if ($bestServer) {
    Write-Host "[测试完成] 最优节点为: $bestServer (延迟: ${lowestLatency}ms)" -ForegroundColor Green
    Write-Host "即将自动执行提速命令: irm $bestServer | iex" -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    
    try {
        # 直接执行选出的最优节点的装载命令
        Invoke-Expression "irm $bestServer | iex"
    }
    catch {
        Write-Host "执行命令时发生错误: $_" -ForegroundColor Red
    }
}
else {
    Write-Host "网络异常：所有节点均无法访问，请检查您的网络连接！" -ForegroundColor Red
}
