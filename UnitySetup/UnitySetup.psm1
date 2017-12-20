# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

class UnityInstance
{
    [string]$InstallationVersion
    [string]$InstallationPath
}

class UnityProjectInstance
{
    [string]$ProjectPath
    [string]$UnityInstanceVersion
}

<#
.Synopsis
   Get the Unity Projects under a specfied folder
.DESCRIPTION
   Recursively discovers Unity projects and their UnityInstance version
.PARAMETER BasePath
   Under what base pattern should we look for Unity projects? Defaults to '$PWD'. 
.EXAMPLE
   Get-UnityProjectInstance
.EXAMPLE
   Get-UnityProjectInstance -BasePath .\MyUnityProjects -Recurse
#>
function Get-UnityProjectInstance
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$false)]
        [string] $BasePath = $PWD,

        [parameter(Mandatory=$false)]
        [switch] $Recurse
    )
    Import-Module powershell-yaml -Force -ErrorAction Stop

    $args = @{
        'Path' = $BasePath;
        'Filter' = 'ProjectSettings';
        'ErrorAction' = 'Ignore';
        'Directory' = $true;
    }

    if( $Recurse )
    {
        $args['Recurse'] = $true;
    }

    Get-ChildItem @args |
    ForEach-Object {
        $path = [io.path]::Combine($_.FullName, "ProjectVersion.txt")
        if( Test-Path $path )
        {
            $projectVersion = Get-Content $path -ErrorAction Stop | ConvertFrom-Yaml -ErrorAction Stop
            New-Object UnityProjectInstance -Property @{ 
                ProjectPath = Join-Path $_.FullName "..\" | Convert-Path
                UnityInstanceVersion = $projectVersion.m_EditorVersion
            }
        }
    }
}

<#
.Synopsis
   Get the Unity versions installed
.DESCRIPTION
   Get the Unity versions installed and their locations
.PARAMETER BasePath
   Under what base pattern should we look for Unity installs? Defaults to 'C:\Program Files*\Unity*'.
.EXAMPLE
   Get-UnitySetupInstance
#>
function Get-UnitySetupInstance
{
     [CmdletBinding()]
     param(
        [parameter(Mandatory=$false)]
        [string] $BasePath = 'C:\Program Files*\Unity*'
     )

     $Path = [io.path]::Combine("$BasePath", 'Editor\Data\UnityExtensions\Unity\Networking\ivy.xml');

     Get-ChildItem  $Path -Recurse -ErrorAction Ignore | 
     ForEach-Object {
         
         [xml]$xmlDoc = Get-Content $_
         
         if( $xmlDoc.'ivy-module'.info.unityVersion) {
            New-Object UnityInstance -Property @{ 
                InstallationVersion = $xmlDoc.'ivy-module'.info.unityVersion
                InstallationPath = Join-Path $_.Directory "..\..\..\..\" | Convert-Path
            }
         }        
     }
}

<#
.Synopsis
   Selects a unity setup instance
.DESCRIPTION
   Given a set of unity setup instances, this will select the best one matching your requirements
.PARAMETER Latest
   Select the latest version available.
.PARAMETER Version
   Select only instances matching Version.
.PARAMETER Project
   Select only instances matching the version of the project at Project.
.PARAMETER instances
   The list of instances to Select from.
.EXAMPLE
   Get-UnitySetupInstance | Select-UnitySetupInstance -Latest
.EXAMPLE
   Get-UnitySetupInstance | Select-UnitySetupInstance -Version 2017.1.0f3
.EXAMPLE
   Get-UnitySetupInstance | Select-UnitySetupInstance -Project C:\MyUnityProject
#>
function Select-UnitySetupInstance
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$false)]
        [switch] $Latest,

        [parameter(Mandatory=$false)]
        [string] $Version,

        [parameter(Mandatory=$false)]
        [string] $Project,

        [parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [UnityInstance[]]$instances
    )

    begin 
    {
        if( $Project )
        {
            $Version = Get-UnityProjectInstance -BasePath $Project | 
                Select-Object -First 1 -ExpandProperty UnityInstanceVersion
        }
    }
    process
    {
        if( $Version )
        { 
            $instances = $instances | Where-Object { $_.InstallationVersion -eq $Version }
        }

        foreach( $i in $instances ) 
        { 
            if( $Latest )
            {
                if( $latestInstance )
                {
                    $i.InstallationVersion -match "(\d+)\.(\d+)\.(\d+)([fpb])(\d+)" | Out-Null
                    $iMajor = [int]($Matches[1]);
                    $iMinor = [int]($Matches[2]);
                    $iRevA = [int]($Matches[3]);
                    $iBuild = [string]($Matches[4]);
                    $iRevB = [int]($Matches[5]);

                    $latestInstance.InstallationVersion -match "(\d+)\.(\d+)\.(\d+)([fpb])(\d+)" | Out-Null
                    $lMajor = [int]($Matches[1]);
                    $lMinor = [int]($Matches[2]);
                    $lRevA = [int]($Matches[3]);
                    $lBuild = [string]($Matches[4]);
                    $lRevB = [int]($Matches[5]);

                    if($iMajor -lt $lMajor) { continue; }
                    elseif( $iMajor -eq $lMajor)
                    {
                        if( $iMinor -lt $lMinor ) { continue; }
                        elseif($iMinor -eq $lMinor)
                        {
                            if($iBuild -lt $lBuild) {continue;}
                            elseif( $iBuild -eq $lBuild)
                            {
                                if($iRevA -lt $lRevA) { continue;}
                                elseif($iRevA -eq $lRevA)
                                {
                                    if( $iRevB -lt $lRevB) { continue;} 
                                }
                            }
                        }
                    }
                }
                
                $latestInstance = $i
            }
            else
            {
                $i
            } 
        }
    }
    end
    {
        if($latestInstance) { $latestInstance }
    }
}

<#
.Synopsis
   Starts the Unity Editor
.DESCRIPTION
   Finds and starts the Unity Editor for the project with the given arguments.
.PARAMETER Instance
   The specific instance to launch. If unspecified, the version at Project is selected.
.PARAMETER Project
   The project to open the Unity Editor for. Defaults to $PWD.
.PARAMETER ExecuteMethod
   The script method for the Unity Editor to execute.
.PARAMETER OutputPath
   The output path that the Unity Editor should use.
.PARAMETER LogFile
   The log file for the Unity Editor to write to.
.PARAMETER BuildTarget
   The platform build target for the Unity Editor to start in.
.PARAMETER BatchMode
   Should the Unity Editor start in batch mode?
.PARAMETER Quit
   Should the Unity Editor quit after it's done?
.PARAMETER Wait
   Should the command wait for the Unity Editor to exit?
.EXAMPLE
   Start-UnityEditor
.EXAMPLE
   Start-UnityEditor -ExecuteMethod Build.Invoke -BatchMode -Quit -LogFile .\build.log -Wait
#>
function Start-UnityEditor
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$false, ValueFromPipeline=$true)]
        [UnityInstance]$Instance,
        [parameter(Mandatory = $false)]
        [string] $Project = $PWD,
        [parameter(Mandatory = $false)]
        [string] $ExecuteMethod,
        [parameter(Mandatory = $false)]
        [string] $OutputPath,
        [parameter(Mandatory = $false)]
        [string] $LogFile,
        [parameter(Mandatory = $false)]
        [string] $BuildTarget,
        [parameter(Mandatory = $false)]
        [switch] $BatchMode,
        [parameter(Mandatory = $false)]
        [switch] $Quit,
        [parameter(Mandatory = $false)]
        [switch] $Wait
    )

    if( $Instance -eq $null )
    {
        $version = Get-UnityProjectInstance -BasePath $Project | Select-Object -First 1 -ExpandProperty UnityInstanceVersion
        $Instance =  Get-UnitySetupInstance | Select-UnitySetupInstance -Version $version
    }
    else 
    {
        $version = $Instance.InstallationVersion
    }
   
    $unityPath = $Instance.InstallationPath

    if ( !$unityPath -or $unityPath -eq "" ) {
        throw "Could not find Unity Editor for version $version"
    }

    $editor = Get-ChildItem "$unityPath" -Filter Unity.exe -Recurse | Select-Object -First 1 -ExpandProperty FullName

    $args = @()
    $args += "-projectPath"
    $args += $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Project)

    if( $ExecuteMethod )
    {
        $args += "-executeMethod"
        $args += $ExecuteMethod
    }

    if( $OutputPath )
    {
        $args += "-buildOutput"
        $args += $OutputPath
    }

    if( $LogFile )
    {
        $args += "-logFile"
        $args += $LogFile
    }

    if( $BuildTarget )
    {
        $args += "-buildTarget"
        $args += $BuildTarget
    }

    if( $BatchMode )
    {
        $args += "-batchmode"
    }

    if( $Quit )
    {
        $args += "-quit"
    }

    Write-Host "$editor $args" -ForegroundColor Green
    $process = Start-Process -FilePath $editor -ArgumentList $args -PassThru -ErrorAction Stop

    if( $Wait )
    {
        $process.WaitForExit();
        if( $process.ExitCode -ne 0 )
        {
            if( $LogFile )
            {
                Get-Content $LogFile | Write-Host
            }

            throw "Unity quit with non-zero exit code"
        }
    }
}