function Get-DataverseAuthToken {
    <#
    .SYNOPSIS
    Retrieves an authentication token for the Dataverse.

    .DESCRIPTION
    This function uses the provided client ID, client secret, and tenant ID to retrieve an authentication token for Dataverse.

    .PARAMETER TenantId
    The tenant ID of the Azure Active Directory.

    .PARAMETER EnvironmentUrl
    The URL of the Dataverse environment (e.g., https://your-org.crm.dynamics.com).

    .PARAMETER ClientId
    The client ID of the application.

    .PARAMETER ClientSecret
    The client secret of the application.

    .OUTPUTS
    PSCustomObject containing the following properties:
    - AccessToken: The access token to use in API calls
    - TokenType: The token type (typically "Bearer")
    - ExpiresIn: Token lifespan in seconds
    - ExpiresAt: DateTime when the token expires (in UTC)
    - Resource: Resource the token is valid for

    .EXAMPLE
    $token = Get-DataverseAuthToken -TenantId '00000000-0000-0000-0000-000000000000' -EnvironmentUrl 'https://your-org.crm.dynamics.com' -ClientId '00000000-0000-0000-0000-000000000000' -ClientSecret 'your-client-secret'

    .EXAMPLE
    # Get token and use it in a subsequent API call
    $token = Get-DataverseAuthToken -TenantId '00000000-0000-0000-0000-000000000000' -EnvironmentUrl 'https://your-org.crm.dynamics.com' -ClientId '00000000-0000-0000-0000-000000000000' -ClientSecret 'your-client-secret'
    
    $headers = @{
        "Authorization" = "$($token.TokenType) $($token.AccessToken)"
        "Content-Type" = "application/json"
    }
    $apiUrl = "$($EnvironmentUrl)/api/data/v9.1/accounts"
    Invoke-RestMethod -Method Get -Uri $apiUrl -Headers $headers
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$TenantId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^https?://')]
        [string]$EnvironmentUrl,
    
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ClientId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ClientSecret
    )

    begin {
        Write-Verbose "Starting authentication process for Dataverse environment: $EnvironmentUrl"
        
        # Ensure URL has no trailing slash
        $resource = $EnvironmentUrl.TrimEnd('/')
        
        # Azure AD OAuth endpoint
        $oauthUrl = "https://login.microsoftonline.com/$TenantId/oauth2/token"
        Write-Verbose "Using OAuth URL: $oauthUrl"
    }

    process {
        try {
            # Prepare the request body
            $body = @{
                client_id     = $ClientId
                client_secret = $ClientSecret
                resource      = $resource
                grant_type    = "client_credentials"
            }
            Write-Verbose "Requesting token for resource: $resource"

            # Get the OAuth token
            $response = Invoke-RestMethod -Method Post -Uri $oauthUrl -Body $body -ContentType "application/x-www-form-urlencoded" -ErrorAction Stop
            
            Write-Verbose "Token acquired successfully. Token expires in $($response.expires_in) seconds"

            # Calculate expiration time
            $expirationTime = (Get-Date).AddSeconds($response.expires_in).ToUniversalTime()
            $expirationTimeString = $expirationTime.ToString("yyyy-MM-ddTHH:mm:ssZ")

            # Create a custom token object with useful properties
            $token = [PSCustomObject]@{
                AccessToken = $response.access_token
                TokenType   = $response.token_type
                ExpiresIn   = $response.expires_in
                ExpiresAt   = $expirationTimeString
                Resource    = $response.resource
            }

            Write-Verbose "Token expires at: $expirationTimeString"
            return $token
        }
        catch [System.Net.WebException] {
            Write-Error "Failed to connect to authentication service. Please check your network connection and the environment URL."
            throw "Authentication failed: $_"
        }
        catch {
            Write-Error "Authentication failed. Please verify your credentials and tenant information."
            throw "Authentication error: $_"
        }
    }
}
