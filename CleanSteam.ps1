#Requires -RunAsAdministrator
Clear-Host
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Steam Modification Cleanup Tool" -ForegroundColor Cyan
Write-Host "  Supports: steam-icu.ps1, steam-run.ps1, cdks-run.ps1" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check admin privileges
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
    Write-Host "[ERROR] Please run as Administrator" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

Write-Host "[INFO] Locating Steam installation..." -ForegroundColor Yellow

# Get Steam path
$steamRegPath = 'HKCU:\Software\Valve\Steam'
try {
    $steamPath = (Get-ItemProperty -Path $steamRegPath -ErrorAction Stop).SteamPath
    Write-Host "[SUCCESS] Steam path: $steamPath" -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] Steam installation not found" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

# Stop Steam processes
Write-Host ""
Write-Host "[INFO] Stopping Steam processes..." -ForegroundColor Yellow
$steamProcesses = Get-Process -Name "steam*" -ErrorAction SilentlyContinue
if ($steamProcesses) {
    $steamProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Write-Host "[SUCCESS] Steam processes stopped" -ForegroundColor Green
}
else {
    Write-Host "[INFO] No running Steam processes found" -ForegroundColor Gray
}

# Files to delete from Steam directory
Write-Host ""
Write-Host "[INFO] Cleaning modified files in Steam directory..." -ForegroundColor Yellow

$filesToDelete = @(
    # Common files modified by all scripts
    "steam.cfg",
    "version.dll",
    "user32.dll",
    "wtsapi32.dll",
    "dwmapi.dll",
    
    # Files from steam-icu.ps1 and cdks-run.ps1
    "xinput1_4.dll",
    "xinput1_4.dll.old",
    
    # Files from steam-run.ps1 (64-bit)
    "xinput1_4.log",
    
    # Files from steam-run.ps1 (32-bit)
    "hid.dll",
    "hid.log",
    "zlib1.dll",
    "zlib1.log",
    
    # Package files
    "package\beta",
    "appcache\packageinfo.vdf"
)

$deletedCount = 0
foreach ($file in $filesToDelete) {
    $filePath = Join-Path $steamPath $file
    if (Test-Path $filePath) {
        try {
            Remove-Item -Path $filePath -Force -Recurse -ErrorAction Stop
            Write-Host "  [DELETED] $file" -ForegroundColor Green
            $deletedCount++
        }
        catch {
            Write-Host "  [FAILED] Cannot delete $file" -ForegroundColor Red
        }
    }
}

# Delete config files (appdata.vdf)
Write-Host ""
Write-Host "[INFO] Cleaning configuration files..." -ForegroundColor Yellow

$configFiles = @(
    "config\appdata.vdf",
    "appcache\appdata.vdf"
)

foreach ($file in $configFiles) {
    $filePath = Join-Path $steamPath $file
    if (Test-Path $filePath) {
        try {
            Remove-Item -Path $filePath -Force -ErrorAction Stop
            Write-Host "  [DELETED] $file" -ForegroundColor Green
            $deletedCount++
        }
        catch {
            Write-Host "  [FAILED] Cannot delete $file" -ForegroundColor Red
        }
    }
}

if ($deletedCount -eq 0) {
    Write-Host "  [INFO] No files to clean in Steam directory" -ForegroundColor Gray
}
else {
    Write-Host "  [DONE] Deleted $deletedCount files from Steam directory" -ForegroundColor Green
}

# Clean registry modifications
Write-Host ""
Write-Host "[INFO] Cleaning registry modifications..." -ForegroundColor Yellow

$steamtoolsRegPath = "HKCU:\Software\Valve\Steamtools"
if (Test-Path $steamtoolsRegPath) {
    try {
        Remove-Item -Path $steamtoolsRegPath -Recurse -Force -ErrorAction Stop
        Write-Host "  [DELETED] Steamtools registry key" -ForegroundColor Green
    }
    catch {
        Write-Host "  [FAILED] Cannot delete registry key" -ForegroundColor Red
    }
}
else {
    Write-Host "  [INFO] Steamtools registry key not found" -ForegroundColor Gray
}

# Clean AppData directories
Write-Host ""
Write-Host "[INFO] Cleaning AppData directories..." -ForegroundColor Yellow

# Clean Stool directory (from steam-run.ps1)
$stoolDirectory = Join-Path $env:APPDATA "Stool"
if (Test-Path $stoolDirectory) {
    try {
        Remove-Item -Path $stoolDirectory -Recurse -Force -ErrorAction Stop
        Write-Host "  [DELETED] $stoolDirectory" -ForegroundColor Green
    }
    catch {
        Write-Host "  [FAILED] Cannot delete Stool directory" -ForegroundColor Red
    }
}
else {
    Write-Host "  [INFO] Stool directory not found" -ForegroundColor Gray
}

# Clean LocalAppData files
Write-Host ""
Write-Host "[INFO] Cleaning LocalAppData files..." -ForegroundColor Yellow

# Clean localData.vdf (from steam-icu.ps1)
$localDataPath = Join-Path $env:LOCALAPPDATA "Steam\localData.vdf"
if (Test-Path $localDataPath) {
    try {
        Remove-Item -Path $localDataPath -Force -ErrorAction Stop
        Write-Host "  [DELETED] localData.vdf" -ForegroundColor Green
    }
    catch {
        Write-Host "  [FAILED] Cannot delete localData.vdf" -ForegroundColor Red
    }
}
else {
    Write-Host "  [INFO] localData.vdf not found" -ForegroundColor Gray
}

# Clean Steam directory in LocalAppData (from cdks-run.ps1)
$localSteamPath = Join-Path $env:LOCALAPPDATA "steam"
if (Test-Path $localSteamPath) {
    Write-Host "  [INFO] Found LocalAppData\steam directory" -ForegroundColor Yellow
    Write-Host "  [WARNING] This may contain user data. Delete it? (Y/N)" -ForegroundColor Yellow
    $deleteLocal = Read-Host "  Enter Y to delete, any other key to skip"
    
    if ($deleteLocal -eq "Y" -or $deleteLocal -eq "y") {
        try {
            Remove-Item -Path $localSteamPath -Recurse -Force -ErrorAction Stop
            Write-Host "  [DELETED] LocalAppData\steam" -ForegroundColor Green
        }
        catch {
            Write-Host "  [FAILED] Cannot delete LocalAppData\steam" -ForegroundColor Red
        }
    }
    else {
        Write-Host "  [SKIPPED] Keeping LocalAppData\steam" -ForegroundColor Gray
    }
}
else {
    Write-Host "  [INFO] LocalAppData\steam not found" -ForegroundColor Gray
}

# Clean Tencent cache (from cdks-run.ps1)
$tencentCachePath = Join-Path $env:LOCALAPPDATA "Microsoft\Tencent"
if (Test-Path $tencentCachePath) {
    try {
        Remove-Item -Path $tencentCachePath -Recurse -Force -ErrorAction Stop
        Write-Host "  [DELETED] Microsoft\Tencent cache" -ForegroundColor Green
    }
    catch {
        Write-Host "  [FAILED] Cannot delete Tencent cache" -ForegroundColor Red
    }
}
else {
    Write-Host "  [INFO] Tencent cache not found" -ForegroundColor Gray
}

# Clean temporary files
Write-Host ""
Write-Host "[INFO] Cleaning temporary files..." -ForegroundColor Yellow

$tempFiles = @(
    (Join-Path $env:USERPROFILE "get.ps1"),
    (Join-Path $PSScriptRoot "a.ps1")
)

foreach ($file in $tempFiles) {
    if (Test-Path $file) {
        try {
            Remove-Item -Path $file -Force -ErrorAction Stop
            Write-Host "  [DELETED] $file" -ForegroundColor Green
        }
        catch {
            Write-Host "  [FAILED] Cannot delete $file" -ForegroundColor Red
        }
    }
}

# Check config files (not auto-modified)
Write-Host ""
Write-Host "[INFO] Checking config file modifications..." -ForegroundColor Yellow

$loginUsersPath = Join-Path $steamPath "config\loginusers.vdf"
if (Test-Path $loginUsersPath) {
    Write-Host "  [INFO] loginusers.vdf exists (contains user data, not auto-modified)" -ForegroundColor Gray
}

$configPath = Join-Path $steamPath "config\config.vdf"
if (Test-Path $configPath) {
    Write-Host "  [INFO] config.vdf exists (contains user settings, not auto-modified)" -ForegroundColor Gray
}

# Remove from Windows Defender exclusions
Write-Host ""
Write-Host "[OPTIONAL] Remove Steam paths from Windows Defender exclusions?" -ForegroundColor Yellow
Write-Host "  Note: This may slow down Steam, usually not recommended" -ForegroundColor Gray
$removeExclusion = Read-Host "  Enter Y to remove, any other key to skip"

if ($removeExclusion -eq "Y" -or $removeExclusion -eq "y") {
    try {
        Remove-MpPreference -ExclusionPath $steamPath -ErrorAction SilentlyContinue
        Remove-MpPreference -ExclusionPath $stoolDirectory -ErrorAction SilentlyContinue
        Remove-MpPreference -ExclusionExtension 'exe' -ErrorAction SilentlyContinue
        Remove-MpPreference -ExclusionExtension 'dll' -ErrorAction SilentlyContinue
        Write-Host "  [SUCCESS] Removed from Windows Defender exclusions" -ForegroundColor Green
    }
    catch {
        Write-Host "  [FAILED] Cannot remove exclusions" -ForegroundColor Red
    }
}
else {
    Write-Host "  [SKIPPED] Keeping Windows Defender exclusion settings" -ForegroundColor Gray
}

# Complete
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Cleanup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[SUMMARY] Cleaned modifications from:" -ForegroundColor Yellow
Write-Host "  - steam-icu.ps1 (xinput1_4.dll, localData.vdf)" -ForegroundColor Gray
Write-Host "  - steam-run.ps1 (appdata.vdf, DLL files, Stool directory)" -ForegroundColor Gray
Write-Host "  - cdks-run.ps1 (xinput1_4.dll, registry settings)" -ForegroundColor Gray
Write-Host ""
Write-Host "[SUGGESTIONS] Next steps:" -ForegroundColor Yellow
Write-Host "  1. Verify Steam game file integrity" -ForegroundColor Gray
Write-Host "  2. Restart Steam client" -ForegroundColor Gray
Write-Host "  3. Reinstall Steam if issues persist" -ForegroundColor Gray
Write-Host ""

Read-Host "Press Enter to exit"
