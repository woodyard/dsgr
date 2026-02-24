#================================================
#   Script: _PROD_Use_local_image.ps1
#   Description: OSDCloud deployment script for Damstahl (DSGR).
#                Uses a local WIM image if available on the boot
#                media, otherwise falls back to downloading
#                Windows 11 25H2 Pro from Microsoft.
#                After OS deployment, configures AutopilotOOBE
#                and enables audit process tracking.
#
#   Version History:
#     1.0  -  Original version
#     1.1  -  2026-02-23 - Henrik Skovgaard
#             - Fixed: $Params hashtable was defined but never
#               passed to Start-OSDCloud (was using hardcoded
#               -ZTI -Firmware -FindImageFile instead)
#             - Fixed: Corrected local WIM path
#             - Updated fallback OS from generic to 25H2 explicitly
#     1.2  -  2026-02-23 - Henrik Skovgaard
#             - Changed: Dynamic drive letter detection for local
#               WIM file since boot media drive letter is unknown
#               in WinPE (searches all drives for OSDCloud\OS\install.wim)
#================================================

#================================================
#   [PreOS] Update Module
#================================================
if ((Get-MyComputerModel) -match 'Virtual') {
    Write-Host -ForegroundColor Green "Setting Display Resolution to 1600x"
    Set-DisRes 1600
}

Write-Host -ForegroundColor Green "Importing OSD PowerShell Module"
Import-Module OSD -Force   

#=======================================================================
#   [OS] Find local WIM and Start-OSDCloud
#=======================================================================
$CustomImagePath = $null

# Search all available drives for the local WIM file
# Exclude X:\ as that is the WinPE RAM drive
$SearchPath = "OSDCloud\OS\install.wim"
foreach ($Drive in (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -ne 'X:\' })) {
    $TestPath = Join-Path $Drive.Root $SearchPath
    if (Test-Path $TestPath) {
        $CustomImagePath = $TestPath
        Write-Host -ForegroundColor Green "Local WIM found: $CustomImagePath"
        break
    }
}

if ($CustomImagePath) {
    $Params = @{
        ImageFileUrl = $CustomImagePath
        ImageIndex   = 1
        ZTI          = $true
        Firmware     = $true
    }
} else {
    Write-Host -ForegroundColor Yellow "Local WIM not found on any drive, downloading from Microsoft..."
    $Params = @{
        OSName     = "Windows 11 25H2 x64"
        OSEdition  = "Pro"
        OSLanguage = "en-us"
        OSLicense  = "Retail"
        ZTI        = $true
        Firmware    = $true
    }
}

Start-OSDCloud @Params

#================================================
#  [PostOS] AutopilotOOBE CMD Command Line
#================================================
Write-Host -ForegroundColor Green "Create C:\Windows\System32\OOBE.cmd"
$OOBECMD = @'
PowerShell -NoL -Com Set-ExecutionPolicy RemoteSigned -Force
Set Path = %PATH%;C:\Program Files\WindowsPowerShell\Scripts
Start /Wait PowerShell -NoL -C Install-Module AutopilotOOBE -Force
Start /Wait PowerShell -NoL -C Install-Module OSD -Force
Start /Wait PowerShell -NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/woodyard/dsgr/main/oobe-PROD.ps1
'@
$OOBECMD | Out-File -FilePath 'C:\Windows\System32\OOBE.cmd' -Encoding ascii -Force

#================================================
#  [PostOS] SetupComplete CMD Command Line
#================================================
Write-Host -ForegroundColor Green "Create C:\Windows\Setup\Scripts\SetupComplete.cmd"
$SetupCompleteCMD = @'
'@
$SetupCompleteCMD | Out-File -FilePath 'C:\Windows\Setup\Scripts\SetupComplete.cmd' -Encoding ascii -Force

#=======================================================================
#   Enable "Audit process tracking"
#=======================================================================
Write-Host -ForegroundColor Green "Get 'Detailed tracking' properties"
C:\Windows\System32\auditpol.exe /get /category:"Detailed Tracking"

Write-Host -ForegroundColor Green "Enable 'Audit process tracking'"
C:\Windows\System32\auditpol.exe /set /category:"Detailed Tracking" /success:enable

Write-Host -ForegroundColor Green "Get 'Audit process tracking' properties"
C:\Windows\System32\auditpol.exe /get /category:"Detailed Tracking"

#=======================================================================
#   Restart-Computer
#=======================================================================
Write-Host -ForegroundColor Green "Restarting in 20 seconds!"
Start-Sleep -Seconds 20
wpeutil reboot