function Invoke-DataverseRequest {
    <#
    .SYNOPSIS
        Internal helper function that handles common request formation and processing for Dataverse API calls.
    
    .DESCRIPTION
        Standardizes request handling for Dataverse API calls, including proper header formation,
        token validation, error handling, and response processing.
    
    .PARAMETER EnvironmentUrl
        The URL of the Power Platform environment.
    
    .PARAMETER RelativeUrl
        The API endpoint relative to the environment URL.
    
    .PARAMETER Token
        The authentication token object from Get-DataverseAuthToken.
    
    .PARAMETER Method
        The HTTP method to use (GET, POST, PATCH, DELETE).
    
    .PARAMETER Body
        The request body to send (for POST/PATCH requests).
    
    .PARAMETER Headers
        Additional headers to include in the request.
    
    .PARAMETER ContentType
        The content type for the request, defaults to "application/json".
    
    .EXAMPLE
        $response = Invoke-DataverseRequest -EnvironmentUrl "https://myorg.crm.dynamics.com" -RelativeUrl "/api/data/v9.2/accounts" -Token $token -Method "GET"
    
    .NOTES
        This is an internal helper function not exported by the module.
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
        [ValidateSet("GET", "POST", "PATCH", "DELETE")]
        [string]$Method,
        
        [Parameter(Mandatory = $false)]
        [object]$Body = $null,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Headers = @{},
        
        [Parameter(Mandatory = $false)]
        [string]$ContentType = "application/json"
    )
    
    Write-Verbose "Starting Dataverse API request: $Method $RelativeUrl"
    
    # Validate token
    if (-not (Test-DataverseToken -Token $Token)) {
        throw [PSCustomObject]@{
            ErrorCode = "AuthenticationError"
            Message   = "Authentication token is invalid or expired"
            Details   = "Please obtain a new token using Get-DataverseAuthToken"
            RequestId = ""
        }
    }
    
    # Normalize environment URL
    if ($EnvironmentUrl.EndsWith("/")) {
        $EnvironmentUrl = $EnvironmentUrl.TrimEnd("/")
    }
    
    # Ensure relative URL starts with a slash
    if (-not $RelativeUrl.StartsWith("/")) {
        $RelativeUrl = "/$RelativeUrl"
    }
    
    # Construct full URL
    $fullUrl = "$EnvironmentUrl$RelativeUrl"
    Write-Verbose "Request URL: $fullUrl"
    
    # Prepare request headers
    $requestHeaders = @{
        "Authorization" = "$($Token.TokenType) $($Token.AccessToken)"
        "Accept"        = "application/json"
        "OData-MaxVersion" = "4.0"
        "OData-Version" = "4.0"
    }
    
    # Add additional headers
    foreach ($key in $Headers.Keys) {
        $requestHeaders[$key] = $Headers[$key]
    }
    
    # Create parameters for Invoke-RestMethod
    $params = @{
        Uri             = $fullUrl
        Method          = $Method
        Headers         = $requestHeaders
        ErrorAction     = "Stop"
    }
    
    # Add body for POST/PATCH operations
    if ($Body -and ($Method -eq "POST" -or $Method -eq "PATCH")) {
        $params.Add("ContentType", $ContentType)
        
        # Convert hashtable/custom object to JSON if content type is application/json
        if ($ContentType -eq "application/json" -and $Body -isnot [string]) {
            $params.Add("Body", (ConvertTo-Json -InputObject $Body -Depth 10))
            Write-Verbose "Request body: $(ConvertTo-Json -InputObject $Body -Depth 3 -Compress)"
        }
        else {
            $params.Add("Body", $Body)
            Write-Verbose "Request has body with content type: $ContentType"
        }
    }
    
    try {
        # Execute the request
        $startTime = Get-Date
        $response = Invoke-RestMethod @params
        $duration = (Get-Date) - $startTime
        
        Write-Verbose "Request completed in $($duration.TotalMilliseconds)ms"
        return $response
    }
    catch {
        $errorRecord = $_
        $statusCode = $null
        $errorData = $null
        $responseBody = $null
        
        # Extract status code if available
        if ($errorRecord.Exception.Response) {
            $statusCode = [int]$errorRecord.Exception.Response.StatusCode
            
            # Try to get response body for more error details
            try {
                $responseStream = $errorRecord.Exception.Response.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($responseStream)
                $responseBody = $reader.ReadToEnd()
                $reader.Close()
                
                if ($responseBody) {
                    $errorData = ConvertFrom-Json $responseBody -ErrorAction SilentlyContinue
                }
            }
            catch {
                Write-Verbose "Could not read error response body: $($_.Exception.Message)"
            }
        }
        
        # Construct standardized error object
        $errorDetails = @{
            ErrorCode = if ($statusCode) { $statusCode } else { "RequestError" }
            Message   = "Dataverse API request failed"
            Details   = $errorRecord.Exception.Message
            RequestId = ""
        }
        
        # Add more context from the error response if available
        if ($errorData) {
            if ($errorData.error) {
                $errorDetails.ErrorCode = if ($errorData.error.code) { $errorData.error.code } else { $errorDetails.ErrorCode }
                $errorDetails.Message = if ($errorData.error.message) { $errorData.error.message } else { $errorDetails.Message }
                
                # Some Dataverse errors include a requestid
                if ($errorData.error.innererror -and $errorData.error.innererror.requestid) {
                    $errorDetails.RequestId = $errorData.error.innererror.requestid
                }
            }
        }
        
        Write-Error "Dataverse API Error: [$($errorDetails.ErrorCode)] $($errorDetails.Message)"
        throw [PSCustomObject]$errorDetails
    }
}