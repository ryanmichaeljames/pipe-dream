function Invoke-DataverseDelete {
    <#
    .SYNOPSIS
        Performs a DELETE request to the Dataverse API.
    .DESCRIPTION
        The Invoke-DataverseDelete function makes a DELETE request to the Dataverse API using a provided
        authentication token and returns the complete HTTP response including status code, headers and content.
    .PARAMETER AccessToken
        The authentication token string (access token) obtained from Get-DataverseAuthToken.
    .PARAMETER Url
        Required. The base URL of the Power Platform environment. For example: https://myorg.crm.dynamics.com
    .PARAMETER Query
        The OData query to append to the base URL. Should start with a forward slash.
        For example: /api/data/v9.2/accounts(00000000-0000-0000-0000-000000000000)
    .PARAMETER Headers
        Optional. Additional headers to include in the request.
    .EXAMPLE
        $authResult = Get-DataverseAuthToken -TenantId "00000000-0000-0000-0000-000000000000" -Url "https://myorg.crm.dynamics.com" -ClientId "00000000-0000-0000-0000-000000000000" -ClientSecret "mySecret"
    $result = Invoke-DataverseDelete -AccessToken $authResult.AccessToken -Url "https://myorg.crm.dynamics.com" -Query "/api/data/v9.2/accounts(00000000-0000-0000-0000-000000000000)"

        # The result object will contain:
        # - StatusCode: HTTP status code of the response
        # - Headers: Response headers (if available)
        # - Success: Boolean indicating if the request was successful
        # - Error: Error message (only if Success is $false)
    .NOTES
        This function accepts an access token directly. Token expiration must be handled by the caller.
        The function returns the complete HTTP response with simple error handling.
        DELETE operations typically do not return content on success, only a status code of 204 No Content.
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

        [Parameter(Mandatory = $false)]
        [hashtable]$Headers = @{},

        [Parameter(Mandatory = $false)]
        [int]$TimeoutSec
    )
    
    Write-Verbose "Starting Invoke-DataverseDelete for URL: $Url"
    
    $response = Invoke-DataverseHttp -Method DELETE -AccessToken $AccessToken -Url $Url -Query $Query -Headers $Headers -TimeoutSec $TimeoutSec
    return $response
}
