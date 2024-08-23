Describe 'Update-UnityPackageManagerConfig' {

    BeforeEach {
        Import-Module "$PSScriptRoot\..\..\UnitySetup\UnitySetup.psd1" -Force
    
        Mock -CommandName 'Import-UnityProjectManifest' -MockWith { @() } -ModuleName UnitySetup
        Mock -CommandName 'Import-TOMLFile' -MockWith { @() } -ModuleName UnitySetup
        Mock -CommandName 'Update-PackageAuthConfig' -MockWith { @() } -ModuleName UnitySetup
        Mock -CommandName 'Export-UPMConfig' -MockWith { @() } -ModuleName UnitySetup
        Mock -CommandName 'Invoke-WebRequest' -MockWith {
            return [pscustomobject]@{
                StatusCode = 200
                Content    = '{"patToken": {"token": "mockedPATToken"}}'
            }
        } -ModuleName UnitySetup
        Mock -CommandName 'Confirm-PAT' -MockWith { $true } -ModuleName UnitySetup
    }
    
    Context 'Input Validation' {
        It 'throws on empty parameters' {
            { Update-UnityPackageManagerConfig } | Should -Throw "*insufficient number of parameters were provided."
        }

        It 'throws on null ProjectManifestPath' {
            { Update-UnityPackageManagerConfig -ProjectManifestPath "" } | Should -Throw "*The argument is null or empty.*"
        }
    }

    Context 'Function Execution' {
        It 'supports a root folder target' {
            { Update-UnityPackageManagerConfig -SearchPath "$PSScriptRoot\..\Data" -SearchDepth 5 } | Should -Not -Throw
        }

        It 'supports a single manifest target' {
            { Update-UnityPackageManagerConfig -ProjectManifestPath "$PSScriptRoot\..\Data\manifest.json" } | Should -Not -Throw
        }

        It 'supports a search target with multiple manifests' {
            { Update-UnityPackageManagerConfig -SearchPath "$PSScriptRoot\..\Data" -SearchDepth 5 } | Should -Not -Throw
        }

        It 'supports a single manifest-like target (any JSON file with valid scoped registries)' {
            { Update-UnityPackageManagerConfig -ProjectManifestPath "$PSScriptRoot\..\Data\manifestlike.json" } | Should -Not -Throw
        }

        It 'should throw if manifest path is a folder, not a file' {
            { Update-UnityPackageManagerConfig -ProjectManifestPath "$PSScriptRoot\..\Data" } | Should -Throw "* is not a valid file"
        }
    }

    Context 'AzureSubscription Validation' {
        It 'should throw on malformed AzureSubscription guid' {
            { Update-UnityPackageManagerConfig -ProjectManifestPath "$PSScriptRoot\..\Data\manifest.json" -AzureSubscription "abcd" } | Should -Throw "*Unrecognized Guid format*"
        }

        It 'should accept a valid AzureSubscription guid' {
            # Random guid input
            { Update-UnityPackageManagerConfig -ProjectManifestPath "$PSScriptRoot\..\Data\manifest.json" -AzureSubscription a4e1d2b6-78e4-4c2a-9f73-1f2a5d6e8b1c } | Should -Not -Throw
        }

        It 'throws on empty guid for AzureSubscription' {
            { Update-UnityPackageManagerConfig -ProjectManifestPath "$PSScriptRoot\..\Data\manifest.json" -AzureSubscription ([guid]::Empty) } | Should -Throw "*Cannot be empty guid.*"
        }
    }

    Context 'PAT Lifetime Validation' {
        It 'throws on PATLifetime less than or equal to zero' {
            { Update-UnityPackageManagerConfig -ProjectManifestPath "$PSScriptRoot\..\Data\manifest.json" -PATLifetime 0 } | Should -Throw "*PATLifetime must be greater than zero*"
        }

        It 'should throw if PATLifetime is zero' {
            { Update-UnityPackageManagerConfig -ProjectManifestPath "$PSScriptRoot\..\Data\manifest.json" -PATLifetime 0 } | Should -Throw "*PATLifetime must be greater than zero*"
        }
    }

    Context 'Verify Mode' {
        It 'runs in VerifyOnly mode without error' {
            { Update-UnityPackageManagerConfig -ProjectManifestPath "$PSScriptRoot\..\Data\manifest.json" -VerifyOnly } | Should -Not -Throw
        }

        It 'should run with VerifyOnly enabled' {
            { Update-UnityPackageManagerConfig -ProjectManifestPath "$PSScriptRoot\..\Data\manifest.json" -VerifyOnly } | Should -Not -Throw
        }
    }

    Context 'AutoClean Mode' {
        It 'runs in AutoClean mode without error' {
            { Update-UnityPackageManagerConfig -ProjectManifestPath "$PSScriptRoot\..\Data\manifest.json" -AutoClean } | Should -Not -Throw
        }

        It 'should run with AutoClean enabled' {
            { Update-UnityPackageManagerConfig -ProjectManifestPath "$PSScriptRoot\..\Data\manifest.json" -AutoClean } | Should -Not -Throw
        }
    }

    Context 'ManualPAT parameter' {
        It 'should run with ManualPAT enabled' {
            { Update-UnityPackageManagerConfig -ProjectManifestPath "$PSScriptRoot\..\Data\manifest.json" -ManualPAT } | Should -Not -Throw
        }
    }

    Context 'Combination of parameters' {
        It 'should run with AutoClean, ManualPAT, and VerifyOnly enabled' {
            { Update-UnityPackageManagerConfig -ProjectManifestPath "$PSScriptRoot\..\Data\manifest.json" -AutoClean -ManualPAT -VerifyOnly } | Should -Not -Throw
        }

        It 'should run with SearchDepth, PATLifetime, and AzureSubscription parameters' {

            # Random guid input
            { Update-UnityPackageManagerConfig -SearchPath "$PSScriptRoot\..\Data" -SearchDepth 7 -PATLifetime 30 -AzureSubscription a4e1d2b6-78e4-4c2a-9f73-1f2a5d6e8b1c } | Should -Not -Throw
        }
    }

    Context 'Edge cases for parameter values' {
        It 'should throw if SearchDepth is negative' {
            { Update-UnityPackageManagerConfig -SearchPath "$PSScriptRoot\..\Data" -SearchDepth -1 } | Should -Throw '*Cannot convert value "-1" to type "System.UInt32"*'
        }
    }
}
