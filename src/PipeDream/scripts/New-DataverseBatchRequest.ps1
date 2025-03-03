function New-DataverseBatchRequest {
    <#
    .SYNOPSIS
    Creates a request object for use with Invoke-DataverseBatchRequest.

    .DESCRIPTION
    This helper function creates properly formatted request objects that can be used
    in batch operations with Invoke-DataverseBatchRequest. It ensures all required
    properties are set and formatted correctly.

    .PARAMETER Method
    The HTTP method for the request (GET, POST, PATCH, DELETE, PUT).

    .PARAMETER Path
    The relative path for the request (e.g., "/api/data/v9.2/accounts").

    .PARAMETER Body
    The request body for POST, PATCH, or PUT operations.

    .PARAMETER ContentId
    Optional Content ID for referencing within changesets.

    .PARAMETER Headers
    Optional additional headers for the request.

    .OUTPUTS
    System.Collections.Hashtable containing the properly formatted request object with all specified properties.

    .EXAMPLE
    # Create POST request
    $request1 = New-DataverseBatchRequest `
        -Method "POST" `
        -Path "/api/data/v9.2/accounts" `
        -Body @{ name = "Evil Corp" } `
        -ContentId "1"

    .EXAMPLE
    # Create GET request
    $request1 = New-DataverseBatchRequest `
        -Method "GET" `
        -Path "/api/data/v9.2/accounts(00000000-0000-0000-0000-000000000000)"

    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("GET", "POST", "PATCH", "DELETE", "PUT")]
        [string]$Method,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [object]$Body,

        [Parameter(Mandatory = $false)]
        [ValidatePattern('^[a-zA-Z0-9_\-]+$')]
        [string]$ContentId,

        [Parameter(Mandatory = $false)]
        [hashtable]$Headers
    )

    begin {
        Write-Verbose "Creating Dataverse batch request with method: $Method, path: $Path"

        # Validate body is present for methods that require it
        if ($Method -in @('POST', 'PATCH', 'PUT') -and $null -eq $Body) {
            Write-Warning "Body parameter is typically required for $Method operations. Creating request without body."
        }
    }

    process {
        try {
            # Ensure path starts with a forward slash
            if (-not $Path.StartsWith("/")) {
                Write-Verbose "Path does not start with '/'. Adding prefix."
                $Path = "/$Path"
            }

            # Create the request object
            $request = @{
                Method = $Method
                Path   = $Path
            }
            Write-Verbose "Request object created with Method '$Method' and Path '$Path'"

            # Add optional properties if provided
            if ($null -ne $Body) {
                $request.Body = $Body
                Write-Verbose "Body added to request"
            }
            
            if (-not [string]::IsNullOrEmpty($ContentId)) {
                $request.ContentId = $ContentId
                Write-Verbose "ContentId '$ContentId' added to request"
            }
            
            if ($null -ne $Headers -and $Headers.Count -gt 0) {
                $request.Headers = $Headers
                Write-Verbose "Added $(($Headers).Count) custom headers to request"
            }

            return $request
        }
        catch {
            Write-Error "Failed to create batch request object: $_"
            throw "Error creating Dataverse batch request: $_"
        }
    }

    end {
        Write-Verbose "Batch request object creation completed"
    }
}

Export-ModuleMember -Function @('New-DataverseBatchRequest')