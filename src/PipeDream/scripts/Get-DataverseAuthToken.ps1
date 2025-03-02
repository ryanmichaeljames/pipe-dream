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

    .EXAMPLE
    $token = Get-DataverseAuthToken -TenantId '00000000-0000-0000-0000-000000000000' -EnvironmentUrl 'https://your-org.crm.dynamics.com' -ClientId '00000000-0000-0000-0000-000000000000' -ClientSecret 'your-client-secret'
    #>

    param (

        [Parameter(Mandatory = $true)]
        [string]$TenantId,

        [Parameter(Mandatory = $true)]
        [string]$EnvironmentUrl,
    
        [Parameter(Mandatory = $true)]
        [string]$ClientId,

        [Parameter(Mandatory = $true)]
        [string]$ClientSecret
    )

    begin {
        # Ensure URL has no trailing slash
        $resource = $EnvironmentUrl.TrimEnd('/')
        
        # Azure AD OAuth endpoint
        $oauthUrl = "https://login.microsoftonline.com/$TenantId/oauth2/token"
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

            # Get the OAuth token
            $response = Invoke-RestMethod -Method Post -Uri $oauthUrl -Body $body -ContentType "application/x-www-form-urlencoded"

            # Create a custom token object with useful properties
            $token = [PSCustomObject]@{
                AccessToken = $response.access_token
                TokenType   = $response.token_type
                ExpiresIn   = $response.expires_in
                ExpiresAt   = (Get-Date).AddSeconds($response.expires_in).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
                Resource    = $response.resource
            }

            return $token
        }
        catch {
            throw $_
        }
    }
}
