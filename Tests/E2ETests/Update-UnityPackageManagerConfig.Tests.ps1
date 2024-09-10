Describe 'Update-UnityPackageManagerConfig' {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '..\..\UnitySetup\UnitySetup.psd1') -Force
    }

    Context 'E2E Validation of manifest/folder targets' {
        It 'supports a root folder target' {
            { Update-UnityPackageManagerConfig -SearchPath $env:TEST_UNITY_FOLDERPATH -SearchDepth 5 } | Should -Not -Throw
        }

        It 'supports a single manifest target' {
            { Update-UnityPackageManagerConfig -ProjectManifestPath $env:TEST_UNITY_MANIFESTPATH } | Should -Not -Throw
        }

        It 'supports a search target with multiple manifests' {
            { Update-UnityPackageManagerConfig -SearchPath $env:TEST_UNITY_MULTIFOLDERPATH -SearchDepth 5 } | Should -Not -Throw
        }

        It 'supports a single manifest-like target (any JSON file with valid scoped registries)' {
            { Update-UnityPackageManagerConfig -ProjectManifestPath $env:TEST_UNITY_MANIFESTLIKEPATH } | Should -Not -Throw
        }

        It 'should throw if manifest path is a folder, not a file' {
            { Update-UnityPackageManagerConfig -ProjectManifestPath $env:TEST_UNITY_FOLDERPATH } | Should -Throw "* is not a valid file"
        }
    }

    Context 'E2E Validation of AzureSubscriptionID options' {
        It 'should throw on malformed AzureSubscription guid' {
            { Update-UnityPackageManagerConfig -ProjectManifestPath $env:TEST_UNITY_MANIFESTPATH -AzureSubscription "abcd" } | Should -Throw "*Unrecognized Guid format*"
        }

        It 'should accept a valid AzureSubscription guid' {
            { Update-UnityPackageManagerConfig -ProjectManifestPath $env:TEST_UNITY_MANIFESTPATH -AzureSubscription $env:TEST_AZURESUBSCRIPTION_ID } | Should -Not -Throw
        }
    }

    Context 'E2E Validation of AutoClean parameter' {
        It 'should run with AutoClean enabled' {
            { Update-UnityPackageManagerConfig -ProjectManifestPath $env:TEST_UNITY_MANIFESTPATH -AutoClean } | Should -Not -Throw
        }
    }

    Context 'E2E Validation of ManualPAT parameter' {
        It 'should run with ManualPAT enabled' {
            { Update-UnityPackageManagerConfig -ProjectManifestPath $env:TEST_UNITY_MANIFESTPATH -ManualPAT } | Should -Not -Throw
        }
    }

    Context 'E2E Validation of VerifyOnly parameter' {
        It 'should run with VerifyOnly enabled' {
            { Update-UnityPackageManagerConfig -ProjectManifestPath $env:TEST_UNITY_MANIFESTPATH -VerifyOnly } | Should -Not -Throw
        }
    }

    Context 'Combination of parameters' {
        It 'should run with AutoClean, ManualPAT, and VerifyOnly enabled' {
            { Update-UnityPackageManagerConfig -ProjectManifestPath $env:TEST_UNITY_MANIFESTPATH -AutoClean -ManualPAT -VerifyOnly } | Should -Not -Throw
        }

        It 'should run with SearchDepth, PATLifetime, and AzureSubscription parameters' {
            { Update-UnityPackageManagerConfig -SearchPath $env:TEST_UNITY_FOLDERPATH -SearchDepth 7 -PATLifetime 30 -AzureSubscription $env:TEST_AZURESUBSCRIPTION_ID } | Should -Not -Throw
        }
    }

    Context 'Edge cases for parameter values' {
        It 'should throw if SearchDepth is negative' {
            { Update-UnityPackageManagerConfig -SearchPath $env:TEST_UNITY_FOLDERPATH -SearchDepth -1 } | Should -Throw '*Cannot convert value "-1" to type "System.UInt32"*'
        }

        It 'should throw if PATLifetime is zero' {
            { Update-UnityPackageManagerConfig -ProjectManifestPath $env:TEST_UNITY_MANIFESTPATH -PATLifetime 0 } | Should -Throw "*PATLifetime must be greater than zero*"
        }

        It 'should throw if AzureSubscription is empty GUID' {
            { Update-UnityPackageManagerConfig -ProjectManifestPath $env:TEST_UNITY_MANIFESTPATH -AzureSubscription [guid]::Empty } | Should -Throw "*Unrecognized Guid format*"
        }
    }
}
