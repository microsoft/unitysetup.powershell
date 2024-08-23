Describe 'Find-UnitySetupInstaller' {

    BeforeEach {
        Import-Module "$PSScriptRoot\..\..\UnitySetup\UnitySetup.psd1" -Force
    }

    Context 'Input Validation' {
        It 'throws on invalidly formatted version' {
            { Find-UnitySetupInstaller -Version "" } | Should -Throw "Cannot process argument transformation*"
        }
    }

    Context 'Function Execution' {
        It 'throws on non-existent version' {
            { Find-UnitySetupInstaller -Version "1.2.3f1" } | Should -Throw "Could not find archives for Unity version*"
        }

        It 'finds an existing version' {
            # https://unity.com/releases/editor/whats-new/2022.3.15 lists 13 for Windows, but we don't support Mac_Server
            Find-UnitySetupInstaller -Version "2022.3.15f1" -ExplicitOS Windows | Should -HaveCount 12
        }

        # TODO: Support Mac ARM as a platform
        # It 'does not find VisionOS before supported (Mac)' {
        #     Find-UnitySetupInstaller -Version "2022.3.15f1" -Components VisionOS -ExplicitOS Mac | Should -HaveCount 0
        # }

        # It 'does find VisionOS once supported (Mac)' {
        #     Find-UnitySetupInstaller -Version "2022.3.18f1" -Components VisionOS -ExplicitOS Mac | Should -HaveCount 1
        # }

        It 'does not find VisionOS before supported (Windows)' {
            Find-UnitySetupInstaller -Version "2022.3.18f1" -Components VisionOS -ExplicitOS Windows `
            | Should -HaveCount 0
        }

        It 'finds VisionOS once supported (Windows, explicit)' {
            Find-UnitySetupInstaller -Version "2022.3.21f1" -Components VisionOS -ExplicitOS Windows `
            | Should -HaveCount 1
        }

        It 'finds VisionOS once supported (Windows, implicit)' {
            Find-UnitySetupInstaller -Version "2022.3.21f1" -ExplicitOS Windows `
            | Where-Object -Property ComponentType -Eq VisionOS `
            | Should -HaveCount 1
        }
    }
}
