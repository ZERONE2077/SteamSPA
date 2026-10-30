#requires -Version 5.1
# SteamSPA 冒烟测试：语法、生成物一致性、规则库、纯函数单测、生成物只扫描运行。
# 全程只读，不会删除任何东西。
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$failures = New-Object System.Collections.Generic.List[string]

function Assert {
    param([bool]$Condition, [string]$Name)
    if ($Condition) { Write-Host ('  ok    ' + $Name) }
    else { Write-Host ('  FAIL  ' + $Name) -ForegroundColor Red; $failures.Add($Name) }
}

Write-Host '== 语法'
$files = @(Get-ChildItem -LiteralPath (Join-Path $root 'src') -Filter '*.ps1') + @(Get-Item -LiteralPath (Join-Path $root 'uninstall.ps1'))
foreach ($file in $files) {
    $tokens = $null; $errors = $null
    [Management.Automation.Language.Parser]::ParseInput([IO.File]::ReadAllText($file.FullName, [Text.Encoding]::UTF8), [ref]$tokens, [ref]$errors) | Out-Null
    Assert ($errors.Count -eq 0) ('parse ' + $file.Name + $(if ($errors.Count) { ': ' + $errors[0].Message }))
}

Write-Host '== 生成物'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'tools\build.ps1') -Check | Out-Null
Assert ($LASTEXITCODE -eq 0) 'uninstall.ps1 与源码一致'
$bytes = [IO.File]::ReadAllBytes((Join-Path $root 'uninstall.ps1'))
Assert ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) 'uninstall.ps1 带 UTF-8 BOM'

# 加载模块（只定义函数，没有副作用）
$Spa = @{ Ui = $null; Defender = $null; Tasks = $null; Warnings = New-Object System.Collections.Generic.List[string] }
foreach ($module in @(Get-ChildItem -LiteralPath (Join-Path $root 'src') -Filter '*.ps1' | Where-Object { $_.Name -ne '90-main.ps1' })) {
    . ([scriptblock]::Create([IO.File]::ReadAllText($module.FullName, [Text.Encoding]::UTF8)))
}

Write-Host '== 规则库'
$db = [IO.File]::ReadAllText((Join-Path $root 'data\rules.json'), [Text.Encoding]::UTF8) | ConvertFrom-Json
$ids = @($db.rules | ForEach-Object { $_.id })
Assert ($ids.Count -gt 0) ('规则数量 ' + $ids.Count)
Assert ($ids.Count -eq @($ids | Select-Object -Unique).Count) '规则 ID 不重复'
$supported = Get-SpaSupportedTypes
foreach ($rule in $db.rules) {
    $ok = $rule.id -and (@('low', 'medium', 'high') -contains $rule.risk) -and @($rule.actions).Count -gt 0
    $badTypes = @($rule.actions | Where-Object { $supported -notcontains $_.type } | ForEach-Object { $_.type })
    Assert ($ok -and $badTypes.Count -eq 0) ('规则 ' + $rule.id + $(if ($badTypes) { ' 不支持的类型: ' + ($badTypes -join ',') }))
}

Write-Host '== 单元'
$vars = @{ SteamPath = 'C:\Steam'; APPDATA = 'C:\Users\u\AppData\Roaming'; TEMP = 'C:\T' }
Assert ((Resolve-SpaTemplate '${SteamPath}\hid.dll' $vars) -eq 'C:\Steam\hid.dll') '模板展开'
Assert ($null -eq (Resolve-SpaTemplate '${SteamPath}\hid.dll' @{ SteamPath = $null })) '变量缺失时返回空，不拼残缺路径'
Assert ($null -eq (Resolve-SpaTemplate '%SPA_NO_SUCH_VAR%\x' @{})) '未知环境变量返回空'
Assert ($null -eq (Get-SpaUnsafePathReason 'C:\Steam\hid.dll' $vars)) '允许删除 STEAM 根目录下的文件'
Assert ($null -ne (Get-SpaUnsafePathReason 'C:\Steam' $vars)) '拒绝 STEAM 根目录本身'
Assert ($null -ne (Get-SpaUnsafePathReason 'C:\Steam\steamapps\common\Game' $vars)) '拒绝游戏目录'
Assert ($null -ne (Get-SpaUnsafePathReason 'C:\Steam\userdata\1\remote' $vars)) '拒绝存档目录'
Assert ($null -ne (Get-SpaUnsafePathReason '\hid.dll' $vars)) '拒绝相对路径'
Assert ($null -ne (Get-SpaUnsafePathReason 'D:\' $vars)) '拒绝磁盘根目录'
Assert ($null -ne (Get-SpaUnsafePathReason $env:APPDATA $vars)) '拒绝 APPDATA 根目录'

$o = ConvertFrom-SpaArguments @('-Risk', 'low,high', '-Only', 'a,b', '-NoBackup')
Assert ((($o.Risk -join ',') -eq 'low,high') -and (($o.Only -join ',') -eq 'a,b') -and $o.NoBackup -and $o.Errors.Count -eq 0) '参数解析'
Assert ((ConvertFrom-SpaArguments @('-Risk', 'extreme')).Errors.Count -eq 1) '非法风险级别报错'
Assert ((ConvertFrom-SpaArguments @('-Bogus')).Errors.Count -eq 1) '未知参数报错'
Assert (((ConvertTo-SpaArgumentList $o) -join ' ') -eq '-Risk low,high -Only a,b -NoBackup') '参数还原（提权重启用）'

$clues = @(Find-SpaHistoryClues @(
        'git commit -m "confirm fix"',
        'irm https://steam.run/x.ps1 | iex',
        'iex (irm https://steamfn.com/a.ps1?token=abc)',
        'irm cdks.run|iex',
        'irm https://claude.ai/install.ps1 | iex',
        'start https://store.steampowered.com/app/1',
        'irm https://raw.githubusercontent.com/ZERONE2077/SteamSPA/main/uninstall.ps1 | iex',
        'Get-ChildItem'))
Assert ($clues.Count -eq 3) ('历史线索命中 3 条（实际 ' + $clues.Count + ': ' + ($clues -join ' ; ') + '）')
Assert ($clues -contains 'https://steamfn.com/a.ps1?token=***') '历史线索脱敏 token'
Assert ((Get-DisplayWidth '中a') -eq 3) '中文显示宽度'

Write-Host '== 沙盒：备份 -> 删除 -> 恢复（临时目录 + HKCU 测试键）'
$sandbox = Join-Path $env:TEMP ('SteamSPA-test-' + [guid]::NewGuid().ToString('N'))
$fakeSteam = Join-Path $sandbox 'Steam'
$regKey = 'HKCU:\Software\SteamSPA-SmokeTest'
try {
    New-Item -ItemType Directory -Force -Path (Join-Path $fakeSteam 'Core') | Out-Null
    [IO.File]::WriteAllText((Join-Path $fakeSteam 'hid.dll'), 'fake')
    [IO.File]::WriteAllText((Join-Path $fakeSteam 'Core\a.txt'), 'a')
    New-Item -Path $regKey -Force | Out-Null
    New-ItemProperty -Path $regKey -Name 'iscdkey' -Value '1' -Force | Out-Null
    New-Item -Path ($regKey + '\Sub') -Force | Out-Null

    $sv = @{ SteamPath = $fakeSteam }
    $targets = @(
        Find-SpaActionTargets ([pscustomobject]@{ type = 'file'; path = '${SteamPath}\hid.dll' }) $sv
        Find-SpaActionTargets ([pscustomobject]@{ type = 'file'; path = '${SteamPath}\Core'; recurse = $true }) $sv
        Find-SpaActionTargets ([pscustomobject]@{ type = 'file'; path = '${SteamPath}\missing.dll' }) $sv
        Find-SpaActionTargets ([pscustomobject]@{ type = 'registry-value'; path = $regKey; name = 'iscdkey' }) $sv
    )
    Assert ($targets.Count -eq 3) ('找到 3 个目标（实际 ' + $targets.Count + '）')

    $keyTarget = Find-SpaActionTargets ([pscustomobject]@{ type = 'registry-key'; path = $regKey }) $sv
    $backup = New-SpaBackup -Enabled $true
    $backup.Root = Join-Path $sandbox 'backup'
    Remove-SpaTarget -Target $keyTarget -Backup $backup -Variables $sv
    Assert ($keyTarget.Status -eq 'skipped' -and (Test-Path $regKey)) '有子项且未允许递归的注册表项不删'

    foreach ($t in $targets) { Remove-SpaTarget -Target $t -Backup $backup -Variables $sv }
    Assert (@($targets | Where-Object { $_.Status -ne 'removed' }).Count -eq 0) ('全部删除成功 ' + (($targets | ForEach-Object { $_.Status + ':' + $_.Message }) -join ','))
    Assert (-not (Test-Path (Join-Path $fakeSteam 'hid.dll')) -and -not (Test-Path (Join-Path $fakeSteam 'Core'))) '文件和目录已删除'
    Assert ($null -eq (Get-ItemProperty -LiteralPath $regKey -Name 'iscdkey' -ErrorAction SilentlyContinue)) '注册表值已删除'

    $SteamSPAReleaseVersion = 'test'
    $backupPath = Complete-SpaBackup -Backup $backup
    Assert ((Test-Path (Join-Path $backupPath 'manifest.json')) -and (Test-Path (Join-Path $backupPath 'restore.ps1'))) '生成 manifest.json 和 restore.ps1'

    '' | & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $backupPath 'restore.ps1') | Out-Null
    Assert ((Test-Path (Join-Path $fakeSteam 'hid.dll')) -and (Test-Path (Join-Path $fakeSteam 'Core\a.txt'))) 'restore.ps1 恢复文件和目录'
    Assert ($null -ne (Get-ItemProperty -LiteralPath $regKey -Name 'iscdkey' -ErrorAction SilentlyContinue)) 'restore.ps1 恢复注册表值'
}
finally {
    Remove-Item -LiteralPath $sandbox -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $regKey -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host '== 生成物只扫描运行'
$out = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'uninstall.ps1') -ScanOnly -NoPause 2>&1 | Out-String
Assert ($LASTEXITCODE -eq 0) ('-ScanOnly 退出码 0（实际 ' + $LASTEXITCODE + '）')
Assert ($out -match '扫描完成') '-ScanOnly 输出包含"扫描完成"'
$out = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'uninstall.ps1') -Bogus -NoPause 2>&1 | Out-String
Assert ($LASTEXITCODE -eq 2) '错误参数退出码 2'

Write-Host ''
if ($failures.Count -gt 0) {
    Write-Host ('{0} 项失败' -f $failures.Count) -ForegroundColor Red
    exit 1
}
Write-Host ('SteamSPA validation passed: {0} rules.' -f $ids.Count) -ForegroundColor Green
