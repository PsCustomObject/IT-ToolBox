@{
    RootModule = 'IT-ToolBox.psm1'
    ModuleVersion = '3.0.0'
    GUID = '02c0c748-00ba-4e8f-b8ce-6aa7e4cefe08'
    Author = 'Daniele Catanesi - PsCustomObject'
    CompanyName = 'Community'
    Copyright = '(c) Daniele Catanesi. MIT License.'
    Description = 'Reusable infrastructure automation utilities. PowerShell 7 modernization foundation.'
    PowerShellVersion = '7.4'
    CompatiblePSEditions = @('Core')
    FunctionsToExport = @(
        'New-LogEntry'
        'New-Timer'
        'Get-TimerStatus'
        'Stop-Timer'
        'Get-ElapsedTime'
        'Test-FileName'
        'Test-IsValidPath'
        'Test-IsIP'
        'Test-IsDate'
        'New-StringEncryption'
        'New-StringDecryption'
        'New-RandomString'
        'New-RandomPassword'
        'New-PhoneticPassword'
        'New-ApiRequest'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('Infrastructure', 'Automation', 'Logging')
            LicenseUri = 'https://github.com/PsCustomObject/IT-ToolBox/blob/master/LICENSE'
            ProjectUri = 'https://github.com/PsCustomObject/IT-ToolBox'
            Prerelease = 'alpha1'
        }
    }
}
