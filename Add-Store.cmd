@echo off
for /f "tokens=6 delims=[]. " %%G in ('ver') do if %%G lss 16299 goto :version
%windir%\system32\reg.exe query "HKU\S-1-5-19" 1>nul 2>nul || goto :uac
setlocal enableextensions
if /i "%PROCESSOR_ARCHITECTURE%" equ "AMD64" (set "arch=x64") else (set "arch=x86")
cd /d "%~dp0"

if not exist "*WindowsStore*.*bundle" goto :nofiles

for /f %%i in ('dir /b *WindowsStore*.*bundle 2^>nul') do set "Store=%%i"
for /f %%i in ('dir /b *NET.Native.Framework*2.2*.* 2^>nul ^| find /i "x64"') do set "Framework6X64=%%i"
for /f %%i in ('dir /b *NET.Native.Framework*2.2*.* 2^>nul ^| find /i "x86"') do set "Framework6X86=%%i"
for /f %%i in ('dir /b *NET.Native.Framework*1.6*.* 2^>nul ^| find /i "x64"') do set "Framework7X64=%%i"
for /f %%i in ('dir /b *NET.Native.Framework*1.6*.* 2^>nul ^| find /i "x86"') do set "Framework7X86=%%i"
for /f %%i in ('dir /b *NET.Native.Runtime*2.2*.* 2^>nul ^| find /i "x64"') do set "Runtime6X64=%%i"
for /f %%i in ('dir /b *NET.Native.Runtime*2.2*.* 2^>nul ^| find /i "x86"') do set "Runtime6X86=%%i"
for /f %%i in ('dir /b *VCLibs*140*.* 2^>nul ^| find /i "x64"') do set "VCLibsX64=%%i"
for /f %%i in ('dir /b *VCLibs*140*.* 2^>nul ^| find /i "x86"') do set "VCLibsX86=%%i"
for /f %%i in ('dir /b *VCLibs.140.00.UWP*.* 2^>nul ^| find /i "x64"') do set "VCLibsUWPX64=%%i"
for /f %%i in ('dir /b *VCLibs.140.00.UWP*.* 2^>nul ^| find /i "x86"') do set "VCLibsUWPX86=%%i"
for /f %%i in ('dir /b *UI.Xaml*.* 2^>nul ^| find /i "x64"') do set "UIXamlX64=%%i"
for /f %%i in ('dir /b *UI.Xaml*.* 2^>nul ^| find /i "x86"') do set "UIXamlX86=%%i"


if exist "*DesktopAppInstaller*.*bundle" (
for /f %%i in ('dir /b *DesktopAppInstaller*.*bundle 2^>nul') do set "AppInstaller=%%i"
)
if exist "*XboxIdentityProvider*.*bundle" (
for /f %%i in ('dir /b *XboxIdentityProvider*.*bundle 2^>nul') do set "XboxIdentity=%%i"
)

if /i %arch%==x64 (
set "DepStore=%VCLibsX64%,%VCLibsX86%,%VCLibsUWPX64%,"%VCLibsUWPX86%",%Framework6X64%,%Framework6X86%,%Framework7X64%,%Framework7X86%,%Runtime6X64%,%Runtime6X86%,%UIXamlX64%,%UIXamlX86%"
set "DepPurchase=%VCLibsX64%,%VCLibsX86%,%Framework6X64%,%Framework6X86%,%Runtime6X64%,%Runtime6X86%"
set "DepXbox=%VCLibsX64%,%VCLibsX86%,%Framework6X64%,%Framework6X86%,%Runtime6X64%,%Runtime6X86%"
set "DepInstaller=%VCLibsX64%,%VCLibsX86%"
) else (
set "DepStore=%VCLibsX86%,"VCLibsUWPX86",%Framework6X86%,%Framework7X86%,%Runtime6X86%,%UIXamlX86%"
set "DepPurchase=%VCLibsX86%,%Framework6X86%,%Runtime6X86%"
set "DepXbox=%VCLibsX86%,%Framework6X86%,%Runtime6X86%"
set "DepInstaller=%VCLibsX86%"
)

for %%i in (%DepStore%) do (
if not exist "%%i" goto :nofiles
)

set "PScommand=PowerShell -NoLogo -NoProfile -NonInteractive -InputFormat None -ExecutionPolicy Bypass"

echo.
echo ============================================================
echo Adding Microsoft Store
echo ============================================================
echo.
1>nul 2>nul %PScommand% Add-appxProvisionedPackage -Online -PackagePath %Store% -DependencyPackagePath %DepStore% -LicensePath Microsoft.WindowsStore_8wekyb3d8bbwe.xml
for %%i in (%DepStore%) do (
%PScommand% Add-appxPackage -Path %%i
)
%PScommand% Add-appxPackage -Path %Store%

if defined PurchaseApp (
echo.
echo ============================================================
echo Adding Store Purchase App
echo ============================================================
echo.
1>nul 2>nul %PScommand% Add-appxProvisionedPackage -Online -PackagePath %PurchaseApp% -DependencyPackagePath %DepPurchase% -LicensePath Microsoft.StorePurchaseApp_8wekyb3d8bbwe.xml
%PScommand% Add-appxPackage -Path %PurchaseApp%
)
if defined AppInstaller (
echo.
echo ============================================================
echo Adding App Installer
echo ============================================================
echo.
1>nul 2>nul %PScommand% Add-appxProvisionedPackage -Online -PackagePath %AppInstaller% -DependencyPackagePath %DepInstaller% -LicensePath Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.xml
%PScommand% Add-appxPackage -Path %AppInstaller%
)
if defined XboxIdentity (
echo.
echo ============================================================
echo Adding Xbox Identity Provider
echo ============================================================
echo.
1>nul 2>nul %PScommand% Add-appxProvisionedPackage -Online -PackagePath %XboxIdentity% -DependencyPackagePath %DepXbox% -LicensePath Microsoft.XboxIdentityProvider_8wekyb3d8bbwe.xml
%PScommand% Add-appxPackage -Path %XboxIdentity%
)
goto :fin

:uac
echo.
echo ============================================================
echo Error: Run the script as administrator
echo ============================================================
echo.
echo.
echo Press any key to Exit
pause >nul
exit

:version
echo.
echo ============================================================
echo Error: This pack is for Windows 10 version 1709 and later
echo ============================================================
echo.
echo.
echo Press any key to Exit
pause >nul
exit

:nofiles
echo.
echo ============================================================
echo Error: Required files are missing in the current directory
echo ============================================================
echo.
echo.
echo Press any key to Exit
pause >nul
exit

:fin
echo.
echo ============================================================
echo Done
echo ============================================================
echo.
echo Press any Key to Exit.
pause >nul
exit
