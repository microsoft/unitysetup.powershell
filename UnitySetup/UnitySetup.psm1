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
    UWP = (1 -shl 6)
    UWP_IL2CPP = (1 -shl 7)
    Android = (1 -shl 8)
    iOS = (1 -shl 9)
    AppleTV = (1 -shl 10)
    Facebook = (1 -shl 11)
    Vuforia = (1 -shl 12)
    WebGL = (1 -shl 13)
    Mac_IL2CPP = (1 -shl 14)
    Lumin = (1 -shl 15)
    Linux_IL2CPP = (1 -shl 16)
    Windows_Server = (1 -shl 17)
    All = (1 -shl 18) - 1
}

[Flags()]
enum OperatingSystem {
    Windows
    Linux
    Mac
}

class UnitySetupResource {
    [UnitySetupComponent] $ComponentType
    [string] $Path
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

        $this.Path = $path
        $this.Version = Get-UnitySetupInstanceVersion -Path $path
        if ( -not $this.Version ) { throw "Unable to find version for $path" }

        $playbackEnginePath = $null
        $componentTests = switch ($currentOS) {
            ([OperatingSystem]::Windows) {
                $this.Components = [UnitySetupComponent]::Windows
                $playbackEnginePath = [io.path]::Combine("$Path", "Editor\Data\PlaybackEngines");
                @{
                    [UnitySetupComponent]::Documentation  = , [io.path]::Combine("$Path", "Editor\Data\Documentation");
                    [UnitySetupComponent]::StandardAssets = , [io.path]::Combine("$Path", "Editor\Standard Assets");
                    [UnitySetupComponent]::Windows_IL2CPP = , [io.path]::Combine("$playbackEnginePath", "windowsstandalonesupport\Variations\win32_development_il2cpp"),
                                                              [io.path]::Combine("$playbackEnginePath", "windowsstandalonesupport\Variations\win32_player_development_il2cpp");
                    [UnitySetupComponent]::UWP            =   [io.path]::Combine("$playbackEnginePath", "MetroSupport\Templates\UWP_.NET_D3D"),
                                                              [io.path]::Combine("$playbackEnginePath", "MetroSupport\Templates\UWP_D3D");
                    [UnitySetupComponent]::UWP_IL2CPP     = , [io.path]::Combine("$playbackEnginePath", "MetroSupport\Templates\UWP_IL2CPP_D3D");
                    [UnitySetupComponent]::Linux          = , [io.path]::Combine("$playbackEnginePath", "LinuxStandaloneSupport\Variations\linux64_headless_development_mono");
                    [UnitySetupComponent]::Linux_IL2CPP   = , [io.path]::Combine("$playbackEnginePath", "LinuxStandaloneSupport\Variations\linux64_headless_development_il2cpp");
                    [UnitySetupComponent]::Mac            = , [io.path]::Combine("$playbackEnginePath", "MacStandaloneSupport");
                    [UnitySetupComponent]::Windows_Server = , [io.path]::Combine("$playbackEnginePath", "WindowsStandaloneSupport\Variations\win32_player_development_mono"),
                                                              [io.path]::Combine("$playbackEnginePath", "WindowsStandaloneSupport\Variations\win32_server_development_il2cpp"),
                                                              [io.path]::Combine("$playbackEnginePath", "WindowsStandaloneSupport\Variations\win32_server_development_mono"),
                                                              [io.path]::Combine("$playbackEnginePath", "WindowsStandaloneSupport\Variations\win64_player_development_mono"),
                                                              [io.path]::Combine("$playbackEnginePath", "WindowsStandaloneSupport\Variations\win64_server_development_il2cpp"),
                                                              [io.path]::Combine("$playbackEnginePath", "WindowsStandaloneSupport\Variations\win64_server_development_mono");   
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
                    [UnitySetupComponent]::Documentation  = , [io.path]::Combine("$Path", "Documentation");
                    [UnitySetupComponent]::StandardAssets = , [io.path]::Combine("$Path", "Standard Assets");
                    [UnitySetupComponent]::Mac_IL2CPP     = , [io.path]::Combine("$playbackEnginePath", "MacStandaloneSupport/Variations/macosx64_development_il2cpp");
                    [UnitySetupComponent]::Windows        = , [io.path]::Combine("$playbackEnginePath", "WindowsStandaloneSupport");
                    [UnitySetupComponent]::Linux          = , [io.path]::Combine("$playbackEnginePath", "LinuxStandaloneSupport/Variations/linux64_headless_development_mono");
                    [UnitySetupComponent]::Linux_IL2CPP   = , [io.path]::Combine("$playbackEnginePath", "LinuxStandaloneSupport/Variations/linux64_headless_development_il2cpp");
                }
            }
        }

        # Common playback engines:
        $componentTests[[UnitySetupComponent]::Lumin]    = , [io.path]::Combine("$playbackEnginePath", "LuminSupport");
        $componentTests[[UnitySetupComponent]::Android]  = , [io.path]::Combine("$playbackEnginePath", "AndroidPlayer");
        $componentTests[[UnitySetupComponent]::iOS]      = , [io.path]::Combine("$playbackEnginePath", "iOSSupport");
        $componentTests[[UnitySetupComponent]::AppleTV]  = , [io.path]::Combine("$playbackEnginePath", "AppleTVSupport");
        $componentTests[[UnitySetupComponent]::Facebook] = , [io.path]::Combine("$playbackEnginePath", "Facebook");
        $componentTests[[UnitySetupComponent]::Vuforia]  = , [io.path]::Combine("$playbackEnginePath", "VuforiaSupport");
        $componentTests[[UnitySetupComponent]::WebGL]    = , [io.path]::Combine("$playbackEnginePath", "WebGLSupport");

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
    [string]$ProductName

    UnityProjectInstance([string]$path) {
        $versionFile = [io.path]::Combine($path, "ProjectSettings\ProjectVersion.txt")
        if (!(Test-Path $versionFile)) { throw "Path is not a Unity project: $path" }

        $fileVersion = (Get-Content $versionFile -Raw | ConvertFrom-Yaml)['m_EditorVersion'];
        if (!$fileVersion) { throw "Project is missing a version in: $versionFile" }

        $projectSettingsFile = [io.path]::Combine($path, "ProjectSettings\ProjectSettings.asset")
        if (!(Test-Path $projectSettingsFile)) { throw "Project is missing ProjectSettings.asset" }

        try { 
            $prodName = ((Get-Content $projectSettingsFile -Raw | ConvertFrom-Yaml)['playerSettings'])['productName']
            if (!$prodName) { throw "ProjectSettings is missing productName" }
        }
        catch {
            $msg = "Could not read $projectSettingsFile, in the Unity project try setting Editor Settings > Asset Serialiazation Mode to 'Force Text'."
            $msg += "`nAn Exception was caught!"
            $msg += "`nException Type: $($_.Exception.GetType().FullName)"
            $msg += "`nException Message: $($_.Exception.Message)"
            Write-Warning -Message $msg
            
            $prodName = $null
        }

        $this.Path = $path
        $this.Version = $fileVersion
        $this.ProductName = $prodName
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
        if ( $this.Suffix ) { $result += "-$($this.Suffix)" }
        return $result
    }

    UnityVersion([string] $version) {
        $parts = $version.Split('-')

        $parts[0] -match "(\d+)\.(\d+)\.(\d+)([fpba])(\d+)" | Out-Null
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
        if ($obj -isnot [UnityVersion]) { throw "Object is not a UnityVersion" }

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
   if (Get-OperatingSystem -eq [OperatingSystem]::Linux) {
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
   Get the Unity Editor application
.PARAMETER Path
   Path of a UnitySetupInstance
.EXAMPLE
   Get-UnityEditor -Path $unitySetupInstance.Path
#>
function Get-UnityEditor {
    [CmdletBinding()]
    param(
        [ValidateScript( { Test-Path $_ -PathType Container } )]
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 0, ParameterSetName = "Path")]
        [string[]]$Path = $PWD,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0, ParameterSetName = "Instance")]
        [ValidateNotNull()]
        [UnitySetupInstance[]]$Instance
    )

    process {

        if ( $PSCmdlet.ParameterSetName -eq "Instance" ) {
            $Path = $Instance.Path
        }

        $currentOS = Get-OperatingSystem
        foreach ($p in $Path) {
            switch ($currentOS) {
                ([OperatingSystem]::Windows) {
                    $editor = Join-Path "$p" 'Editor\Unity.exe'
                    
                    if (Test-Path $editor) {
                        Write-Output (Resolve-Path $editor).Path
                    }
                }
                ([OperatingSystem]::Linux) {
                    throw "Get-UnityEditor has not been implemented on the Linux platform. Contributions welcomed!";
                }
                ([OperatingSystem]::Mac) {
                    $editor = Join-Path "$p" "Unity.app/Contents/MacOS/Unity"

                    if (Test-Path $editor) {
                        Write-Output (Resolve-Path $editor).Path
                    }
                }
            }
        }
    }
}

<#
.Synopsis
   Help to create UnitySetupComponent
.PARAMETER Components
   What components would you like included?
.PARAMETER Version
   Allows for conversion that can take into account version restrictions
   E.g. 2019.x only supports UWP_IL2CPP
.EXAMPLE
   ConvertTo-UnitySetupComponent Windows,UWP
.EXAMPLE
   ConvertTo-UnitySetupComponent Windows,UWP -Version 2019.3.4f1
#>
function ConvertTo-UnitySetupComponent {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true, Position = 0)]
        [UnitySetupComponent] $Component,
        [parameter(Mandatory = $false)]
        [UnityVersion] $Version
    )
    
    if ($Version) {
        if ($Version.Major -ge 2019) {
            if ($Component -band [UnitySetupComponent]::UWP) {
                if ( $Component -band [UnitySetupComponent]::UWP_IL2CPP) {
                    Write-Verbose "2019.x only supports IL2CPP for UWP - removing $([UnitySetupComponent]::UWP)"
                }
                else {
                    Write-Verbose "2019.x only supports IL2CPP for UWP - swapping to $([UnitySetupComponent]::UWP_IL2CPP)"
                    $Component += [UnitySetupComponent]::UWP_IL2CPP;
                }

                $Component -= [UnitySetupComponent]::UWP;
            }
        }
    }

    $Component
}

<#
.Synopsis
   Finds UnitySetup installers for a specified version.
.DESCRIPTION
   Finds UnitySetup component installers for a specified version by querying Unity's website.
.PARAMETER Version
   What version of Unity are you looking for?
.PARAMETER Hash
   Manually specify the build hash, to select a private build.
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
        [UnitySetupComponent] $Components = [UnitySetupComponent]::All,

        [parameter(Mandatory = $false)]
        [string] $Hash = ""
    )

    $Components = ConvertTo-UnitySetupComponent -Component $Components -Version $Version

    $currentOS = Get-OperatingSystem
    switch ($currentOS) {
        ([OperatingSystem]::Windows) {
            $targetSupport = "TargetSupportInstaller"
            $installerExtension = "exe"
        }
        ([OperatingSystem]::Linux) {
            throw "Find-UnitySetupInstaller has not been implemented on the Linux platform. Contributions welcomed!";
        }
        ([OperatingSystem]::Mac) {
            $targetSupport = "MacEditorTargetInstaller"
            $installerExtension = "pkg"
        }
    }

    $unitySetupRegEx = "^(.+)\/([a-z0-9]+)\/(.+)\/(.+)-(\d+)\.(\d+)\.(\d+)([fpba])(\d+).$installerExtension$"

    $knownBaseUrls = @(
        "https://download.unity3d.com/download_unity",
        "https://netstorage.unity3d.com/unity",
        "https://beta.unity3d.com/download"
    )

    $installerTemplates = @{
        [UnitySetupComponent]::UWP            =   "$targetSupport/UnitySetup-UWP-.NET-Support-for-Editor-$Version.$installerExtension",
                                                  "$targetSupport/UnitySetup-Metro-Support-for-Editor-$Version.$installerExtension",
                                                  "$targetSupport/UnitySetup-Universal-Windows-Platform-Support-for-Editor-$Version.$installerExtension";
        [UnitySetupComponent]::UWP_IL2CPP     = , "$targetSupport/UnitySetup-UWP-IL2CPP-Support-for-Editor-$Version.$installerExtension";
        [UnitySetupComponent]::Android        = , "$targetSupport/UnitySetup-Android-Support-for-Editor-$Version.$installerExtension";
        [UnitySetupComponent]::iOS            = , "$targetSupport/UnitySetup-iOS-Support-for-Editor-$Version.$installerExtension";
        [UnitySetupComponent]::AppleTV        = , "$targetSupport/UnitySetup-AppleTV-Support-for-Editor-$Version.$installerExtension";
        [UnitySetupComponent]::Facebook       = , "$targetSupport/UnitySetup-Facebook-Games-Support-for-Editor-$Version.$installerExtension";
        [UnitySetupComponent]::Linux          =   "$targetSupport/UnitySetup-Linux-Support-for-Editor-$Version.$installerExtension",
                                                  "$targetSupport/UnitySetup-Linux-Mono-Support-for-Editor-$Version.$installerExtension";
        [UnitySetupComponent]::Mac            =   "$targetSupport/UnitySetup-Mac-Support-for-Editor-$Version.$installerExtension",
                                                  "$targetSupport/UnitySetup-Mac-Mono-Support-for-Editor-$Version.$installerExtension";
        [UnitySetupComponent]::Mac_IL2CPP     = , "$targetSupport/UnitySetup-Mac-IL2CPP-Support-for-Editor-$Version.$installerExtension";
        [UnitySetupComponent]::Vuforia        = , "$targetSupport/UnitySetup-Vuforia-AR-Support-for-Editor-$Version.$installerExtension";
        [UnitySetupComponent]::WebGL          = , "$targetSupport/UnitySetup-WebGL-Support-for-Editor-$Version.$installerExtension";
        [UnitySetupComponent]::Windows_IL2CPP = , "$targetSupport/UnitySetup-Windows-IL2CPP-Support-for-Editor-$Version.$installerExtension";
        [UnitySetupComponent]::Lumin          = , "$targetSupport/UnitySetup-Lumin-Support-for-Editor-$Version.$installerExtension";
        [UnitySetupComponent]::Linux_IL2CPP   = , "$targetSupport/UnitySetup-Linux-IL2CPP-Support-for-Editor-$Version.$installerExtension";
        [UnitySetupComponent]::Windows_Server = , "$targetSupport/UnitySetup-Windows-Server-Support-for-Editor-$Version.$installerExtension";
    }

    # In 2019.x there is only IL2CPP UWP so change the search for UWP_IL2CPP
    if ( $Version.Major -ge 2019 ) {
        $installerTemplates[[UnitySetupComponent]::UWP_IL2CPP] = @(
            "$targetSupport/UnitySetup-Universal-Windows-Platform-Support-for-Editor-$Version.$installerExtension");
    }

    switch ($currentOS) {
        ([OperatingSystem]::Windows) {
            $setupComponent = [UnitySetupComponent]::Windows
            $installerTemplates[$setupComponent] = , "Windows64EditorInstaller/UnitySetup64-$Version.exe";

            $installerTemplates[[UnitySetupComponent]::Documentation] = , "WindowsDocumentationInstaller/UnityDocumentationSetup-$Version.exe";
            $installerTemplates[[UnitySetupComponent]::StandardAssets] = , "WindowsStandardAssetsInstaller/UnityStandardAssetsSetup-$Version.exe";
        }
        ([OperatingSystem]::Linux) {
            $setupComponent = [UnitySetupComponent]::Linux
            # TODO: $installerTemplates[$setupComponent] = , "???/UnitySetup64-$Version.exe";

            throw "Find-UnitySetupInstaller has not been implemented on the Linux platform. Contributions welcomed!";
        }
        ([OperatingSystem]::Mac) {
            $setupComponent = [UnitySetupComponent]::Mac
            $installerTemplates[$setupComponent] = , "MacEditorInstaller/Unity-$Version.pkg";

            # Note: These links appear to be unavailable even on Unity's website for 2018.
            # StandardAssets appears to work if you select a 2017 version.
            $installerTemplates[[UnitySetupComponent]::Documentation] = , "MacDocumentationInstaller/DocumentationSetup-$Version.pkg";
            $installerTemplates[[UnitySetupComponent]::StandardAssets] = , "MacStandardAssetsInstaller/StandardAssets-$Version.pkg";
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
        'a' { $searchPages += "https://unity3d.com/alpha/$($Version.Major).$($Version.Minor)" }
        'b' {
            $searchPages += "https://unity3d.com/unity/beta/unity$Version",
            "https://unity3d.com/unity/beta/$($Version.Major).$($Version.Minor)",
            "https://unity3d.com/unity/beta/$Version"
        }
        'f' {
            $searchPages += "https://unity3d.com/get-unity/download/archive",
            "https://unity3d.com/unity/whats-new/$($Version.Major).$($Version.Minor).$($Version.Revision)"
            
            # Just in case it's a release candidate search the beta as well.
            if ($Version.Revision -eq '0') {
                $searchPages += "https://unity3d.com/unity/beta/unity$Version",
                "https://unity3d.com/unity/beta/$($Version.Major).$($Version.Minor)",
                "https://unity3d.com/unity/beta/$Version"
            }
        }
        'p' {
            $patchPage = "https://unity3d.com/unity/qa/patch-releases?version=$($Version.Major).$($Version.Minor)"
            $searchPages += $patchPage

            $webResult = Invoke-WebRequest $patchPage -UseBasicParsing
            $searchPages += $webResult.Links | 
                Where-Object { $_.href -match "\/unity\/qa\/patch-releases\?version=$($Version.Major)\.$($Version.Minor)&page=(\d+)" -and $Matches[1] -gt 1 } | 
                ForEach-Object { "https://unity3d.com$($_.href)" }
        }
    }

    if($Hash -ne ""){
        $searchPages += "http://beta.unity3d.com/download/$Hash/download.html"
    }

    foreach ($page in $searchPages) {
        try {
            Write-Verbose "Searching page - $page"
            $webResult = Invoke-WebRequest $page -UseBasicParsing
            $prototypeLink = $webResult.Links | 
                Select-Object -ExpandProperty href -ErrorAction SilentlyContinue |
                Where-Object {
                    $link = $_

                    foreach ( $installer in $installerTemplates.Keys ) {
                        foreach ( $template in $installerTemplates[$installer] ) {
                            if ( $link -like "*$template*" ) { return $true }
                        }
                    }

                    return $false
                } |
                Select-Object -First 1

            if ($null -ne $prototypeLink) 
            {
                # Ensure prototype link is absolute uri
                if(-not [system.uri]::IsWellFormedUriString($_,[System.UriKind]::Absolute)) {
                    $prototypeLink = "$([system.uri]::new([system.uri]$page, [system.uri]$prototypeLink))"
                }

                break 
            }
        }
        catch {
            Write-Verbose "$page failed: $($_.Exception.Message)"
        }
    }

    if ($null -eq $prototypeLink) {
        throw "Could not find archives for Unity version $Version"
    }

    Write-Verbose "Prototype link found: $prototypeLink"
    $linkComponents = $prototypeLink -split $unitySetupRegEx -ne ""

    if ($knownBaseUrls -notcontains $linkComponents[0]) {
        $knownBaseUrls = $linkComponents[0], $knownBaseUrls
    }
    else {
        $knownBaseUrls = $knownBaseUrls | Sort-Object -Property @{ Expression = { [math]::Abs(($_.CompareTo($linkComponents[0]))) }; Ascending = $true }
    }

    if ($Hash -ne "") {
        $linkComponents[1] = $Hash
    }

    $installerTemplates.Keys | Where-Object { $Components -band $_ } | ForEach-Object {
        $templates = $installerTemplates.Item($_);
        $result = $null
        foreach ($template in $templates ) {
            foreach ( $baseUrl in $knownBaseUrls) {
                $endpoint = [uri][System.IO.Path]::Combine($baseUrl, $linkComponents[1], $template);
                try {
                    Write-Verbose "Attempting to get component $_ details from endpoint: $endpoint"
                    $testResult = Invoke-WebRequest $endpoint -Method HEAD -UseBasicParsing
                    # For packages on macOS the Content-Length and Last-Modified are returned as an array.
                    if ($testResult.Headers['Content-Length'] -is [System.Array]) {
                        $installerLength = [int64]$testResult.Headers['Content-Length'][0]
                    }
                    else {
                        $installerLength = [int64]$testResult.Headers['Content-Length']
                    }
                    if ($testResult.Headers['Last-Modified'] -is [System.Array]) {
                        $lastModified = [System.DateTime]$testResult.Headers['Last-Modified'][0]
                    }
                    else {
                        $lastModified = [System.DateTime]$testResult.Headers['Last-Modified']
                    }
                    $result = New-Object UnitySetupInstaller -Property @{
                        'ComponentType' = $_;
                        'Version'       = $Version;
                        'DownloadUrl'   = $endpoint;
                        'Length'        = $installerLength;
                        'LastModified'  = $lastModified;
                    }

                    break
                }
                catch {
                    Write-Verbose "$endpoint failed: $($_.Exception.Message)"
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
   Test if a Unity instance is installed.
.DESCRIPTION
   Returns the status of a Unity install by Version and/or Path to install.
.PARAMETER Version
   What version of Unity are you looking for?
.PARAMETER BasePath
   Under what base patterns is Unity customly installed at.
.PARAMETER Path
   Exact path you expect Unity to be installed at.
.EXAMPLE
   Test-UnitySetupInstance -Version 2017.3.0f3
.EXAMPLE
   Test-UnitySetupInstance -BasePath D:/UnityInstalls/Unity2018
#>
function Test-UnitySetupInstance {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $false)]
        [UnityVersion] $Version,

        [parameter(Mandatory = $false)]
        [string] $BasePath,

        [parameter(Mandatory = $false)]
        [string] $Path
    )

    $instance = Get-UnitySetupInstance -BasePath $BasePath | Select-UnitySetupInstance -Version $Version -Path $Path
    return $null -ne $instance
}

<#
.Synopsis
   Select installers by a version and/or components.
.DESCRIPTION
   Filters a list of `UnitySetupInstaller` down to a specific version and/or specific components.
.PARAMETER Installers
   List of installers that needs to be reduced.
.PARAMETER Version
   What version of UnitySetupInstaller that you want to keep.
.PARAMETER Components
   What components should be maintained.
.EXAMPLE
   $installers = Find-UnitySetupInstaller -Version 2017.3.0f3
   $installers += Find-UnitySetupInstaller -Version 2018.2.5f1
   $installers | Select-UnitySetupInstaller -Component Windows,Linux,Mac
#>
function Select-UnitySetupInstaller {
    [CmdletBinding()]
    param(
        [parameter(ValueFromPipeline = $true)]
        [UnitySetupInstaller[]] $Installers,

        [parameter(Mandatory = $false)]
        [UnityVersion] $Version,

        [parameter(Mandatory = $false)]
        [UnitySetupComponent] $Components = [UnitySetupComponent]::All
    )
    begin {
        $selectedInstallers = @()
    }
    process {
        # Keep only the matching version specified.
        if ( $PSBoundParameters.ContainsKey('Version') ) {
            $Installers = $Installers | Where-Object { [UnityVersion]::Compare($_.Version, $Version) -eq 0 }
        }

        # Keep only the matching component(s).
        foreach ($installer in $Installers) {
            $versionComponents = ConvertTo-UnitySetupComponent $Components -Version $installer.Version
            if ( $versionComponents -band $_.ComponentType ) {
                $selectedInstallers += $installer
            }
        }
    }
    end {
        return $selectedInstallers
    }
}

filter Format-Bytes {
    return "{0:N2} {1}" -f $(
        if ($_ -lt 1kb) { $_, 'Bytes' }
        elseif ($_ -lt 1mb) { ($_ / 1kb), 'KB' }
        elseif ($_ -lt 1gb) { ($_ / 1mb), 'MB' }
        elseif ($_ -lt 1tb) { ($_ / 1gb), 'GB' }
        elseif ($_ -lt 1pb) { ($_ / 1tb), 'TB' }
        else { ($_ / 1pb), 'PB' }
    )
}

function Format-BitsPerSecond {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)]
        [int64] $Bytes,

        [parameter(Mandatory = $true)]
        [int] $Seconds
    )
    if ($Seconds -le 0.001) {
        return "0 Bps"
    }
    # Convert from bytes to bits
    $Bits = ($Bytes * 8) / $Seconds
    return "{0:N2} {1}" -f $(
        if ($Bits -lt 1kb) { $Bits, 'Bps' }
        elseif ($Bits -lt 1mb) { ($Bits / 1kb), 'Kbps' }
        elseif ($Bits -lt 1gb) { ($Bits / 1mb), 'Mbps' }
        elseif ($Bits -lt 1tb) { ($Bits / 1gb), 'Gbps' }
        elseif ($Bits -lt 1pb) { ($Bits / 1tb), 'Tbps' }
        else { ($Bits / 1pb), 'Pbps' }
    )
}

<#
.Synopsis
   Download specified Unity installers.
.DESCRIPTION
   Downloads the given installers into the $Cache directory. 
.PARAMETER Installers
   List of installers that needs to be downloaded.
.PARAMETER Cache
   File path where installers will be downloaded to.
.EXAMPLE
   $installers = Find-UnitySetupInstaller -Version 2017.3.0f3
   Request-UnitySetupInstaller -Installers $installers
.EXAMPLE
   Find-UnitySetupInstaller -Version 2017.3.0f3 | Request-UnitySetupInstaller
#>
function Request-UnitySetupInstaller {
    [CmdletBinding()]
    param(
        [parameter(ValueFromPipeline = $true)]
        [UnitySetupInstaller[]] $Installers,

        [parameter(Mandatory = $false)]
        [string]$Cache = [io.Path]::Combine("~", ".unitysetup")
    )
    begin {
        # Note that this has to happen before calculating the full path since
        # Resolve-Path throws an exception on missing paths.
        if (!(Test-Path $Cache -PathType Container)) {
            New-Item $Cache -ItemType Directory -ErrorAction Stop | Out-Null
        }

        # Expanding '~' to the absolute path on the system. `WebClient` on macOS asumes
        # relative path. macOS also treats alt directory separators as part of the file
        # name and this corrects the separators to current environment.
        $fullCachePath = (Resolve-Path -Path $Cache).Path

        $allInstallers = @()
    }
    process {
        # Append the full list of installers to enable batch downloading of installers.
        $Installers | ForEach-Object {
            $allInstallers += , $_
        }
    }
    end {
        $downloads = @()

        try {
            $global:downloadData = [ordered]@{ }
            $downloadIndex = 1

            $allInstallers | ForEach-Object {
                $installerFileName = [io.Path]::GetFileName($_.DownloadUrl)
                $destination = [io.Path]::Combine($fullCachePath, "Installers", "Unity-$($_.Version)", "$installerFileName")

                # Already downloaded?
                if ( Test-Path $destination ) {
                    $destinationItem = Get-Item $destination
                    if ( ($destinationItem.Length -eq $_.Length ) -and
                        ($destinationItem.LastWriteTime -eq $_.LastModified) ) {
                        Write-Verbose "Skipping download because it's already in the cache: $($_.DownloadUrl)"

                        $resource = New-Object UnitySetupResource -Property @{
                            'ComponentType' = $_.ComponentType
                            'Path'          = $destination
                        }
                        $downloads += , $resource
                        return
                    }
                }

                $destinationDirectory = [io.path]::GetDirectoryName($destination)
                if (!(Test-Path $destinationDirectory -PathType Container)) {
                    New-Item "$destinationDirectory" -ItemType Directory | Out-Null
                }

                $webClient = New-Object System.Net.WebClient

                ++$downloadIndex
                $global:downloadData[$installerFileName] = New-Object PSObject -Property @{
                    installerFileName = $installerFileName
                    startTime         = Get-Date
                    totalBytes        = [int64]$_.Length
                    receivedBytes     = [int64]0
                    isDownloaded      = $false
                    destination       = $destination
                    lastModified      = $_.LastModified
                    componentType     = $_.ComponentType
                    webClient         = $webClient
                    downloadIndex     = $downloadIndex
                }

                # Register to events for showing progress of file download.
                Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -SourceIdentifier "$installerFileName-Changed" -MessageData $installerFileName -Action {
                    $global:downloadData[$event.MessageData].receivedBytes = $event.SourceArgs.BytesReceived
                } | Out-Null
                Register-ObjectEvent -InputObject $webClient -EventName DownloadFileCompleted -SourceIdentifier "$installerFileName-Completed" -MessageData $installerFileName -Action {
                    $global:downloadData[$event.MessageData].isDownloaded = $true
                } | Out-Null

                try {
                    Write-Verbose "Downloading $($_.DownloadUrl) to $destination"
                    $webClient.DownloadFileAsync($_.DownloadUrl, $destination)
                }
                catch [System.Net.WebException] {
                    Write-Error "Failed downloading $installerFileName - $($_.Exception.Message)"
                    $global:downloadData.Remove($installerFileName)

                    Unregister-Event -SourceIdentifier "$installerFileName-Completed" -Force
                    Unregister-Event -SourceIdentifier "$installerFileName-Changed" -Force

                    $webClient.Dispose()
                }
            }

            # Showing progress of all file downloads
            $totalDownloads = $global:downloadData.Count
            do {
                $installersDownloaded = 0

                $global:downloadData.Keys | ForEach-Object {
                    $installerFileName = $_
                    $data = $global:downloadData[$installerFileName]

                    # Finished downloading
                    if ($null -eq $data.webClient) {
                        ++$installersDownloaded
                        return
                    }
                    if ($data.isDownloaded) {
                        Write-Progress -Activity "Downloading $installerFileName" -Status "Done" -Completed `
                            -Id $data.downloadIndex

                        Unregister-Event -SourceIdentifier "$installerFileName-Completed" -Force
                        Unregister-Event -SourceIdentifier "$installerFileName-Changed" -Force

                        $data.webClient.Dispose()
                        $data.webClient = $null

                        # Re-writes the last modified time for ensuring downloads are cached properly.
                        $downloadedFile = Get-Item $data.destination
                        $downloadedFile.LastWriteTime = $data.lastModified

                        $resource = New-Object UnitySetupResource -Property @{
                            'ComponentType' = $data.componentType
                            'Path'          = $data.destination
                        }
                        $downloads += , $resource
                        return
                    }

                    $elapsedTime = (Get-Date) - $data.startTime
                    $progress = [int](($data.receivedBytes / [double]$data.totalBytes) * 100)
                    $secondsRemaining = -1 # -1 for Write-Progress prevents seconds remaining from showing.

                    if ($data.receivedBytes -gt 0 -and $elapsedTime.TotalSeconds -gt 0) {
                        $averageSpeed = $data.receivedBytes / $elapsedTime.TotalSeconds
                        $secondsRemaining = ($data.totalBytes - $data.receivedBytes) / $averageSpeed
                    }

                    $downloadSpeed = Format-BitsPerSecond -Bytes $data.receivedBytes -Seconds $elapsedTime.TotalSeconds

                    Write-Progress -Activity "Downloading $installerFileName | $downloadSpeed" `
                        -Status "$($data.receivedBytes | Format-Bytes) of $($data.totalBytes | Format-Bytes)" `
                        -SecondsRemaining $secondsRemaining `
                        -PercentComplete $progress `
                        -Id $data.downloadIndex
                }
            } while ($installersDownloaded -lt $totalDownloads)
        }
        finally {
            # If the script is stopped, e.g. Ctrl+C, we want to cancel any remaining downloads
            $global:downloadData.Keys | ForEach-Object {
                $installerFileName = $_
                $data = $global:downloadData[$installerFileName]

                if ($null -ne $data.webClient) {
                    if (-not $data.isDownloaded) {
                        $data.webClient.CancelAsync()
                    }

                    Unregister-Event -SourceIdentifier "$installerFileName-Completed" -Force
                    Unregister-Event -SourceIdentifier "$installerFileName-Changed" -Force

                    $data.webClient.Dispose()
                    $data.webClient = $null
                }
            }

            Remove-Variable -Name downloadData -Scope Global
        }

        return $downloads
    }
}

function Install-UnitySetupPackage {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)]
        [UnitySetupResource] $Package,

        [parameter(Mandatory = $true)]
        [string]$Destination
    )

    $currentOS = Get-OperatingSystem
    switch ($currentOS) {
        ([OperatingSystem]::Windows) {
            $startProcessArgs = @{
                'FilePath'     = $Package.Path;
                'ArgumentList' = @("/S", "/D=$Destination");
                'PassThru'     = $true;
                'Wait'         = $true;
            }
        }
        ([OperatingSystem]::Linux) {
            throw "Install-UnitySetupPackage has not been implemented on the Linux platform. Contributions welcomed!";
        }
        ([OperatingSystem]::Mac) {
            # Note that $Destination has to be a disk path.
            # sudo installer -package $Package.Path -target /
            $startProcessArgs = @{
                'FilePath'     = 'sudo';
                'ArgumentList' = @("installer", "-package", $Package.Path, "-target", $Destination);
                'PassThru'     = $true;
                'Wait'         = $true;
            }
        }
    }

    Write-Verbose "$(Get-Date): Installing $($Package.ComponentType) to $Destination."
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

<#
.Synopsis
   Installs a UnitySetup instance.
.DESCRIPTION
   Downloads and installs UnitySetup installers found via Find-UnitySetupInstaller.
.PARAMETER Installers
   What installers would you like to download and execute?
.PARAMETER BasePath
   Under what base patterns is Unity customly installed at.
.PARAMETER Destination
   Where would you like the UnitySetup instance installed?
.PARAMETER Cache
   Where should the installers be cached. This defaults to ~\.unitysetup.
.EXAMPLE
   Find-UnitySetupInstaller -Version 2017.3.0f3 | Install-UnitySetupInstance
.EXAMPLE
   Find-UnitySetupInstaller -Version 2017.3.0f3 | Install-UnitySetupInstance -Destination D:\Unity-2017.3.0f3
.EXAMPLE
   Find-UnitySetupInstaller -Version 2017.3.0f3 | Install-UnitySetupInstance -BasePath D:\UnitySetup\
.EXAMPLE
   Find-UnitySetupInstaller -Version 2017.3.0f3 | Install-UnitySetupInstance -BasePath D:\UnitySetup\ -Destination Unity-2017
#>
function Install-UnitySetupInstance {
    [CmdletBinding()]
    param(
        [parameter(ValueFromPipeline = $true)]
        [UnitySetupInstaller[]] $Installers,

        [parameter(Mandatory = $false)]
        [string]$BasePath,

        [parameter(Mandatory = $false)]
        [string]$Destination,

        [parameter(Mandatory = $false)]
        [string]$Cache = [io.Path]::Combine("~", ".unitysetup")
    )
    begin {
        $currentOS = Get-OperatingSystem
        if ($currentOS -eq [OperatingSystem]::Linux) {
            throw "Install-UnitySetupInstance has not been implemented on the Linux platform. Contributions welcomed!";
        }

        if ( -not $PSBoundParameters.ContainsKey('BasePath') ) {
            $defaultInstallPath = switch ($currentOS) {
                ([OperatingSystem]::Windows) {
                    "C:\Program Files\Unity\Hub\Editor\"
                }
                ([OperatingSystem]::Linux) {
                    throw "Install-UnitySetupInstance has not been implemented on the Linux platform. Contributions welcomed!";
                }
                ([OperatingSystem]::Mac) {
                    "/Applications/Unity/Hub/Editor/"
                }
            }
        }
        else {
            $defaultInstallPath = $BasePath
        }

        $versionInstallers = @{ }
    }
    process {
        # Sort each installer received from the pipe into versions
        $Installers | ForEach-Object {
            $versionInstallers[$_.Version] += , $_
        }
    }
    end {
        $versionInstallers.Keys | ForEach-Object {
            $installVersion = $_
            $installerInstances = $versionInstallers[$installVersion]

            if ( $PSBoundParameters.ContainsKey('Destination') ) {
                # Slight API change here. If BasePath is also provided treat Destination as a relative path.
                if ( $PSBoundParameters.ContainsKey('BasePath') ) {
                    $installPath = $Destination
                }
                else {
                    $installPath = [io.path]::Combine($BasePath, $Destination)
                }
            }
            else {
                $installPath = [io.path]::Combine($defaultInstallPath, $installVersion)
            }

            if ($currentOS -eq [OperatingSystem]::Mac) {
                $volumeRoot = "/Volumes/UnitySetup/"
                $volumeInstallPath = [io.path]::Combine($volumeRoot, "Applications/Unity/")

                # Make sure the install path ends with a trailing slash. This
                # is required in some commands to treat as directory.
                if (-not $installPath.EndsWith([io.path]::DirectorySeparatorChar)) {
                    $installPath += [io.path]::DirectorySeparatorChar
                }
                
                # Make sure the folder .unitysetup exist before create sparsebundle
                if (-not (Test-Path $Cache -PathType Container)) {
                    Write-Verbose "Creating directory $Cache."
                    New-Item $Cache -ItemType Directory -ErrorAction Stop | Out-Null
                }

                # Creating sparse bundle to host installing Unity in other locations
                $unitySetupBundlePath = [io.path]::Combine($Cache, "UnitySetup.sparsebundle")
                if (-not (Test-Path $unitySetupBundlePath)) {
                    Write-Verbose "Creating new sparse bundle disk image for installation."
                    & hdiutil create -size 32g -fs 'HFS+' -type 'SPARSEBUNDLE' -volname 'UnitySetup' $unitySetupBundlePath
                }
                Write-Verbose "Mounting sparse bundle disk."
                & hdiutil mount $unitySetupBundlePath

                # Previous version failed to remove. Cleaning up!
                if (Test-Path $volumeInstallPath) {
                    Write-Verbose "Previous install did not clean up properly. Doing that now."
                    & sudo rm -Rf ([io.path]::Combine($volumeRoot, '*'))
                }

                # Copy installed version back to the sparse bundle disk for Unity component installs.
                if (Test-UnitySetupInstance -Path $installPath -BasePath $BasePath) {
                    Write-Verbose "Copying $installPath to $volumeInstallPath"

                    # Ensure the path exists before copying the previous version to the sparse bundle disk.
                    & mkdir -p $volumeInstallPath

                    # Copy the files (-r) and recreate symlinks (-l) to the install directory.
                    # Preserve permissions (-p) and owner (-o).
                    # Need to mark the files with read permissions or installs may fail.
                    & sudo rsync -rlpo $installPath $volumeInstallPath --chmod=+r
                }
            }

            # TODO: Strip out components already installed in the destination.

            $installerPaths = $installerInstances | Request-UnitySetupInstaller -Cache $Cache

            # First install the Unity editor before other components.
            $editorComponent = switch ($currentOS) {
                ([OperatingSystem]::Windows) { [UnitySetupComponent]::Windows }
                ([OperatingSystem]::Linux) { [UnitySetupComponent]::Linux }
                ([OperatingSystem]::Mac) { [UnitySetupComponent]::Mac }
            }

            $packageDestination = $installPath
            # Installers in macOS get installed to the sparse bundle disk first.
            if ($currentOS -eq [OperatingSystem]::Mac) {
                $packageDestination = $volumeRoot
            }

            $editorInstaller = $installerPaths | Where-Object { $_.ComponentType -band $editorComponent }
            if ($null -ne $editorInstaller) {
                Write-Verbose "Installing $($editorInstaller.ComponentType) Editor"
                Install-UnitySetupPackage -Package $editorInstaller -Destination $packageDestination
            }

            $installerPaths | ForEach-Object {
                # Already installed this earlier. Skipping.
                if ($_.ComponentType -band $editorComponent) {
                    return
                }

                Write-Verbose "Installing $($_.ComponentType)"
                Install-UnitySetupPackage -Package $_ -Destination $packageDestination
            }

            # Move the install from the sparse bundle disk to the install directory.
            if ($currentOS -eq [OperatingSystem]::Mac) {
                # rsync does not recursively create the directory path.
                if (-not (Test-Path $installPath -PathType Container)) {
                    Write-Verbose "Creating directory $installPath."
                    New-Item $installPath -ItemType Directory -ErrorAction Stop | Out-Null
                }

                Write-Verbose "Copying install to $installPath."
                # Copy the files (-r) and recreate symlinks (-l) to the install directory.
                # Preserve permissions (-p) and owner (-o).
                # chmod gives files read permissions.
                & sudo rsync -rlpo $volumeInstallPath $installPath --chmod="+wr" --remove-source-files

                Write-Verbose "Freeing sparse bundle disk space and unmounting."
                # Ensure the drive is cleaned up.
                & sudo rm -Rf ([io.path]::Combine($volumeRoot, '*'))

                & hdiutil eject $volumeRoot
                # Free up disk space since deleting items in the volume send them to the trash
                # Also note that -batteryallowed enables compacting while not connected to
                # power. The compact is quite quick since the volume is small.
                & hdiutil compact $unitySetupBundlePath -batteryallowed
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
                'FilePath'     = $uninstaller;
                'PassThru'     = $true;
                'Wait'         = $true;
                'ErrorAction'  = 'Stop';
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
   Defaults to Unity default locations by platform
   Default can be configured by comma separated paths in $env:UNITY_SETUP_INSTANCE_DEFAULT_BASEPATH
.EXAMPLE
   Get-UnitySetupInstance
#>
function Get-UnitySetupInstance {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $false)]
        [string[]] $BasePath
    )

    if((-not $BasePath) -and $env:UNITY_SETUP_INSTANCE_BASEPATH_DEFAULT){
        $BasePath = ($env:UNITY_SETUP_INSTANCE_BASEPATH_DEFAULT -split ',') | ForEach-Object { 
            $_.trim() 
        }
        Write-Verbose "Set BasePath to $BasePath from `$env:UNITY_SETUP_INSTANCE_BASEPATH_DEFAULT."
    }

    switch (Get-OperatingSystem) {
        ([OperatingSystem]::Windows) {
            if (-not $BasePath) {
                $BasePath = @('C:\Program Files*\Unity*', 'C:\Program Files\Unity\Hub\Editor\*')
            }
        }
        ([OperatingSystem]::Linux) {
            throw "Get-UnitySetupInstance has not been implemented on the Linux platform. Contributions welcomed!";
        }
        ([OperatingSystem]::Mac) {
            if (-not $BasePath) {
                $BasePath = @('/Applications/Unity*', '/Applications/Unity/Hub/Editor/*')
            }
        }
    }

    Write-Verbose "Searching `"$BasePath`" for UnitySetup instances..."
    Get-ChildItem -Path $BasePath -Directory -ErrorAction Ignore | 
        Where-Object { (Get-UnityEditor $_.FullName).Count -gt 0 } | 
        ForEach-Object {
            $path = $_.FullName
            try {
                Write-Verbose "Creating UnitySetupInstance for $path"
                [UnitySetupInstance]::new($path)
            }
            catch {
                Write-Warning "$_"
            }
        }
}

<#
.Synopsis
   Gets the UnityVersion for a UnitySetupInstance at Path
.DESCRIPTION
   Given a set of unity setup instances, this will select the best one matching your requirements
.PARAMETER Path
   Path to a UnitySetupInstance
.OUTPUTS
   UnityVersion
   Returns the UnityVersion for the UnitySetupInstance at Path, or nothing if there isn't one
.EXAMPLE
   Get-UnitySetupInstanceVersion -Path 'C:\Program Files\Unity'
#>
function Get-UnitySetupInstanceVersion {
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { Test-Path $_ -PathType Container })]
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path
    )

    Write-Verbose "Attempting to find UnityVersion in $path"

    # Try to look in the modules.json file for installer paths that contain version info
    if ( Test-Path "$path\modules.json" -PathType Leaf ) {
        try {
            Write-Verbose "Searching $path\modules.json for module versions"
            $table = (Get-Content "$path\modules.json" -Raw) | ConvertFrom-Json -AsHashtable

            foreach ( $url in $table.downloadUrl ) {
                Write-Debug "`tTesting DownloadUrl $url"
                if ( $url -notmatch "(\d+)\.(\d+)\.(\d+)([fpab])(\d+)" ) { continue; }

                Write-Verbose "`tFound version!"
                return [UnityVersion]$Matches[0]
            }
        }
        catch {
            Write-Verbose "Error parsing $path\modules.json:`n`t$_"
        }
    }

    # No version found, start digging deeper
    if ( Test-Path "$path\Editor" -PathType Container ) {
        
        # Search for the version using the ivy.xml definitions for legacy editor compatibility.
        Write-Verbose "Looking for ivy.xml files under $path\Editor\"
        $ivyFiles = Get-ChildItem -Path "$path\Editor\" -Filter 'ivy.xml' -Recurse -ErrorAction SilentlyContinue -Force -File
        foreach ( $ivy in $ivyFiles) {
            if ( $null -eq $ivy ) { continue; }

            Write-Verbose "`tLooking for version in $($ivy.FullName)"

            [xml]$xmlDoc = Get-Content $ivy.FullName

            [string]$ivyVersion = $xmlDoc.'ivy-module'.info.unityVersion
            if ( -not $ivyVersion ) { continue; }

            Write-Verbose "`tFound version!"
            return [UnityVersion]$ivyVersion
        }

        # Search through any header files which might define the unity version
        [string[]]$knownFiles = @(
            "$path\Editor\Data\PlaybackEngines\windowsstandalonesupport\Source\WindowsPlayer\WindowsPlayer\UnityConfigureVersion.gen.h",
            "$path\Editor\Data\PlaybackEngines\windowsstandalonesupport\Source\WindowsPlayer\WindowsPlayer\UnityConfiguration.gen.cpp"
        )
        foreach ($file in $knownFiles) {
            Write-Verbose "Looking for UNITY_VERSION defined in $file"
            if (Test-Path -PathType Leaf -Path $file) {
                $fileMatchInfo = Select-String -Path $file -Pattern "UNITY_VERSION.+`"(\d+\.\d+\.\d+[fpba]\d+).*`""
                if($null -ne $fileMatchInfo)
                {
                    break;
                }
            }
        }

        if ($null -eq $fileMatchInfo) {
            Write-Verbose "Looking for source files with UNITY_VERSION defined under $path\Editor\ "
            $fileMatchInfo = do {
                Get-ChildItem -Path "$path\Editor" -Include '*.cpp','*.h' -Recurse -ErrorAction Ignore -Force -File | 
                    Select-String -Pattern "UNITY_VERSION.+`"(\d+\.\d+\.\d+[fpba]\d+).*`"" |
                    ForEach-Object { $_; break; } # Stop the pipeline after the first result
            } while ($false);
        }

        if ( $fileMatchInfo.Matches.Groups.Count -gt 1 ) {
            Write-Verbose "`tFound version!"
            return [UnityVersion]($fileMatchInfo.Matches.Groups[1].Value)
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
.PARAMETER Path
   Select only instances matching the project at the provided path.
.PARAMETER instances
   The list of instances to Select from.
.EXAMPLE
   Get-UnitySetupInstance | Select-UnitySetupInstance -Latest
.EXAMPLE
   Get-UnitySetupInstance | Select-UnitySetupInstance -Version 2017.1.0f3
.EXAMPLE
   Get-UnitySetupInstance | Select-UnitySetupInstance -Path (Get-Item /Applications/Unity*)
#>
function Select-UnitySetupInstance {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $false)]
        [switch] $Latest,

        [parameter(Mandatory = $false)]
        [UnityVersion] $Version,

        [parameter(Mandatory = $false)]
        [string] $Path,

        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [UnitySetupInstance[]] $Instances
    )

    begin {
        if ( $Path ) {
            $pathInfo = Resolve-Path $Path -ErrorAction Ignore
        }
    }

    process {
        if ( $pathInfo ) {
            $Instances = $Instances | Where-Object {
                $instancePathInfo = Resolve-Path $_.Path -ErrorAction Ignore
                return $pathInfo.Path -eq $instancePathInfo.Path
            }
        }

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
        'Path'        = $BasePath;
        'Filter'      = 'ProjectSettings';
        'ErrorAction' = 'Ignore';
        'Directory'   = $true;
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
   Tests the meta file integrity of the Unity Project Instance(s).
.DESCRIPTION
   Tests if every item under assets has an associated .meta file 
   and every .meta file an associated item
   and that none of the meta file guids collide.
.PARAMETER Project
   Unity Project Instance(s) to test the meta file integrity of.
.PARAMETER PassThru
   Output the meta file integrity issues rather than $true (no issues) or $false (at least one issue).
.EXAMPLE
   Test-UnityProjectInstanceMetaFileIntegrity
.EXAMPLE
   Test-UnityProjectInstanceMetaFileIntegrity -PassThru
.EXAMPLE
   Test-UnityProjectInstanceMetaFileIntegrity .\MyUnityProject
.EXAMPLE
   Test-UnityProjectInstanceMetaFileIntegrity -Project .\MyUnityProject
.EXAMPLE
   Get-UnityProjectInstance -Recurse | Test-UnityProjectInstanceMetaFileIntegrity
.EXAMPLE
   Get-UnityProjectInstance -Recurse | Test-UnityProjectInstanceMetaFileIntegrity -PassThru
#>
function Test-UnityProjectInstanceMetaFileIntegrity {
    [CmdletBinding(DefaultParameterSetName = "Context")]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0, ParameterSetName = "Projects")]
        [ValidateNotNullOrEmpty()]
        [UnityProjectInstance[]] $Project,
        [switch] $PassThru
    )

    process {

        switch ( $PSCmdlet.ParameterSetName) {
            'Context' {
                $currentFolderProject = Get-UnityProjectInstance $PWD.Path
                if ($null -ne $currentFolderProject) {
                    $Project = @($currentFolderProject)
                }
            }
        }

        # Derived from https://docs.unity3d.com/Manual/SpecialFolders.html
        $unityAssetExcludes = @('.*', '*~', 'cvs', '*.tmp')

        foreach ( $p in $Project) {

            $testResult = $true

            Write-Verbose "Getting meta file integrity for project at $($p.path)"
            $assetDir = Join-Path $p.Path "Assets"

            # get all the directories under assets
            [System.IO.DirectoryInfo[]]$dirs = 
                Get-ChildItem -Path "$assetDir/*" -Recurse -Directory -Exclude $unityAssetExcludes

            Write-Verbose "Testing asset directories for missing meta files..."
            [float]$progressCounter = 0
            foreach ($dir in $dirs) {

                ++$progressCounter
                $progress = @{
                    'Activity'        = "Testing directories for missing meta files"
                    'Status'          = "$progressCounter / $($dirs.Length) - $dir"
                    'PercentComplete' = (($progressCounter / $dirs.Length) * 100)
                }
                Write-Debug $progress.Status
                Write-Progress @progress

                $testPath = "$($dir.FullName).meta";
                if (Test-Path -PathType Leaf -Path $testPath) { continue }

                if ($PassThru) {
                    [PSCustomObject]@{
                        'Item'  = $dir
                        'Issue' = "Directory is missing associated meta file."
                    }
                }
                else {
                    $testResult = $false;
                    break;
                }
            }

            if (-not $testResult) { $false; continue; }

            # get all the non-meta files under assets
            $unityAssetFileExcludes = $unityAssetExcludes + '*.meta'
            [System.IO.FileInfo[]]$files = Get-ChildItem -Path "$assetDir/*" -Exclude $unityAssetFileExcludes -File
            foreach ($dir in $dirs) {
                $files += Get-ChildItem -Path "$($dir.FullName)/*" -Exclude $unityAssetFileExcludes -File
            }

            Write-Verbose "Testing asset files for missing meta files..."
            $progressCounter = 0
            foreach ( $file in $files ) {

                ++$progressCounter
                $progress = @{
                    'Activity'        = "Testing files for missing meta files"
                    'Status'          = "$progressCounter / $($files.Length) - $file"
                    'PercentComplete' = (($progressCounter / $files.Length) * 100)
                
                }
                Write-Debug $progress.Status
                Write-Progress @progress

                $testPath = "$($file.FullName).meta";
                if (Test-Path -PathType Leaf -Path $testPath) { continue }

                if ($PassThru) {
                    [PSCustomObject]@{
                        'Item'  = $file
                        'Issue' = "File is missing associated meta file."
                    }
                }
                else {
                    $testResult = $false;
                    break;
                }
            }

            if (-not $testResult) { $false; continue; }

            $metaFileSearchArgs = @{
                'Exclude' = $unityAssetExcludes
                'Include' = '*.meta'
                'File'    = $true
                'Force'   = $true # Ensure we include hidden meta files
            }

            # get all the meta files under assets
            [System.IO.FileInfo[]]$metaFiles = Get-ChildItem -Path "$assetDir/*" @metaFileSearchArgs
            foreach ($dir in $dirs) {
                $metaFiles += Get-ChildItem -Path "$($dir.FullName)/*" @metaFileSearchArgs
            }

            Write-Verbose "Testing meta files for missing assets..."
            $progressCounter = 0
            foreach ($metaFile in $metaFiles) {

                ++$progressCounter
                $progress = @{
                    'Activity'        = "Testing meta files for missing assets"
                    'Status'          = "$progressCounter / $($metaFiles.Length) - $metaFile"
                    'PercentComplete' = (($progressCounter / $metaFiles.Length) * 100)
                }
                Write-Debug $progress.Status
                Write-Progress @progress

                $testPath = $metaFile.FullName.SubString(0, $metaFile.FullName.Length - $metaFile.Extension.Length);
                if (Test-Path -Path $testPath) { continue }

                if ($PassThru) {
                    [PSCustomObject]@{
                        'Item'  = $metaFile
                        'Issue' = "Meta file is missing associated item."
                    }
                }
                else {
                    $testResult = $false;
                    break;
                }
            }

            if (-not $testResult) { $false; continue; }

            Write-Verbose "Testing meta files for guid collisions..."
            $metaGuids = @{ }
            $progressCounter = 0
            foreach ($metaFile in $metaFiles) {

                ++$progressCounter
                $progress = @{
                    'Activity'        = "Testing meta files for guid collisions"
                    'Status'          = "$progressCounter / $($metaFiles.Length) - $metaFile"
                    'PercentComplete' = (($progressCounter / $metaFiles.Length) * 100)
                }
                Write-Debug $progress.Status
                Write-Progress @progress

                try {
                    $guidResult = Get-Content $metaFile.FullName | Select-String -Pattern '^guid:\s*([a-z,A-Z,\d]+)\s*$'
                    if ($guidResult.Matches.Groups.Length -lt 2) {
                        Write-Warning "Could not find guid in meta file - $metaFile"
                        continue;
                    }

                    $guid = $guidResult.Matches.Groups[1].Value
                    if ($null -eq $metaGuids[$guid]) {
                        $metaGuids[$guid] = $metaFile;
                        continue
                    }

                    if ($PassThru) {
                        [PSCustomObject]@{
                            'Item'  = $metaFile
                            'Issue' = "Meta file guid collision with $($metaGuids[$guid])"
                        }
                    }
                    else {
                        $testResult = $false;
                        break;
                    }
                }
                catch {
                    Write-Error "Exception testing guid of $metaFile - $_"
                }
            }

            if (-not $PassThru) { $testResult; }
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
.PARAMETER AdditionalArguments
   Additional arguments for Unity or your custom method
.PARAMETER OutputPath
   The output path that the Unity Editor should use.
.PARAMETER LogFile
   The log file for the Unity Editor to write to.
.PARAMETER BuildTarget
   The platform build target for the Unity Editor to start in.
.PARAMETER StandaloneBuildSubtarget 
   Select an active build sub-target for the Standalone platforms before loading a project.
.PARAMETER AcceptAPIUpdate
   Accept the API Updater automatically. Implies BatchMode unless explicitly specified by the user.
.PARAMETER Credential
   What user name and password should be used by Unity for activation?
.PARAMETER Serial
   What serial should be used by Unity for activation? Implies BatchMode and Quit if they're not supplied by the User.
.PARAMETER ReturnLicense
   Unity should return the current license it's been activated with. Implies Quit if not supplied by the User.
.PARAMETER EditorTestsCategories
   Filter tests by category names.
.PARAMETER EditorTestsFilter
   Filter tests by test names.
.PARAMETER EditorTestsResultFile
   Where to put the results? Unity states, "If the path is a folder, the command line uses a default file name. If not specified, it places the results in the project’s root folder."
.PARAMETER RunEditorTests
   Should Unity run the editor tests? Unity states, "[...]it’s good practice to run it with batchmode argument. quit is not required, because the Editor automatically closes down after the run is finished."
.PARAMETER TestPlatform
   The platform you want to run the tests on. Note that If unspecified, tests run in editmode by default.
.PARAMETER TestResults
   The path indicating where Unity should save the result file. By default, Unity saves it in the Project’s root folder.
.PARAMETER RunTests
   Should Unity run tests? Unity states, "[...]it’s good practice to run it with batchmode argument. quit is not required, because the Editor automatically closes down after the run is finished."
.PARAMETER BatchMode
   Should the Unity Editor start in batch mode?
.PARAMETER Quit
   Should the Unity Editor quit after it's done?
.PARAMETER Wait
   Should the command wait for the Unity Editor to exit?
.PARAMETER CacheServerEndpoint
    If included, the editor will attempt to use a Unity Accelerator hosted in the provided IP. The endpoint should be in the format of [IP]:[Port]. If the default Accelerator port is used, at the time of writing this, the port should be ommited.
.PARAMETER CacheServerNamespacePrefix
    Set the namespace prefix. Used to group data together on the cache server. 
.PARAMETER CacheServerDisableDownload
    Disable downloading from the cache server. If ommited, the default value is true (download enabled)
.PARAMETER CacheServerDisableUpload
    Disable uploading to the cache server. If ommited, the default value is true (upload enabled)
.EXAMPLE
   Start-UnityEditor
.EXAMPLE
   Start-UnityEditor -Latest
.EXAMPLE
   Start-UnityEditor -Version 2017.3.0f3
.EXAMPLE
   Start-UnityEditor -ExecuteMethod Build.Invoke -BatchMode -Quit -LogFile .\build.log -Wait -AdditionalArguments "-BuildArg1 -BuildArg2"
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
        [string]$AdditionalArguments,
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
        [ValidateSet('StandaloneOSX', 'StandaloneWindows', 'iOS', 'Android', 'StandaloneLinux', 'StandaloneWindows64', 'WebGL', 'WSAPlayer', 'StandaloneLinux64', 'StandaloneLinuxUniversal', 'Tizen', 'PSP2', 'PS4', 'XBoxOne', 'N3DS', 'WiiU', 'tvOS', 'Switch', 'Lumin')]
        [string]$BuildTarget,
        [parameter(Mandatory = $false)]
        [ValidateSet('Player', 'Server')]
        [string]$StandaloneBuildSubtarget,
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
        [string[]]$EditorTestsCategory,
        [parameter(Mandatory = $false)]
        [string[]]$EditorTestsFilter,
        [parameter(Mandatory = $false)]
        [string]$EditorTestsResultFile,
        [parameter(Mandatory = $false)]
        [switch]$RunEditorTests,
        [parameter(Mandatory = $false)]
        [ValidateSet('EditMode', 'PlayMode')]
        [string]$TestPlatform,
        [parameter(Mandatory = $false)]
        [string]$TestResults,
        [parameter(Mandatory = $false)]
        [switch]$RunTests,
        [parameter(Mandatory = $false)]
        [switch]$BatchMode,
        [parameter(Mandatory = $false)]
        [switch]$Quit,
        [parameter(Mandatory = $false)]
        [switch]$Wait,
        [parameter(Mandatory = $false)]
        [switch]$PassThru,
        [parameter(Mandatory = $false)]
        [string]$CacheServerEndpoint,
        [parameter(Mandatory = $false)]
        [string]$CacheServerNamespacePrefix,
        [parameter(Mandatory = $false)]
        [switch]$CacheServerDisableDownload,
        [parameter(Mandatory = $false)]
        [switch]$CacheServerDisableUpload
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

        [string[]]$sharedArgs = @()
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
        if ( $CreateProject ) { $sharedArgs += "-createProject", "`"$CreateProject`"" }
        if ( $ExecuteMethod ) { $sharedArgs += "-executeMethod", $ExecuteMethod }
        if ( $OutputPath ) { $sharedArgs += "-buildOutput", "`"$OutputPath`"" }
        if ( $LogFile ) { $sharedArgs += "-logFile", "`"$LogFile`"" }
        if ( $BuildTarget ) { $sharedArgs += "-buildTarget", $BuildTarget }
        if ( $StandaloneBuildSubtarget ) { $sharedArgs += "-standaloneBuildSubtarget", $StandaloneBuildSubtarget }
        if ( $BatchMode ) { $sharedArgs += "-batchmode" }
        if ( $Quit ) { $sharedArgs += "-quit" }
        if ( $ExportPackage ) { $sharedArgs += "-exportPackage", ($ExportPackage | ForEach-Object { "`"$_`"" }) }
        if ( $ImportPackage ) { $sharedArgs += "-importPackage", "`"$ImportPackage`"" }
        if ( $Credential ) { $sharedArgs += '-username', $Credential.UserName }
        if ( $EditorTestsCategory ) { $sharedArgs += '-editorTestsCategories', ($EditorTestsCategory -join ',') }
        if ( $EditorTestsFilter ) { $sharedArgs += '-editorTestsFilter', ($EditorTestsFilter -join ',') }
        if ( $EditorTestsResultFile ) { $sharedArgs += '-editorTestsResultFile', $EditorTestsResultFile }
        if ( $RunEditorTests ) { $sharedArgs += '-runEditorTests' }
        if ( $TestPlatform ) { $sharedArgs += '-testPlatform', $TestPlatform }
        if ( $TestResults ) { $sharedArgs += '-testResults', $TestResults }
        if ( $RunTests ) { $sharedArgs += '-runTests' }
        if ( $ForceFree) { $sharedArgs += '-force-free' }
        if ( $AdditionalArguments) { $sharedArgs += $AdditionalArguments }
        if ( $CacheServerEndpoint) {
            $sharedArgs += "-cacheServerEndpoint", $CacheServerEndpoint  
            $sharedArgs += "-adb2"
            $sharedArgs += "-enableCacheServer"           
            if ( $CacheServerNamespacePrefix) { $sharedArgs += "-cacheServerNamespacePrefix", $CacheServerNamespacePrefix}
            $sharedArgs += "-cacheServerEnableDownload", $(If ($CacheServerDisableDownload) {"false"} Else {"true"})
            $sharedArgs += "-cacheServerEnableUpload", $(If ($CacheServerDisableUpload) {"false"} Else {"true"})
        }

        [string[][]]$instanceArgs = @()
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
            $instanceArgs += , ("-projectPath", "`"$projectPath`"")
            $setupInstances += , $setupInstance
        }


        for ($i = 0; $i -lt $setupInstances.Length; $i++) {
            $setupInstance = $setupInstances[$i]

            $editor = Get-UnityEditor "$($setupInstance.Path)"
            if ( -not $editor ) {
                Write-Error "Could not find Unity Editor under setup instance path: $($setupInstance.Path)"
                continue
            }

            # clone the shared args list
            [string[]]$unityArgs = $sharedArgs | ForEach-Object { $_ }
            if ( $instanceArgs[$i] ) { $unityArgs += $instanceArgs[$i] }

            $actionString = "$editor $unityArgs"
            if ( $Credential ) { $actionString += " -password (hidden)" }
            if ( $Serial ) { $actionString += " -serial (hidden)" }

            if (-not $PSCmdlet.ShouldProcess($actionString, "System.Diagnostics.Process.Start()")) {
                continue
            }

            # Defered till after potential display by ShouldProcess
            if ( $Credential ) { $unityArgs += '-password', $Credential.GetNetworkCredential().Password }
            if ( $Serial ) { $unityArgs += '-serial', [System.Net.NetworkCredential]::new($null, $Serial).Password }

            # We've experienced issues with Start-Process -Wait and redirecting
            # output so we're using the Process class directly now.
            $process = New-Object System.Diagnostics.Process
            $process.StartInfo.Filename = $editor
            $process.StartInfo.Arguments = $unityArgs
            $process.StartInfo.RedirectStandardOutput = $true
            $process.StartInfo.RedirectStandardError = $true
            $process.StartInfo.UseShellExecute = $false
            $process.StartInfo.CreateNoWindow = $true
            $process.StartInfo.WorkingDirectory = $PWD
            $process.StartInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
            $process.Start() | Out-Null

            if ( $Wait ) {
                $process.WaitForExit()

                if ( $LogFile -and (Test-Path $LogFile -Type Leaf) ) {
                    # Note that Unity sometimes returns a success ExitCode despite the presence of errors, but we want
                    # to make sure that we flag such errors.
                    Write-UnityErrors $LogFile

                    Write-Verbose "Writing $LogFile to Information stream Tagged as 'Logs'"
                    Get-Content $LogFile | ForEach-Object { Write-Information -MessageData $_ -Tags 'Logs' }
                }

                if ( $process.ExitCode -ne 0 ) {
                    Write-Error "Unity quit with non-zero exit code: $($process.ExitCode)"
                }
            }

            if ($PassThru) { $process }
        }
    }
}

# Open the specified Unity log file and write any errors found in the file to the error stream.
function Write-UnityErrors {
    param([string] $LogFileName)
    Write-Verbose "Checking $LogFileName for errors"
    $errors = Get-Content $LogFileName | Where-Object { Get-IsUnityError $_ }
    if ( $errors.Count -gt 0 ) {
        $errors = $errors | Select-Object -uniq # Unity prints out errors as they occur and also in a summary list. We only want to see each unique error once.
        $errorMessage = $errors -join "`r`n"
        $errorMessage = "Errors were found in $LogFileName`:`r`n$errorMessage"
        Write-Error $errorMessage
    }
}

function Get-IsUnityError {
    param([string] $LogLine)

    # Detect Unity License error, for example:
    # BatchMode: Unity has not been activated with a valid License. Could be a new activation or renewal...
    if ( $LogLine -match 'Unity has not been activated with a valid License' ) {
        return $true
    }

    # Detect that the method specified by -ExecuteMethod doesn't exist, for example:
    # executeMethod method 'Invoke' in class 'Build' could not be found.
    if ( $LogLine -match 'executeMethod method .* could not be found' ) {
        return $true
    }

    # Detect compilation error, for example:
    #   Assets/Errors.cs(7,9): error CS0103: The name `NonexistentFunction' does not exist in the current context
    if ( $LogLine -match '\.cs\(\d+,\d+\): error ' ) {
        return $true
    }

    # In the future, additional kinds of errors that can be found in Unity logs could be added here:
    # ...

    return $false
}

function ConvertTo-DateTime {
    param([string] $Text)

    if ( -not $text -or $text.Length -eq 0 ) { [DateTime]::MaxValue }
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
function Get-UnityLicense {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification = "Used to convert discovered plaintext serials into secure strings.")]
    param([SecureString]$Serial)

    $licenseFiles = Get-ChildItem "C:\ProgramData\Unity\Unity_*.ulf" -ErrorAction 'SilentlyContinue'
    foreach ( $licenseFile in $licenseFiles ) {
        Write-Verbose "Discovered License File at $licenseFile"
        $doc = [xml](Get-Content "$licenseFile")
        $devBytes = [System.Convert]::FromBase64String($doc.root.License.DeveloperData.Value)

        # The first four bytes look like a count so skip that to pull out the serial string
        $licenseSerial = [String]::new($devBytes[4..($devBytes.Length - 1)])
        if ( $Serial -and [System.Net.NetworkCredential]::new($null, $Serial).Password -ne $licenseSerial ) { continue; }

        $license = $doc.root.License
        [PSCustomObject]@{
            'LicenseVersion' = $license.LicenseVersion.Value
            'Serial'         = ConvertTo-SecureString $licenseSerial -AsPlainText -Force
            'UnityVersion'   = $license.ClientProvidedVersion.Value
            'DisplaySerial'  = $license.SerialMasked.Value
            'ActivationDate' = ConvertTo-DateTime $license.InitialActivationDate.Value
            'StartDate'      = ConvertTo-DateTime $license.StartDate.Value
            'StopDate'       = ConvertTo-DateTime $license.StopDate.Value
            'UpdateDate'     = ConvertTo-DateTime $license.UpdateDate.Value
        }
    }
}

@(
    @{ 'Name' = 'gusi'; 'Value' = 'Get-UnitySetupInstance' },
    @{ 'Name' = 'gupi'; 'Value' = 'Get-UnityProjectInstance' },
    @{ 'Name' = 'susi'; 'Value' = 'Select-UnitySetupInstance' },
    @{ 'Name' = 'gue'; 'Value' = 'Get-UnityEditor' }
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

function Import-ProjectManifests {
    [CmdletBinding()]
    param(
        [Parameter()]
        [String]$ProjectManifestPath,
        [int]$SearchDepth = 3
    )

    $ProjectManifestPaths = @()

    if ((Get-Item $ProjectManifestPath) -is [System.IO.DirectoryInfo]) {
        Write-Host "Path provided is not a manifest.json file ($ProjectManifestPath), will attempt search"
        $FoundPaths = @(Get-ChildItem -Path $ProjectManifestPath -Include manifest.json -File -Recurse -Depth $SearchDepth -ErrorAction SilentlyContinue)
        foreach ($file in $FoundPaths) {
            $ProjectManifestPaths += $file.FullName
            if ($Verbose) { Write-Host "Found ($file.FullName)" }
        }
    }
    else {
        $ProjectManifestPaths += $ProjectManifestPath
    }

    if (([string]::IsNullOrEmpty($ProjectManifestPath)) -or (-not $(Test-Path $ProjectManifestPath))) {
        throw "Unable to find manifest.json file, please provide a path pointing directly to a Unity project's manifest.json or provide a path to a Unity project"
    }

    $scopedRegistrySet = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($ManifestPath in $ProjectManifestPaths) {
        $manifest = Get-Content -Path $ManifestPath | ConvertFrom-Json

        foreach ($scopedRegistry in $manifest.scopedRegistries) {
            $url = $scopedRegistry.url -replace '/$', ''  
            if ($url -like 'https://pkgs.dev.azure.com/*') {
                $scopedRegistrySet.Add($url) | Out-Null
            }
        }
    }

    return [System.Collections.Generic.HashSet[string]]::new($scopedRegistrySet)
}

function Import-TOMLFiles {
    param(
        [string[]]$tomlFilePaths = @(),
        [switch]$VerifyOnly
    )

    $tomlFileContents = @()
    
    foreach ($tomlFile in $tomlFilePaths) {
        if (-not (Test-Path $tomlFile)) {
            if ($Verbose) { Write-Host "$tomlFile doesn't exist, creating $tomlFile" }
            New-Item -Path $tomlFile -Force
        }

        $tomlFileContent = Get-Content $tomlFile -Raw
        $tomlFileContents += $tomlFileContent
    }
    
    return $tomlFileContents
}

function Sync-UPMConfig {
    [CmdletBinding()]
    param(
        [string[]]$scopedRegistryURLs,
        [string[]]$tomlFileContents,
        [switch]$AutoClean,
        [switch]$VerifyOnly,
        [switch]$ManualPAT,
        [int]$PATLifetime,
        [string]$DefaultScope,
        [string]$AzAPIVersion,
        [string]$ScopedURLRegEx,
        [string]$UPMRegEx
    )

    $Results = @()
    if ($IsWindows) {
        $isRunAsAdministrator = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    }
    else {
        $isRunAsAdministrator = (& whoami) -eq "root"
    }

    function Confirm-PAT($Org, $Project, $FeedID, $RawPAT) {
        if ($NoValidation) {
            Write-Host "Skipping PAT validation because of -NoValidation flag"
            return $true
        }
        $user = 'any'
        $pass = $RawPAT
        $pair = "$($user):$($pass)"
        $encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
        $basicAuthValue = "Basic $encodedCreds"
        $Headers = @{
            Authorization = $basicAuthValue
        }

        $URI = "https://feeds.dev.azure.com/$($Org)"
        if (-not [string]::IsNullOrEmpty($Project)) {
            $URI += "/$($Project)"
        }
        $URI += "/_apis/packaging/feeds/$($FeedID)?api-version=$AzAPIVersion"

        Write-Host "Attempting to validate PAT for '$($Org)' in feed: '$FeedID'"
        try {
            $req = Invoke-WebRequest -uri $URI -Method 'GET' -Headers $Headers -ErrorVariable $WebError -UseBasicParsing -ErrorAction SilentlyContinue
            $HTTP_Status = [int]$req.StatusCode
        }
        catch {
            $HTTP_Status = [int]$_.Exception.Response.StatusCode
            $HTTP_ErrorMessage = $_
        }

        If ($HTTP_Status -eq 200) {
            if ($Verbose) { Write-Host "PAT is valid for $Org!" }
            $result = $true
        }
        else {
            Write-Warning "Unable to validate PAT for $($Org). Error: $HTTP_ErrorMessage"
            $result = $false
        }
        if ($HTTP_Response -eq $null) { }
        else { $HTTP_Response.Close() }

        return $result
    }

    function Get-RegExForConfig($Org, $Project, $Feed, $PAT) {
        $regexresult = "[`r`n]*\[npmAuth\.""https:\/\/pkgs.dev.azure.com\/$($Org)\/"
        if (-not [string]::IsNullOrEmpty($Project)) {
            $regexresult += "$($Project)\/"
        }
        $regexresult += "_packaging\/$($Feed)\/npm\/registry""\][\n\r\s]*_auth ?= ?""$($PAT)""[\n\r\s]*(?:alwaysAuth[\n\r\s]*=[\n\r\s]*true)[\n\r\s]?"
        return $regexresult
    }

    function Read-PATFromUser($OrgName) {
        Write-Host "You need to create or supply a PAT for $($OrgName)."

        Write-Host "Please navigate to:"
        Write-Host "https://dev.azure.com/$($OrgName)/_usersSettings/tokens" -ForegroundColor Green
        Write-Host "to create a PAT with at least 'Package Read' (check your documentation for other scopes)"
        Write-Host ""

        $LaunchBrowserForPATs = 'y'
        $LaunchBrowserForPATs = Read-Host "Launch browser to 'https://dev.azure.com/$($OrgName)/_usersSettings/tokens'? (Default: $($LaunchBrowserForPATs))"
        if (($LaunchBrowserForPATs -like 'y') -or ($LaunchBrowserForPATs -like 'yes') -or [string]::IsNullOrEmpty($LaunchBrowserForPATs)) {
            Start-Process "https://dev.azure.com/$($OrgName)/_usersSettings/tokens"
        }

        $GoodPAT = $false
        while (-not $GoodPAT) {
            $UserPAT = Read-Host -Prompt "Please enter your PAT for $($OrgName)"
            if (Confirm-PAT "$($OrgName)" "$($ProjectName)" "$($FeedName)" "$($UserPAT.trim())") {
                return [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(":" + $UserPAT.trim()))
                $GoodPAT = $true
            }
            else {
                Write-Host "Unable to validate PAT, please try again"
            }
        }
    }

    function New-PAT($PATName, $OrgName, $Scopes, $ExpireDays) {
        $expireDate = (Get-Date).adddays($ExpireDays).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')

        $createPAT = 'y'

        if (-not $env:ADO_BUILD_ENVIRONMENT) {
            $answer = Read-Host "A Personal Access Token (PAT) will be created for you with the following details
    Name: $PATName
    Organization: $OrgName
    Expiration: $expireDate
Would you like to continue? (Default: $($createPAT))
"
            if (-not [string]::IsNullOrEmpty($answer)) {
                $createPAT = $answer
            }
        }

        if (($createPAT -like 'y') -or ($createPAT -like 'yes')) {
        }
        else {
            return $null
        }

        if (-not (Get-Module -ListAvailable "Az.Accounts")) {
            if (-not $isRunAsAdministrator) {
                Write-Error "This script requires admin permissions to install a module for Azure Accounts (used to log you in and create PATs for you).
             Please restart the script in an admin console, or run the script with the -ManualPAT option and supply your own PATs when prompted."
            }
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Install-Module -Name Az.Accounts -AllowClobber -Repository PSGallery -Scope CurrentUser -Force | Out-Null
        }

        if (-not (Get-Module -ListAvailable "Az.Accounts")) {
            Write-Error "Unable to find the az.accounts module. Please check previous errors and/or restart Powershell and try again. If it's still not working, run with the `-ManualPAT` flag to go through the interactive flow of manually creating a PAT."
            exit 1
        }

        if (-not $env:ADO_BUILD_ENVIRONMENT) {
            $azaccount = $(Get-AzContext).Account

            if ([string]::IsNullOrEmpty($azaccount) -or (-not $azaccount.Id.Contains("@microsoft.com"))) {
                Write-Host "Connecting to Azure, please login if prompted"
                Connect-AzAccount | Out-Null
            }
            $AZTokenRequest = Get-AzAccessToken -ResourceType Arm
            $headers = @{Authorization = "Bearer $($AZTokenRequest.Token)" }
        }
        else {
            $headers = @{Authorization = "Bearer $env:SYSTEM_ACCESSTOKEN" }
        }

        $RequestBody =
@"
{
    "allOrgs":"false",
    "displayName":"$($PatName)",
    "scope":"$($Scopes)",
    "validTo":"$($expireDate)"
}
"@
        $Url = "https://vssps.dev.azure.com/$($OrgName)/_apis/tokens/pats?api-version=$AzAPIVersion"

        $responseData = (Invoke-WebRequest -Uri $Url -Body $RequestBody -Method Post -Headers $headers -UseBasicParsing -ContentType "application/json").Content | ConvertFrom-Json

        $UserPAT = "$($responseData.patToken.token.trim())"

        if (Confirm-PAT "$($OrgName)" "$($ProjectName)" "$($FeedName)" "$($UserPAT)") {
            return [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(":" + $UserPAT))
        }
        else {
            Write-Host "Unable to validate PAT, please try again"
            return $null
        }
    }

    $UPMConfigs = @()
    foreach ($scopedRegistryURL in $scopedRegistryURLs) {
        if ($Verbose) { Write-Host "Resolving $scopedRegistryURL" }

        $CurrentRegistry = [Regex]::Match($scopedRegistryURL, $ScopedURLRegEx)

        $OrgURL = "$($CurrentRegistry.Groups["OrgURL"])"
        $OrgName = "$($CurrentRegistry.Groups["Org"])"
        $ProjectName = "$($CurrentRegistry.Groups["Project"])"
        $FeedName = "$($CurrentRegistry.Groups["Feed"])"

        $OrgNameUpper = $($OrgName).ToUpper()

        $foundCount = 0

        foreach ($tomlFileContent in $tomlFileContents) {
            if (-not [string]::IsNullOrWhiteSpace($tomlFileContent)) {
                [string[]]$FullURLs = @()

                foreach ($org in [Regex]::Matches($tomlFileContent, $UPMRegEx)) {
                    $FullURL = $org.Groups["FullURL"]
                    if ($FullURL -in $FullURLs) {
                        Write-Error "Config file $tomlFile contains duplicate entry for $FullURL, will cause error on reading file."

                        $RemoveBadPAT = 'y'
                        if (-not $AutoClean) {
                            $RemoveBadPAT = Read-Host "Remove all entries for $($org.Groups["Org"]) $($org.Groups["Project"]) $($org.Groups["Feed"])? (Default: $($RemoveBadPAT))"
                        }
                        if (($RemoveBadPAT -like 'y') -or ($RemoveBadPAT -like 'yes') -or [string]::IsNullOrEmpty($RemoveBadPAT)) {
                            Write-Host "Removing all entries for $($org.Groups["Org"]) $($org.Groups["Project"]) $($org.Groups["Feed"])"
                            $replaceFilter = (Get-RegExForConfig $org.Groups["Org"] $org.Groups["Project"] $org.Groups["Feed"] "$($org.Groups["Token"])")
                            $tomlFileContent = $tomlFileContent -replace $replaceFilter, ''
                            Set-Content -Path $tomlFile $tomlFileContent
                        }
                        continue
                    }
                    $FullURLs += $FullURL
                }

                foreach ($org in [Regex]::Matches($tomlFileContent, $UPMRegEx)) {
                    if ("$($org.Groups["FullURL"])" -like $scopedRegistryURL) {
                        try {
                            $reversedPAT = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("$($org.Groups["Token"])")).trim(':')
                        }
                        catch {
                            Write-Error "Auth appears malformed, unable to convert from base64"
                            $RemoveBadPAT = 'y'
                            if (-not $AutoClean) {
                                $RemoveBadPAT = Read-Host "Unable to validate a cached PAT, it could be expired or otherwise invalid. Remove expired/invalid auth for $OrgName in feed $FeedName? (Default: $($RemoveBadPAT))"
                            }
                            if (($RemoveBadPAT -like 'y') -or ($RemoveBadPAT -like 'yes') -or [string]::IsNullOrEmpty($RemoveBadPAT)) {
                                $replaceFilter = "$(Get-RegExForConfig "$($OrgName)" "$($ProjectName)" "$($FeedName)" "$($org.Groups["Token"])")"
                                $tomlFileContent = $tomlFileContent -replace $replaceFilter, ''
                                Set-Content -Path $tomlFile $tomlFileContent
                            }
                            continue
                        }

                        if (Confirm-PAT "$($OrgName)" "$($ProjectName)" "$($FeedName)" $reversedPAT) {
                            if ($Verbose) { Write-Host "Found: $tomlFile has valid auth for $scopedRegistryURL" }
                            $AuthState = "Present and valid"
                            $foundCount++
                        }
                        else {
                            $AuthState = "Invalid, failed validation"

                            if ($VerifyOnly) {
                                Write-Error "Invalid PAT found in Verify Mode"
                                exit 1
                            }
                            $RemoveBadPAT = 'y'
                            if (-not $AutoClean) {
                                $RemoveBadPAT = Read-Host "Unable to validate a cached PAT, it could be expired or otherwise invalid. Remove expired/invalid auth for $OrgName in feed $FeedName? (Default: $($RemoveBadPAT))"
                            }
                            if (($RemoveBadPAT -like 'y') -or ($RemoveBadPAT -like 'yes') -or [string]::IsNullOrEmpty($RemoveBadPAT)) {
                                $replaceFilter = "$(Get-RegExForConfig "$($OrgName)" "$($ProjectName)" "$($FeedName)" "$($org.Groups["Token"])")"
                                $tomlFileContent = $tomlFileContent -replace $replaceFilter, ''
                                Set-Content -Path $tomlFile $tomlFileContent
                            }
                        }
                    }
                }

                if ($foundCount -eq 0) {
                    $MatchedOrg = $false
                    foreach ($org in [Regex]::Matches($tomlFileContent, $UPMRegEx)) {
                        if (($org.Groups["OrgURL"]) -like $OrgURL) {
                            $reversedPAT = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("$($org.Groups["Token"])")).trim(':')

                            if (Confirm-PAT "$($OrgName)" "$($ProjectName)" "$($FeedName)" $reversedPAT) {
                                if ($Verbose) {
                                    Write-Host "Existing auth in the same organization, copying existing auth..."
                                    Write-Host "Auth for '$($org.Groups["OrgURL"])$($org.Groups["ProjectURL"])$($org.Groups["FeedID"])' will be copied for $scopedRegistryURL"
                                }

                                $tomlConfigContent = @(
                                    "`r`n[npmAuth.""$scopedRegistryURL""]"
                                    "_auth = ""$($org.Groups["Token"])"""
                                    "alwaysAuth = true"
                                ) -join "`r`n"
                                Add-Content -Path $tomlFile -Value $tomlConfigContent
                                $MatchedOrg = $true
                                $AuthState = "Verified and copied existing auth from same org"
                                $foundCount++
                            }
                            else {
                                Write-Host "Existing auth in the same organization found, but it appears to be expired or otherwise invalid"
                            }
                        }
                        if ($MatchedOrg) {
                            break
                        }
                    }
                    if (-not $MatchedOrg) {
                        $AuthState = "Not found!"
                        if ($Verbose) { Write-Host "No suitable auth inside $tomlFile for $scopedRegistryURL" }
                    }
                }
            }
        }

        $ScopedPAT = ''
        if ($foundCount -eq 0) {
            if ($VerifyOnly) {
                Write-Error "No PAT found in Verify Mode"
                exit 1
            }

            if ($env:ADO_BUILD_ENVIRONMENT) {
                if (-not [string]::IsNullOrWhiteSpace($([System.Environment]::GetEnvironmentVariable("$($OrgNameUpper)_ACCESSTOKEN")))) {
                    $org_pat = [System.Environment]::GetEnvironmentVariable("$($OrgNameUpper)_ACCESSTOKEN")
                    if (Confirm-PAT "$($OrgName)" "$($ProjectName)" "$($FeedName)" $org_pat) {
                        if ($Verbose) { Write-Host "Organization specific token found" }
                        $ScopedPAT = [System.Environment]::GetEnvironmentVariable("$($OrgNameUpper)_ACCESSTOKEN")
                        $AuthState = "Applied from $OrgName PAT"
                    }
                    else {
                        Write-Error "Organization specific token found, but it was invalid"
                        $AuthState = "$OrgName PAT is invalid"
                    }
                }
                else {
                    if (Confirm-PAT "$($OrgName)" "$($ProjectName)" "$($FeedName)" $env:SYSTEM_ACCESSTOKEN) {
                        if ($Verbose) { Write-Host "System access token found" }
                        $ScopedPAT = $env:SYSTEM_ACCESSTOKEN
                        $AuthState = "Applied from system PAT"
                    }
                    else {
                        Write-Error "System access token found, but it was invalid for this org"
                        $AuthState = "PAT is invalid"
                    }
                }
            }

            if (![string]::IsNullOrEmpty($ScopedPAT)) {
                $convertedScopedPAT = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(":" + $ScopedPAT.trim()))

            }
            else {
                Write-Host "Missing authentication for $scopedRegistryURL"
                Write-Host ""
                if ($ManualPAT) {
                    $newPAT = Read-PATFromUser($OrgName)
                }
                else {
                    $newPAT = $(New-PAT "$($OrgName)_Package-Read (Automated)"  "$($OrgName)"  "$($DefaultScope)"  $PATLifetime)
                }
                if (-not [string]::IsNullOrEmpty($newPAT)) {
                    $convertedScopedPAT = $newPAT
                    $AuthState = "Applied from user"
                }
                else {
                    $AuthState = "Failed to validate PAT from user"
                }
            }

            if (-not $convertedScopedPAT) {
                Write-Error "Auth not found for $scopedRegistryURL and no valid PAT to add"
                $AuthState = "Missing"
                continue
            }

            if ($Verbose) { Write-Host "Auth not found for $scopedRegistryURL. Adding using supplied PAT..." }

            $UPMConfigs += [PSCustomObject]@{
                Scoped_URL = $scopedRegistryURL
                Auth = $convertedScopedPAT
            }
        }
        $Results += [PSCustomObject]@{
            Scoped_URL = $scopedRegistryURL
            Auth_State = $AuthState
        }
    }

    return $UPMConfigs
}

function Export-UPMConfig {
    [CmdletBinding()]
    param(
        [PSCustomObject[]]$UPMConfigs,
        [string[]]$tomlFilePaths
    )

    foreach ($UPMConfig in $UPMConfigs) {
        if (![string]::IsNullOrEmpty($UPMConfig.Scoped_URL) -and ![string]::IsNullOrEmpty($UPMConfig.Auth)) {
            $scopedRegistryURL = $UPMConfig.Scoped_URL
            $convertedScopedPAT = $UPMConfig.Auth

            $tomlConfigContent = @(
                "`r`n[npmAuth.""$scopedRegistryURL""]"
                "_auth = ""$convertedScopedPAT"""
                "alwaysAuth = true"
            ) -join "`r`n"

            foreach ($filePath in $tomlFilePaths) {
                Add-Content -Path $filePath -Value $tomlConfigContent
            }
        }
    }
}

<#
.Synopsis
   Ensures that the user has the appropriate auth tokens to fetch Unity packages in their .toml file.

   For more information on Unity Package Manager config, please visit https://docs.unity3d.com/Manual/upm-config.html
.DESCRIPTION
   Looks at the Unity Project Manifest and finds the scoped registries used for fetching NPM packages.  

   For each of the scoped registries found within the project manifest(s) or SOT.json file, the cmdlet will verify that
   there is a valid auth token for each scoped registry URL.  If none were found, it will try to fetch a new auth token
   and save it to the .toml file.

   Additional arguments are available to automatically clean expired tokens, allow the user to manually propulate the token,
   scan a deeper folder tree for manifests, or simply validate your existing PATs.
.PARAMETER ProjectManifestPath
   A path to a project manifest, or a path to a root directory under which Unity project manifests can be found.
.PARAMETER AutoClean
   Automatically remove PATs that can't be validated
.PARAMETER NoValidation
   Skip validation of PATs
.PARAMETER ManualPAT
   Do not use Azure APIs to automatically create the PAT, user will manually enter it
.PARAMETER SearchDepth
   How deep to search for manifest files
.PARAMETER VerifyOnly
   Runs in validation only mode, returns 0 if all registries are valid, otherwise returns 1
.PARAMETER PATLifetime
   How many days the created PAT is valid
.EXAMPLE
   Update-UPMConfig -ProjectManifestPath '/User/myusername/MyUnityProjectRoot'
.EXAMPLE
   Update-UPMConfig -ProjectManifestPath '/User/myusername/MyUnityProjectRoot/manifest.json'
.EXAMPLE
   Update-UPMConfig -AutoClean True
.EXAMPLE
   Update-UPMConfig -NoValidation True -ManualPAT True
.EXAMPLE
   Update-UPMConfig -ProjectManifestPath '/User/myusername/MyUnityProjectRoot' -SearchDepth 7 -VerifyOnly True
#>
function Update-UPMConfig {
    [CmdletBinding()]
    param(
        [Parameter()]
        [String]$ProjectManifestPath,
        [Switch]$AutoClean = $false,
        [Switch]$NoValidation = $false, 
        [Switch]$ManualPAT = $false, 
        [int]$SearchDepth = 3,
        [Switch]$VerifyOnly,
        [int]$PATLifetime = 7
    )

    $ScopedURLRegEx = "(?<FullURL>(?<OrgURL>https:\/\/pkgs.dev.azure.com\/(?<Org>[a-zA-Z0-9]*))\/?(?<Project>[a-zA-Z0-9]*)?\/_packaging\/(?<Feed>[a-zA-Z0-9\-_\.%\(\)!]*)?\/npm\/registry\/?)"
    $UPMRegEx = "\[npmAuth\.""(?<FullURL>(?<OrgURL>https:\/\/pkgs.dev.azure.com\/(?<Org>[a-zA-Z0-9]*))\/?(?<Project>[a-zA-Z0-9]*)?\/_packaging\/(?<Feed>[a-zA-Z0-9\-_\.%\(\)!]*)?\/npm\/registry\/?)""\][\n\r\s]*_auth ?= ?""(?<Token>[a-zA-Z0-9=]*)""[\n\r\s]*(?:alwaysAuth[\n\r\s]*=[\n\r\s]*true)[\n\r\s]*"
    $AzAPIVersion = '7.1-preview.1'
    $DefaultScope = 'vso.packaging'

    $NonInteractive = [Environment]::GetCommandLineArgs() | Where-Object { $_ -like '-NonI*' }
    if (-not [Environment]::UserInteractive -or $NonInteractive) {
        $AutoClean = $true
    }

    if ($IsMacOS -or $IsLinux) {
        $tomlFilePaths += [io.path]::combine($env:HOME, ".upmconfig.toml")
    }
    else {
        $tomlFilePaths += [io.path]::combine($env:USERPROFILE, ".upmconfig.toml")
    }

    $scopedRegistryURLs = Import-ProjectManifests -ProjectManifestPath $ProjectManifestPath -SearchDepth $SearchDepth
    $tomlFileContents = Import-TOMLFiles -tomlFilePaths $tomlFilePaths -VerifyOnly $VerifyOnly

    $UPMConfigs = Sync-UPMConfig -scopedRegistryURLs $scopedRegistryURLs -tomlFileContents $tomlFileContents -AutoClean:$AutoClean.IsPresent -VerifyOnly:$VerifyOnly.IsPresent -ManualPAT:$ManualPAT.IsPresent -PATLifetime $PATLifetime -DefaultScope $DefaultScope -AzAPIVersion $AzAPIVersion -ScopedURLRegEx $ScopedURLRegEx -UPMRegEx $UPMRegEx

    Export-UPMConfig -UPMConfigs $UPMConfigs -tomlFilePaths $tomlFilePaths

    Write-Host "Summary"
    Format-Table -AutoSize -InputObject $UPMConfigs
    if ($VerifyOnly) {
        Write-Host "Verify Mode complete"
        exit 0
    }
}
