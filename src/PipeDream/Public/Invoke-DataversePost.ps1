function Invoke-DataversePost {
    <#
    .SYNOPSIS
        Performs a POST request to the Dataverse API.
    .DESCRIPTION
        The Invoke-DataversePost function makes a POST request to the Dataverse API using a provided
        authentication token and returns the complete HTTP response including status code, headers and content.
        POST is used for creating new records in Dataverse.
    .PARAMETER AccessToken
        The authentication token string (access token) obtained from Get-DataverseAuthToken.    .PARAMETER Url
        Optional. The base URL of the Power Platform environment. For example: https://myorg.crm.dynamics.com
        If not provided, the function will try to extract it from the AccessToken.
    .PARAMETER Query
        The OData query to append to the base URL. Should start with a forward slash.
        For example: /api/data/v9.2/accounts
    .PARAMETER Body
        The request body as a hashtable or PSObject that will be converted to JSON.
        This contains the data for the new record to be created.
    .PARAMETER Headers
        Optional. Additional headers to include in the request.
    .EXAMPLE
        $authResult = Get-DataverseAuthToken -TenantId "00000000-0000-0000-0000-000000000000" -Url "https://myorg.crm.dynamics.com" -ClientId "00000000-0000-0000-0000-000000000000" -ClientSecret "mySecret"
        $body = @{
            name = "New Account Name"
            telephone1 = "555-123-4567"
            accountcategorycode = 1
        }
    $result = Invoke-DataversePost -AccessToken $authResult.AccessToken -Url "https://myorg.crm.dynamics.com" -Query "/api/data/v9.2/accounts" -Body $body

        # The result object will contain:
        # - StatusCode: HTTP status code of the response
        # - Headers: Response headers including the OData-EntityId header with the URL of the created record
        # - Content: Parsed response content (if JSON)
        # - RawContent: Raw response content string
        # - Success: Boolean indicating if the request was successful
        # - Error: Error message (only if Success is $false)
    .NOTES
        This function accepts an access token directly. Token expiration must be handled by the caller.
        The function returns the complete HTTP response with simple error handling.
        POST operations typically return 204 No Content on success with the OData-EntityId header containing
        the URL of the newly created entity.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$AccessToken,

        [Parameter(Mandatory = $false)]
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
    Write-Verbose "Starting Invoke-DataversePost for URL: $Url"
    # Ensure default POST behavior keeps Prefer: return=representation unless caller overrides.
    # This preserves prior behavior where POST returned the created entity.
    if (-not $Headers) { $Headers = @{} }
    if (-not $Headers.ContainsKey('Prefer')) { $Headers['Prefer'] = 'return=representation' }
    $res = Invoke-DataverseHttp -Method POST -AccessToken $AccessToken -Url $Url -Query $Query -Body $Body -Headers $Headers -TimeoutSec $TimeoutSec
    return $res
}
