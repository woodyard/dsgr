# Thin wrapper: runs the shared oobe.ps1 with this profile's Autopilot GroupTag.
# Edit oobe.ps1 to change OOBE behaviour, not this file.
$Uri  = 'https://raw.githubusercontent.com/woodyard/dsgr/main/oobe.ps1'
$Path = Join-Path $env:SystemRoot 'Temp\dsgr-oobe.ps1'
Invoke-WebRequest -UseBasicParsing -Uri $Uri -OutFile $Path
& $Path -GroupTag 'KMR_WARE'
