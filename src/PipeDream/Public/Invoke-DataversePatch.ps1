function Invoke-DataversePatch {
    <#
    .SYNOPSIS
        Performs a PATCH request to the Dataverse API.
    .DESCRIPTION
        The Invoke-DataversePatch function makes a PATCH request to the Dataverse API using a provided
        authentication token and returns the complete HTTP response including status code, headers and content.
        PATCH is used for updating existing records in Dataverse.
    .PARAMETER AccessToken
        The authentication token string (access token) obtained from Get-DataverseAuthToken.
    .PARAMETER Url
        Required. The base URL of the Power Platform environment. For example: https://myorg.crm.dynamics.com
    .PARAMETER Query
        The OData query to append to the base URL. Should start with a forward slash.
        For example: /api/data/v9.2/accounts(00000000-0000-0000-0000-000000000000)
    .PARAMETER Body
        The request body as a hashtable or PSObject that will be converted to JSON.
        This contains the fields to update on the record.
    .PARAMETER Headers
        Optional. Additional headers to include in the request.
    .EXAMPLE
        $authResult = Get-DataverseAuthToken -TenantId "00000000-0000-0000-0000-000000000000" -Url "https://myorg.crm.dynamics.com" -ClientId "00000000-0000-0000-0000-000000000000" -ClientSecret "mySecret"
        $body = @{
            name = "Updated Account Name"
            telephone1 = "555-123-4567"
        }
    $result = Invoke-DataversePatch -AccessToken $authResult.AccessToken -Url "https://myorg.crm.dynamics.com" -Query "/api/data/v9.2/accounts(00000000-0000-0000-0000-000000000000)" -Body $body

        # The result object will contain:
        # - StatusCode: HTTP status code of the response
        # - Headers: Response headers
        # - Success: Boolean indicating if the request was successful
        # - Error: Error message (only if Success is $false)
    .NOTES
        This function accepts an access token directly. Token expiration must be handled by the caller.
        The function returns the complete HTTP response with simple error handling.
        PATCH operations typically return 204 No Content on success with no response body.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$AccessToken,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Url,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Query,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [object]$Body,

        [Parameter(Mandatory = $false)]
        [hashtable]$Headers = @{},

        [Parameter(Mandatory = $false)]
        [int]$TimeoutSec
    )

    Write-Verbose "Starting Invoke-DataversePatch for URL: $Url"
    
    $response = Invoke-DataverseHttp -Method PATCH -AccessToken $AccessToken -Url $Url -Query $Query -Body $Body -Headers $Headers -TimeoutSec $TimeoutSec
    return $response
}
