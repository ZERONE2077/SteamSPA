# SteamSPA source module
# Edit this module, then run tools/build.ps1.

function Get-FakeLibraryHistoryClues {
    $historyPaths = New-Object System.Collections.Generic.List[string]

    try {
        $psReadLineOption = Get-PSReadLineOption -ErrorAction SilentlyContinue
        if ($psReadLineOption -and -not [string]::IsNullOrWhiteSpace($psReadLineOption.HistorySavePath)) {
            $historyPaths.Add($psReadLineOption.HistorySavePath)
        }
    }
    catch {
    }

    $fallbackPaths = @(
        (Join-Path $env:APPDATA 'Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt'),
        (Join-Path $env:APPDATA 'Microsoft\Windows\PowerShell\PSReadLine\Visual Studio Code Host_history.txt'),
        (Join-Path $env:APPDATA 'Microsoft\Windows\PowerShell\PSReadLine\Windows PowerShell ISE Host_history.txt')
    )
    foreach ($path in $fallbackPaths) {
        if (-not [string]::IsNullOrWhiteSpace($path)) {
            $historyPaths.Add($path)
        }
    }

    $suspiciousKeywords = @(
        'irm',
        'iwr',
        'iex',
        'Invoke-RestMethod',
        'Invoke-WebRequest',
        'steam.run',
        'steam.work',
        'cdk.ruku.run',
        'ruku.run',
        'steamcdkey.cn',
        'steamcn.cc',
        'SDL3_voder',
        'sdl3_setup',
        'csu_install',
        'vfc88.cn',
        'vfc77.cn',
        '121.41.99.14',
        'siyecao',
        'tfdl.net',
        'steamcdk',
        'steam-',
        'gitee.com',
        'githubusercontent.com',
        'lanzou',
        'lanzoui',
        'lanzoup',
        'Steamtools',
        'Stool'
    )

    $trustedPatterns = @(
        'raw.githubusercontent.com/ZERONE2077/SteamSPA',
        'cdn.jsdelivr.net/gh/ZERONE2077/SteamSPA'
    )

    $results = New-Object System.Collections.Generic.List[string]

    foreach ($historyPath in @($historyPaths | Select-Object -Unique)) {
        if ([string]::IsNullOrWhiteSpace($historyPath) -or -not (Test-Path -LiteralPath $historyPath)) {
            continue
        }

        $lines = @(Get-Content -LiteralPath $historyPath -Encoding UTF8 -ErrorAction SilentlyContinue)
        foreach ($line in $lines) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }

            $isSuspicious = $false
            foreach ($keyword in $suspiciousKeywords) {
                if ($line.IndexOf($keyword, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
                    $isSuspicious = $true
                    break
                }
            }
            if (-not $isSuspicious) { continue }

            $urlMatches = [regex]::Matches($line, '(?i)https?://[^\s''")<>|]+')
            if ($urlMatches.Count -gt 0) {
                foreach ($match in $urlMatches) {
                    $url = $match.Value.Trim()
                    $url = $url -replace '([?&](?:token|access_token|auth|key|pwd|password|sign|signature)=)[^&\s]+', '$1<redacted>'
                    $url = $url.TrimEnd('.', ',', ';')
                    $isTrusted = $false
                    foreach ($trustedPattern in $trustedPatterns) {
                        if ($url.IndexOf($trustedPattern, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
                            $isTrusted = $true
                            break
                        }
                    }
                    if ($isTrusted) { continue }
                    if (-not [string]::IsNullOrWhiteSpace($url)) {
                        $results.Add($url)
                    }
                }
                continue
            }

            $shortIrm = [regex]::Match($line, '(?i)\b(?:irm|iwr|Invoke-RestMethod|Invoke-WebRequest)\s+([A-Za-z0-9][A-Za-z0-9._:/-]{2,80})')
            if ($shortIrm.Success) {
                $results.Add(($shortIrm.Value -replace '\s+', ' ').Trim())
                continue
            }

            $trimmed = ($line -replace '\s+', ' ').Trim()
            if ($trimmed.Length -gt 140) {
                $trimmed = $trimmed.Substring(0, 137) + '...'
            }
            $results.Add($trimmed)
        }
    }

    return @($results | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
}

function Write-FakeLibraryHistoryClues {
    param([string[]]$Clues)

    if (-not $Clues -or $Clues.Count -eq 0) {
        return
    }

    Write-Section '🧭 历史线索'
    Write-Status '  发现以下可能的假入库脚本线索（仅本机显示，不会上传）：' WarningSoft
    $index = 1
    foreach ($clue in @($Clues)) {
        Write-Status ('    {0}. ' -f $index) Muted -NoNewline
        Write-Status $clue Path
        $index++
    }
    Write-Blank
}
