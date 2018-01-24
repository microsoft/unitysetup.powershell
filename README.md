# Unity Setup Powershell Module

This PowerShell module contains tools for managing and automating your Unity installs and projects.

## Builds
[![Build status](https://ci.appveyor.com/api/projects/status/m7ykg9s8gw23fn6h?svg=true)](https://ci.appveyor.com/project/jwittner/unitysetup-powershell)

The `master` branch is automatically built and deployed to the [PowerShell Gallery](https://www.powershellgallery.com/packages/UnitySetup).


## Installation

```powershell
PS C:\> Install-Module UnitySetup -Scope CurrentUser
```

## Using

Find all of your Unity installs:
```powershell
PS C:\> Get-UnitySetupInstance

InstallationVersion InstallationPath
------------------- ----------------
2017.2.1f1          C:\Program Files\Unity-2017.2.1f1\Editor\
2017.1.0p5          C:\Program Files\Unity.2017.1.0p5\Editor\
2017.1.1f1          C:\Program Files\Unity.2017.1.1f1\Editor\
2017.1.1p3          C:\Program Files\Unity.2017.1.1p3\Editor\
2017.2.0f3          C:\Program Files\Unity.2017.2.0f3\Editor\
2017.3.0f3          C:\Program Files\Unity.2017.3.0f3\Editor\
5.5.4p3             C:\Program Files (x86)\Unity.5.5.4p3\Editor\
```

Select the Unity installs that you want:
```powershell
PS C:\> Get-UnitySetupInstance | Select-UnitySetupInstance -Latest
PS C:\> Get-UnitySetupInstance | Select-UnitySetupInstance -Version '2017.1.1f1'
PS C:\> Get-UnitySetupInstance | Select-UnitySetupInstance -Project '.\MyUnityProject'
```

Launch the right Unity editor for a project:
```powershell
PS C:\MyUnityProject> Start-UnityEditor
PS C:\> Start-UnityEditor -Project .\MyUnityProject
```

Find all the Unity projects recursively
```powershell
PS C:\Projects> Get-UnityProjectInstance -Recurse

ProjectPath                                    UnityInstanceVersion
-----------                                    --------------------
C:\Projects\Project1\OneUnity\                 2017.2.0f3
C:\Projects\Project1\TwoUnity\                 2017.3.0f3
C:\Projects\Project2\                          2017.1.1p1
C:\Projects\Project3\App.Unity\                2017.1.2f1
```

# Feedback
To file issues or suggestions, please use the [Issues](https://github.com/Microsoft/unitysetup.powershell/issues) page for this project on GitHub.


# Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit https://cla.microsoft.com.

When you submit a pull request, a CLA-bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.