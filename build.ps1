# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

param([int]$Revision = 0, [string]$Suffix = '')
Import-Module 'PowerShellGet' -Force

$ErrorActionPreference = 'Stop'

$manifest = Test-ModuleManifest .\UnitySetup\UnitySetup.psd1
$versionString = $manifest.Version.ToString()
if ($manifest.PrivateData['PSData']['Prerelease']) { 
    $versionString += "-$($manifest.PrivateData['PSData']['Prerelease'])"
}
Write-Host "Current Module Version: $versionString"

$newVersion = New-Object System.Version($manifest.Version.Major, $manifest.Version.Minor, $Revision)
Update-ModuleManifest -ModuleVersion $newVersion -Prerelease $Suffix -Path .\UnitySetup\UnitySetup.psd1

$manifest = Test-ModuleManifest .\UnitySetup\UnitySetup.psd1
$versionString = $manifest.Version.ToString()
if ($manifest.PrivateData['PSData']['Prerelease']) { 
    $versionString += "-$($manifest.PrivateData['PSData']['Prerelease'])"
}
Write-Host "New Module Version: $versionString"