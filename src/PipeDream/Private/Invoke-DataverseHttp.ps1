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
        Base environment URL. If not supplied, will try to derive from token 'aud' via Get-UrlFromAccessToken.
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
        [Parameter(Mandatory=$true)][ValidateSet('GET','POST','PATCH','DELETE')] [string] $Method,
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $AccessToken,
        [string] $Url,
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $Query,
        [object] $Body,
        [hashtable] $Headers,
        [int] $TimeoutSec
    )

    # Derive URL if needed
    # If Url isn't provided, we pull 'aud' from the access token payload via Get-UrlFromAccessToken.
    # This preserves the existing public behavior where Url was optional when the token audience matched the env URL.
    if ([string]::IsNullOrEmpty($Url)) {
        $extractedUrl = Get-UrlFromAccessToken -AccessToken $AccessToken
        if ($extractedUrl) { $Url = $extractedUrl } else { throw "Could not extract URL from the access token." }
    }
    if ([string]::IsNullOrEmpty($Url)) { throw "URL is required. Either provide it as a parameter or use an access token that contains an 'aud' claim." }

    # Normalize URL and Query
    # - Trim trailing slash from Url
    # - Ensure Query starts with '/'
    # - Build requestUrl for Invoke-WebRequest
    if ($Url.EndsWith('/')) { $Url = $Url.TrimEnd('/') }
    if (-not $Query.StartsWith('/')) { $Query = "/$Query" }
    $requestUrl = "$Url$Query"

    # Auto content-type if sending a body and not provided by headers
    # Default to application/json for body scenarios unless explicitly overridden by caller headers.
    $contentType = $null
    if ($null -ne $Body) { $contentType = 'application/json' }
    if ($Headers -and $Headers.ContainsKey('Content-Type')) { $contentType = $Headers['Content-Type'] }

    # Build headers with sane defaults and pass-through
    # New-DataverseHeaders composes Prefer parts and merges ExtraHeaders to maintain intent.
    $builtHeaders = New-DataverseHeaders -AccessToken $AccessToken -ContentType $contentType -ExtraHeaders $Headers

    # Serialize body when present
    $jsonBody = $null
    if ($null -ne $Body) { $jsonBody = $Body | ConvertTo-Json -Depth 20 -Compress }

    # Prepare Invoke-WebRequest splat
    # TimeoutSec is passed through if specified; otherwise platform default is used.
    $splat = @{ Uri = $requestUrl; Method = $Method; Headers = $builtHeaders; ErrorAction = 'Stop' }
    if ($jsonBody) { $splat['Body'] = $jsonBody }
    if ($TimeoutSec -gt 0) { $splat['TimeoutSec'] = $TimeoutSec }

    try {
        $response = Invoke-WebRequest @splat

        # Try parse JSON content
        $parsed = $null
        $raw    = $response.Content
        if ($raw) {
            try { $parsed = $raw | ConvertFrom-Json } catch { $parsed = $null }
        }

    # capture ids
    # Capture common request/trace identifiers when provided by the service.
        $reqId = $null
        $corr  = $null
        try { $reqId = $response.Headers['x-ms-service-request-id'] } catch {}
        try { if (-not $corr) { $corr = $response.Headers['x-ms-client-request-id'] } } catch {}

        return [PSCustomObject]@{
            StatusCode   = $response.StatusCode
            Headers      = $response.Headers
            Content      = $parsed
            RawContent   = $raw
            Success      = $true
            RequestId    = $reqId
            CorrelationId= $corr
        }
    }
    catch {
        $statusCode = $null
        try { if ($_.Exception.Response) { $statusCode = $_.Exception.Response.StatusCode.value__ } } catch {}
        $responseContent = ''
        if ($_.ErrorDetails) { $responseContent = $_.ErrorDetails.Message }
        $contentObj = $null
        if ($responseContent) { try { $contentObj = $responseContent | ConvertFrom-Json } catch { $contentObj = $responseContent } }

        $reqId = $null; $corr = $null
        try { if ($_.Exception.Response -and $_.Exception.Response.Headers) { $reqId = $_.Exception.Response.Headers['x-ms-service-request-id']; $corr = $_.Exception.Response.Headers['x-ms-client-request-id'] } } catch {}

    if ($statusCode) {
            return [PSCustomObject]@{
                StatusCode   = $statusCode
                Headers      = $null
                Content      = $contentObj
                RawContent   = $responseContent
                Error        = $_.Exception.Message
                Success      = $false
                RequestId    = $reqId
                CorrelationId= $corr
            }
        }
        else {
            return [PSCustomObject]@{
                Error        = $_.Exception.Message
                Success      = $false
                RequestId    = $reqId
                CorrelationId= $corr
            }
        }
    }
}
