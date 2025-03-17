function Invoke-DataversePatch {
    <#
    .SYNOPSIS
        Performs PATCH requests against Dataverse Web API to update existing records.
    
    .DESCRIPTION
        The Invoke-DataversePatch function sends a PATCH request to the Dataverse Web API
        to update existing records. It handles authentication, request formation, body serialization,
        and error handling.
    
    .PARAMETER EnvironmentUrl
        The URL of the Power Platform environment.
    
    .PARAMETER RelativeUrl
        The API endpoint relative to the environment URL.
    
    .PARAMETER Token
        The authentication token object from Get-DataverseAuthToken.
    
    .PARAMETER Body
        The request body object containing the data to update.
        This will be automatically serialized to JSON.
    
    .PARAMETER Headers
        Additional headers to include in the request.
    
    .PARAMETER ContentType
        The content type for the request, defaults to "application/json".
    
    .EXAMPLE
        $accountUpdate = @{
            telephone1 = "555-0200"
            revenue = 15000000
        }
        Invoke-DataversePatch -EnvironmentUrl "https://myorg.crm.dynamics.com" -RelativeUrl "/api/data/v9.2/accounts(00000000-0000-0000-0000-000000000000)" -Token $token -Body $accountUpdate
    
    .NOTES
        This function leverages the Invoke-DataverseRequest helper function to handle the actual request.
        Dataverse PATCH requests typically don't return content unless specifically requested with a Prefer header.
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
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [object]$Body,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Headers = @{},
        
        [Parameter(Mandatory = $false)]
        [string]$ContentType = "application/json"
    )
    
    Write-Verbose "Starting Invoke-DataversePatch for: $RelativeUrl"
    
    # Use the common request handler to perform the request
    $response = Invoke-DataverseRequest -EnvironmentUrl $EnvironmentUrl `
                                       -RelativeUrl $RelativeUrl `
                                       -Token $Token `
                                       -Method "PATCH" `
                                       -Body $Body `
                                       -Headers $Headers `
                                       -ContentType $ContentType
    
    # By default, PATCH requests to Dataverse return no content
    # Return true for success (since we'd get an exception otherwise)
    if ($null -eq $response) {
        return $true
    }
    
    # Or return whatever response we got if a Prefer header was used
    return $response
}