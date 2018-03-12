<#
    Uninstall multiple versions of Unity
#>
Configuration Sample_xUnitySetup_Install {

    Import-DscResource -ModuleName UnitySetup

    Node 'localhost' {

        xUnitySetup Unity {
            Versions = '2017.3.1f1,2018.1.0b9'
            Ensure = 'Absent'
        }
    }
}