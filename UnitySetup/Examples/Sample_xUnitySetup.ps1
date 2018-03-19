<#
    Create a custom configuration by passing in necessary values
#>
Configuration Sample_xUnitySetup {
    param 
    (       
        [System.String]
        $Versions = '2017.3.0f3,2018.1.0b9',

        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [System.String[]]
        $Components = @('Setup', 'Linux', 'Metro', 'Mac', 'iOS')
    )

    Import-DscResource -ModuleName UnitySetup

    Node 'localhost' {

        xUnitySetup Unity {
            Versions   = $Versions
            Components = $Components
            Ensure     = $Ensure
        }
    }
}