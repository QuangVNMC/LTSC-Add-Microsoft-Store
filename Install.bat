<# :
@echo off & setlocal
rem Self-elevate if not running as administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
pushd "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((Get-Content -LiteralPath '%~f0' -Raw))"
echo.
popd
pause
exit /b
#>

# --- PowerShell section ---
$ErrorActionPreference = 'Continue'
$folder = (Get-Location).Path

# Collect package files in this folder
$allFiles = Get-ChildItem -LiteralPath $folder -File |
    Where-Object { $_.Extension -in '.appx', '.msix', '.appxbundle', '.msixbundle' }

if (-not $allFiles) {
    Write-Host "No .appx/.msix package files found in '$folder'." -ForegroundColor Red
    return
}

# Old dependency versions to skip if present in the folder
$excludedNames = @(
    'Microsoft.NET.Native.Framework.1.3',
    'Microsoft.NET.Native.Framework.1.7',
    'Microsoft.NET.Native.Runtime.1.3',
    'Microsoft.NET.Native.Runtime.1.7',
    'Microsoft.UI.Xaml.2.4'
)

# Main apps are installed last; Microsoft.WindowsStore must be the very last one
$mainAppOrder = @(
    'Microsoft.HEVCVideoExtension',
    'Microsoft.XboxIdentityProvider',
    'Microsoft.DesktopAppInstaller',
    'Microsoft.WindowsStore'
)

# Dependency install order
$dependencyOrder = @(
    'Microsoft.VCLibs',
    'Microsoft.NET.Native.Framework',
    'Microsoft.NET.Native.Runtime',
    'Microsoft.UI.Xaml',
    'Microsoft.WindowsAppRuntime'
)

$installed = 0
$failed = 0

function Install-Package {
    param($File)
    # Compatibility check: HEVC Video Extensions 2.5.0.0+ require Windows 11 build 26200 or higher
    if ($File.Name -like 'Microsoft.HEVCVideoExtension_*') {
        $ver = [version]($File.Name -replace '^Microsoft\.HEVCVideoExtension_([0-9.]+)_.*$', '$1')
        if ($ver -ge [version]'2.5.0.0' -and [Environment]::OSVersion.Version.Build -lt 26200) {
            Write-Host "     SKIPPED: $($File.Name) requires OS build 26200+ (this is build $([Environment]::OSVersion.Version.Build)). Use a version below 2.5.0.0." -ForegroundColor Yellow
            return $false
        }
    }
    Write-Host "  -> Installing $($File.Name)" -ForegroundColor Cyan
    try {
        Add-AppxPackage -Path $File.FullName -ErrorAction Stop
        Write-Host "     SUCCESS." -ForegroundColor Green
        return $true
    } catch {
        Write-Host "     FAILED: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Separate main apps from dependencies
$mainFiles     = $allFiles | Where-Object { $n = $_.Name; ($mainAppOrder | Where-Object { $n -like "$_*" }) }
$depFiles      = $allFiles | Where-Object { $n = $_.Name; -not ($mainAppOrder | Where-Object { $n -like "$_*" }) } |
                 Where-Object { $n = $_.Name; -not ($excludedNames | Where-Object { $n -like "$_*" }) }

Write-Host "Installing dependencies..." -ForegroundColor Yellow
foreach ($baseName in $dependencyOrder) {
    # Sort descending so the newest version is tried first if multiple exist
    foreach ($pkg in ($depFiles | Where-Object { $_.Name -like "$baseName*" } | Sort-Object Name -Descending)) {
        if (Install-Package $pkg) { $installed++ } else { $failed++ }
    }
}

Write-Host ""
Write-Host "Installing main application(s)..." -ForegroundColor Yellow
foreach ($baseName in $mainAppOrder) {
    foreach ($pkg in ($mainFiles | Where-Object { $_.Name -like "$baseName*" } | Sort-Object Name -Descending)) {
        if (Install-Package $pkg) { $installed++ } else { $failed++ }
    }
}

Write-Host ""
Write-Host "Done. Installed: $installed, Failed: $failed." -ForegroundColor $(if ($failed) { 'Yellow' } else { 'Green' })
