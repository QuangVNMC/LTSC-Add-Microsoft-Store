# Add Store to Windows 10/11  
If you only want Microsoft Store, you can use [ThioJoe Windows Sandbox Tools Microsoft Store install script](https://github.com/ThioJoe/Windows-Sandbox-Tools/blob/main/Installer%20Scripts/Install-Microsoft-Store.ps1). It work well enough.  
This script will install Microsoft Store and Xbox Identity Provider (and HEVC Video Extensions from Device Manufacturer with -installHevc flag), you can download latest version [here](https://github.com/QuangVNMC/LTSC-Add-Microsoft-Store/releases/latest) (for both online and offline version)  
Current minimum version this script is supported is Windows 10 19H1 (Windows 10 build 18362)  
For Windows 10 Enterprise LTSC 2019   
[Download](https://github.com/lixuy/LTSC-Add-MicrosoftStore/archive/2019.zip)  
## To install  
Online version: Run Set-ExecutionPolicy Bypass -Scope Process and then run the script  
Offline version: Run Install.bat as Administrator  
## Addition troubleshooting    
>Right click start  
Select Run  
Type in: WSReset.exe  
This will clear the cache if needed.  
