BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\UnitySetup\UnitySetup.psd1') -Force
}

Describe 'Update-UnityPackageManagerConfig' {
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
}
