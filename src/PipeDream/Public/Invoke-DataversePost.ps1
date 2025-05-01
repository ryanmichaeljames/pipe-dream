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
    
    Write-Verbose "Starting Invoke-DataversePost for URL: $Url"
    
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
        "Content-Type"     = "application/json"
        "OData-MaxVersion" = "4.0"
        "OData-Version"    = "4.0"
        "Prefer"           = "return=representation" # Request the created entity to be returned
    }
    
    # Merge with any additional headers provided
    foreach ($key in $Headers.Keys) {
        $authHeaders[$key] = $Headers[$key]
    }

    # Convert the body to JSON
    $jsonBody = $Body | ConvertTo-Json -Depth 20 -Compress
    Write-Verbose "Request body: $jsonBody"

    try {
        Write-Verbose "Sending POST request to: $requestUrl"
        
        # Use Invoke-WebRequest instead of Invoke-RestMethod to get the full response
        $response = Invoke-WebRequest -Uri $requestUrl -Method Post -Headers $authHeaders -Body $jsonBody -ErrorAction Stop
        
        # Check if we have content to parse
        if ($response.Content -and $response.Content.Length -gt 0) {
            try {
                $content = $response.Content | ConvertFrom-Json
                return [PSCustomObject]@{
                    StatusCode = $response.StatusCode
                    Headers    = $response.Headers
                    Content    = $content
                    RawContent = $response.Content
                    Success    = $true
                }
            }
            catch {
                # Return raw content if not JSON
                return [PSCustomObject]@{
                    StatusCode = $response.StatusCode
                    Headers    = $response.Headers
                    Content    = $null
                    RawContent = $response.Content
                    Success    = $true
                }
            }
        }
        else {
            # For POST, even with no content, we still have useful headers (OData-EntityId)
            return [PSCustomObject]@{
                StatusCode = $response.StatusCode
                Headers    = $response.Headers
                Success    = $true
            }
        }
    }
    catch {
        # Simple error handling - return the error as part of the response object
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            
            try {
                # Try to get response content
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                $reader.BaseStream.Position = 0
                $reader.DiscardBufferedData()
                $responseContent = $reader.ReadToEnd()
                
                # Try to parse as JSON
                try {
                    $content = $responseContent | ConvertFrom-Json
                }
                catch {
                    $content = $responseContent
                }
                
                return [PSCustomObject]@{
                    StatusCode = $statusCode
                    Content    = $content
                    RawContent = $responseContent
                    Error      = $_.Exception.Message
                    Success    = $false
                }
            }
            catch {
                # If we can't get response content
                return [PSCustomObject]@{
                    StatusCode = $statusCode
                    Error      = $_.Exception.Message
                    Success    = $false
                }
            }
        }
        else {
            # For non-HTTP errors
            return [PSCustomObject]@{
                Error   = $_.Exception.Message
                Success = $false
            }
        }
    }
}
