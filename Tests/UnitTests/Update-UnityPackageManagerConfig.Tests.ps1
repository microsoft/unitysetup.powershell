BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\UnitySetup\UnitySetup.psd1') -Force
}
Describe 'Update-UnityPackageManagerConfig' {
    Context 'Input Validation' {
        It 'throws on empty parameters'{
            { Update-UnityPackageManagerConfig } | Should -Throw "*insufficient number of parameters were provided."
        }

        It 'throws on null projectmanifestpath'{
            { Update-UnityPackageManagerConfig -ProjectManifestPath "" } | Should -Throw "*The argument is null or empty.*"
        }
    }
}