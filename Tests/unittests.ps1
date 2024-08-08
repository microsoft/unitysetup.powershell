#Requires -Modules @{ModuleName = 'PSSCriptAnalyzer'; ModuleVersion = '1.20.0'}
#Requires -Modules @{ModuleName = 'Pester'; ModuleVersion = '5.3.1'}

[CmdletBinding()]
param([switch]$PassThru)

# Import the external module
Import-Module "$PSScriptRoot\testhelpers.psm1" -ErrorAction Stop
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\UnitySetup'
$testsFolder = "$PSScriptRoot\UnitTests"


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
