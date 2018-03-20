
<#
.Synopsis
    Returns the status of Unity installs and the set of their overlapping components.
.Parameter Versions
    The versions of Unity to test for.
#>
function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Versions
    )
    Write-Verbose "Begin executing Get on $Versions"

    [string[]]$splitVersions = $Versions -split ',' | ForEach-Object { $_.Trim() }
    
    $setupInstances = Get-UnitySetupInstance | Where-Object { $splitVersions -contains $_.Version }
    $result = @{
        "Versions" = $setupInstances | Select-Object -ExpandProperty Version | Sort-Object -Unique
        "Ensure"   = if ($setupInstances.Count -gt 0) { 'Present'} else { 'Absent' }
    }

    Write-Verbose "Found versions: $($result['Versions'])"

    if ( $setupInstances.Count -gt 0 ) {
        $components = $setupInstances[0].Components;
        for ( $i = 1; $i -lt $setupInstances.Count; $i++) {
            $components = $components -band $setupInstances[$i].Components; 
        }
        
        $result["Components"] = $components
    }

    $result

    Write-Verbose "Found overlapping components: $($result['Components'])"
    Write-Verbose "End executing Get on $Versions"
}

<#
.Synopsis
    Installs or uninstalls the specified Versions of Unity and corresponding Components.
.Parameter Versions
    What versions are we concered with?
.Parameter Ensure
    Should we ensure they're there or ensure they're not?
.Parameter Components
    What components are we concerned with?
.Notes
    Only uninstalls whole versions of Unity. Ensuring components doesn't
    mean other components weren't previously installed and aren't still available.
#>
function Set-TargetResource {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Versions,

        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = 'Present',

        [System.String[]]
        $Components = @('All')
    )

    Write-Verbose "Begin executing Set to Ensure $Versions with $Components are $Ensure"

    [string[]]$splitVersions = $Versions -split ',' | ForEach-Object { $_.Trim() }
        
    switch ($Ensure) {
        'Present' {
            foreach ($version in $splitVersions) {
                $findArgs = @{ 
                    'Version'    = $version
                    'Components' = New-UnitySetupComponent -Components $Components 
                }

                $installArgs = @{ 'Cache' = "$env:TEMP\.unitysetup" }

                $setupInstances = Get-UnitySetupInstance | Select-UnitySetupInstance -Version $version
                if ($setupInstances.Count -gt 0) {
                    $findArgs["Components"] = ($findArgs.Components -band (-bnot ($setupInstances[0].Components -band $findArgs.Components)))
                    $installArgs["Destination"] = $setupInstances[0].Path
                }

                # No missing components for this version
                if ( $findArgs.Components -eq 0 ) { 
                    Write-Verbose "All components of $version were installed"
                    continue; 
                }
                
                Write-Verbose "Finding $($findArgs["Components"]) installers for $version"
                $installArgs["Installers"] = Find-UnitySetupInstaller @findArgs -WarningAction Stop
                if ( $installArgs.Installers.Count -gt 0 ) {
                    Write-Verbose "Starting install of $($installArgs.Installers.Count) components for $version"
                    Install-UnitySetupInstance @installArgs
                    Write-Verbose "Finished install of $($installArgs.Installers.Count) components for $version"
                }
            }
        }
        'Absent' {
            $setupInstances = Get-UnitySetupInstance | Where-Object { $splitVersions -contains $_.Version }
            Write-Verbose "Found $($setupInstances.Count) instance(s) of $splitVersions"

            if ( $setupInstances.Count -gt 0 ) {
                Write-Verbose "Starting uninstall of $($setupInstances.Count) versions of Unity"
                Uninstall-UnitySetupInstance -Instances $setupInstances
                Write-Verbose "Finished uninstall of $($setupInstances.Count) versions of Unity"
            }
        }
    }

    Write-Verbose "End executing Set to Ensure $Versions with $Components are $Ensure"
}

<#
.Synopsis
    Test if the Unity installs are in the desired state.
.Parameter Versions
    What versions are we concered with?
.Parameter Ensure
    Should we ensure they're there or ensure they're not?
.Parameter Components
    What components are we concerned with?
.Notes
    This test is not strict. Versions and Components not described are not considered.
#>
function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Versions,

        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = 'Present',

        [System.String[]]
        $Components = @('All')
    )

    Write-Verbose "Begin executing Test to verify $Versions with $Components are $Ensure"
    
    [string[]]$splitVersions = $Versions -split ',' | ForEach-Object { $_.Trim() }

    $result = $true
    switch ( $Ensure ) {
        'Present' {
            $setupComponents = New-UnitySetupComponent -Components $Components
            foreach ($version in $splitVersions) {
                Write-Verbose "Starting test for $version"
                $setupInstances = Get-UnitySetupInstance | Select-UnitySetupInstance -Version $version
                Write-Verbose "Found $($setupInstances.Count) instance(s) of $version"

                if ($setupInstances.Count -eq 0) {
                    Write-Verbose "Found $version missing."
                    $result = $false
                    break 
                }
                
                $availableComponents = ($setupInstances[0].Components -band $setupComponents)
                if ($availableComponents -ne $setupComponents) { 
                    $missingComponents = New-UnitySetupComponent ($setupComponents -bxor $availableComponents)
                    Write-Verbose "Found $version missing $($missingComponents)"
                    $result = $false 
                    break
                }
            }
        }
        'Absent' { 
            foreach ($version in $splitVersions) {
                $setupInstances = Get-UnitySetupInstance | Select-UnitySetupInstance -Version $version
                Write-Verbose "Found $($setupInstances.Count) instance(s) of $version"

                if ($setupInstances.Count -gt 0) {
                    Write-Verbose "Found $version installed."
                    $result = $false 
                    break
                }
            }
        }
    }

    $result

    Write-Verbose "End executing Test to verify $Versions with $Components are $Ensure"
}


Export-ModuleMember -Function *-TargetResource

