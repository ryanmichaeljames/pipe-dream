function Invoke-DataverseGet {
    <#
    .SYNOPSIS
        Performs a GET request to the Dataverse API.
    .DESCRIPTION
        The Invoke-DataverseGet function makes a GET request to the Dataverse API using a provided
        authentication token and returns the complete HTTP response including status code, headers and content.
        
        If the Url parameter is not provided, the function will attempt to extract the audience (aud) claim
        from the access token and use it as the URL.
    .PARAMETER AccessToken
        The authentication token string (access token) obtained from Get-DataverseAuthToken.
    .PARAMETER Url
        Optional. The base URL of the Power Platform environment. For example: https://myorg.crm.dynamics.com
        If not provided, the function will try to extract it from the AccessToken.
    .PARAMETER Query
        The OData query to append to the base URL. Should start with a forward slash.
        For example: /api/data/v9.2/accounts
    .PARAMETER Headers
        Optional. Additional headers to include in the request.
    .EXAMPLE
        $authResult = Get-DataverseAuthToken -TenantId "00000000-0000-0000-0000-000000000000" -Url "https://myorg.crm.dynamics.com" -ClientId "00000000-0000-0000-0000-000000000000" -ClientSecret "mySecret"
        $result = Invoke-DataverseGet -AccessToken $authResult.AccessToken -Query "/api/data/v9.2/accounts"
        
        # The result object will contain:
        # - StatusCode: HTTP status code of the response
        # - Headers: Response headers
        # - Content: Parsed response content (if JSON)
        # - RawContent: Raw response content string
        # - Success: Boolean indicating if the request was successful
        # - Error: Error message (only if Success is $false)
    .EXAMPLE
        $authResult = Get-DataverseAuthToken -TenantId "00000000-0000-0000-0000-000000000000" -Url "https://myorg.crm.dynamics.com" -ClientId "00000000-0000-0000-0000-000000000000" -ClientSecret "mySecret"
        $result = Invoke-DataverseGet -AccessToken $authResult.AccessToken -Url "https://myorg.crm.dynamics.com" -Query "/api/data/v9.2/accounts"
    .NOTES
        This function accepts an access token directly. Token expiration must be handled by the caller.
        The function returns the complete HTTP response with simple error handling.
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

        [Parameter(Mandatory = $false)]
        [hashtable]$Headers = @{},

        [Parameter(Mandatory = $false)]
        [int]$TimeoutSec
    )
    Write-Verbose "Starting Invoke-DataverseGet for URL: $Url"
    # Delegate to the HTTP core which handles URL/query normalization, headers, and result shape.
    $res = Invoke-DataverseHttp -Method GET -AccessToken $AccessToken -Url $Url -Query $Query -Headers $Headers -TimeoutSec $TimeoutSec
    return $res
}
