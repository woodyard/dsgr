# Thin wrapper: runs the shared deploy.ps1 for profile KMR_PROD.
# Edit deploy.ps1 to change deployment behaviour, not this file.
Import-Module OSD -Force
$Uri  = 'https://raw.githubusercontent.com/woodyard/dsgr/main/deploy.ps1'
$Path = Join-Path $env:TEMP 'dsgr-deploy.ps1'
Invoke-WebRequest -UseBasicParsing -Uri $Uri -OutFile $Path
& $Path -GroupTag 'KMR_PROD' -NoDriverPack
