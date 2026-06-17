# CDK Steam Uninstall Script

$ErrorActionPreference = 'SilentlyContinue'

function Write-LargeGreen {
    param([string]$message)
    Write-Host ""
    Write-Host "[$message]" -ForegroundColor Green
    Write-Host ""
}

function Get-SteamPath {
    $steamPaths = @(
        "$env:ProgramFiles\Steam",
        "$env:ProgramFiles(x86)\Steam",
        "$env:LOCALAPPDATA\Steam",
        "$env:ProgramW6432Dir\Steam"
    )
    
    foreach ($path in $steamPaths) {
        if (Test-Path $path) {
            return $path
        }
    }
    return $null
}

Clear-Host
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "     CDK Steam Uninstall Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$steamPath = Get-SteamPath

if (-not $steamPath) {
    Write-Host "[!] Steam not found" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[*] Steam Path: $steamPath" -ForegroundColor Yellow

# 1. Stop steamcdk.exe process
Write-Host ""
Write-Host "[*] Stopping steamcdk.exe..." -ForegroundColor Cyan
Get-Process -Name "steamcdk" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Write-Host "[OK] Process stopped" -ForegroundColor Green

# 2. Delete steamcdk.exe
Write-Host ""
Write-Host "[*] Deleting steamcdk.exe..." -ForegroundColor Cyan
$appStorePath = Join-Path $steamPath "steamcdk.exe"
if (Test-Path $appStorePath) {
    Remove-Item -Path $appStorePath -Force
    Write-Host "[OK] steamcdk.exe deleted" -ForegroundColor Green
} else {
    Write-Host "[*] steamcdk.exe not found, skip" -ForegroundColor Yellow
}

# 3. Restore Steam config
Write-Host ""
Write-Host "[*] Restoring Steam config..." -ForegroundColor Cyan

# Restore loginusers.vdf - disable offline mode
try {
    $loginUsersPath = Join-Path $steamPath "config\loginusers.vdf"
    if (Test-Path $loginUsersPath) {
        $content = Get-Content $loginUsersPath -Encoding UTF8 -Raw
        $pattern = '("WantsOfflineMode"\s+)(")0(")'
        if ($content -match $pattern) {
            $newContent = $content -replace $pattern, '$11"'
            Set-Content -Path $loginUsersPath -Value $newContent -Encoding UTF8
            Write-Host "[OK] Offline mode restored" -ForegroundColor Green
        } else {
            Write-Host "[*] Offline mode setting unchanged" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "[!] Failed to restore loginusers.vdf" -ForegroundColor Red
}

# Restore config.vdf - re-enable shader cache
try {
    $configPath = Join-Path $steamPath "config\config.vdf"
    if (Test-Path $configPath) {
        $content = Get-Content $configPath -Encoding UTF8 -Raw
        $pattern = '("DisableShaderCache"\s+)(")1(")'
        if ($content -match $pattern) {
            $newContent = $content -replace $pattern, '$10"'
            Set-Content -Path $configPath -Value $newContent -Encoding UTF8
            Write-Host "[OK] Shader cache restored" -ForegroundColor Green
        } else {
            Write-Host "[*] Shader cache setting unchanged" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "[!] Failed to restore config.vdf" -ForegroundColor Red
}

# 4. Remove from Windows Defender exclusions
Write-Host ""
Write-Host "[*] Removing Windows Defender exclusions..." -ForegroundColor Cyan
try {
    if (Get-Service | Where-Object { $_.Name -eq "WinDefend" -and $_.Status -eq "Running" }) {
        $currentExclusions = Get-MpPreference | Select-Object -ExpandProperty ExclusionPath
        if ($currentExclusions -contains $steamPath) {
            Remove-MpPreference -ExclusionPath $steamPath -ErrorAction SilentlyContinue
            Write-Host "[OK] Removed from exclusion path" -ForegroundColor Green
        }
        
        $extExclusions = Get-MpPreference | Select-Object -ExpandProperty ExclusionExtension
        if ($extExclusions -contains "exe") {
            Remove-MpPreference -ExclusionExtension "exe" -ErrorAction SilentlyContinue
            Write-Host "[OK] Removed exe extension exclusion" -ForegroundColor Green
        }
        if ($extExclusions -contains "dll") {
            Remove-MpPreference -ExclusionExtension "dll" -ErrorAction SilentlyContinue
            Write-Host "[OK] Removed dll extension exclusion" -ForegroundColor Green
        }
    } else {
        Write-Host "[*] Windows Defender not running" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[!] Failed to remove exclusions (need admin)" -ForegroundColor Yellow
}

# Done
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-LargeGreen "Uninstall Complete!"
Write-Host "Steam config restored, steamcdk.exe cleaned" -ForegroundColor White
Write-Host "Please restart Steam to apply changes" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Read-Host "Press Enter to exit"
