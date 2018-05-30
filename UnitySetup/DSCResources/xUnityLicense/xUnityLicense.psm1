# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $Credential,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $Serial,

        [parameter(Mandatory = $false)]
        [System.String]
        $UnityVersion,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    @{ 'Licenses' = (Get-UnityLicense) }
}


function Set-TargetResource {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $Credential,

        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = 'Present',

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $Serial,

        [System.String]
        $UnityVersion,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    if ( Test-TargetResource @PSBoundParameters ) { return }

    $unityArgs = @{ 
        'Credential' = $Credential 
        'Wait'       = $true
    }

    if ( $UnityVersion ) { $unityArgs['Version'] = $UnityVersion }
    if ( $Ensure -eq 'Present' ) { $unityArgs['Serial'] = $Serial.Password }
    else { $unityArgs['ReturnLicense'] = $true }

    Start-UnityEditor @unityArgs -Verbose
}


function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $Credential,

        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = 'Present',

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $Serial,

        [parameter(Mandatory = $false)]
        [System.String]
        $UnityVersion,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    foreach ( $license in (Get-UnityLicense -Serial $Serial.Password) ) {
        Write-Verbose "Found license: $license"

        $currentSerial = [System.Net.NetworkCredential]::new($null, $license.Serial).Password
        $passedSerial = $Serial.GetNetworkCredential().Password 
        if ( $currentSerial -ne $passedSerial ) { continue }

        return $Ensure -eq 'Present'
    }

    return $Ensure -eq 'Absent'
}


Export-ModuleMember -Function *-TargetResource

