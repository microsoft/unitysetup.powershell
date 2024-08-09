# Unity Setup Powershell Module

This PowerShell module contains tools for managing and automating your Unity installs and projects.

## Builds

### Master
[![Build status](https://ci.appveyor.com/api/projects/status/m7ykg9s8gw23fn6h/branch/master?svg=true)](https://ci.appveyor.com/project/jwittner/unitysetup-powershell/branch/master)

The `master` branch is automatically built and deployed to the [PowerShell Gallery](https://www.powershellgallery.com/packages/UnitySetup).

### Develop
[![Build status](https://ci.appveyor.com/api/projects/status/m7ykg9s8gw23fn6h/branch/develop?svg=true)](https://ci.appveyor.com/project/jwittner/unitysetup-powershell/branch/develop)

The `develop` branch is automatically built and deployed as a prerelease module to the [PowerShell Gallery](https://www.powershellgallery.com/packages/UnitySetup).

## Installation

```powershell
Install-Module UnitySetup -Scope CurrentUser
```

## Using

### Cmdlets
Find all of your Unity installs:
```powershell
Get-UnitySetupInstance

# Example output:
# Version                                          Components Path
# -------                                          ---------- ----
# 2017.1.2f1                       Windows, UWP, UWP_IL2CPP C:\Program Files\Unity-2017.1.2f1\
# 2017.1.3f1                       Windows, UWP, UWP_IL2CPP C:\Program Files\Unity-2017.1.3f1\
# 2017.2.1f1                       Windows, UWP, UWP_IL2CPP C:\Program Files\Unity-2017.2.1f1\
# 2017.3.1f1       Windows, UWP, UWP_IL2CPP, Linux, Vuforia C:\Program Files\Unity-2017.3.1f1\
# 2018.1.0b4              Windows, UWP, UWP_IL2CPP, Vuforia C:\Program Files\Unity-2018.1.0b4\
# 2018.1.0b8                                              All C:\Program Files\Unity-2018.1.0b8\
# 2017.1.0p5                       Windows, UWP, UWP_IL2CPP C:\Program Files\Unity.2017.1.0p5\
# 2017.1.1f1                       Windows, UWP, UWP_IL2CPP C:\Program Files\Unity.2017.1.1f1\
# 2017.1.1p3       Windows, StandardAssets, UWP, UWP_IL2CPP C:\Program Files\Unity.2017.1.1p3\
# 2017.2.0f3              Windows, UWP, UWP_IL2CPP, Vuforia C:\Program Files\Unity.2017.2.0f3\
# 2017.3.0f3         Windows, UWP, UWP_IL2CPP, Mac, Vuforia C:\Program Files\Unity.2017.3.0f3\
```
Select the Unity installs that you want:
```powershell
Get-UnitySetupInstance | Select-UnitySetupInstance -Latest
Get-UnitySetupInstance | Select-UnitySetupInstance -Version '2017.1.1f1'
Get-UnitySetupInstance | Select-UnitySetupInstance -Project '.\MyUnityProject'
```
Find all the Unity projects recursively:
```powershell
Get-UnityProjectInstance -Recurse

# Example output:
# Version    Path                            ProductName
# -------    ----                            -----------
# 2017.2.0f3 C:\Projects\Project1\OneUnity\  Contoso
# 2017.3.0f3 C:\Projects\Project1\TwoUnity\  Northwind
# 2017.1.1p1 C:\Projects\Project2\           My Cool App
# 2017.1.2f1 C:\Projects\Project3\App.Unity\ TemplateProject
```
Launch the right Unity editor for a project:
```powershell
Start-UnityEditor
Start-UnityEditor -Project .\MyUnityProject
Start-UnityEditor -Project .\MyUnityProject -Latest
Start-UnityEditor -Project .\MyUnityProject -Version '2017.3.0f3'
```

Using the [Unity Accelerator](https://docs.unity3d.com/2019.3/Documentation/Manual/UnityAccelerator.html):
```powershell
Start-UnityEditor -Project .\MyUnityProject -CacheServerEndpoint 192.168.0.23 
Start-UnityEditor -Project .\MyUnityProject -CacheServerEndpoint 192.168.0.23:2523 -CacheServerNamespacePrefix "dev"
Start-UnityEditor -Project .\MyUnityProject -CacheServerEndpoint 192.168.0.23 -CacheServerNamespacePrefix "dev" -CacheServerDisableDownload
Start-UnityEditor -Project .\MyUnityProject -CacheServerEndpoint 192.168.0.23 -CacheServerDisableUpload
```
Launch many projects at the same time:
```powershell
Get-UnityProjectInstance -Recurse | Start-UnityEditor
```
Invoke methods with arbitrary arguments:
```powershell
Start-UnityEditor -ExecuteMethod Build.Invoke -BatchMode -Quit -LogFile .\build.log -Wait -AdditionalArguments "-BuildArg1 -BuildArg2"
```
Test the meta file integrity of Unity Projects:
```powershell
Test-UnityProjectInstanceMetaFileIntegrity # Test project in current folder
Test-UnityProjectInstanceMetaFileIntegrity .\MyUnityProject
Test-UnityProjectInstanceMetaFileIntegrity -Project .\MyUnityProject
Get-UnityProjectInstance -Recurse | Test-UnityProjectInstanceMetaFileIntegrity

# Example output:
# True
```
Get meta file integrity issues for Unity Projects:
```powershell
Test-UnityProjectInstanceMetaFileIntegrity .\MyUnityProject -PassThru

# Example output:
# Item                                                              Issue
# ----                                                              -----
# C:\MyUnityProject\Assets\SomeFolder                               Directory is missing associated meta file.
# C:\MyUnityProject\Assets\SomeFolder\SomeShader.shader             File is missing associated meta file.
# C:\MyUnityProject\Assets\SomeFolder\SomeOtherShader.shader.meta   Meta file is missing associated item.
# C:\MyUnityProject\Assets\SomeFolder\SomeNewShader.shader.meta     Meta file guid collision with C:\MyUnityProject\Assets\SomeFolder\SomeOtherShader.shader.meta
```

Find the installers for a particular version:
```powershell
Find-UnitySetupInstaller -Version '2017.3.0f3' | Format-Table

# Example output:
#  ComponentType Version       Length LastModified          DownloadUrl
#  ------------- -------       ------ ------------          -----------
#        Windows 2017.3.0f3 553688024 12/18/2017 8:05:31 AM https://download.unity3d.com/download_unity/...
#          Linux 2017.3.0f3 122271984 12/18/2017 8:06:53 AM https://download.unity3d.com/download_unity/...
#            Mac 2017.3.0f3  28103888 12/18/2017 8:06:53 AM https://download.unity3d.com/download_unity/...
#  Documentation 2017.3.0f3 358911256 12/18/2017 8:07:34 AM https://download.unity3d.com/download_unity/...
# StandardAssets 2017.3.0f3 189886032 12/18/2017 8:05:50 AM https://download.unity3d.com/download_unity/...
#          UWP 2017.3.0f3 172298008 12/18/2017 8:07:04 AM https://download.unity3d.com/download_unity/...
#     UWP_IL2CPP 2017.3.0f3 152933480 12/18/2017 8:07:10 AM https://download.unity3d.com/download_unity/...
#        Android 2017.3.0f3 194240888 12/18/2017 8:05:58 AM https://download.unity3d.com/download_unity/...
#            iOS 2017.3.0f3 802853872 12/18/2017 8:06:46 AM https://download.unity3d.com/download_unity/...
#        AppleTV 2017.3.0f3 273433528 12/18/2017 8:06:09 AM https://download.unity3d.com/download_unity/...
#       Facebook 2017.3.0f3  32131560 12/18/2017 8:06:12 AM https://download.unity3d.com/download_unity/...
#        Vuforia 2017.3.0f3  65677296 12/18/2017 8:07:12 AM https://download.unity3d.com/download_unity/...
#          WebGL 2017.3.0f3 134133288 12/18/2017 8:07:19 AM https://download.unity3d.com/download_unity/...
```

Limit what components you search for:
```powershell
Find-UnitySetupInstaller -Version 2017.3.0f3 -Components 'Windows','Documentation' | Format-Table

# Example output:
# ComponentType Version       Length LastModified          DownloadUrl
# ------------- -------       ------ ------------          -----------
#       Windows 2017.3.0f3 553688024 12/18/2017 8:05:31 AM https://download.unity3d.com/download_unity/...
# Documentation 2017.3.0f3 358911256 12/18/2017 8:07:34 AM https://download.unity3d.com/download_unity/...
```

Install UnitySetup instances:
```powershell
# Pipeline is supported, but downloads, then installs, then downloads, etc.
Find-UnitySetupInstaller -Version '2017.3.0f3' | Install-UnitySetupInstance

# This will issue all downloads together, then install each.
Install-UnitySetupInstance -Installers (Find-UnitySetupInstaller -Version '2017.3.0f3')
```

Manage Unity licenses.
```powershell
# Get any active licenses
Get-UnityLicense

# Example Output:
# LicenseVersion : 6.x
# Serial         : System.Security.SecureString
# UnityVersion   : 2017.4.2f2
# DisplaySerial  : AB-CDEF-GHIJ-KLMN-OPQR-XXXX
# ActivationDate : 2017-07-13 16:32:16
# StartDate      : 2017-07-12 00:00:00
# StopDate       : 2019-01-01 00:00:00
# UpdateDate     : 2018-05-11 23:47:10

# Activate a license
Start-UnityEditor -Credential <unityAccount> -Serial <unitySerial> -Wait

# Return license
Start-UnityEditor -Credential <unityAccount> -ReturnLicense -Wait
```

Manage Unity Package Manager configuration
``` powershell
# Update NPM auth tokens for my project manifest
Update-UnityPackageManagerConfig -ProjectManifestPath "C:\MyUnityProject\Packages\manifest.json"   

# Example output
# A Personal Access Token (PAT) will be created for you with the following details
# Name: myorg_Package-Read (Automated)
# Organization: myorg
# Expiration: 2024-07-17T13:53:04.889Z
# Would you like to continue? (Default: y): y
#
# ScopedURL                                                                 Auth
# ---------                                                                 ----
# https://pkgs.dev.azure.com/myorg/myproject/_packaging/MyRegistry/npm/registry my_auth_token_string_base64=
```

### DSC
UnitySetup includes the xUnitySetupInstance DSC Resource. An example configuration might look like:

```powershell
<#
    Install multiple versions of Unity and several components
#>
Configuration Sample_xUnitySetupInstance_Install {
    param(
        [PSCredential]$UnityCredential,
        [PSCredential]$UnitySerial
    )

    Import-DscResource -ModuleName UnitySetup

    Node 'localhost' {

        xUnitySetupInstance Unity {
            Versions = '2017.4.2f2,2018.1.0f2'
            Components = 'Windows', 'Mac', 'Linux', 'UWP', 'iOS'
            Ensure = 'Present'
        }

        xUnityLicense UnityLicense {
            Name = 'UL01'
            Credential = $UnityCredential
            Serial = $UnitySerial
            Ensure = 'Present'
            UnityVersion = '2017.4.2f2'
            DependsOn = '[xUnitySetupInstance]Unity'   
        }
    }
}
```

See more by perusing the `UnitySetup\Examples` folder.

# Feedback
To file issues or suggestions, please use the [Issues](https://github.com/Microsoft/unitysetup.powershell/issues) page for this project on GitHub.


# Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit https://cla.microsoft.com.

When you submit a pull request, a CLA-bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.


## Testing

This project includes Pester test runners for both unit tests and end to end tests - which can test against real Unity projects via environment variables.

To learn more about how to run and write tests, please refer to the [Test Runner Guide](./Tests/README.md).


# Reporting Security Issues

Security issues and bugs should be reported privately, via email, to the Microsoft Security Response Center (MSRC) at [secure@microsoft.com](mailto:secure@microsoft.com). You should receive a response within 24 hours. If for some reason you do not, please follow up via email to ensure we received your original message. Further information, including the [MSRC PGP](https://technet.microsoft.com/en-us/security/dn606155) key, can be found in the [Security TechCenter](https://technet.microsoft.com/en-us/security/default).