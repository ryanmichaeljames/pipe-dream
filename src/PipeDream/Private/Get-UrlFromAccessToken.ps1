function Get-UrlFromAccessToken {
    <#
    .SYNOPSIS
        Extracts the URL from an access token.
    .DESCRIPTION
        Extract the Dataverse environment base URL from the 'aud' (audience) claim of a JWT access token.
        Robustly supports string or array 'aud' values, normalizes the result to a canonical
        https://<host> form (lowercase host, no path/query, no trailing slash). Returns $null on any
        parse/validation failure – no throws – to keep callers resilient.
    .PARAMETER AccessToken
        The authentication token string (access token) obtained from Get-DataverseAuthToken.
    .OUTPUTS
        System.String. Normalized https://<host> URL or $null if extraction/validation fails.
    .EXAMPLE
        $url = Get-UrlFromAccessToken -AccessToken $authResult.AccessToken
    .NOTES
        This function expects a valid JWT token format.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $AccessToken
    )

    try {
    # Split the JWT token and decode the payload (middle part)
        $tokenParts = $AccessToken.Split('.')
        if ($tokenParts.Count -ne 3) {
            Write-Verbose "Invalid token format. Expected JWT format with 3 parts."
            return $null
        }

        # Add padding to avoid Base64 decode errors
        $payloadBase64 = $tokenParts[1].Replace('-', '+').Replace('_', '/')
        $padLength = 4 - ($payloadBase64.Length % 4)
        if ($padLength -lt 4) {
            $payloadBase64 = $payloadBase64 + ("=" * $padLength)
        }

        # Decode the base64 payload to JSON
        $payloadBytes = [System.Convert]::FromBase64String($payloadBase64)
        $payloadJson = [System.Text.Encoding]::UTF8.GetString($payloadBytes)
        $tokenPayload = $payloadJson | ConvertFrom-Json

        # Extract & normalize the audience claim.
        $audValues = @()
        if ($null -ne $tokenPayload.aud) {
            if ($tokenPayload.aud -is [System.Array]) {
                $audValues = @($tokenPayload.aud)
            }
            else {
                $audValues = @($tokenPayload.aud)
            }
        }
        if (-not $audValues -or $audValues.Count -eq 0) {
            Write-Verbose "Could not find 'aud' claim in the token payload."
            return $null
        }

        foreach ($aud in $audValues) {
            if (-not [string]::IsNullOrWhiteSpace($aud)) {
                # Accept only potential https dynamics hosts
                if ($aud -match '^https?://') {
                    # Attempt to parse with System.Uri
                    $uri = $null
                    if ([System.Uri]::TryCreate($aud, [System.UriKind]::Absolute, [ref]$uri)) {
                        if ($uri.Host -and $uri.Host -match '\.dynamics\.com$') {
                            # Build canonical HTTPS URL with lowercase host only
                            $builder = [System.UriBuilder]::new('https', $uri.Host.ToLowerInvariant())
                            $normalized = $builder.Uri.AbsoluteUri.TrimEnd('/')
                            Write-Verbose "Normalized audience '$aud' => '$normalized'"
                            return $normalized
                        }
                    }
                }
            }
        }

        Write-Verbose "No valid Dataverse audience host found in 'aud' claim."
        return $null
    }
    catch {
        Write-Verbose "Failed to extract URL from access token: $_"
        return $null
    }
}
