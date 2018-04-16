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
# 2017.1.2f1                       Windows, Metro, UWP_IL2CPP C:\Program Files\Unity-2017.1.2f1\
# 2017.1.3f1                       Windows, Metro, UWP_IL2CPP C:\Program Files\Unity-2017.1.3f1\
# 2017.2.1f1                       Windows, Metro, UWP_IL2CPP C:\Program Files\Unity-2017.2.1f1\
# 2017.3.1f1       Windows, Metro, UWP_IL2CPP, Linux, Vuforia C:\Program Files\Unity-2017.3.1f1\
# 2018.1.0b4              Windows, Metro, UWP_IL2CPP, Vuforia C:\Program Files\Unity-2018.1.0b4\
# 2018.1.0b8                                              All C:\Program Files\Unity-2018.1.0b8\
# 2017.1.0p5                       Windows, Metro, UWP_IL2CPP C:\Program Files\Unity.2017.1.0p5\
# 2017.1.1f1                       Windows, Metro, UWP_IL2CPP C:\Program Files\Unity.2017.1.1f1\
# 2017.1.1p3       Windows, StandardAssets, Metro, UWP_IL2CPP C:\Program Files\Unity.2017.1.1p3\
# 2017.2.0f3              Windows, Metro, UWP_IL2CPP, Vuforia C:\Program Files\Unity.2017.2.0f3\
# 2017.3.0f3         Windows, Metro, UWP_IL2CPP, Mac, Vuforia C:\Program Files\Unity.2017.3.0f3\
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
# Version    Path
# -------    ----
# 2017.2.0f3 C:\Projects\Project1\OneUnity\                 
# 2017.3.0f3 C:\Projects\Project1\TwoUnity\                 
# 2017.1.1p1 C:\Projects\Project2\                          
# 2017.1.2f1 C:\Projects\Project3\App.Unity\                
```
Launch the right Unity editor for a project:
```powershell
Start-UnityEditor
Start-UnityEditor -Project .\MyUnityProject
Start-UnityEditor -Project .\MyUnityProject -Latest
Start-UnityEditor -Project .\MyUnityProject -Version '2017.3.0f3'
```
Launch many projects at the same time:
```powershell
Get-UnityProjectInstance -Recurse | Start-UnityEditor
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
#          Metro 2017.3.0f3 172298008 12/18/2017 8:07:04 AM https://download.unity3d.com/download_unity/...
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

### DSC
UnitySetup includes the xUnitySetupInstance DSC Resource. An example configuration might look like:

```powershell
<#
    Install multiple versions of Unity and several components
#>
Configuration Sample_xUnitySetupInstance_Install {

    Import-DscResource -ModuleName UnitySetup

    Node 'localhost' {

        xUnitySetupInstance Unity {
            Versions = '2017.3.1f1,2018.1.0b9'
            Components = 'Windows', 'Mac', 'Linux', 'Metro', 'iOS'
            Ensure = 'Present'
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