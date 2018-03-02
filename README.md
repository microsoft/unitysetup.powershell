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

Find all of your Unity installs:
```powershell
Get-UnitySetupInstance

# Example output:
# InstallationVersion InstallationPath
# ------------------- ----------------
# 2017.2.1f1          C:\Program Files\Unity-2017.2.1f1\Editor\
# 2017.1.0p5          C:\Program Files\Unity.2017.1.0p5\Editor\
# 2017.1.1f1          C:\Program Files\Unity.2017.1.1f1\Editor\
# 2017.1.1p3          C:\Program Files\Unity.2017.1.1p3\Editor\
# 2017.2.0f3          C:\Program Files\Unity.2017.2.0f3\Editor\
# 2017.3.0f3          C:\Program Files\Unity.2017.3.0f3\Editor\
# 5.5.4p3             C:\Program Files (x86)\Unity.5.5.4p3\Editor\
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
# ProjectPath                                    UnityInstanceVersion
# -----------                                    --------------------
# C:\Projects\Project1\OneUnity\                 2017.2.0f3
# C:\Projects\Project1\TwoUnity\                 2017.3.0f3
# C:\Projects\Project2\                          2017.1.1p1
# C:\Projects\Project3\App.Unity\                2017.1.2f1
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
# ComponentType Version       Length LastModified        DownloadUrl
#  ------------- -------       ------ ------------        -----------
#          Setup 2017.3.0f3 553688024 2017-12-18 08:15:20 https://netstorage.unity3d.com/unity/...
#  Documentation 2017.3.0f3 358911256 2017-12-18 08:18:37 https://netstorage.unity3d.com/unity/...
# StandardAssets 2017.3.0f3 189886032 2017-12-18 08:15:52 https://netstorage.unity3d.com/unity/...
#          Metro 2017.3.0f3 172298008 2017-12-18 08:17:44 https://netstorage.unity3d.com/unity/...
#     UWP_IL2CPP 2017.3.0f3 152933480 2017-12-18 08:17:55 https://netstorage.unity3d.com/unity/...
#        Android 2017.3.0f3 194240888 2017-12-18 08:16:06 https://netstorage.unity3d.com/unity/...
#            iOS 2017.3.0f3 802853872 2017-12-18 08:17:21 https://netstorage.unity3d.com/unity/...
#        AppleTV 2017.3.0f3 273433528 2017-12-18 08:16:24 https://netstorage.unity3d.com/unity/...
#       Facebook 2017.3.0f3  32131560 2017-12-18 08:16:27 https://netstorage.unity3d.com/unity/...
#          Linux 2017.3.0f3 122271984 2017-12-18 08:17:30 https://netstorage.unity3d.com/unity/...
#        Vuforia 2017.3.0f3  65677296 2017-12-18 08:18:00 https://netstorage.unity3d.com/unity/...
#          WebGL 2017.3.0f3 134133288 2017-12-18 08:18:09 https://netstorage.unity3d.com/unity/...
```

Limit what components you search for:
```powershell
Find-UnitySetupInstaller -Version 2017.3.0f3 -Components 'Setup','Documentation' | Format-Table

# Example output:
# ComponentType Version       Length LastModified        DownloadUrl
#  ------------- -------       ------ ------------        -----------
#          Setup 2017.3.0f3 553688024 2017-12-18 08:15:20 https://netstorage.unity3d.com/unity/...
#  Documentation 2017.3.0f3 358911256 2017-12-18 08:18:37 https://netstorage.unity3d.com/unity/...
```

Install UnitySetup instances:
```powershell
# Pipeline is supported, but downloads, then installs, then downloads, etc.
Find-UnitySetupInstaller -Version '2017.3.0f3' | Install-UnitySetupInstance

# This will issue all downloads together, then install each.
Install-UnitySetupInstance -Installers (Find-UnitySetupInstaller -Version '2017.3.0f3')
```


# Feedback
To file issues or suggestions, please use the [Issues](https://github.com/Microsoft/unitysetup.powershell/issues) page for this project on GitHub.


# Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit https://cla.microsoft.com.

When you submit a pull request, a CLA-bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.