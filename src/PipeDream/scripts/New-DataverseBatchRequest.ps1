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
        [string]$Method,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [object]$Body,

        [Parameter(Mandatory = $false)]
        [string]$ContentId,

        [Parameter(Mandatory = $false)]
        [hashtable]$Headers
    )

    begin {
        Write-Verbose "Creating Dataverse batch request with method: $Method, path: $Path"
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
            throw
        }
    }

    end {
        Write-Verbose "Batch request object creation completed"
    }
}

Export-ModuleMember -Function @('New-DataverseBatchRequest')