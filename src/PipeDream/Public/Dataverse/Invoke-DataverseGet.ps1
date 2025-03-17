function Invoke-DataverseGet {
    <#
    .SYNOPSIS
        Performs GET requests against Dataverse Web API.
    
    .DESCRIPTION
        The Invoke-DataverseGet function sends a GET request to the Dataverse Web API
        and returns the deserialized response. It handles authentication, request formation,
        and error handling.
    
    .PARAMETER EnvironmentUrl
        The URL of the Power Platform environment.
    
    .PARAMETER RelativeUrl
        The API endpoint relative to the environment URL.
    
    .PARAMETER Token
        The authentication token object from Get-DataverseAuthToken.
    
    .PARAMETER Headers
        Additional headers to include in the request.
    
    .EXAMPLE
        $accounts = Invoke-DataverseGet -EnvironmentUrl "https://myorg.crm.dynamics.com" -RelativeUrl "/api/data/v9.2/accounts" -Token $token
    
    .EXAMPLE
        $account = Invoke-DataverseGet -EnvironmentUrl "https://myorg.crm.dynamics.com" -RelativeUrl "/api/data/v9.2/accounts(00000000-0000-0000-0000-000000000000)" -Token $token
    
    .EXAMPLE
        # Retrieve records with query options
        $topAccounts = Invoke-DataverseGet -EnvironmentUrl "https://myorg.crm.dynamics.com" -RelativeUrl "/api/data/v9.2/accounts?$select=name,revenue&$top=10&$orderby=revenue desc" -Token $token
    
    .NOTES
        This function leverages the Invoke-DataverseRequest helper function to handle the actual request.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentUrl,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RelativeUrl,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSCustomObject]$Token,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Headers = @{}
    )
    
    Write-Verbose "Starting Invoke-DataverseGet for: $RelativeUrl"
    
    # Use the common request handler to perform the request
    $response = Invoke-DataverseRequest -EnvironmentUrl $EnvironmentUrl `
                                       -RelativeUrl $RelativeUrl `
                                       -Token $Token `
                                       -Method "GET" `
                                       -Headers $Headers
    
    # Return the response (already deserialized by Invoke-RestMethod in Invoke-DataverseRequest)
    return $response
}