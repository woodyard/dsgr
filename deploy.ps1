#================================================
#   deploy.ps1
#   Shared OSDCloud WinPE deployment script for Damstahl (DSGR).
#
#   Called by the thin wrapper scripts in ScriptPad\, which pass the
#   profile name (used as Autopilot GroupTag) and optional switches.
#   Do not edit the ScriptPad wrappers to change deployment behaviour;
#   edit this file instead.
#
#   Parameters:
#     -GroupTag      Profile name, e.g. PROD, WARE, KIOSK. Selects which
#                    oobe-<GroupTag>.ps1 runs after the OS is installed.
#     -NoDriverPack  Skip the OSDCloud driver pack and MS Catalog firmware.
#     -LocalImage    Use OSDCloud\OS\install.wim from the boot media if
#                    present, otherwise fall back to the Microsoft download.
#================================================
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$GroupTag,

    [switch]$NoDriverPack,

    [switch]$LocalImage
)

$RepoBase = 'https://raw.githubusercontent.com/woodyard/dsgr/main'

#================================================
#   [PreOS]
#================================================
if ((Get-MyComputerModel) -match 'Virtual') {
    Write-Host -ForegroundColor Green "Setting Display Resolution to 1600x"
    Set-DisRes 1600
}

Write-Host -ForegroundColor Green "Importing OSD PowerShell Module"
Import-Module OSD -Force

#=======================================================================
#   [OS] Params and Start-OSDCloud
#=======================================================================
$Params = @{
    OSName     = "Windows 11 25H2 x64"
    OSEdition  = "Pro"
    OSLanguage = "en-us"
    OSLicense  = "Retail"
    ZTI        = $true
    Firmware   = $false
}

if ($LocalImage) {
    # Search all drives except the WinPE RAM drive (X:) for a local WIM
    $CustomImagePath = $null
    $SearchPath = "OSDCloud\OS\install.wim"
    foreach ($Drive in (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -ne 'X:\' })) {
        $TestPath = Join-Path $Drive.Root $SearchPath
        if (Test-Path $TestPath) {
            $CustomImagePath = $TestPath
            break
        }
    }
    if ($CustomImagePath) {
        Write-Host -ForegroundColor Green "Local WIM found: $CustomImagePath"
        $Params = @{
            ImageFileUrl = $CustomImagePath
            ImageIndex   = 1
            ZTI          = $true
            Firmware     = $false
        }
    }
    else {
        Write-Host -ForegroundColor Yellow "Local WIM not found on any drive, downloading from Microsoft..."
    }
}

if ($NoDriverPack) {
    Write-Host -ForegroundColor Yellow "Driver pack disabled for this profile"
    $Global:MyOSDCloud = @{
        DriverPackName    = "None"
        MSCatalogFirmware = $false
    }
}

Write-Host -ForegroundColor Green "Starting OSDCloud for profile $GroupTag"
Start-OSDCloud @Params

#================================================
#  [PostOS] OOBE.cmd - runs the profile's OOBE script on first boot
#================================================
Write-Host -ForegroundColor Green "Create C:\Windows\System32\OOBE.cmd"
$OOBECMD = @"
PowerShell -NoL -Com Set-ExecutionPolicy RemoteSigned -Force
Start /Wait PowerShell -NoL -C "Invoke-WebRequest -UseBasicParsing -Uri '$RepoBase/oobe-$GroupTag.ps1' -OutFile 'C:\Windows\Temp\oobe-$GroupTag.ps1'; & 'C:\Windows\Temp\oobe-$GroupTag.ps1'"
"@
$OOBECMD | Out-File -FilePath 'C:\Windows\System32\OOBE.cmd' -Encoding ascii -Force

#================================================
#  [PostOS] SetupComplete.cmd (intentionally empty)
#================================================
Write-Host -ForegroundColor Green "Create C:\Windows\Setup\Scripts\SetupComplete.cmd"
$SetupCompleteCMD = @'
'@
$SetupCompleteCMD | Out-File -FilePath 'C:\Windows\Setup\Scripts\SetupComplete.cmd' -Encoding ascii -Force

#=======================================================================
#   Enable "Audit process tracking"
#=======================================================================
Write-Host -ForegroundColor Green "Enable 'Audit process tracking'"
C:\Windows\System32\auditpol.exe /set /category:"Detailed Tracking" /success:enable
C:\Windows\System32\auditpol.exe /get /category:"Detailed Tracking"

#=======================================================================
#   Restart-Computer
#=======================================================================
Write-Host -ForegroundColor Green "Restarting in 20 seconds!"
Start-Sleep -Seconds 20
wpeutil reboot
