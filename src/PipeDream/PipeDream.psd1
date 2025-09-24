@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'PipeDream.psm1'
    
    # Version number of this module.
    ModuleVersion = '4.3.0'
    
    # ID used to uniquely identify this module
    GUID = '63075401-baaa-4011-b646-6bde9e6e1a8b'
    
    # Author of this module
    Author = 'Ryan James'
    
    # Company or vendor of this module
    CompanyName = 'ryanjames.dev'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Ryan James. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'A PowerShell module for facilitating deployment pipelines for Power Platform environments'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        'Get-DataverseAuthToken',
        'Invoke-DataverseGet',
        'Invoke-DataversePost',
        'Invoke-DataversePatch',
        'Invoke-DataverseDelete'
    )
    
    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = '*'
    
    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('PowerPlatform', 'Dataverse', 'Deployment', 'Pipeline')
            
            # A URL to the license for this module.
            LicenseUri = 'https://github.com/ryanmichaeljames/pipe-dream/blob/main/LICENSE'
            
            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/ryanmichaeljames/pipe-dream'
            
            # A URL to an icon representing this module.
            IconUri = 'https://raw.githubusercontent.com/ryanmichaeljames/pipe-dream/refs/heads/main/assets/logo_powershell_gallery.png'
            
            # ReleaseNotes of this module
            ReleaseNotes = 'https://github.com/ryanmichaeljames/pipe-dream/blob/main/CHANGELOG.md'

            # Prerelease label
            # Prerelease = 'alpha'
        }
    }
}