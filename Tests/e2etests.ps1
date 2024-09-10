#Requires -Modules @{ModuleName = 'PSSCriptAnalyzer'; ModuleVersion = '1.20.0'}
#Requires -Modules @{ModuleName = 'Pester'; ModuleVersion = '5.3.1'}

[CmdletBinding()]
param([switch]$PassThru)

# Import the external module
Import-Module "$PSScriptRoot\testhelpers.psm1" -ErrorAction Stop
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\UnitySetup'
$testsFolder = "$PSScriptRoot\E2ETests"

# Check for the reqired environment variables
if (-not $env:TEST_UNITY_FOLDERPATH) {
    $env:TEST_UNITY_FOLDERPATH = Read-Host "Please enter the path for `$env:TEST_UNITY_FOLDERPATH.  This should be a path to the root folder of a Unity project"
}

if (-not $env:TEST_UNITY_MANIFESTPATH) {
    $env:TEST_UNITY_MANIFESTPATH = Read-Host "Please enter the path for TEST_UNITY_MANIFESTPATH.  This should be a path to a valid Unity project manifest."
}

if (-not $env:TEST_UNITY_MULTIFOLDERPATH) {
    $env:TEST_UNITY_MULTIFOLDERPATH = Read-Host "Please enter the path for TEST_UNITY_MULTIFOLDERPATH.  This should be a path to the root folder of a Unity project with multiple manifests in subfolders less than 5 directories deep."
}

if (-not $env:TEST_UNITY_MANIFESTLIKEPATH) {
    $env:TEST_UNITY_MANIFESTLIKEPATH = Read-Host "Please enter the path for TEST_UNITY_MANIFESTPATH.  This should be a path to a valid Unity project manifest."
}

if (-not $env:TEST_AZURESUBSCRIPTION_ID) {
    $env:TEST_AZURESUBSCRIPTION_ID = Read-Host "Please enter the value for TEST_AZURESUBSCRIPTION_ID.  This should be the azure subscription ID used to reconnect with if an interactive reconnect is required"
}



Write-Host "Running Analyzer..." -ForegroundColor Blue
$analyzerResults = Invoke-Analyzer -ModulePath $modulePath -PassThru:$PassThru

Write-Host "Running Tests..." -ForegroundColor Blue
$testResults = Invoke-Tests -TargetFolder $testsFolder -PassThru:$PassThru

if ($PassThru) {
    @{
        Analyzer = $analyzerResults
        Pester   = $testResults
    }
}
