@{
    # Module manifest for module 'PipeDream'
    RootModule = 'PipeDream.psm1'
    ModuleVersion = '1.0.0'
    GUID = '63075401-baaa-4011-b646-6bde9e6e1a8b'
    Author = 'Ryan James'
    CompanyName = 'ryanjames.dev'
    Copyright = 'Copyright (c) 2025 Ryan James'
    Description = 'Tools for easier interaction with Power Platform, Azure DevOps, and PowerShell.'
    FunctionsToExport = @('Get-DataverseAuthToken')
    PrivateData = @{
        PSData = @{
            Tags = 'PowerShell', 'PowerPlatform', 'Dataverse', 'AzureDevOps', 'DevOps'
            LicenseUri = 'https://github.com/ryanmichaeljames/pipe-dream/v1.0.0/main/LICENSE.md'
            ProjectUri = 'https://github.com/ryanmichaeljames/pipe-dream'
            IconUri = 'https://www.ryanjames.dev/assets/img/pipe-dream-logo.png'
            ReleaseNotes = '[CHANGELOG](https://github.com/ryanmichaeljames/pipe-dream/v1.0.0/main/CHANGELOG.md)'
        }
    }
}
