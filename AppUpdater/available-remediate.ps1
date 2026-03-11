$global:whitelistUrl = "https://raw.githubusercontent.com/woodyard/dsgr/main/AppUpdater/app-whitelist.json"
$tmp = "$env:TEMP\availableUpgrades-detect_$(Get-Random).ps1"
irm "https://raw.githubusercontent.com/woodyard/public-scripts/main/remediations/availableUpgrades-detect.ps1" -OutFile $tmp
& $tmp
$exitCode = $LASTEXITCODE
Remove-Item $tmp -Force -ErrorAction SilentlyContinue
exit $exitCode