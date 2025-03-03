function Invoke-DataverseBatchRequest {
    <#
    .SYNOPSIS
    Executes a batch operation against the Dataverse Web API.

    .DESCRIPTION
    This function sends batch requests to the Dataverse Web API using the provided authentication token.
    It allows grouping multiple operations into a single HTTP request, which can improve performance
    and enable transactional operations when changesets are used.

    .PARAMETER Token
    The authentication token object obtained from Get-DataverseAuthToken.
    This object must contain access_token, token_type, expires_in, expires_at, and resource properties.

    .PARAMETER Requests
    An array of request objects. Each request should have the following properties:
    - Method: The HTTP method (GET, POST, PATCH, DELETE, PUT)
    - Path: The relative path for the request
    - Body: The request body (for POST, PATCH, PUT operations)
    - Headers: Additional headers for the request (optional)
    - ContentId: Content ID for referencing within changesets (optional)

    .PARAMETER UseChangeset
    When specified, all requests are included in a single changeset, making them transactional.
    All operations will succeed or fail together.

    .PARAMETER ContinueOnError
    When specified, batch execution will continue even if individual requests fail.

    .OUTPUTS
    System.String containing the raw response from the Dataverse batch operation.
    The response contains individual results for each request in the batch.

    .EXAMPLE
    # Create a batch that updates a record and retrieves it in a single operation
    # Update an account
    $request1 = New-DataverseBatchRequest `
        -Method "PUT" `
        -Path "/api/data/v9.2/accounts(00000000-0000-0000-0000-000000000000)" `
        -Body @{ name = "Evil Corp" }

    # Get the account
    $request2 = New-DataverseBatchRequest `
        -Method "GET" `
        -Path "/api/data/v9.2/accounts(00000000-0000-0000-0000-000000000000)"

    # Use the requests in a batch operation
    Invoke-DataverseBatchRequest -Token "AUTH_TOKEN" -Requests @($request1, $request2)

    .EXAMPLE
    # Create a changeset that references the result of the first request in subsequent requests
    # Create an account
    $request1 = New-DataverseBatchRequest `
        -Method "POST" `
        -Path "/api/data/v9.2/accounts" `
        -Body @{ name = "Evil Corp" } `
        -ContentId "1"

    # Create a contact and links it to the newly created account using $1 reference syntax
    $request2 = New-DataverseBatchRequest `
        -Method "POST" `
        -Path "/api/data/v9.2/contacts" `
        -Body @{
            firstname = "Phillip"
            "parentcustomerid_account@odata.bind" = "$1"  # References the account created in request with ContentId "1"
        }

    # Use the requests in a batch operation with changeset enabled
    Invoke-DataverseBatchRequest -Token "AUTH_TOKEN" -Requests @($request1, $request2) -UseChangeset

    .EXAMPLE
    # Create requests using hash tables directly
    $requests = @(
        @{
            Method = "GET"
            Path = "/api/data/v9.2/accounts"
        },
        @{
            Method = "GET"
            Path = "/api/data/v9.2/contacts"
        }
    )
    
    Invoke-DataverseBatchRequest -Token "AUTH_TOKEN" -Requests $requests
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [PSCustomObject]$Token,

        [Parameter(Mandatory = $true, Position = 1)]
        [array]$Requests,

        [Parameter(Mandatory = $false)]
        [switch]$UseChangeset,

        [Parameter(Mandatory = $false)]
        [switch]$ContinueOnError
    )

    begin {
        $startTime = Get-Date
        Write-Verbose "[$($startTime.ToString('yyyy-MM-dd HH:mm:ss'))] Starting batch request execution."
        Write-Verbose "Number of requests to process: $($Requests.Count)"
        
        if ($UseChangeset) {
            Write-Verbose "Requests will be processed as a single transaction using changeset."
        }
        if ($ContinueOnError) {
            Write-Verbose "Batch will continue processing even if individual requests fail."
        }

        # Extract base URL from the token's resource
        $baseUrl = $Token.resource
        Write-Verbose "Base URL: $baseUrl"
        
        # Create a boundary for the multipart request
        $batchBoundary = "batch_" + [Guid]::NewGuid().ToString()
        $changesetBoundary = "changeset_" + [Guid]::NewGuid().ToString()
        Write-Verbose "Batch boundary: $batchBoundary"
        Write-Verbose "Changeset boundary: $changesetBoundary"
        
        # Create request headers with the proper authorization format from token properties
        $headers = @{
            "Authorization"    = "$($Token.token_type) $($Token.access_token)"
            "OData-MaxVersion" = "4.0"
            "OData-Version"    = "4.0"
            "If-None-Match"    = "null"
            "Accept"           = "application/json"
            "Content-Type"     = "multipart/mixed; boundary=""$batchBoundary"""
        }
        
        if ($ContinueOnError) {
            $headers["Prefer"] = "odata.continue-on-error"
            Write-Verbose "Added continue-on-error preference header."
        }
    }

    process {
        Write-Verbose "Building batch request body..."
        # Initialize the body as a list of strings to ensure proper line endings
        $bodyLines = New-Object System.Collections.ArrayList
        
        # If using changeset, wrap all requests in a changeset
        if ($UseChangeset) {
            Write-Verbose "Adding changeset wrapper for transactional processing."
            [void]$bodyLines.Add("--$batchBoundary")
            [void]$bodyLines.Add("Content-Type: multipart/mixed; boundary=""$changesetBoundary""")
            [void]$bodyLines.Add("")
        }

        # Process each request
        for ($i = 0; $i -lt $Requests.Count; $i++) {
            $request = $Requests[$i]
            Write-Verbose "Processing request $($i+1) of $($Requests.Count): $($request.Method) $($request.Path)"
            
            if ($UseChangeset) {
                [void]$bodyLines.Add("--$changesetBoundary")
            } 
            else {
                [void]$bodyLines.Add("--$batchBoundary")
            }
            
            [void]$bodyLines.Add("Content-Type: application/http")
            [void]$bodyLines.Add("Content-Transfer-Encoding: binary")
            
            if ($UseChangeset -and $request.ContentId) {
                [void]$bodyLines.Add("Content-ID: $($request.ContentId)")
                Write-Verbose "Added Content-ID: $($request.ContentId) for referencing within changeset."
            }
            
            [void]$bodyLines.Add("")
            
            # Add the request method and path - no Host header needed per OData spec
            [void]$bodyLines.Add("$($request.Method) $($request.Path) HTTP/1.1")
            
            # Add additional headers if specified in the request
            if ($request.Headers -and $request.Headers.Count -gt 0) {
                Write-Verbose "Adding custom headers for request $($i+1)."
                foreach ($headerKey in $request.Headers.Keys) {
                    [void]$bodyLines.Add("$($headerKey): $($request.Headers[$headerKey])")
                }
            }
            
            # Add content type for requests with bodies
            if ($request.Body) {
                [void]$bodyLines.Add("Content-Type: application/json; type=entry")
                [void]$bodyLines.Add("")
                
                # Convert body to JSON if it's not already a string
                if ($request.Body -is [string]) {
                    [void]$bodyLines.Add($request.Body)
                    Write-Verbose "Added string body content for request $($i+1)."
                }
                else {
                    $bodyJson = $request.Body | ConvertTo-Json -Depth 10
                    [void]$bodyLines.Add($bodyJson)
                    Write-Verbose "Converted object body to JSON for request $($i+1)."
                }
            }
            
            [void]$bodyLines.Add("")
        }
        
        # Close the changeset if used
        if ($UseChangeset) {
            [void]$bodyLines.Add("--$changesetBoundary--")
            Write-Verbose "Closed changeset boundary."
        }
        
        # Close the batch
        [void]$bodyLines.Add("--$batchBoundary--")
        [void]$bodyLines.Add("")  # Final empty line required for proper parsing
        
        # Join lines with CRLF as required by HTTP protocol
        $batchBodyContent = [String]::Join("`r`n", [string[]]$bodyLines)
        
        # Execute the batch request
        try {
            $fullUrl = "$baseUrl/api/data/v9.2/`$batch"
            Write-Verbose "Sending batch request to: $fullUrl"
            Write-Verbose "Batch request body size: $(($batchBodyContent.Length / 1KB).ToString('0.00')) KB"
            
            $params = @{
                Method      = "POST"
                Uri         = $fullUrl
                Headers     = $headers
                Body        = $batchBodyContent
                ContentType = "multipart/mixed; boundary=$batchBoundary"
            }
            
            # Calculate request start time
            $requestStartTime = Get-Date
            Write-Verbose "Executing batch request at $($requestStartTime.ToString('HH:mm:ss.fff'))..."
            
            # Make the request
            $response = Invoke-WebRequest @params -ErrorAction Stop
            
            # Calculate request duration
            $requestEndTime = Get-Date
            $requestDuration = $requestEndTime - $requestStartTime
            Write-Verbose "Batch request completed in $($requestDuration.TotalSeconds.ToString('0.000')) seconds."
            Write-Verbose "Response status: $($response.StatusCode) $($response.StatusDescription)"
            
            # Convert response content from byte array to string
            $responseContent = [System.Text.Encoding]::UTF8.GetString($response.Content)
            Write-Verbose "Response content size: $(($responseContent.Length / 1KB).ToString('0.00')) KB"

            return $responseContent
        }
        catch {
            throw
        }
    }

    end {
        $endTime = Get-Date
        $totalDuration = $endTime - $startTime
        Write-Verbose "[$($endTime.ToString('yyyy-MM-dd HH:mm:ss'))] Batch request operation completed."
        Write-Verbose "Total execution time: $($totalDuration.TotalSeconds.ToString('0.000')) seconds."
    }
}

Export-ModuleMember -Function @('Invoke-DataverseBatchRequest')