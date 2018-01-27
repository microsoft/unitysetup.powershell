param([int]$Revision = 0)
$currentVersion = Test-ModuleManifest -ErrorAction Stop .\UnitySetup\UnitySetup.psd1 | Select-Object -ExpandProperty Version
Write-Host "Current Module Version: $currentVersion"
$newVersion = New-Object System.Version($currentVersion.Major, $currentVersion.Minor, $Revision)

Write-Host "New Module Version:$newVersion"
Update-ModuleManifest -ErrorAction Stop -ModuleVersion $newVersion -Path .\UnitySetup\UnitySetup.psd1