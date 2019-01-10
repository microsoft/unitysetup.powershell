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
    All = (1 -shl 14) - 1
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
                    [UnitySetupComponent]::UWP = [io.path]::Combine("$playbackEnginePath", "MetroSupport\Templates\UWP_.NET_D3D"),
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
   Help to create UnitySetupComponent
.PARAMETER Components
   What components would you like included?
.EXAMPLE
   ConvertTo-UnitySetupComponent Windows,UWP
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

    $currentOS = Get-OperatingSystem
    switch ($currentOS) {
        ([OperatingSystem]::Windows) {
            $unitySetupRegEx = "^(.+)\/([a-z0-9]+)\/Windows64EditorInstaller\/UnitySetup64-(\d+)\.(\d+)\.(\d+)([fpb])(\d+).exe$"
            $targetSupport = "TargetSupportInstaller"
            $installerExtension = "exe"
        }
        ([OperatingSystem]::Linux) {
            throw "Find-UnitySetupInstaller has not been implemented on the Linux platform. Contributions welcomed!";
        }
        ([OperatingSystem]::Mac) {
            $unitySetupRegEx = "^(.+)\/([a-z0-9]+)\/MacEditorInstaller\/Unity-(\d+)\.(\d+)\.(\d+)([fpb])(\d+).pkg$"
            $targetSupport = "MacEditorTargetInstaller"
            $installerExtension = "pkg"
        }
    }

    $knownBaseUrls = @(
        "https://download.unity3d.com/download_unity",
        "https://netstorage.unity3d.com/unity",
        "https://beta.unity3d.com/download"
    )

    $installerTemplates = @{
        [UnitySetupComponent]::UWP = "$targetSupport/UnitySetup-UWP-.NET-Support-for-Editor-$Version.$installerExtension",
         "$targetSupport/UnitySetup-Metro-Support-for-Editor-$Version.$installerExtension";
        [UnitySetupComponent]::UWP_IL2CPP = , "$targetSupport/UnitySetup-UWP-IL2CPP-Support-for-Editor-$Version.$installerExtension";
        [UnitySetupComponent]::Android = , "$targetSupport/UnitySetup-Android-Support-for-Editor-$Version.$installerExtension";
        [UnitySetupComponent]::iOS = , "$targetSupport/UnitySetup-iOS-Support-for-Editor-$Version.$installerExtension";
        [UnitySetupComponent]::AppleTV = , "$targetSupport/UnitySetup-AppleTV-Support-for-Editor-$Version.$installerExtension";
        [UnitySetupComponent]::Facebook = , "$targetSupport/UnitySetup-Facebook-Games-Support-for-Editor-$Version.$installerExtension";
        [UnitySetupComponent]::Linux = , "$targetSupport/UnitySetup-Linux-Support-for-Editor-$Version.$installerExtension";
        [UnitySetupComponent]::Mac = "$targetSupport/UnitySetup-Mac-Support-for-Editor-$Version.$installerExtension",
        "$targetSupport/UnitySetup-Mac-Mono-Support-for-Editor-$Version.$installerExtension";
        [UnitySetupComponent]::Vuforia = , "$targetSupport/UnitySetup-Vuforia-AR-Support-for-Editor-$Version.$installerExtension";
        [UnitySetupComponent]::WebGL = , "$targetSupport/UnitySetup-WebGL-Support-for-Editor-$Version.$installerExtension";
        [UnitySetupComponent]::Windows_IL2CPP = , "$targetSupport/UnitySetup-Windows-IL2CPP-Support-for-Editor-$Version.$installerExtension";
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
                        'Version' = $Version;
                        'DownloadUrl' = $endpoint;
                        'Length' = $installerLength;
                        'LastModified' = $lastModified;
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
        $Installers = $Installers | Where-Object { $Components -band $_.ComponentType } | ForEach-Object { $_ }

        if ($Installers.Length -ne 0) {
            $selectedInstallers += $Installers
        }
    }
    end {
        return $selectedInstallers
    }
}

filter Format-Bytes {
	return "{0:N2} {1}" -f $(
        if ($_ -lt 1kb)     { $_, 'Bytes' }
        elseif ($_ -lt 1mb) { ($_/1kb), 'KB' }
        elseif ($_ -lt 1gb) { ($_/1mb), 'MB' }
        elseif ($_ -lt 1tb) { ($_/1gb), 'GB' }
        elseif ($_ -lt 1pb) { ($_/1tb), 'TB' }
        else                { ($_/1pb), 'PB' }
    )
}

function Format-BitsPerSecond {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)]
        [int] $Bytes,

        [parameter(Mandatory = $true)]
        [int] $Seconds
    )
    if ($Seconds -le 0.001) {
        return "0 Bps"
    }
    # Convert from bytes to bits
    $Bits = ($Bytes * 8) / $Seconds
	return "{0:N2} {1}" -f $(
        if ($Bits -lt 1kb)     { $Bits, 'Bps' }
        elseif ($Bits -lt 1mb) { ($Bits/1kb), 'Kbps' }
        elseif ($Bits -lt 1gb) { ($Bits/1mb), 'Mbps' }
        elseif ($Bits -lt 1tb) { ($Bits/1gb), 'Gbps' }
        elseif ($Bits -lt 1pb) { ($Bits/1tb), 'Tbps' }
        else                   { ($Bits/1pb), 'Pbps' }
    )
}

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
            $global:downloadData = [ordered]@{}
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
                            'Path' = $destination
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
                    startTime = Get-Date
                    totalBytes = $_.Length
                    receivedBytes = 0
                    isDownloaded = $false
                    destination = $destination
                    lastModified = $_.LastModified
                    componentType = $_.ComponentType
                    webClient = $webClient
                    downloadIndex = $downloadIndex
                }

                # Register to events for showing progress of file download.
                Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -SourceIdentifier "$installerFileName-Changed" -MessageData $installerFileName -Action {
                    $global:downloadData[$event.MessageData].receivedBytes = $event.SourceArgs.BytesReceived
                } | Out-Null
                Register-ObjectEvent -InputObject $webClient -EventName DownloadFileCompleted -SourceIdentifier "$installerFileName-Completed" -MessageData $installerFileName -Action {
                    $global:downloadData[$event.MessageData].isDownloaded = $true
                } | Out-Null

                try
                {
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

            $totalDownloads = $global:downloadData.Count

            # Showing progress of all file downloads
            while ($global:downloadData.Count -gt 0) {
                $global:downloadData.Keys | ForEach-Object {
                    $installerFileName = $_
                    $data = $global:downloadData[$installerFileName]

                    # Finished downloading
                    if ($null -eq $data.webClient) {
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
                            'Path' = $data.destination
                        }
                        $downloads += , $resource
                        return
                    }

                    $elapsedTime = (Get-Date) - $data.startTime

                    $progress = [int](($data.receivedBytes / [double]$data.totalBytes) * 100)
    
                    $averageSpeed = $data.receivedBytes / $elapsedTime.TotalSeconds
                    $secondsRemaining = ($data.totalBytes - $data.receivedBytes) / $averageSpeed
    
                    if ([double]::IsInfinity($secondsRemaining)) {
                        $averageSpeed = 0
                        # -1 for Write-Progress prevents seconds remaining from showing.
                        $secondsRemaining = -1
                    }
    
                    $downloadSpeed = Format-BitsPerSecond -Bytes $data.receivedBytes -Seconds $elapsedTime.TotalSeconds

                    Write-Progress -Activity "Downloading $installerFileName | $downloadSpeed" `
                        -Status "$($data.receivedBytes | Format-Bytes) of $($data.totalBytes | Format-Bytes)" `
                        -SecondsRemaining $secondsRemaining `
                        -PercentComplete $progress `
                        -Id $data.downloadIndex
                }
            }
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
                'FilePath' = $Package.Path;
                'ArgumentList' = @("/S", "/D=$Destination");
                'PassThru' = $true;
                'Wait' = $true;
            }
        }
        ([OperatingSystem]::Linux) {
            throw "Install-UnitySetupPackage has not been implemented on the Linux platform. Contributions welcomed!";
        }
        ([OperatingSystem]::Mac) {
            # Note that $Destination has to be a disk path.
            # sudo installer -package $Package.Path -target /
            $startProcessArgs = @{
                'FilePath' = 'sudo';
                'ArgumentList' = @("installer", "-package", $Package.Path, "-target", $Destination);
                'PassThru' = $true;
                'Wait' = $true;
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
                ([OperatingSystem]::Windows) { 'C:\Program Files\Unity' }
                ([OperatingSystem]::Linux) { throw "Install-UnitySetupInstance has not been implemented on the Linux platform. Contributions welcomed!"; }
                ([OperatingSystem]::Mac) { '/Applications/Unity' }
            }
        }
        else {
            $defaultInstallPath = $BasePath
        }

        $unitySetupInstances = Get-UnitySetupInstance -BasePath $BasePath

        $versionInstallers = @{}
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
                $installPath = "$defaultInstallPath-$installVersion"
            }

            if ($currentOS -eq [OperatingSystem]::Mac) {
                $volumeRoot = "/Volumes/UnitySetup/"
                $volumeInstallPath = [io.path]::Combine($volumeRoot, "Applications/Unity/")

                # Make sure the install path ends with a trailing slash. This
                # is required in some commands to treat as directory.
                if (-not $installPath.EndsWith([io.path]::DirectorySeparatorChar)) {
                    $installPath += [io.path]::DirectorySeparatorChar
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
                Write-Verbose "Installing $($editorInstaller.ComponentType)"
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
                Write-Verbose "Copying install to $installPath."
                # Copy the files (-r) and recreate symlinks (-l) to the install directory.
                # Preserve permissions (-p) and owner (-o).
                # chmod gives files read permissions.
                & sudo rsync -rlpo $volumeInstallPath $installPath --chmod=+r --remove-source-files

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
                $BasePath = @('/Applications/Unity*', '/Applications/Unity/Hub/Editor/*')
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

    process {
        if ( $PSBoundParameters.ContainsKey('Path') ) {
            $Path = $Path.TrimEnd([io.path]::DirectorySeparatorChar)
            $Instances = $Instances | Where-Object {
                $Path -eq (Get-Item $_.Path).FullName.TrimEnd([io.path]::DirectorySeparatorChar)
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
.PARAMETER EditorTestsCategories
   Filter tests by category names.
.PARAMETER EditorTestsFilter
   Filter tests by test names.
.PARAMETER EditorTestsResultFile
   Where to put the results? Unity states, "If the path is a folder, the command line uses a default file name. If not specified, it places the results in the project’s root folder."
.PARAMETER RunEditorTests
   Should Unity run the editor tests? Unity states, "[...]it’s good practice to run it with batchmode argument. quit is not required, because the Editor automatically closes down after the run is finished."
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
        [string[]]$EditorTestsCategory,
        [parameter(Mandatory = $false)]
        [string[]]$EditorTestsFilter,
        [parameter(Mandatory = $false)]
        [string]$EditorTestsResultFile,
        [parameter(Mandatory = $false)]
        [switch]$RunEditorTests,
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
        if ( $EditorTestsCategory ) { $sharedArgs += '-editorTestsCategories', ($EditorTestsCategory -join ',') }
        if ( $EditorTestsFilter ) { $sharedArgs += '-editorTestsFilter', ($EditorTestsFilter -join ',') }
        if ( $EditorTestsResultFile ) { $sharedArgs += '-editorTestsResultFile', $EditorTestsResultFile }
        if ( $RunEditorTests ) { $sharedArgs += '-runEditorTests' }
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
        $errors = $errors | select -uniq # Unity prints out errors as they occur and also in a summary list. We only want to see each unique error once.
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
