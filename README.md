# Unity Setup Powershell Module

This PowerShell module contains cmdlets to query installed instances of Unity3D and easily launch the Unity Editor for the correct instances for Unity projects.

## Installation

```powershell
PS C:\> Install-Module UnitySetup -Scope CurrentUser
```

## Using

```powershell
PS C:\> Get-UnitySetupInstance
```

```powershell
PS C:\> Get-UnitySetupInstance | Select-UnitySetupInstance -Latest
PS C:\> Get-UnitySetupInstance | Select-UnitySetupInstance -Version '2017.1.1f1'
PS C:\> Get-UnitySetupInstance | Select-UnitySetupInstance -Project '.\MyUnityProject'
```

```powershell
PS C:\MyUnityProject> Start-UnityEditor
```

# Feedback
To file issues or suggestions, please use the [Issues](https://github.com/Microsoft/unitysetup.powershell/issues) page for this project on GitHub.


# Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit https://cla.microsoft.com.

When you submit a pull request, a CLA-bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.