#requires -Version 5.1
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$rulesPath=Join-Path $root 'data\rules.json'
$artifact=Join-Path $root 'uninstall.ps1'
$versionPath=Join-Path $root 'data\\version.json'
$rules=Get-Content -LiteralPath $rulesPath -Raw -Encoding UTF8|ConvertFrom-Json
$version=Get-Content -LiteralPath $versionPath -Raw -Encoding UTF8|ConvertFrom-Json
if([string]::IsNullOrWhiteSpace([string]$version.version)){throw 'version.json: missing version'}
if([string]::IsNullOrWhiteSpace([string]$version.updatedAt)){throw 'version.json: missing updatedAt'}
if($rules.version -lt 1){throw 'rules.json: invalid version'}
$ids=@($rules.rules|ForEach-Object{$_.id})
if($ids.Count -ne (@($ids|Select-Object -Unique)).Count){throw 'rules.json: duplicate rule id'}
$validRisks=@('low','medium','high')
foreach($rule in @($rules.rules)){
  if([string]::IsNullOrWhiteSpace($rule.id)){throw 'rules.json: rule id is empty'}
  if($rule.risk -notin $validRisks){throw "rules.json: invalid risk $($rule.risk)"}
  if(-not $rule.actions -or @($rule.actions).Count -eq 0){throw "rules.json: rule $($rule.id) has no actions"}
}
$files=@($artifact)+@('src\00-bootstrap.ps1','src\10-ui.ps1','src\20-environment.ps1','src\30-detection.ps1','src\40-cleanup.ps1','src\50-report.ps1','src\60-history.ps1','src\90-main.ps1')
foreach($file in $files){
  $path=Join-Path $root $file
  $tokens=$null;$errors=$null
  [System.Management.Automation.Language.Parser]::ParseFile($path,[ref]$tokens,[ref]$errors)|Out-Null
  if($errors.Count -gt 0){throw "PowerShell parse failed: $file"}
}
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'tools\build.ps1') -Check
if($LASTEXITCODE -ne 0){exit $LASTEXITCODE}
Write-Host ("SteamSPA validation passed: {0} rules."-f $ids.Count)
