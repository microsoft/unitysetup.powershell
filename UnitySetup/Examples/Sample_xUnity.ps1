<#
    Create a custom configuration by passing in necessary values
#>
Configuration Sample_xUnitySetupInstance {
    param 
    (       
        [System.String]
        $Versions = '2017.4.2f2'

        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [System.String[]]
        $Components = @('Windows', 'Mac', 'Linux', 'Metro', 'iOS', 'Android'),

        [PSCredential]
        $UnityCredential,

        [PSCredential]
        $UnitySerial
    )

    Import-DscResource -ModuleName UnitySetup

    Node 'localhost' {

        xUnitySetupInstance Unity {
            Versions   = $Versions
            Components = $Components
            Ensure     = $Ensure
            DependsOn  = if( $Ensure -eq 'Absent' ) { '[xUnityLicense]UnityLicense' }
        }

        xUnityLicense UnityLicense {
            Name = 'UL01'
            Credential = $UnityCredential
            Serial = $UnitySerial
            Ensure = $Ensure
            DependsOn = if( $Ensure -eq 'Present' ) { '[xUnitySetupInstance]Unity' }
        }
    }
}