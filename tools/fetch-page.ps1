Param(
    [Parameter(Mandatory)][string]$Url,
    [string]$OutFile
)

# 抓取落地页 / irm 首段内容，供人工核对用。不是假入库样本，别把它当样本扫。
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8

if ([string]::IsNullOrWhiteSpace($OutFile)) {
    $name = ($Url -replace '^https?://', '' -replace '[^\w\.\-]', '_') + '.html'
    $OutFile = Join-Path $PSScriptRoot $name
}

Write-Host "Downloading $Url -> $OutFile" -ForegroundColor Cyan
try {
    $resp = Invoke-RestMethod -Uri $Url -ErrorAction Stop
    if ($resp -is [string]) {
        $resp | Out-File -FilePath $OutFile -Encoding utf8
    } else {
        $resp | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutFile -Encoding utf8
    }
    Write-Host "Saved to $OutFile" -ForegroundColor Green
} catch {
    Write-Host "下载失败: $_" -ForegroundColor Red
    exit 1
}
