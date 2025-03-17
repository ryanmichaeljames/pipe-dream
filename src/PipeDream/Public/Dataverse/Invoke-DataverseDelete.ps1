function Invoke-DataverseDelete {
    <#
    .SYNOPSIS
        Performs DELETE requests against Dataverse Web API.
    
    .DESCRIPTION
        The Invoke-DataverseDelete function sends a DELETE request to the Dataverse Web API
        to remove existing records. It handles authentication, request formation,
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
        Invoke-DataverseDelete -EnvironmentUrl "https://myorg.crm.dynamics.com" -RelativeUrl "/api/data/v9.2/accounts(00000000-0000-0000-0000-000000000000)" -Token $token
    
    .NOTES
        This function leverages the Invoke-DataverseRequest helper function to handle the actual request.
        Successful DELETE operations typically don't return content.
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
    
    Write-Verbose "Starting Invoke-DataverseDelete for: $RelativeUrl"
    
    # Use the common request handler to perform the request
    $response = Invoke-DataverseRequest -EnvironmentUrl $EnvironmentUrl `
                                       -RelativeUrl $RelativeUrl `
                                       -Token $Token `
                                       -Method "DELETE" `
                                       -Headers $Headers
    
    # DELETE requests typically return no content
    # Return true for success (since we'd get an exception otherwise)
    return $true
}