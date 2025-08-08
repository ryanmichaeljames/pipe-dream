function Invoke-DataverseDelete {
    <#
    .SYNOPSIS
        Performs a DELETE request to the Dataverse API.
    .DESCRIPTION
        The Invoke-DataverseDelete function makes a DELETE request to the Dataverse API using a provided
        authentication token and returns the complete HTTP response including status code, headers and content.
    .PARAMETER AccessToken
        The authentication token string (access token) obtained from Get-DataverseAuthToken.    .PARAMETER Url
        Optional. The base URL of the Power Platform environment. For example: https://myorg.crm.dynamics.com
        If not provided, the function will try to extract it from the AccessToken.
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

        [Parameter(Mandatory = $false)]
        [string]$Url,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Query,

        [Parameter(Mandatory = $false)]
        [hashtable]$Headers = @{}
    )
    
    # If URL is not provided, try to extract it from the access token
    if ([string]::IsNullOrEmpty($Url)) {
        Write-Verbose "Url not provided. Attempting to extract from the access token."
        $extractedUrl = Get-UrlFromAccessToken -AccessToken $AccessToken
        
        if ($extractedUrl) {
            $Url = $extractedUrl
        }
        else {
            throw "Could not extract URL from the access token."
        }
    }
    
    if ([string]::IsNullOrEmpty($Url)) {
        throw "URL is required. Either provide it as a parameter or use an access token that contains an 'aud' claim."
    }
    
    Write-Verbose "Starting Invoke-DataverseDelete for URL: $Url"
    
    # Normalize URL (remove trailing slash if present)
    if ($Url.EndsWith("/")) {
        $Url = $Url.TrimEnd("/")
        Write-Verbose "Normalized URL: $Url"
    }
    
    # Ensure the query starts with a '/'
    if (-not $Query.StartsWith("/")) {
        $Query = "/$Query"
        Write-Verbose "Normalized Query: $Query"
    }
    
    # Construct the full request URL
    $requestUrl = "$Url$Query"
    Write-Verbose "Full request URL: $requestUrl"
    
    # Prepare headers with authentication
    $authHeaders = @{
        "Authorization"    = "Bearer $AccessToken"
        "Accept"           = "application/json"
        "OData-MaxVersion" = "4.0"
        "OData-Version"    = "4.0"
    }
    
    # Merge with any additional headers provided
    foreach ($key in $Headers.Keys) {
        $authHeaders[$key] = $Headers[$key]
    }

    try {
        Write-Verbose "Sending DELETE request to: $requestUrl"
        
        # Use Invoke-WebRequest instead of Invoke-RestMethod to get the full response
        $response = Invoke-WebRequest -Uri $requestUrl -Method Delete -Headers $authHeaders -ErrorAction Stop
        
        # DELETE typically returns 204 No Content with no content body
        return [PSCustomObject]@{
            StatusCode = $response.StatusCode
            Headers    = $response.Headers
            Success    = $true
        }
    }
    catch {
        # Normalize HTTP vs non-HTTP errors without relying on specific exception types
        $statusCode = $null
        try { if ($_.Exception.Response) { $statusCode = $_.Exception.Response.StatusCode.value__ } } catch {}

        # Get response content from ErrorDetails if available
        $responseContent = ""
        if ($_.ErrorDetails) {
            $responseContent = $_.ErrorDetails.Message
        }

        if ($statusCode) {
            # Try to parse as JSON
            try { $content = $responseContent | ConvertFrom-Json } catch { $content = $responseContent }

            return [PSCustomObject]@{
                StatusCode = $statusCode
                Content    = $content
                RawContent = $responseContent
                Error      = $_.Exception.Message
                Success    = $false
            }
        }
        else {
            return [PSCustomObject]@{
                Error   = $_.Exception.Message
                Success = $false
            }
        }
    }
}
