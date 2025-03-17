function Get-DataverseTokenInfo {
    <#
    .SYNOPSIS
        Extracts and formats information from a Dataverse authentication token.
    
    .DESCRIPTION
        Internal helper function that extracts useful information from a token object,
        such as expiration time, claims, and other metadata.
    
    .PARAMETER Token
        The authentication token object to extract information from.
    
    .EXAMPLE
        $tokenInfo = Get-DataverseTokenInfo -Token $tokenObject
    
    .NOTES
        This is an internal helper function not exported by the module.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSCustomObject]$Token
    )
    
    Write-Verbose "Extracting information from Dataverse token"
    
    # Ensure token has the required properties
    if (-not $Token.AccessToken) {
        Write-Error "Invalid token object - missing AccessToken property"
        return $null
    }
    
    try {
        # Extract token parts (header, payload, signature)
        $tokenParts = $Token.AccessToken.Split('.')
        if ($tokenParts.Count -ne 3) {
            Write-Warning "Token does not appear to be in valid JWT format"
            return $null
        }
        
        # Decode the payload (middle part of the JWT)
        $payloadBytes = [System.Convert]::FromBase64String($tokenParts[1].Replace('-', '+').Replace('_', '/').PadRight(4 * [math]::Ceiling($tokenParts[1].Length / 4), '='))
        $payloadJson = [System.Text.Encoding]::UTF8.GetString($payloadBytes)
        $payload = ConvertFrom-Json $payloadJson
        
        # Create a formatted token info object
        $tokenInfo = [PSCustomObject]@{
            IsValid       = (Test-DataverseToken -Token $Token)
            ExpiresOn     = $Token.ExpiresOn
            TimeRemaining = [math]::Round((New-TimeSpan -Start (Get-Date) -End $Token.ExpiresOn).TotalMinutes, 1)
            Subject       = $payload.sub
            Issuer        = $payload.iss
            AppId         = $payload.appid
            TenantId      = $Token.TenantId
            Resource      = $Token.Resource
            Scopes        = $payload.scp
        }
        
        return $tokenInfo
    }
    catch {
        Write-Error "Failed to extract token information: $($_.Exception.Message)"
        return $null
    }
}