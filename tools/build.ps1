#requires -Version 5.1
[CmdletBinding()]
param([switch]$Check,[string]$OutputPath)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
if([string]::IsNullOrWhiteSpace($OutputPath)){$OutputPath=Join-Path $root 'uninstall.ps1'}
$dataPath=Join-Path $root 'data\rules.json'
if(-not(Test-Path -LiteralPath $dataPath)){throw "Missing rule database: $dataPath"}
$rules=Get-Content -LiteralPath $dataPath -Raw -Encoding UTF8|ConvertFrom-Json
if(-not $rules.rules -or @($rules.rules).Count -eq 0){throw 'Rule database contains no rules.'}
$sourceFiles=@('src\00-bootstrap.ps1','src\10-ui.ps1','src\20-environment.ps1','src\30-detection.ps1','src\40-cleanup.ps1','src\50-report.ps1','src\60-history.ps1','src\90-main.ps1')
foreach($file in $sourceFiles){if(-not(Test-Path -LiteralPath(Join-Path $root $file))){throw "Missing source file: $file"}}
$nl=[Environment]::NewLine
$bootstrap=Get-Content -LiteralPath(Join-Path $root $sourceFiles[0])-Raw-Encoding UTF8
$modules=($sourceFiles[1..6]|ForEach-Object{Get-Content -LiteralPath(Join-Path $root $_)-Raw-Encoding UTF8})-join $nl
$main=Get-Content -LiteralPath(Join-Path $root $sourceFiles[7])-Raw-Encoding UTF8
$rulesText=Get-Content -LiteralPath $dataPath -Raw -Encoding UTF8
$content=$bootstrap.TrimEnd()+$nl+$nl
$content+='# Embedded rule database. Source of truth: data/rules.json'+$nl
$content+='$EmbeddedTargetsJson = @'''+$nl+$rulesText.TrimEnd()+$nl+'@'+$nl+$nl
$content+=$modules.Trim()+$nl+$nl+'# Application entry point'+$nl+$main.Trim()+$nl
$utf8=New-Object System.Text.UTF8Encoding($false)
if($Check){
  if(-not(Test-Path -LiteralPath $OutputPath)){Write-Error 'uninstall.ps1 is missing';exit 1}
  $existing=[IO.File]::ReadAllText($OutputPath,$utf8)
  if($existing -ne $content){Write-Error 'uninstall.ps1 is out of date. Run tools/build.ps1';exit 1}
  Write-Host 'SteamSPA build is up to date.';exit 0
}
[IO.Directory]::CreateDirectory((Split-Path -Parent $OutputPath))|Out-Null
[IO.File]::WriteAllText($OutputPath,$content,$utf8)
Write-Host ("Built {0} ({1:N0} bytes)"-f $OutputPath,(Get-Item -LiteralPath $OutputPath).Length)
