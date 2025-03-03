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
    - access_token: The access token to use in API calls
    - token_type: The token type (typically "Bearer")
    - expires_in: Token lifespan in seconds
    - expires_at: DateTime when the token expires (in UTC)
    - resource: Resource the token is valid for

    .EXAMPLE
    # Get an authentication token
    Get-DataverseAuthToken `
        -TenantId "00000000-0000-0000-0000-000000000000" `
        -ResourceUrl "https://your-org.crm.dynamics.com" `
        -ClientId "00000000-0000-0000-0000-000000000000" `
        -ClientSecret "your-client-secret"
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
            Write-Verbose "Token expires at: $expirationTimeString"

            # Create a custom token object with useful properties
            $token = [PSCustomObject]@{
                access_token = $response.access_token
                token_type   = $response.token_type
                expires_in   = $response.expires_in
                expires_at   = $expirationTimeString
                resource     = $response.resource
            }

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

Export-ModuleMember -Function @('Get-DataverseAuthToken')