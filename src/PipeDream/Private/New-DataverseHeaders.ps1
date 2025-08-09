function New-DataverseHeaders {
    <#
    .SYNOPSIS
        Build Dataverse HTTP headers from common options.
    .DESCRIPTION
        Produces a case-insensitive hashtable of HTTP headers for Dataverse, including auth and OData defaults.
        Allows composing Prefer directives, conditional headers, correlation IDs, and localization.
    .PARAMETER AccessToken
        OAuth access token (raw JWT string). Required for Authorization header.
    .PARAMETER Accept
        Accept header value. Defaults to application/json.
    .PARAMETER ContentType
        Content-Type header value. Optional; usually application/json when sending a body.
    .PARAMETER ODataVersion
        OData-Version header. Defaults to 4.0.
    .PARAMETER ODataMaxVersion
        OData-MaxVersion header. Defaults to 4.0.
    .PARAMETER PreferReturnRepresentation
        When true, include Prefer: return=representation.
    .PARAMETER PreferODataMaxPageSize
        Include odata.maxpagesize in Prefer header.
    .PARAMETER PreferIncludeAnnotations
        Include odata.include-annotations in Prefer header (e.g. "*").
    .PARAMETER ConsistencyLevel
        ConsistencyLevel header (e.g., "eventual").
    .PARAMETER IfMatch
        If-Match header value (e.g., "*").
    .PARAMETER IfNoneMatch
        If-None-Match header value.
    .PARAMETER CorrelationId
        Correlation identifier (GUID string). Sent as x-ms-client-request-id.
    .PARAMETER SuppressDuplicateDetection
        When specified, set MSCRM.SuppressDuplicateDetection=true.
    .PARAMETER AcceptLanguage
        Accept-Language header value (e.g., "en-US").
    .PARAMETER ExtraHeaders
        Additional headers to merge in last, overriding built values when conflicts occur.
    .OUTPUTS
        Hashtable
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $AccessToken,
        [string] $Accept = 'application/json',
        [string] $ContentType,
        [string] $ODataVersion = '4.0',
        [string] $ODataMaxVersion = '4.0',
        [switch] $PreferReturnRepresentation,
        [int] $PreferODataMaxPageSize,
        [string] $PreferIncludeAnnotations,
        [ValidateSet('eventual')] [string] $ConsistencyLevel,
        [string] $IfMatch,
        [string] $IfNoneMatch,
        [string] $CorrelationId,
        [switch] $SuppressDuplicateDetection,
        [string] $AcceptLanguage,
        [hashtable] $ExtraHeaders
    )

    # Start with core headers
    # Note: We intentionally keep this builder deterministic:
    # - Always sets Authorization + OData defaults
    # - Accept/Content-Type are optional (Content-Type typically set by caller/core when body exists)
    # - ExtraHeaders apply LAST and can override, except for a composed Prefer we build below
    $headers = @{}
    $headers['Authorization'] = "Bearer $AccessToken"
    if ($Accept) { $headers['Accept'] = $Accept }
    if ($ContentType) { $headers['Content-Type'] = $ContentType }
    if ($ODataVersion) { $headers['OData-Version'] = $ODataVersion }
    if ($ODataMaxVersion) { $headers['OData-MaxVersion'] = $ODataMaxVersion }

    # Compose Prefer
    # We support multiple Prefer parts; if the caller also provides a Prefer header via ExtraHeaders,
    # we MERGE the missing parts instead of overwriting. This ensures flags like return=representation
    # or odata.maxpagesize are preserved while still honoring caller-provided entries.
    $preferComposed = $false
    $preferParts = @()
    if ($PreferReturnRepresentation.IsPresent) { $preferParts += 'return=representation' }
    if ($PreferODataMaxPageSize) { $preferParts += "odata.maxpagesize=$PreferODataMaxPageSize" }
    if ($PreferIncludeAnnotations) { $preferParts += "odata.include-annotations=$PreferIncludeAnnotations" }
    if ($preferParts.Count -gt 0) {
        # If ExtraHeaders already contains Prefer, append parts after a comma unless identical
        $existingPrefer = $null
        if ($ExtraHeaders -and $ExtraHeaders.ContainsKey('Prefer')) { $existingPrefer = [string]$ExtraHeaders['Prefer'] }
        if ($existingPrefer) {
            $toAdd = ($preferParts | Where-Object { $existingPrefer -notmatch [regex]::Escape($_) })
            if ($toAdd.Count -gt 0) { $headers['Prefer'] = ($existingPrefer.TrimEnd(',') + ',' + ($toAdd -join ',')).Trim(',') }
            else { $headers['Prefer'] = $existingPrefer }
        }
        else { $headers['Prefer'] = ($preferParts -join ',') }
        $preferComposed = $true
    }

    if ($ConsistencyLevel) { $headers['ConsistencyLevel'] = $ConsistencyLevel }
    if ($IfMatch) { $headers['If-Match'] = $IfMatch }
    if ($IfNoneMatch) { $headers['If-None-Match'] = $IfNoneMatch }
    if ($CorrelationId) { $headers['x-ms-client-request-id'] = $CorrelationId }
    if ($SuppressDuplicateDetection.IsPresent) { $headers['MSCRM.SuppressDuplicateDetection'] = 'true' }
    if ($AcceptLanguage) { $headers['Accept-Language'] = $AcceptLanguage }

    # Merge extra headers last to allow explicit override by caller
    # Special-case: if we already composed a Prefer header, we skip overwriting it so the
    # merged value is retained. Callers that need full control can pass all parts in ExtraHeaders.Prefer.
    if ($ExtraHeaders) {
        foreach ($k in $ExtraHeaders.Keys) {
            if ($k -eq 'Prefer' -and $preferComposed) { continue }
            $headers[$k] = $ExtraHeaders[$k]
        }
    }

    return $headers
}
