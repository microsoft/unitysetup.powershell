<#
    Install multiple versions of Unity and several components
#>
Configuration Sample_xUnitySetupInstance_Install {

    param(
        [PSCredential]$UnityCredential,
        [PSCredential]$UnitySerial
    )

    Import-DscResource -ModuleName UnitySetup

    Node 'localhost' {

        xUnitySetupInstance Unity {
            Versions   = '2017.4.2f2'
            Components = 'Windows', 'Mac', 'Linux', 'Metro', 'iOS', 'Android'
            Ensure     = 'Present'
        }

        xUnityLicense UnityLicense {
            Name = 'UL01'
            Credential = $UnityCredential
            Serial = $UnitySerial
            Ensure = 'Present'
            UnityVersion = '2017.4.2f2'
            DependsOn = '[xUnitySetupInstance]Unity'   
        }
    }
}