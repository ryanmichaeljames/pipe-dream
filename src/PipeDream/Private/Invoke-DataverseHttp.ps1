function Invoke-DataverseHttp {
    <#
    .SYNOPSIS
        Core HTTP executor for Dataverse requests.
    .DESCRIPTION
        Centralizes URL normalization, header building, request execution, and structured output.
        Does not throw for normal HTTP errors; returns a structured result contract.
    .PARAMETER Method
        HTTP method: GET, POST, PATCH, DELETE.
    .PARAMETER AccessToken
        OAuth access token string.
    .PARAMETER Url
        Base environment URL. Required; not derived from token.
    .PARAMETER Query
        Path/query beginning with '/'. Will be normalized.
    .PARAMETER Body
        Optional object. Serialized to JSON when provided; sets Content-Type to application/json if not set.
    .PARAMETER Headers
        Extra headers to merge.
    .PARAMETER TimeoutSec
        Request timeout in seconds.
    .OUTPUTS
        PSCustomObject with fields: StatusCode, Headers, Content, RawContent, Success, Error, RequestId, CorrelationId
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][ValidateSet('GET', 'POST', 'PATCH', 'DELETE')][string] $Method,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $AccessToken,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $Url,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $Query,
        [object] $Body,
        [hashtable] $Headers,
        [int] $TimeoutSec
    )

    # Normalize URL and Query
    # - Trim trailing slash from Url
    # - Ensure Query starts with '/'
    # - Build requestUrl for Invoke-WebRequest
    if ($Url.EndsWith('/')) {
        $Url = $Url.TrimEnd('/')
    }

    if (-not $Query.StartsWith('/')) {
        $Query = "/$Query"
    }

    $requestUrl = "$Url$Query"

    # Auto content-type if sending a body and not provided by headers
    # Default to application/json for body scenarios unless explicitly overridden by caller headers.
    $contentType = $null
    if ($null -ne $Body) {
        $contentType = 'application/json'
    }

    if ($Headers -and $Headers.ContainsKey('Content-Type')) {
        $contentType = $Headers['Content-Type']
    }

    # Build headers with sane defaults and pass-through
    # New-DataverseHeaders composes Prefer parts and merges ExtraHeaders to maintain intent.
    $builtHeaders = New-DataverseHeaders -AccessToken $AccessToken -ContentType $contentType -ExtraHeaders $Headers

    # Serialize body when present
    # Per contract: if object and Content-Type not set, ConvertTo-Json -Depth 10; otherwise pass through as-is.
    $bodyToSend = $null
    if ($null -ne $Body) {
        $hasContentType = ($Headers -and $Headers.ContainsKey('Content-Type'))
        if (-not $hasContentType -and ($Body -isnot [string])) {
            $bodyToSend = $Body | ConvertTo-Json -Depth 20 -Compress
        }
        else {
            $bodyToSend = $Body
        }
    }

    # Prepare Invoke-WebRequest splat
    # TimeoutSec is passed through if specified; otherwise platform default is used.
    $splat = @{
        Uri = $requestUrl; Method = $Method; Headers = $builtHeaders; ErrorAction = 'Stop'
    }
    if ($null -ne $bodyToSend) {
        $splat['Body'] = $bodyToSend
    }
    if ($TimeoutSec -gt 0) {
        $splat['TimeoutSec'] = $TimeoutSec
    }

    try {
        $response = Invoke-WebRequest @splat

        # Try parse JSON content
        $parsed = $null
        $raw = $response.Content
        if ($raw) {
            try { $parsed = $raw | ConvertFrom-Json } catch { $parsed = $null }
        }

        # Capture common request/trace identifiers when provided by the service.
        $reqId = $null
        $corr = $null
        try {
            $reqId = $response.Headers['x-ms-service-request-id']
        }
        catch {
            Write-Verbose 'Invoke-DataverseHttp: x-ms-service-request-id header not present.'
        }
        try {
            if (-not $corr) {
                $corr = $response.Headers['x-ms-client-request-id']
            }
        }
        catch {
            Write-Verbose 'Invoke-DataverseHttp: x-ms-client-request-id header not present.'
        }

        return [PSCustomObject]@{
            StatusCode    = $response.StatusCode
            Headers       = $response.Headers
            Content       = $parsed
            RawContent    = $raw
            Success       = $true
            RequestId     = $reqId
            CorrelationId = $corr
        }
    }
    catch {
        $statusCode = $null
        try {
            if ($_.Exception.Response) { $statusCode = [int]$_.Exception.Response.StatusCode }
        }
        catch {
            Write-Verbose 'Invoke-DataverseHttp: Unable to read StatusCode from exception response.'
        }

        $responseContent = ''
        if ($_.ErrorDetails) { $responseContent = $_.ErrorDetails.Message }

        # Initialize parsed content; try JSON first, else keep the raw string.
        $contentObj = $null

        if ($responseContent) {
            try {
                $contentObj = $responseContent | ConvertFrom-Json
            }
            catch {
                $contentObj = $responseContent
            }
        }

        $reqId = $null; $corr = $null
        try {
            if ($_.Exception.Response -and $_.Exception.Response.Headers) {
                $reqId = $_.Exception.Response.Headers['x-ms-service-request-id']; $corr = $_.Exception.Response.Headers['x-ms-client-request-id']
            }
        }
        catch {
            Write-Verbose 'Invoke-DataverseHttp: Unable to read identifiers from exception response headers.'
        }

        if ($statusCode) {
            return [PSCustomObject]@{
                StatusCode    = $statusCode
                Headers       = $null
                Content       = $contentObj
                RawContent    = $responseContent
                Error         = $_.Exception.Message
                Success       = $false
                RequestId     = $reqId
                CorrelationId = $corr
            }
        }
        else {
            return [PSCustomObject]@{
                Error         = $_.Exception.Message
                Success       = $false
                RequestId     = $reqId
                CorrelationId = $corr
            }
        }
    }
}
