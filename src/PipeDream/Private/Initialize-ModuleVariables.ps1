function Initialize-ModuleVariables {
    <#
    .SYNOPSIS
        Initializes module-level variables needed by the PipeDream module.
    
    .DESCRIPTION
        Sets up module-level variables such as the token cache that are used
        across multiple functions in the PipeDream module.
    
    .EXAMPLE
        Initialize-ModuleVariables
    
    .NOTES
        This function is called automatically when the module is imported.
    #>
    [CmdletBinding()]
    param()
    
    Write-Verbose "Initializing PipeDream module variables"
    
    # Initialize token cache if it doesn't exist
    if (-not (Get-Variable -Name 'TokenCache' -Scope Script -ErrorAction SilentlyContinue)) {
        $script:TokenCache = @{}
        Write-Verbose "Initialized token cache"
    }
    
    # Initialize other module variables as needed
    
    Write-Verbose "Module variables initialized successfully"
}

# Call the initialization function when the script is loaded
Initialize-ModuleVariables