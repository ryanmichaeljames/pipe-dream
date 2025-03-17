function Invoke-DataversePost {
    <#
    .SYNOPSIS
        Performs POST requests against Dataverse Web API.
    
    .DESCRIPTION
        The Invoke-DataversePost function sends a POST request to the Dataverse Web API
        to create new records. It handles authentication, request formation, body serialization,
        and error handling.
    
    .PARAMETER EnvironmentUrl
        The URL of the Power Platform environment.
    
    .PARAMETER RelativeUrl
        The API endpoint relative to the environment URL.
    
    .PARAMETER Token
        The authentication token object from Get-DataverseAuthToken.
    
    .PARAMETER Body
        The request body object containing the data to send.
        This will be automatically serialized to JSON.
    
    .PARAMETER Headers
        Additional headers to include in the request.
    
    .PARAMETER ContentType
        The content type for the request, defaults to "application/json".
    
    .EXAMPLE
        $newAccount = @{
            name = "Contoso Ltd."
            telephone1 = "555-0100"
            revenue = 10000000
        }
        $result = Invoke-DataversePost -EnvironmentUrl "https://myorg.crm.dynamics.com" -RelativeUrl "/api/data/v9.2/accounts" -Token $token -Body $newAccount
    
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
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [object]$Body,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Headers = @{},
        
        [Parameter(Mandatory = $false)]
        [string]$ContentType = "application/json"
    )
    
    Write-Verbose "Starting Invoke-DataversePost for: $RelativeUrl"
    
    # Ensure we get the entity ID from the response
    if ($Headers.Keys -notcontains "Prefer") {
        $Headers["Prefer"] = "return=representation"
    }
    
    # Use the common request handler to perform the request
    $response = Invoke-DataverseRequest -EnvironmentUrl $EnvironmentUrl `
                                       -RelativeUrl $RelativeUrl `
                                       -Token $Token `
                                       -Method "POST" `
                                       -Body $Body `
                                       -Headers $Headers `
                                       -ContentType $ContentType
    
    # Return the response
    return $response
}