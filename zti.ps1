Write-Host -ForegroundColor Green "Starting OSDCloud ZTI"
Write-Host  -ForegroundColor Green "Importing OSD PowerShell Module"
Import-Module OSD -Force

#Start OSDCloudScriptPad
Write-Host -ForegroundColor Green "Start OSDPad"
Start-OSDPad -RepoOwner woodyard -RepoName dsgr -RepoFolder ScriptPad -Hide Script -BrandingTitle 'Damstahl'
