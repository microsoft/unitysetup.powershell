<#
    Create a custom configuration by passing in necessary values
#>
Configuration Sample_xUnity {
    param 
    (       
        [System.String]
        $Version = '2017.4.2f2',

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
            Versions   = $Version
            Components = $Components
            Ensure     = $Ensure
            DependsOn  = if( $Ensure -eq 'Absent' ) { '[xUnityLicense]UnityLicense' } else { $null }
        }

        xUnityLicense UnityLicense {
            Name = 'UL01'
            Credential = $UnityCredential
            Serial = $UnitySerial
            Ensure = $Ensure
            UnityVersion = $Version
            DependsOn = if( $Ensure -eq 'Present' ) { '[xUnitySetupInstance]Unity' } else { $null }
        }
    }
}