# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
Import-Module powershell-yaml -MinimumVersion '0.3' -ErrorAction Stop

[Flags()]
enum UnitySetupComponent {
    Windows = (1 -shl 0)
    Linux = (1 -shl 1)
    Mac = (1 -shl 2)
    Documentation = (1 -shl 3)
    StandardAssets = (1 -shl 4)
    Windows_IL2CPP = (1 -shl 5)
    Metro = (1 -shl 6)
    UWP_IL2CPP = (1 -shl 7)
    Android = (1 -shl 8)
    iOS = (1 -shl 9)
    AppleTV = (1 -shl 10)
    Facebook = (1 -shl 11)
    Vuforia = (1 -shl 12)
    WebGL = (1 -shl 13)
    All = (1 -shl 14) - 1
}

[Flags()]
enum OperatingSystem {
    Windows
    Linux
    Mac
}

class UnitySetupInstaller {
    [UnitySetupComponent] $ComponentType
    [UnityVersion] $Version
    [int64]$Length
    [DateTime]$LastModified
    [string]$DownloadUrl
}

class UnitySetupInstance {
    [UnityVersion]$Version
    [UnitySetupComponent]$Components
    [string]$Path

    UnitySetupInstance([string]$path) {

        $currentOS = Get-OperatingSystem
        $ivyPath = switch ($currentOS) {
            ([OperatingSystem]::Windows) { 'Editor\Data\UnityExtensions\Unity\Networking\ivy.xml' }
            ([OperatingSystem]::Linux) { throw "UnitySetupInstance has not been implemented on the Linux platform. Contributions welcomed!"; }
            ([OperatingSystem]::Mac) { 'Unity.app/Contents/UnityExtensions/Unity/Networking/ivy.xml' }
        }

        $ivyPath = [io.path]::Combine("$path", $ivyPath);
        if (!(Test-Path $ivyPath)) { throw "Path is not a Unity setup: $path"}
        [xml]$xmlDoc = Get-Content $ivyPath

        if ( !($xmlDoc.'ivy-module'.info.unityVersion)) {
            throw "Unity setup ivy is missing version: $ivyPath"
        }

        $this.Path = $path
        $this.Version = $xmlDoc.'ivy-module'.info.unityVersion

        $playbackEnginePath = $null
        $componentTests = switch ($currentOS) {
            ([OperatingSystem]::Windows) {
                $this.Components = [UnitySetupComponent]::Windows
                $playbackEnginePath = [io.path]::Combine("$Path", "Editor\Data\PlaybackEngines");
                @{
                    [UnitySetupComponent]::Documentation = , [io.path]::Combine("$Path", "Editor\Data\Documentation");
                    [UnitySetupComponent]::StandardAssets = , [io.path]::Combine("$Path", "Editor\Standard Assets");
                    [UnitySetupComponent]::Windows_IL2CPP = , [io.path]::Combine("$playbackEnginePath", "windowsstandalonesupport\Variations\win32_development_il2cpp");
                    [UnitySetupComponent]::Metro = [io.path]::Combine("$playbackEnginePath", "MetroSupport\Templates\UWP_.NET_D3D"),
                    [io.path]::Combine("$playbackEnginePath", "MetroSupport\Templates\UWP_D3D");
                    [UnitySetupComponent]::UWP_IL2CPP = , [io.path]::Combine("$playbackEnginePath", "MetroSupport\Templates\UWP_IL2CPP_D3D");
                    [UnitySetupComponent]::Linux = , [io.path]::Combine("$playbackEnginePath", "LinuxStandaloneSupport");
                    [UnitySetupComponent]::Mac = , [io.path]::Combine("$playbackEnginePath", "MacStandaloneSupport");
                }
            }
            ([OperatingSystem]::Linux) {
                $this.Components = [UnitySetupComponent]::Linux

                throw "UnitySetupInstance has not been implemented on the Linux platform. Contributions welcomed!";
            }
            ([OperatingSystem]::Mac) {
                $this.Components = [UnitySetupComponent]::Mac
                $playbackEnginePath = [io.path]::Combine("$Path", "PlaybackEngines");
                @{
                    [UnitySetupComponent]::Documentation = , [io.path]::Combine("$Path", "Documentation");
                    [UnitySetupComponent]::StandardAssets = , [io.path]::Combine("$Path", "Standard Assets");
                    [UnitySetupComponent]::Windows = , [io.path]::Combine("$playbackEnginePath", "WindowsStandaloneSupport");
                    [UnitySetupComponent]::Linux = , [io.path]::Combine("$playbackEnginePath", "LinuxStandaloneSupport");
                }
            }
        }

        # Common playback engines:
        $componentTests[[UnitySetupComponent]::Android] = , [io.path]::Combine("$playbackEnginePath", "AndroidPlayer");
        $componentTests[[UnitySetupComponent]::iOS] = , [io.path]::Combine("$playbackEnginePath", "iOSSupport");
        $componentTests[[UnitySetupComponent]::AppleTV] = , [io.path]::Combine("$playbackEnginePath", "AppleTVSupport");
        $componentTests[[UnitySetupComponent]::Facebook] = , [io.path]::Combine("$playbackEnginePath", "Facebook");
        $componentTests[[UnitySetupComponent]::Vuforia] = , [io.path]::Combine("$playbackEnginePath", "VuforiaSupport");
        $componentTests[[UnitySetupComponent]::WebGL] = , [io.path]::Combine("$playbackEnginePath", "WebGLSupport");

        $componentTests.Keys | ForEach-Object {
            foreach ( $test in $componentTests[$_] ) {
                if ( Test-Path -PathType Container -Path $test ) {
                    $this.Components += $_
                    break;
                }
            }
        }
    }
}

class UnityProjectInstance {
    [UnityVersion]$Version
    [string]$Path

    UnityProjectInstance([string]$path) {
        $versionFile = [io.path]::Combine($path, "ProjectSettings\ProjectVersion.txt")
        if (!(Test-Path $versionFile)) { throw "Path is not a Unity project: $path"}

        $fileVersion = (Get-Content $versionFile -Raw | ConvertFrom-Yaml)['m_EditorVersion'];
        if (!$fileVersion) { throw "Project is missing a version in: $versionFile"}

        $this.Path = $path
        $this.Version = $fileVersion
    }
}

class UnityVersion : System.IComparable {
    [int] $Major;
    [int] $Minor;
    [int] $Revision;
    [char] $Release;
    [int] $Build;
    [string] $Suffix;

    [string] ToString() {
        $result = "$($this.Major).$($this.Minor).$($this.Revision)$($this.Release)$($this.Build)"
        if ( $this.Suffix ) { $result += "-$($this.Suffix)"}
        return $result
    }

    UnityVersion([string] $version) {
        $parts = $version.Split('-')

        $parts[0] -match "(\d+)\.(\d+)\.(\d+)([fpb])(\d+)" | Out-Null
        if ( $Matches.Count -ne 6 ) { throw "Invalid unity version: $version" }
        $this.Major = [int]($Matches[1]);
        $this.Minor = [int]($Matches[2]);
        $this.Revision = [int]($Matches[3]);
        $this.Release = [char]($Matches[4]);
        $this.Build = [int]($Matches[5]);

        if ($parts.Length -gt 1) {
            $this.Suffix = $parts[1];
        }
    }

    [int] CompareTo([object]$obj) {
        if ($null -eq $obj) { return 1 }
        if ($obj -isnot [UnityVersion]) { throw "Object is not a UnityVersion"}

        return [UnityVersion]::Compare($this, $obj)
    }

    static [int] Compare([UnityVersion]$a, [UnityVersion]$b) {
        if ($a.Major -lt $b.Major) { return -1 }
        if ($a.Major -gt $b.Major) { return 1 }

        if ($a.Minor -lt $b.Minor) { return -1 }
        if ($a.Minor -gt $b.Minor) { return 1 }

        if ($a.Revision -lt $b.Revision) { return -1 }
        if ($a.Revision -gt $b.Revision) { return 1 }

        if ($a.Release -lt $b.Release) { return -1 }
        if ($a.Release -gt $b.Release) { return 1 }

        if ($a.Build -lt $b.Build) { return -1 }
        if ($a.Build -gt $b.Build) { return 1 }

        if ($a.Suffix -lt $b.Suffix) { return -1 }
        if ($a.Suffix -gt $b.Suffix) { return 1 }

        return 0
    }
}

<#
.Synopsis
   Easy way to determine the current operating system platform being executed on.
.DESCRIPTION
   Determine which operating system that's executing the script for things like path variants.
.OUTPUTS
   Get-OperatingSystem returns a [OperatingSystem] enumeration based off the Powershell platform being run on.
.EXAMPLE
   $OS = Get-OperatingSystem
.EXAMPLE
   # Loosely typed.
   switch (Get-OperatingSystem) {
       Windows { echo "On Windows" }
       Linux { echo "On Linux" }
       Mac { echo "On Mac" }
   }
.EXAMPLE
   # Strongly typed.
   switch (Get-OperatingSystem) {
       ([OperatingSystem]::Windows) { echo "On Windows" }
       ([OperatingSystem]::Linux) { echo "On Linux" }
       ([OperatingSystem]::Mac) { echo "On Mac" }
   }
.EXAMPLE
   if (Get-OperatingSystem == [OperatingSystem]::Linux) {
       echo "On Linux"
   }
#>
function Get-OperatingSystem {
    if ((-not $global:PSVersionTable.Platform) -or ($global:PSVersionTable.Platform -eq "Win32NT")) {
        return [OperatingSystem]::Windows
    }
    elseif ($global:PSVersionTable.OS.Contains("Linux")) {
        return [OperatingSystem]::Linux
    }
    elseif ($global:PSVersionTable.OS.Contains("Darwin")) {
        return [OperatingSystem]::Mac
    }
}

<#
.Synopsis
   Help to create UnitySetupComponent
.PARAMETER Components
   What components would you like included?
.EXAMPLE
   ConvertTo-UnitySetupComponent Windows,Metro
#>
function ConvertTo-UnitySetupComponent {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true, Position = 0)]
        [UnitySetupComponent] $Component
    )

    $Component
}

<#
.Synopsis
   Finds UnitySetup installers for a specified version.
.DESCRIPTION
   Finds UnitySetup component installers for a specified version by querying Unity's website.
.PARAMETER Version
   What version of Unity are you looking for?
.PARAMETER Components
   What components would you like to search for? Defaults to All
.EXAMPLE
   Find-UnitySetupInstaller -Version 2017.3.0f3
.EXAMPLE
   Find-UnitySetupInstaller -Version 2017.3.0f3 -Components Windows,Documentation
#>
function Find-UnitySetupInstaller {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)]
        [UnityVersion] $Version,

        [parameter(Mandatory = $false)]
        [UnitySetupComponent] $Components = [UnitySetupComponent]::All
    )

    $unitySetupRegEx = "^(.+)\/([a-z0-9]+)\/Windows64EditorInstaller\/UnitySetup64-(\d+)\.(\d+)\.(\d+)([fpb])(\d+).exe$"
    $knownBaseUrls = @(
        "https://download.unity3d.com/download_unity",
        "https://netstorage.unity3d.com/unity",
        "https://beta.unity3d.com/download"
    )

    $installerTemplates = @{
        [UnitySetupComponent]::Documentation = , "WindowsDocumentationInstaller/UnityDocumentationSetup-$Version.exe";
        [UnitySetupComponent]::StandardAssets = , "WindowsStandardAssetsInstaller/UnityStandardAssetsSetup-$Version.exe";
        [UnitySetupComponent]::Metro = , "TargetSupportInstaller/UnitySetup-Metro-Support-for-Editor-$Version.exe";
        [UnitySetupComponent]::UWP_IL2CPP = , "TargetSupportInstaller/UnitySetup-UWP-IL2CPP-Support-for-Editor-$Version.exe";
        [UnitySetupComponent]::Android = , "TargetSupportInstaller/UnitySetup-Android-Support-for-Editor-$Version.exe";
        [UnitySetupComponent]::iOS = , "TargetSupportInstaller/UnitySetup-iOS-Support-for-Editor-$Version.exe";
        [UnitySetupComponent]::AppleTV = , "TargetSupportInstaller/UnitySetup-AppleTV-Support-for-Editor-$Version.exe";
        [UnitySetupComponent]::Facebook = , "TargetSupportInstaller/UnitySetup-Facebook-Games-Support-for-Editor-$Version.exe";
        [UnitySetupComponent]::Linux = , "TargetSupportInstaller/UnitySetup-Linux-Support-for-Editor-$Version.exe";
        [UnitySetupComponent]::Mac = "TargetSupportInstaller/UnitySetup-Mac-Support-for-Editor-$Version.exe",
        "TargetSupportInstaller/UnitySetup-Mac-Mono-Support-for-Editor-$Version.exe";
        [UnitySetupComponent]::Vuforia = , "TargetSupportInstaller/UnitySetup-Vuforia-AR-Support-for-Editor-$Version.exe";
        [UnitySetupComponent]::WebGL = , "TargetSupportInstaller/UnitySetup-WebGL-Support-for-Editor-$Version.exe";
        [UnitySetupComponent]::Windows_IL2CPP = , "TargetSupportInstaller/UnitySetup-Windows-IL2CPP-Support-for-Editor-$Version.exe";
    }

    $currentOS = Get-OperatingSystem
    switch ($currentOS) {
        ([OperatingSystem]::Windows) {
            $setupComponent = [UnitySetupComponent]::Windows
            $installerTemplates[$setupComponent] = , "Windows64EditorInstaller/UnitySetup64-$Version.exe";
        }
        ([OperatingSystem]::Linux) {
            $setupComponent = [UnitySetupComponent]::Linux
            # TODO: $installerTemplates[$setupComponent] = , "???/UnitySetup64-$Version.exe";

            throw "Find-UnitySetupInstaller has not been implemented on the Linux platform. Contributions welcomed!";
        }
        ([OperatingSystem]::Mac) {
            $setupComponent = [UnitySetupComponent]::Mac
            # TODO: $installerTemplates[$setupComponent] = , "???/UnitySetup64-$Version.exe";

            throw "Find-UnitySetupInstaller has not been implemented on the Mac platform. Contributions welcomed!";
        }
    }

    # By default Tls12 protocol is not enabled, but is what backs Unity's website, so enable it
    $secProtocol = [System.Net.ServicePointManager]::SecurityProtocol
    if ( ($secProtocol -band [System.Net.SecurityProtocolType]::Tls12) -eq 0 ) {
        $secProtocol += [System.Net.SecurityProtocolType]::Tls12;
        [System.Net.ServicePointManager]::SecurityProtocol = $secProtocol
    }

    # Every release type has a different pattern for finding installers
    $searchPages = @()
    switch ($Version.Release) {
        'f' { $searchPages += "https://unity3d.com/get-unity/download/archive" }
        'b' { $searchPages += "https://unity3d.com/unity/beta/unity$Version" }
        'p' {
            $patchPage = "https://unity3d.com/unity/qa/patch-releases?version=$($Version.Major).$($Version.Minor)"
            $searchPages += $patchPage

            $webResult = Invoke-WebRequest $patchPage -UseBasicParsing 
            $searchPages += $webResult.Links | Where-Object { 
                $_.href -match "\/unity\/qa\/patch-releases\?version=$($Version.Major)\.$($Version.Minor)&page=(\d+)" -and $Matches[1] -gt 1
            } | ForEach-Object { "https://unity3d.com$($_.href)" }
        }
    }

    foreach ($page in $searchPages) {
        $webResult = Invoke-WebRequest $page -UseBasicParsing
        $prototypeLink = $webResult.Links | Select-Object -ExpandProperty href -ErrorAction SilentlyContinue | Where-Object {
            $_ -match "$($installerTemplates[$setupComponent])$"
        }

        if ($null -ne $prototypeLink) { break }
    }

    if ($null -eq $prototypeLink) {
        throw "Could not find archives for Unity version $Version"
    }

    $linkComponents = $prototypeLink -split $unitySetupRegEx -ne ""

    if ($knownBaseUrls -notcontains $linkComponents[0]) {
        $knownBaseUrls = $linkComponents[0], $knownBaseUrls
    }
    else {
        $knownBaseUrls = $knownBaseUrls | Sort-Object -Property @{ Expression = {[math]::Abs(($_.CompareTo($linkComponents[0])))}; Ascending = $true}
    }

    $installerTemplates.Keys |  Where-Object { $Components -band $_ } | ForEach-Object {
        $templates = $installerTemplates.Item($_);
        $result = $null
        foreach ($template in $templates ) {
            foreach ( $baseUrl in $knownBaseUrls) {
                $endpoint = [uri][System.IO.Path]::Combine($baseUrl, $linkComponents[1], $template);
                try {
                    $testResult = Invoke-WebRequest $endpoint -Method HEAD -UseBasicParsing
                    $result = New-Object UnitySetupInstaller -Property @{
                        'ComponentType' = $_;
                        'Version' = $Version;
                        'DownloadUrl' = $endpoint;
                        'Length' = [int64]$testResult.Headers['Content-Length'];
                        'LastModified' = ([System.DateTime]$testResult.Headers['Last-Modified']);
                    }

                    break
                }
                catch {
                    Write-Verbose "$endpoint failed: $_"
                }
            }

            if ( $result ) { break }
        }

        if ( -not $result ) {
            Write-Warning "Unable to find installer for the $_ component."
        }
        else { $result }
    } | Sort-Object -Property ComponentType
}

<#
.Synopsis
   Installs a UnitySetup instance.
.DESCRIPTION
   Downloads and installs UnitySetup installers found via Find-UnitySetupInstaller.
.PARAMETER Installers
   What installers would you like to download and execute?
.PARAMETER Destination
   Where would you like the UnitySetup instance installed?
.PARAMETER Cache
   Where should the installers be cached. This defaults to $env:USERPROFILE\.unitysetup.
.EXAMPLE
   Find-UnitySetupInstaller -Version 2017.3.0f3 | Install-UnitySetupInstance
.EXAMPLE
   Find-UnitySetupInstaller -Version 2017.3.0f3 | Install-UnitySetupInstance -Destination D:\Unity-2017.3.0f3
#>
function Install-UnitySetupInstance {
    [CmdletBinding()]
    param(
        [parameter(ValueFromPipeline = $true)]
        [UnitySetupInstaller[]] $Installers,

        [parameter(Mandatory = $false)]
        [string]$Destination,

        [parameter(Mandatory = $false)]
        [string]$Cache = [io.Path]::Combine($env:USERPROFILE, ".unitysetup"),

        [parameter(Mandatory = $false)]
        [ValidateSet('Open', 'RunAs')]
        [string]$Verb
    )

    process {
        if (!(Test-Path $Cache -PathType Container)) {
            New-Item $Cache -ItemType Directory -ErrorAction Stop | Out-Null
        }

        $localInstallers = @()
        $localDestinations = @()

        $downloadSource = @()
        $downloadDest = @()
        foreach ( $i in $Installers) {
            $fileName = [io.Path]::GetFileName($i.DownloadUrl)
            $destPath = [io.Path]::Combine($Cache, "Installers\Unity-$($i.Version)\$fileName")

            $localInstallers += , $destPath
            if ($Destination) {
                $localDestinations += , $Destination
            }
            else {
                $localDestinations += , "C:\Program Files\Unity-$($i.Version)"
            }

            if ( Test-Path $destPath ) {
                $destItem = Get-Item $destPath
                if ( ($destItem.Length -eq $i.Length ) -and ($destItem.LastWriteTime -eq $i.LastModified) ) {
                    Write-Verbose "Skipping download because it's already in the cache: $($i.DownloadUrl)"
                    continue
                }
            }

            $downloadSource += $i.DownloadUrl
            $downloadDest += $destPath
        }

        if ( $downloadSource.Length -gt 0 ) {
            for ($i = 0; $i -lt $downloadSource.Length; $i++) {
                Write-Verbose "Downloading $($downloadSource[$i]) to $($downloadDest[$i])"
                $destDirectory = [io.path]::GetDirectoryName($downloadDest[$i])
                if (!(Test-Path $destDirectory -PathType Container)) {
                    New-Item "$destDirectory" -ItemType Directory | Out-Null
                }
            }

            Start-BitsTransfer -Source $downloadSource -Destination $downloadDest
        }
       
        for ($i = 0; $i -lt $localInstallers.Length; $i++) {
            $installer = $localInstallers[$i]
            $destination = $localDestinations[$i]

            $startProcessArgs = @{
                'FilePath' = $installer;
                'ArgumentList' = @("/S", "/D=$destination");
                'PassThru' = $true;
                'Wait' = $true;
            }
            
            Write-Verbose "$(Get-Date): Installing $installer to $destination."
            $process = Start-Process @startProcessArgs
            if ( $process ) {
                if ( $process.ExitCode -ne 0) {
                    Write-Error "$(Get-Date): Failed with exit code: $($process.ExitCode)"
                }
                else { 
                    Write-Verbose "$(Get-Date): Succeeded."
                }
            }
        }
    }
}

<#
.Synopsis
   Uninstall Unity Setup Instances
.DESCRIPTION
   Uninstall the specified Unity Setup Instances
.PARAMETER Instance
   What instances of UnitySetup should be uninstalled
.EXAMPLE
   Get-UnitySetupInstance | Uninstall-UnitySetupInstance
#>
function Uninstall-UnitySetupInstance {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [UnitySetupInstance[]] $Instances
    )

    process {
        foreach ( $setupInstance in $Instances ) {
            $uninstaller = Get-ChildItem "$($setupInstance.Path)" -Filter 'Uninstall.exe' -Recurse |
                Select-Object -First 1 -ExpandProperty FullName

            if ($null -eq $uninstaller) {
                Write-Error "Could not find Uninstaller.exe under $($setupInstance.Path)"
                continue
            }

            $startProcessArgs = @{
                'FilePath' = $uninstaller;
                'PassThru' = $true;
                'Wait' = $true;
                'ErrorAction' = 'Stop';
                'ArgumentList' = @("/S");
            }

            if ( -not $PSCmdlet.ShouldProcess("$uninstaller", "Start-Process")) { continue }

            $process = Start-Process @startProcessArgs
            if ( $process.ExitCode -ne 0 ) {
                Write-Error "Uninstaller quit with non-zero exit code"
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
   Under what base patterns should we look for Unity installs?
.EXAMPLE
   Get-UnitySetupInstance
#>
function Get-UnitySetupInstance {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $false)]
        [string[]] $BasePath
    )

    switch (Get-OperatingSystem) {
        ([OperatingSystem]::Windows) {
            if (-not $BasePath) {
                $BasePath = @('C:\Program Files*\Unity*', 'C:\Program Files\Unity\Hub\Editor\*')
            }
            $ivyPath = 'Editor\Data\UnityExtensions\Unity\Networking\ivy.xml'
        }
        ([OperatingSystem]::Linux) {
            throw "Get-UnitySetupInstance has not been implemented on the Linux platform. Contributions welcomed!";
        }
        ([OperatingSystem]::Mac) {
            if (-not $BasePath) {
                $BasePath = @('/Applications/Unity*')
            }
            $ivyPath = 'Unity.app/Contents/UnityExtensions/Unity/Networking/ivy.xml'
        }
    }

    foreach ( $folder in $BasePath ) {
        $path = [io.path]::Combine("$folder", $ivyPath);

        Get-ChildItem  $path -Recurse -ErrorAction Ignore |
            ForEach-Object {
            [UnitySetupInstance]::new((Join-Path $_.Directory "..\..\..\..\..\" | Convert-Path))
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
#>
function Select-UnitySetupInstance {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $false)]
        [switch] $Latest,

        [parameter(Mandatory = $false)]
        [UnityVersion] $Version,

        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [UnitySetupInstance[]] $Instances
    )

    process {
        if ( $Version ) {
            $Instances = $Instances | Where-Object { [UnityVersion]::Compare($_.Version, $Version) -eq 0 }
        }

        if ( $Latest ) {
            foreach ( $i in $Instances ) {
                if ( $null -eq $latestInstance -or [UnityVersion]::Compare($i.Version, $latestInstance.Version) -gt 0) {
                    $latestInstance = $i
                }
            }
        }
        elseif ( $Instances.Count -gt 0 ) { $Instances }
    }
    end {
        if ($latestInstance) { $latestInstance }
    }
}

<#
.Synopsis
   Get the Unity Projects under a specfied folder
.DESCRIPTION
   Recursively discovers Unity projects and their Unity version
.PARAMETER BasePath
   Under what base pattern should we look for Unity projects? Defaults to '$PWD'.
.EXAMPLE
   Get-UnityProjectInstance
.EXAMPLE
   Get-UnityProjectInstance -BasePath .\MyUnityProjects -Recurse
#>
function Get-UnityProjectInstance {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $false)]
        [string] $BasePath = $PWD,

        [parameter(Mandatory = $false)]
        [switch] $Recurse
    )

    $args = @{
        'Path' = $BasePath;
        'Filter' = 'ProjectSettings';
        'ErrorAction' = 'Ignore';
        'Directory' = $true;
    }

    if ( $Recurse ) {
        $args['Recurse'] = $true;
    }

    Get-ChildItem @args |
        ForEach-Object {
        $path = [io.path]::Combine($_.FullName, "ProjectVersion.txt")
        if ( Test-Path $path ) {
            [UnityProjectInstance]::new((Join-Path $_.FullName "..\" | Convert-Path))
        }
    }
}

<#
.Synopsis
   Starts the Unity Editor
.DESCRIPTION
   If Project, Instance, and Latest are unspecified, tests if the current folder is a
   UnityProjectInstance, and if so, selects it as Project. Otherwise the latest
   UnitySetupInstance is selected as Instance.
.PARAMETER Project
   The project instance to open the Unity Editor for.
.PARAMETER Setup
   The setup instances to launch. If unspecified, the version at Project is selected.
.PARAMETER Latest
   Launch the latest version installed.
.PARAMETER Version
   Launch the specified version.
.PARAMETER IgnoreProjectContext
   Force operation as though $PWD is not a unity project.
.PARAMETER ExecuteMethod
   The script method for the Unity Editor to execute.
.PARAMETER OutputPath
   The output path that the Unity Editor should use.
.PARAMETER LogFile
   The log file for the Unity Editor to write to.
.PARAMETER BuildTarget
   The platform build target for the Unity Editor to start in.
.PARAMETER AcceptAPIUpdate
   Accept the API Updater automatically. Implies BatchMode unless explicitly specified by the user.
.PARAMETER Credential
   What user name and password should be used by Unity for activation?
.PARAMETER Serial
   What serial should be used by Unity for activation? Implies BatchMode and Quit if they're not supplied by the User.
.PARAMETER ReturnLicense
   Unity should return the current license it's been activated with. Implies Quit if not supplied by the User.
.PARAMETER BatchMode
   Should the Unity Editor start in batch mode?
.PARAMETER Quit
   Should the Unity Editor quit after it's done?
.PARAMETER Wait
   Should the command wait for the Unity Editor to exit?
.EXAMPLE
   Start-UnityEditor
.EXAMPLE
   Start-UnityEditor -Latest
.EXAMPLE
   Start-UnityEditor -Version 2017.3.0f3
.EXAMPLE
   Start-UnityEditor -ExecuteMethod Build.Invoke -BatchMode -Quit -LogFile .\build.log -Wait
.EXAMPLE
   Get-UnityProjectInstance -Recurse | Start-UnityEditor -BatchMode -Quit
.EXAMPLE
   Get-UnitySetupInstance | Start-UnityEditor
#>
function Start-UnityEditor {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = "Context")]
    param(
        [parameter(Mandatory = $false, ValueFromPipeline = $true, ParameterSetName = 'Projects', Position = 0)]
        [parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ProjectsLatest', Position = 0)]
        [parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ProjectsVersion', Position = 0)]
        [ValidateNotNullOrEmpty()]
        [UnityProjectInstance[]] $Project,
        [parameter(Mandatory = $false, ValueFromPipeline = $true, ParameterSetName = 'Setups')]
        [ValidateNotNullOrEmpty()]
        [UnitySetupInstance[]]$Setup,
        [parameter(Mandatory = $true, ParameterSetName = 'Latest')]
        [parameter(Mandatory = $true, ParameterSetName = 'ProjectsLatest')]
        [switch]$Latest,
        [parameter(Mandatory = $true, ParameterSetName = 'Version')]
        [parameter(Mandatory = $true, ParameterSetName = 'ProjectsVersion')]
        [UnityVersion]$Version,
        [parameter(Mandatory = $false, ParameterSetName = 'Latest')]
        [parameter(Mandatory = $false, ParameterSetName = 'Version')]
        [parameter(Mandatory = $false, ParameterSetName = 'Context')]
        [switch]$IgnoreProjectContext,
        [parameter(Mandatory = $false)]
        [string]$ExecuteMethod,
        [parameter(Mandatory = $false)]
        [string[]]$ExportPackage,
        [parameter(Mandatory = $false)]
        [string]$ImportPackage,
        [parameter(Mandatory = $false)]
        [string]$CreateProject,
        [parameter(Mandatory = $false)]
        [string]$OutputPath,
        [parameter(Mandatory = $false)]
        [string]$LogFile,
        [parameter(Mandatory = $false)]
        [ValidateSet('StandaloneOSX', 'StandaloneWindows', 'iOS', 'Android', 'StandaloneLinux', 'StandaloneWindows64', 'WebGL', 'WSAPlayer', 'StandaloneLinux64', 'StandaloneLinuxUniversal', 'Tizen', 'PSP2', 'PS4', 'XBoxOne', 'N3DS', 'WiiU', 'tvOS', 'Switch')]
        [string]$BuildTarget,
        [parameter(Mandatory = $false)]
        [switch]$AcceptAPIUpdate,
        [parameter(Mandatory = $false)]
        [pscredential]$Credential,
        [parameter(Mandatory = $false)]
        [securestring]$Serial,
        [parameter(Mandatory = $false)]
        [switch]$ReturnLicense,
        [parameter(Mandatory = $false)]
        [switch]$ForceFree,
        [parameter(Mandatory = $false)]
        [switch]$BatchMode,
        [parameter(Mandatory = $false)]
        [switch]$Quit,
        [parameter(Mandatory = $false)]
        [switch]$Wait,
        [parameter(Mandatory = $false)]
        [switch]$PassThru
    )
    process {
        switch -wildcard ( $PSCmdlet.ParameterSetName ) {
            'Context' {
                $projectInstances = [UnityProjectInstance[]]@()
                $setupInstances = [UnitySetupInstance[]]@()

                $currentFolderProject = if ( !$IgnoreProjectContext ) { Get-UnityProjectInstance $PWD.Path }
                if ($null -ne $currentFolderProject) {
                    $projectInstances += , $currentFolderProject
                }
                else {
                    $setupInstance = Get-UnitySetupInstance | Select-UnitySetupInstance -Latest
                    if ($setupInstance.Count -gt 0) {
                        $setupInstances += , $setupInstance
                    }
                }
            }
            'Projects*' {
                $projectInstances = $Project
                $setupInstances = [UnitySetupInstance[]]@()
            }
            'Setups' {
                $projectInstances = [UnityProjectInstance[]]@()
                $setupInstances = $Setup
            }
            'Latest' {
                $projectInstances = [UnityProjectInstance[]]@()

                $currentFolderProject = if (!$IgnoreProjectContext) { Get-UnityProjectInstance $PWD.Path }
                if ($null -ne $currentFolderProject) {
                    $projectInstances += , $currentFolderProject
                }
                elseif ( $Latest ) {
                    $setupInstance = Get-UnitySetupInstance | Select-UnitySetupInstance -Latest
                    if ($setupInstance.Count -gt 0) {
                        $setupInstances = , $setupInstance
                    }
                }
            }
            'Version' {
                $projectInstances = [UnityProjectInstance[]]@()

                $currentFolderProject = if (!$IgnoreProjectContext) { Get-UnityProjectInstance $PWD.Path }
                if ($null -ne $currentFolderProject) {
                    $projectInstances += , $currentFolderProject
                }
                elseif ($null -ne $Version) {
                    $setupInstance = Get-UnitySetupInstance | Select-UnitySetupInstance -Version $Version
                    if ($setupInstance.Count -gt 0) {
                        $setupInstances = , $setupInstance
                    }
                    else {
                        Write-Error "Could not find Unity Editor for version $Version"
                    }
                }
            }
        }

        $sharedArgs = @()
        if ( $ReturnLicense ) {
            if ( -not $PSBoundParameters.ContainsKey('BatchMode') ) { $BatchMode = $true }
            if ( -not $PSBoundParameters.ContainsKey('Quit') ) { $Quit = $true }

            $sharedArgs += '-returnLicense'
        }
        if ( $Serial ) {
            if ( -not $PSBoundParameters.ContainsKey('BatchMode') ) { $BatchMode = $true }
            if ( -not $PSBoundParameters.ContainsKey('Quit') ) { $Quit = $true }
        }
        if ( $AcceptAPIUpdate ) { 
            $sharedArgs += '-accept-apiupdate'
            if ( -not $PSBoundParameters.ContainsKey('BatchMode')) { $BatchMode = $true }
        }
        if ( $CreateProject ) { $sharedArgs += "-createProject", $CreateProject }
        if ( $ExecuteMethod ) { $sharedArgs += "-executeMethod", $ExecuteMethod }
        if ( $OutputPath ) { $sharedArgs += "-buildOutput", $OutputPath }
        if ( $LogFile ) { $sharedArgs += "-logFile", $LogFile }
        if ( $BuildTarget ) { $sharedArgs += "-buildTarget", $BuildTarget }
        if ( $BatchMode ) { $sharedArgs += "-batchmode" }
        if ( $Quit ) { $sharedArgs += "-quit" }
        if ( $ExportPackage ) { $sharedArgs += "-exportPackage", "$ExportPackage" }
        if ( $ImportPackage ) { $sharedArgs += "-importPackage", "$ImportPackage" }
        if ( $Credential ) { $sharedArgs += '-username', $Credential.UserName }
        if ( $ForceFree) { $sharedArgs += '-force-free' }

        $instanceArgs = @()
        foreach ( $p in $projectInstances ) {

            if ( $Latest ) {
                $setupInstance = Get-UnitySetupInstance | Select-UnitySetupInstance -Latest
                if ($setupInstance.Count -eq 0) {
                    Write-Error "Could not find any Unity Editor installed"
                    continue
                }
            }
            elseif ($null -ne $Version) {
                $setupInstance = Get-UnitySetupInstance | Select-UnitySetupInstance -Version $Version
                if ($setupInstance.Count -eq 0) {
                    Write-Error "Could not find Unity Editor for version $Version"
                    continue
                }
            }
            else {
                $setupInstance = Get-UnitySetupInstance | Select-UnitySetupInstance -Version $p.Version
                if ($setupInstance.Count -eq 0) {
                    Write-Error "Could not find Unity Editor for version $($p.Version)"
                    continue
                }
            }

            $projectPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($($p.Path))
            $instanceArgs += , ("-projectPath", $projectPath)
            $setupInstances += , $setupInstance
        }

        $currentOS = Get-OperatingSystem

        for ($i = 0; $i -lt $setupInstances.Length; $i++) {
            $setupInstance = $setupInstances[$i]

            switch ($currentOS) {
                ([OperatingSystem]::Windows) {
                    $editor = Get-ChildItem "$($setupInstance.Path)" -Filter 'Unity.exe' -Recurse |
                        Select-Object -First 1 -ExpandProperty FullName
    
                    if ([string]::IsNullOrEmpty($editor)) {
                        Write-Error "Could not find Unity.exe under setup instance path: $($setupInstance.Path)"
                        continue
                    }
                }
                ([OperatingSystem]::Linux) {
                    throw "Start-UnityEditor has not been implemented on the Linux platform. Contributions welcomed!";
                }
                ([OperatingSystem]::Mac) {
                    $editor = [io.path]::Combine("$($setupInstance.Path)", "Unity.app/Contents/MacOS/Unity")
    
                    if ([string]::IsNullOrEmpty($editor)) {
                        Write-Error "Could not find Unity app under setup instance path: $($setupInstance.Path)"
                        continue
                    }
                }
            }

            # clone the shared args list
            $unityArgs = $sharedArgs | ForEach-Object { $_ }
            if ( $instanceArgs[$i] ) { $unityArgs += $instanceArgs[$i] }

            $setProcessArgs = @{
                'FilePath' = $editor;
                'PassThru' = $true;
                'ErrorAction' = 'Stop';
                'RedirectStandardOutput' = New-TemporaryFile;
                'RedirectStandardError' = New-TemporaryFile;
            }

            if ($Wait) { $setProcessArgs['Wait'] = $true }

            Write-Verbose "Redirecting standard output to $($setProcessArgs['RedirectStandardOutput'])"
            Write-Verbose "Redirecting standard error to $($setProcessArgs['RedirectStandardError'])"

            $actionString = "$editor $unityArgs"
            if( $Credential ) { $actionString += " -password (hidden)"}
            if( $Serial ) { $actionString += " -serial (hidden)"}

            if (-not $PSCmdlet.ShouldProcess($actionString, "Start-Process")) {
                continue
            }

            # Defered till after potential display by ShouldProcess
            if ( $Credential ) { $unityArgs += '-password', $Credential.GetNetworkCredential().Password }
            if ( $Serial ) { $unityArgs += '-serial', [System.Net.NetworkCredential]::new($null, $Serial).Password }

            if ($unityArgs -and $unityArgs.Length -gt 0) {
                $setProcessArgs['ArgumentList'] = $unityArgs
            }

            $process = Start-Process @setProcessArgs
            if ( $Wait ) {
                if ( $process.ExitCode -ne 0 ) {
                    if ( $LogFile -and (Test-Path $LogFile -Type Leaf) ) {
                        Write-Verbose "Writing $LogFile to Information stream Tagged as 'Logs'"
                        Get-Content $LogFile | ForEach-Object { Write-Information -MessageData $_ -Tags 'Logs' }
                    }

                    Write-Error "Unity quit with non-zero exit code: $($process.ExitCode)"
                }
            }

            if ($PassThru) { $process }
        }
    }
}

function ConvertTo-DateTime {
    param([string] $Text)

    if( -not $text -or $text.Length -eq 0 ) { [DateTime]::MaxValue }
    else { [DateTime]$Text }
}

<#
.Synopsis
   Get the active Unity licenses for the machine.
.PARAMETER Serial
   Filter licenses to the specified serial
.EXAMPLE
   Get-UnityLicense
#>
function Get-UnityLicense
{
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Used to convert discovered plaintext serials into secure strings.")]
    param([SecureString]$Serial)

    $licenseFiles = Get-ChildItem "C:\ProgramData\Unity\Unity_*.ulf" -ErrorAction 'SilentlyContinue'
    foreach ( $licenseFile in $licenseFiles ) {
        Write-Verbose "Discovered License File at $licenseFile"
        $doc = [xml](Get-Content "$licenseFile")
        $devBytes = [System.Convert]::FromBase64String($doc.root.License.DeveloperData.Value)

        # The first four bytes look like a count so skip that to pull out the serial string
        $licenseSerial = [String]::new($devBytes[4..($devBytes.Length - 1)])
        if( $Serial -and [System.Net.NetworkCredential]::new($null, $Serial).Password -ne $licenseSerial ) { continue; }
        
        $license = $doc.root.License
        [PSCustomObject]@{
            'LicenseVersion' = $license.LicenseVersion.Value
            'Serial' = ConvertTo-SecureString $licenseSerial -AsPlainText -Force
            'UnityVersion' = [UnityVersion]$license.ClientProvidedVersion.Value
            'DisplaySerial' = $license.SerialMasked.Value
            'ActivationDate' = ConvertTo-DateTime $license.InitialActivationDate.Value
            'StartDate' = ConvertTo-DateTime $license.StartDate.Value
            'StopDate' = ConvertTo-DateTime $license.StopDate.Value
            'UpdateDate' = ConvertTo-DateTime $license.UpdateDate.Value
        }
    }
}

@(
    @{ 'Name' = 'gusi'; 'Value' = 'Get-UnitySetupInstance' },
    @{ 'Name' = 'gupi'; 'Value' = 'Get-UnityProjectInstance' },
    @{ 'Name' = 'susi'; 'Value' = 'Select-UnitySetupInstance' },
    @{ 'Name' = 'sue'; 'Value' = 'Start-UnityEditor' }
) | ForEach-Object {

    $alias = Get-Alias -Name $_.Name -ErrorAction 'SilentlyContinue'
    if ( -not $alias ) {
        Write-Verbose "Creating new alias $($_.Name) for $($_.Value)" 
        New-Alias @_ 
    }
    elseif ( $alias.ModuleName -eq 'UnitySetup' ) {
        Write-Verbose "Setting alias $($_.Name) to $($_.Value)" 
        Set-Alias @_
    }
    else {
        Write-Warning "Alias $($_.Name) already configured by $($alias.Source)"
    }
}
