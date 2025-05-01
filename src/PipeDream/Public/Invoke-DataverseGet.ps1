function Invoke-DataverseGet {
    <#
    .SYNOPSIS
        Performs a GET request to the Dataverse API.
    .DESCRIPTION
        The Invoke-DataverseGet function makes a GET request to the Dataverse API using a provided
        authentication token and returns the complete HTTP response including status code, headers and content.
    .PARAMETER AccessToken
        The authentication token string (access token) obtained from Get-DataverseAuthToken.
    .PARAMETER Url
        The base URL of the Power Platform environment. For example: https://myorg.crm.dynamics.com
    .PARAMETER Query
        The OData query to append to the base URL. Should start with a forward slash.
        For example: /api/data/v9.2/accounts
    .PARAMETER Headers
        Optional. Additional headers to include in the request.
    .EXAMPLE
        $authResult = Get-DataverseAuthToken -TenantId "00000000-0000-0000-0000-000000000000" -Url "https://myorg.crm.dynamics.com" -ClientId "00000000-0000-0000-0000-000000000000" -ClientSecret "mySecret"
        $result = Invoke-DataverseGet -AccessToken $authResult.AccessToken -Url "https://myorg.crm.dynamics.com" -Query "/api/data/v9.2/accounts"
        
        # The result object will contain:
        # - StatusCode: HTTP status code of the response
        # - Headers: Response headers
        # - Content: Parsed response content (if JSON)
        # - RawContent: Raw response content string
        # - Success: Boolean indicating if the request was successful
        # - Error: Error message (only if Success is $false)
    .NOTES
        This function accepts an access token directly. Token expiration must be handled by the caller.
        The function returns the complete HTTP response with simple error handling.
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
        [hashtable]$Headers = @{}
    )
    
    Write-Verbose "Starting Invoke-DataverseGet for URL: $Url"
    
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
    Write-Verbose "Full request URL: $requestUrl"    # Prepare headers with authentication
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
        Write-Verbose "Sending GET request to: $requestUrl"
        
        # Use Invoke-WebRequest instead of Invoke-RestMethod to get the full response
        $response = Invoke-WebRequest -Uri $requestUrl -Method Get -Headers $authHeaders -ErrorAction Stop
        
        # Parse and return the response content
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
                Content    = $response.Content
                RawContent = $response.Content
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
