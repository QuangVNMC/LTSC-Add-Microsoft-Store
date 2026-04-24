@echo off
for /f "tokens=6 delims=[]. " %%G in ('ver') do if %%G lss 16299 goto :version
%windir%\system32\reg.exe query "HKU\S-1-5-19" 1>nul 2>nul || goto :uac
setlocal enableextensions
set "arch=x86"
cd /d "%~dp0"
if not exist "*WindowsStore*.*bundle" goto :nofiles
:: ===== FIND PACKAGES =====
for /f %%i in ('dir /b *WindowsStore*.*bundle 2^>nul') do set "Store=%%i"
for /f %%i in ('dir /b *NET.Native.Framework*2.2*.* 2^>nul ^| find /i "x86"') do set "Framework6x86=%%i"
for /f %%i in ('dir /b *NET.Native.Runtime*2.2*.* 2^>nul ^| find /i "x86"') do set "Runtime6x86=%%i"
for /f %%i in ('dir /b *VCLibs*140*.* 2^>nul ^| find /i "x86"') do set "VCLibsx86=%%i"
for /f %%i in ('dir /b *VCLibs.140.00.UWP*.* 2^>nul ^| find /i "x86"') do set "VCLibsUWPx86=%%i"
for /f %%i in ('dir /b *UI.Xaml*.* 2^>nul ^| find /i "x86"') do set "UIXamlx86=%%i"
for /f %%i in ('dir /b *WindowsAppRuntime*.* 2^>nul ^| find /i "x86"') do set "WindowsAppRuntimex86=%%i"
if exist "*DesktopAppInstaller*.*bundle" (
    for /f %%i in ('dir /b *DesktopAppInstaller*.*bundle 2^>nul') do set "AppInstaller=%%i"
)
if exist "*XboxIdentityProvider*.*bundle" (
    for /f %%i in ('dir /b *XboxIdentityProvider*.*bundle 2^>nul') do set "XboxIdentity=%%i"
)
:: ===== DEPENDENCIES =====
set "DepStore=%VCLibsx86%,%VCLibsUWPx86%,%Framework6x86%,%Runtime6x86%,%UIXamlx86%"
set "DepPurchase=%VCLibsx86%,%Framework6x86%,%Runtime6x86%"
set "DepXbox=%VCLibsx86%,%Framework6x86%,%Runtime6x86%"
set "DepInstaller=%WindowsAppRuntimex86%,%VCLibsx86%"
for %%i in (%DepStore%) do (
    if not exist "%%i" goto :nofiles
)
set "PScommand=PowerShell -NoLogo -NoProfile -NonInteractive -InputFormat None -ExecutionPolicy Bypass"
echo.
echo ============================================================
echo Adding Microsoft Store
echo ============================================================
echo.
1>nul 2>nul %PScommand% Add-AppxProvisionedPackage -Online -PackagePath %Store% -DependencyPackagePath %DepStore% -LicensePath Microsoft.WindowsStore_8wekyb3d8bbwe.xml

for %%i in (%DepStore%) do (
    %PScommand% Add-AppxPackage -Path %%i
)

%PScommand% Add-AppxPackage -Path %Store%

if defined AppInstaller (
    echo.
    echo ============================================================
    echo Adding App Installer
    echo ============================================================
    echo.
    1>nul 2>nul %PScommand% Add-AppxProvisionedPackage -Online -PackagePath %AppInstaller% -DependencyPackagePath %DepInstaller% -LicensePath Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.xml
    %PScommand% Add-AppxPackage -Path %AppInstaller%
)

if defined XboxIdentity (
    echo.
    echo ============================================================
    echo Adding Xbox Identity Provider
    echo ============================================================
    echo.
    1>nul 2>nul %PScommand% Add-AppxProvisionedPackage -Online -PackagePath %XboxIdentity% -DependencyPackagePath %DepXbox% -LicensePath Microsoft.XboxIdentityProvider_8wekyb3d8bbwe.xml
    %PScommand% Add-AppxPackage -Path %XboxIdentity%
)

goto :fin

:uac
echo.
echo ============================================================
echo Error: Run the script as administrator
echo ============================================================
pause >nul
exit

:version
echo.
echo ============================================================
echo Error: This pack is for Windows 10 version 1709 and later
echo ============================================================
pause >nul
exit

:nofiles
echo.
echo ============================================================
echo Error: Required files are missing
echo ============================================================
pause >nul
exit

:fin
echo.
echo ============================================================
echo Done
echo ============================================================
pause >nul
exit
