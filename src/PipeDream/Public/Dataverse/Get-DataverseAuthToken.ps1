function Get-DataverseAuthToken {
    <#
    .SYNOPSIS
        Obtains an authentication token for Dataverse API access.
    
    .DESCRIPTION
        The Get-DataverseAuthToken function obtains an OAuth access token for authenticating with the Dataverse API.
        It supports service principal authentication and includes token caching and refresh mechanisms.
    
    .PARAMETER EnvironmentUrl
        The URL of the Power Platform environment.
    
    .PARAMETER ClientId
        The Application/Client ID for authentication.
    
    .PARAMETER ClientSecret
        The Client secret for service principal authentication.
    
    .PARAMETER TenantId
        The Azure AD tenant ID.
    
    .EXAMPLE
        $token = Get-DataverseAuthToken -EnvironmentUrl "https://myorg.crm.dynamics.com" -ClientId "00000000-0000-0000-0000-000000000000" -ClientSecret "mySecret" -TenantId "00000000-0000-0000-0000-000000000000"
    
    .NOTES
        This function caches tokens to avoid unnecessary authentication requests and handles token refresh when needed.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentUrl,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ClientId,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ClientSecret,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$TenantId
    )
    
    Write-Verbose "Starting Get-DataverseAuthToken for environment: $EnvironmentUrl"
    
    # Normalize environment URL (remove trailing slash if present)
    if ($EnvironmentUrl.EndsWith("/")) {
        $EnvironmentUrl = $EnvironmentUrl.TrimEnd("/")
        Write-Verbose "Normalized environment URL: $EnvironmentUrl"
    }
    
    # Create a cache key based on the parameters to uniquely identify this token request
    $cacheKey = "$($ClientId)_$($TenantId)_$($EnvironmentUrl)".GetHashCode().ToString()
    Write-Verbose "Generated cache key: $cacheKey"
    
    # Check if we have a valid cached token
    if ($script:TokenCache -and $script:TokenCache.ContainsKey($cacheKey)) {
        $cachedToken = $script:TokenCache[$cacheKey]
        
        # Check if token is still valid (with 5 minute buffer)
        $timeSpan = New-TimeSpan -Start (Get-Date) -End $cachedToken.ExpiresOn
        $timeRemaining = $timeSpan.TotalSeconds
        
        if ($timeRemaining -gt 300) {
            Write-Verbose "Using cached token with $timeRemaining seconds remaining until expiration"
            return $cachedToken
        }
        else {
            Write-Verbose "Cached token is about to expire or already expired. Will request a new one."
        }
    }
    else {
        Write-Verbose "No cached token found for this environment and client. Will request a new one."
    }
    
    try {
        # Prepare token request
        $tokenEndpoint = "https://login.microsoftonline.com/$TenantId/oauth2/token"
        $resource = "https://$(([System.Uri]$EnvironmentUrl).Host)"
        
        Write-Verbose "Requesting token from: $tokenEndpoint"
        Write-Verbose "Resource URI: $resource"
        
        # Create body for token request
        $body = @{
            grant_type    = "client_credentials"
            client_id     = $ClientId
            client_secret = $ClientSecret
            resource      = $resource
        }
        
        # Make the request
        $response = Invoke-RestMethod -Uri $tokenEndpoint -Method Post -Body $body -ContentType "application/x-www-form-urlencoded" -ErrorAction Stop
        
        # Process response
        $tokenExpiresOn = (Get-Date).AddSeconds($response.expires_in)
        
        # Create token object
        $tokenObject = [PSCustomObject]@{
            AccessToken = $response.access_token
            TokenType   = $response.token_type
            ExpiresIn   = $response.expires_in
            ExpiresOn   = $tokenExpiresOn
            Resource    = $resource
            ClientId    = $ClientId
            TenantId    = $TenantId
        }
        
        # Initialize token cache if not exists
        if (-not $script:TokenCache) {
            $script:TokenCache = @{}
            Write-Verbose "Initialized token cache"
        }
        
        # Cache the token
        $script:TokenCache[$cacheKey] = $tokenObject
        Write-Verbose "Cached new token that expires on $tokenExpiresOn"
        
        # Return the token object
        return $tokenObject
    }
    catch {
        $errorDetails = @{
            ErrorCode = "AuthenticationError"
            Message   = "Failed to obtain authentication token"
            Details   = $_.Exception.Message
            RequestId = ""
        }
        
        Write-Error "Authentication Error: $($errorDetails.Details)"
        throw [PSCustomObject]$errorDetails
    }
}