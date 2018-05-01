<#
    Uninstall multiple versions of Unity
#>
Configuration Sample_xUnity_Install {
    
    param(
        [PSCredential]$UnityCredential,
        [PSCredential]$UnitySerial
    )

    Import-DscResource -ModuleName UnitySetup

    Node 'localhost' {

        xUnitySetupInstance Unity {
            Versions = '2017.4.2f2'
            Ensure   = 'Absent'
            DependsOn = '[xUnityLicense]UnityLicense'   
        }

        xUnityLicense UnityLicense {
            Name = 'UL01'
            Credential = $UnityCredential
            Serial = $UnitySerial
            Ensure = 'Absent'
            UnityVersion = '2017.4.2f2'  
        }
    }
}