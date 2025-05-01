function Get-UrlFromAccessToken {
    <#
    .SYNOPSIS
        Extracts the URL from an access token.
    .DESCRIPTION
        The Get-UrlFromAccessToken function extracts the audience (aud) claim from a JWT access token,
        which typically contains the resource URL.
    .PARAMETER AccessToken
        The authentication token string (access token) obtained from Get-DataverseAuthToken.
    .OUTPUTS
        System.String. Returns the URL extracted from the token or $null if extraction fails.
    .EXAMPLE
        $url = Get-UrlFromAccessToken -AccessToken $authResult.AccessToken
    .NOTES
        This function expects a valid JWT token format.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$AccessToken
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
        
        # Extract the audience claim
        if ($tokenPayload.aud) {
            Write-Verbose "Extracted URL from token: $($tokenPayload.aud)"
            return $tokenPayload.aud
        }
        else {
            Write-Verbose "Could not find 'aud' claim in the token payload."
            return $null
        }
    }
    catch {
        Write-Verbose "Failed to extract URL from access token: $_"
        return $null
    }
}
