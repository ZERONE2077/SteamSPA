# SteamSPA · PowerShell 历史线索
# 只在本机显示，不上传，也不作为删除依据。

function Get-SpaHistoryLines {
    $files = @()
    try {
        $option = Get-PSReadLineOption -ErrorAction Stop
        if ($option.HistorySavePath) { $files += $option.HistorySavePath }
    }
    catch {}
    $dir = Join-Path $env:APPDATA 'Microsoft\Windows\PowerShell\PSReadLine'
    if (Test-Path -LiteralPath $dir) {
        $files += @(Get-ChildItem -LiteralPath $dir -Filter '*_history.txt' -File -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
    }

    $lines = @()
    foreach ($file in @($files | Select-Object -Unique)) {
        if (Test-Path -LiteralPath $file -PathType Leaf) {
            $lines += @(Get-Content -LiteralPath $file -Encoding UTF8 -ErrorAction SilentlyContinue)
        }
    }
    return $lines
}

# 一行算线索的条件（任一）：
#   1. 命中已知假入库域名/IP/文件特征；
#   2. 出现非 Valve 官方的 steam*.xxx 域名（steamfn.com、steamcc.cn 这类）；
#   3. "下载并直接执行"且目标是不带 https:// 的裸域名/IP（irm xxx.run | iex 是假入库的典型写法，
#      正规安装命令一般是完整 https 地址，不算线索）。
# 只命中 irm 之类的单词不算（"confirm" 里也有 irm）。
function Find-SpaHistoryClues {
    param([string[]]$Lines, [int]$Limit = 15)

    $indicators = @(
        'steam.run', 'steam.work', 'steam.icu', 'steam-run.com', 'cdks.run', 'ruku.run', 'steamcdkey.cn',
        'steamcn.cc', 'steamcc.cn', 'vfc88.cn', 'vfc77.cn', 'tfdl.net', 'siyecao', 'wanzi666', 'kyeamu',
        '121.41.99.14', '139.196.146.200', '47.100.121.251', '47.98.148.132', 'opensteamtool',
        'keymanifest', 'SdkoInjector', 'sdko.dll', 'SDL3_voder', 'sdl3_setup', 'csu_install', 'CSU_DIVA_HOST',
        'steamcdk', 'Steamtools', 'lanzou'
    )
    $trusted = @('ZERONE2077/SteamSPA')
    $steamDomain = '\bsteam[\w-]*\.(run|cn|cc|icu|work|top|xyz|com|net|vip|fun|site|shop)\b'
    $valveDomain = '\bsteam(powered|community|static|content|games|usercontent|server)\.(com|net)\b'
    $netCommand = '\b(irm|iwr|Invoke-RestMethod|Invoke-WebRequest|curl|wget|iex|Invoke-Expression|DownloadString|DownloadFile|Start-BitsTransfer)\b|https?://'
    $bareFetch ='\b(irm|iwr|Invoke-RestMethod|Invoke-WebRequest)\s+["'']?(?!https?://)[\w-]+(\.[\w-]+)+'

    $clues = New-Object System.Collections.Generic.List[string]
    foreach ($line in @($Lines)) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $isTrusted = $false
        foreach ($t in $trusted) { if ($line.IndexOf($t, [StringComparison]::OrdinalIgnoreCase) -ge 0) { $isTrusted = $true } }
        if ($isTrusted) { continue }

        # 只看"联网/执行"类命令，避免 Move-Item D:\Dev\SteamCDK 这种普通文件操作被当成线索。
        if ($line -notmatch $netCommand) { continue }
        $hit = ($line -match $bareFetch) -or (($line -replace $valveDomain, '') -match $steamDomain)
        if (-not $hit) {
            foreach ($i in $indicators) {
                if ($line.IndexOf($i, [StringComparison]::OrdinalIgnoreCase) -ge 0) { $hit = $true; break }
            }
        }
        if (-not $hit) { continue }

        $urls = @([regex]::Matches($line, '(?i)https?://[^\s''"()<>|;“”‘’，]+') | ForEach-Object { $_.Value.TrimEnd('.', ',') })
        if ($urls.Count -gt 0) {
            foreach ($url in $urls) {
                $clues.Add(($url -replace '(?i)([?&](token|access_token|auth|key|pwd|password|sign|signature)=)[^&]+', '$1***'))
            }
        }
        else {
            $text = ($line -replace '\s+', ' ').Trim()
            if ($text.Length -gt 120) { $text = $text.Substring(0, 117) + '...' }
            $clues.Add($text)
        }
    }

    # 历史文件按时间顺序追加，保留最近的若干条。
    $unique = @($clues | Select-Object -Unique)
    if ($unique.Count -gt $Limit) { $unique = $unique[($unique.Count - $Limit)..($unique.Count - 1)] }
    return $unique
}
