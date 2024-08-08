# testhelpers.psm1

function Invoke-Analyzer {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({ if ($_.Exists) {return $true } throw "ModulePath $_ must exist"})]
        [System.IO.DirectoryInfo]$ModulePath,
        [switch]$PassThru
    )

    Import-Module PSScriptAnalyzer -MinimumVersion '1.20.0' -ErrorAction Stop

    $issues = Invoke-ScriptAnalyzer $ModulePath | ForEach-Object { 
        $_ | Add-Member -PassThru -MemberType ScriptProperty -Name 'DisplayProperties' -Value { ($this | Select-Object RuleName, Severity, ScriptName, Line, Message) }
    }
    $information = $issues | Where-Object { $_.Severity -eq 'Information' }
    $warnings = $issues | Where-Object { $_.Severity -eq 'Warning' }
    $errors = $issues | Where-Object { $_.Severity -eq 'Error' }

    foreach ($info in $information) { Write-Verbose $info.DisplayProperties }
    foreach ($warn in $warnings) { Write-Warning $warn.DisplayProperties }
    foreach ($err in $errors) { Write-Error $err.DisplayProperties }

    if ($PassThru) {
        @{
            Issues      = $issues
            Information = $information
            Warnings    = $warnings
            Errors      = $errors
        }
    }
}

function Invoke-Tests {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TargetFolder,
        [switch]$PassThru
    )

    Import-Module Pester -MinimumVersion '5.3.1' -ErrorAction Stop
    $pesterConfig = [PesterConfiguration]::Default
    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputFormat = 'NUnitXml'
    $pesterConfig.TestResult.OutputPath = "Test-Results.xml"
    $pesterConfig.Run.Path = $TargetFolder
    $pesterConfig.Run.PassThru = $PassThru ? $true : $false

    Invoke-Pester -Configuration $pesterConfig
}
