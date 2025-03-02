@{
    # Module manifest for module 'PipeDream'
    RootModule = 'PipeDream.psm1'
    ModuleVersion = '0.0.1'
    GUID = '63075401-baaa-4011-b646-6bde9e6e1a8b'
    Author = 'Ryan James'
    CompanyName = 'ryanjames.dev'
    Copyright = 'Copyright (c) 2025 Ryan James'
    Description = 'A collection of tools that make interaction with the Dataverse web API by PowerShell easier.'
    FunctionsToExport = @('*')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Prerelease = 'alpha'
            Tags = 'PowerShell', 'Power Platform', 'Dataverse'
            LicenseUri = 'https://github.com/ryanmichaeljames/pipe-dream/blob/main/LICENSE.md'
            ProjectUri = 'https://github.com/ryanmichaeljames/pipe-dream'
            IconUri = 'https://www.ryanjames.dev/assets/img/pipe-dream-logo.png'
        }
    }
}