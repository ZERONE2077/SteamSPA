#requires -Version 5.1
# 抓取假入库脚本样本：按原始字节保存，并记录响应头和编码信息。只下载，不运行。
#   tools/fetch-sample.ps1                       抓默认列表里的全部入口
#   tools/fetch-sample.ps1 vfc88.cn steamcn.cc   只抓指定入口（可不写 http://，和 irm 一样）
# 结果在 research/samples/<主机>/（research 已被 .gitignore 排除，不会推到 GitHub）：
#   <主机>.<日期>.ps1        服务器返回的原始字节
#   <主机>.<日期>.meta.txt   地址、状态码、Content-Type、SHA256、BOM、编码判断
# 内容和上一次抓到的完全相同时不重复保存。
# 杀软可能在下载后立刻隔离样本，需要的话先给 research 目录加排除项。
[CmdletBinding()]
param(
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$Url,
    [string]$OutDir
)

$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = $utf8
try { [Console]::OutputEncoding = $utf8 } catch {}
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$root = Split-Path -Parent $PSScriptRoot
if (-not $OutDir) { $OutDir = Join-Path $root 'research\samples' }

if (-not $Url) {
    $Url = @(
        'steam-run.com', 'steamcdkey.cn', 'steam.run', 'cdks.run',
        'steam.icu', 'steam.work', 'steamcn.cc', 'steamfn.com',
        'vfc88.cn', 'ss.vfc77.cn', 'cdk.ruku.run',
        '47.100.121.251', '47.98.148.132', '118.178.88.163', '150.158.29.244'
    )
}

function Get-EncodingInfo([byte[]]$Bytes, [string]$ContentType) {
    $bom = '无'
    if ($Bytes.Length -ge 3 -and $Bytes[0] -eq 0xEF -and $Bytes[1] -eq 0xBB -and $Bytes[2] -eq 0xBF) { $bom = 'UTF-8 BOM' }
    elseif ($Bytes.Length -ge 2 -and $Bytes[0] -eq 0xFF -and $Bytes[1] -eq 0xFE) { $bom = 'UTF-16LE BOM' }
    elseif ($Bytes.Length -ge 2 -and $Bytes[0] -eq 0xFE -and $Bytes[1] -eq 0xFF) { $bom = 'UTF-16BE BOM' }

    $asciiOnly = $true
    foreach ($b in $Bytes) { if ($b -ge 0x80) { $asciiOnly = $false; break } }

    $validUtf8 = $true
    $strict = New-Object System.Text.UTF8Encoding($false, $true)
    try { $null = $strict.GetString($Bytes) } catch { $validUtf8 = $false }

    $charset = ''
    $m = [regex]::Match([string]$ContentType, 'charset\s*=\s*"?([^";\s]+)', 'IgnoreCase')
    if ($m.Success) { $charset = $m.Groups[1].Value }

    # PS 5.1 的 irm/iwr：有 charset 按 charset 解码，没有时按 ISO-8859-1 解码。
    if ($asciiOnly) { $verdict = '全是 ASCII，irm | iex 不会乱码' }
    elseif ($charset -match '^utf-?8$') { $verdict = '服务器声明了 UTF-8，PS 5.1 irm 中文正常' }
    elseif ($charset) { $verdict = "服务器声明 charset=$charset，PS 5.1 irm 按它解码" }
    elseif ($bom -ne '无') { $verdict = "没有 charset，但有 $bom，PS 5.1 irm 结果未验证" }
    else { $verdict = '没有 charset，PS 5.1 irm 按 ISO-8859-1 解码，中文会乱码' }

    [pscustomobject]@{
        Bom       = $bom
        AsciiOnly = $asciiOnly
        ValidUtf8 = $validUtf8
        Charset   = $charset
        Verdict   = $verdict
    }
}

foreach ($u in $Url) {
    if ($u -notmatch '^[a-z]+://') { $u = 'http://' + $u }
    $hostName = ([Uri]$u).Host
    $dir = Join-Path $OutDir $hostName
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $stamp = (Get-Date).ToString('yyyy-MM-dd')
    $base = Join-Path $dir "$hostName.$stamp"
    if (Test-Path -LiteralPath "$base.ps1") { $base = Join-Path $dir ("$hostName.$stamp-" + (Get-Date).ToString('HHmmss')) }
    $file = "$base.ps1"
    $tmp = "$base.download"

    Write-Host "==> $u" -ForegroundColor Cyan
    $meta = New-Object System.Collections.Generic.List[string]
    $meta.Add("URL: $u")
    $meta.Add('抓取时间: ' + (Get-Date).ToString('yyyy-MM-dd HH:mm:ss zzz'))
    try {
        # 用 iwr 默认 UA，和 irm 一致；有的站点按 UA 分流。
        $resp = Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 30 -OutFile $tmp -PassThru
        $ct = [string]$resp.Headers['Content-Type']
        $meta.Add('最终地址: ' + $resp.BaseResponse.ResponseUri)
        $meta.Add('状态码: ' + [int]$resp.StatusCode)
        $meta.Add("Content-Type: $ct")
        $meta.Add('Server: ' + [string]$resp.Headers['Server'])
    } catch {
        $r = $_.Exception.Response
        if ($r) {
            $meta.Add('状态码: ' + [int]$r.StatusCode)
            $meta.Add('Content-Type: ' + $r.ContentType)
            $meta.Add('最终地址: ' + $r.ResponseUri)
        }
        $meta.Add('错误: ' + $_.Exception.Message)
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
        [IO.File]::WriteAllLines("$base.meta.txt", $meta, $utf8)
        Write-Host ('    失败：' + $_.Exception.Message) -ForegroundColor Red
        continue
    }

    if (-not (Test-Path -LiteralPath $tmp)) {
        Write-Host '    下载后文件不见了，可能被杀软隔离' -ForegroundColor Yellow
        continue
    }
    $hash = (Get-FileHash -LiteralPath $tmp -Algorithm SHA256).Hash
    $same = Get-ChildItem -LiteralPath $dir -Filter '*.ps1' -ErrorAction SilentlyContinue |
        Where-Object { (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash -eq $hash } |
        Select-Object -First 1
    if ($same) {
        Remove-Item -LiteralPath $tmp -Force
        Write-Host "    和 $($same.Name) 完全相同，未保存" -ForegroundColor DarkGray
        continue
    }
    Move-Item -LiteralPath $tmp -Destination $file

    $bytes = [IO.File]::ReadAllBytes($file)
    $info = Get-EncodingInfo $bytes $ct
    $meta.Add("大小: $($bytes.Length) 字节")
    $meta.Add("SHA256: $hash")
    $meta.Add("BOM: $($info.Bom)")
    $meta.Add("charset: $(if ($info.Charset) { $info.Charset } else { '（未声明）' })")
    $meta.Add("全 ASCII: $($info.AsciiOnly)")
    $meta.Add("合法 UTF-8: $($info.ValidUtf8)")
    $meta.Add("判断: $($info.Verdict)")
    [IO.File]::WriteAllLines("$base.meta.txt", $meta, $utf8)

    Write-Host ("    已保存 {0}（{1} 字节）" -f (Split-Path -Leaf $file), $bytes.Length) -ForegroundColor Green
    Write-Host "    Content-Type: $ct | BOM: $($info.Bom) | $($info.Verdict)"
}
