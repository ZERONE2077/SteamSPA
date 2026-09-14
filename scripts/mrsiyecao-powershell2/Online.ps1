try {
    $appIdKey = "app_id"
    $lobbyIdKey = "lobby_id"
    $regValues = Get-ItemProperty -Path "HKCU:\Software\Valve\Steamtools" -ErrorAction Stop
    if (-not $regValues.PSObject.Properties[$appIdKey]) {
        throw "游戏未启动,请先启动游戏并创建大厅/房间"
    }
    $appId = $regValues.$appIdKey
    if (-not $regValues.PSObject.Properties[$lobbyIdKey]) {
        throw "未创建大厅/房间"
    }
    $lobbyId = $regValues.$lobbyIdKey
    $steamLink = "steam://run/$appId//+connect_lobby%20$lobbyId"
    Write-Host $steamLink -ForegroundColor Cyan
    $steamLink | Set-Clipboard
}
catch {
    Write-Host "错误: $_" -ForegroundColor Red
}