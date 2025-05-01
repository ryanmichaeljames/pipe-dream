function Get-DataverseAuthToken {
    <#
    .SYNOPSIS
        Obtains an authentication token for Dataverse API access.
    .DESCRIPTION
        The Get-DataverseAuthToken function obtains an OAuth access token for authenticating with the Dataverse API.
        It supports service principal authentication using the Microsoft Identity Platform v2.0 endpoint and returns a formatted token object.
    .PARAMETER TenantId
        The Azure AD tenant ID.
    .PARAMETER Url
        The URL of the Power Platform environment. For example: https://myorg.crm.dynamics.com
    .PARAMETER ClientId
        The Application/Client ID for authentication.
    .PARAMETER ClientSecret
        The Client secret for service principal authentication.
    .EXAMPLE
        $token = Get-DataverseAuthToken -TenantId "00000000-0000-0000-0000-000000000000" -Url "https://myorg.crm.dynamics.com" -ClientId "00000000-0000-0000-0000-000000000000" -ClientSecret "mySecret"
    .NOTES
        This function returns a formatted token object with AccessToken, TokenType, ExpiresIn, and ExpiresOn properties.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$TenantId,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Url,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ClientId,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ClientSecret
    )
    Write-Verbose "Starting Get-DataverseAuthToken for URL: $Url"
    
    # Normalize URL (remove trailing slash if present)
    if ($Url.EndsWith("/")) {
        $Url = $Url.TrimEnd("/")
        Write-Verbose "Normalized URL: $Url"
    }
    try {
        # Prepare token request - using v2 endpoint
        $tokenEndpoint = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
        $scope = "https://$(([System.Uri]$Url).Host)/.default"
        
        Write-Verbose "Requesting token from: $tokenEndpoint"
        Write-Verbose "Scope: $scope"
        
        # Create body for token request
        $body = @{
            grant_type    = "client_credentials"
            client_id     = $ClientId
            client_secret = $ClientSecret
            scope         = $scope
        }        
        
        # Make the request
        $response = Invoke-RestMethod -Uri $tokenEndpoint -Method Post -Body $body -ContentType "application/x-www-form-urlencoded" -ErrorAction Stop
        
        # Calculate the expiration time
        $tokenExpiresOn = (Get-Date).AddSeconds($response.expires_in)
        
        # Format and return the token response as a custom object
        return [PSCustomObject]@{
            AccessToken = $response.access_token
            TokenType   = $response.token_type
            ExpiresIn   = $response.expires_in
            ExpiresOn   = $tokenExpiresOn
        }
    }
    catch {
        # Check if the error response contains a JSON payload
        if ($_.Exception.Response) {
            try {
                # Extract the error details from the response
                $errorDetails = $_.ErrorDetails
                if ($null -eq $errorDetails) {
                    # For some errors, the error details might be in the response stream
                    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                    $reader.BaseStream.Position = 0
                    $reader.DiscardBufferedData()
                    $responseContent = $reader.ReadToEnd()
                    $errorObject = $responseContent | ConvertFrom-Json
                } 
                else {
                    $errorObject = $errorDetails.Message | ConvertFrom-Json
                }

                # Format a detailed error message
                $detailedError = "Authentication Error Code: $($errorObject.error)`n"
                $detailedError += "Description: $($errorObject.error_description)`n"
                
                if ($errorObject.correlation_id) {
                    $detailedError += "Correlation ID: $($errorObject.correlation_id)`n"
                }
                
                if ($errorObject.trace_id) {
                    $detailedError += "Trace ID: $($errorObject.trace_id)`n"
                }
                # Add specific guidance based on error type
                switch -Regex ($errorObject.error) {
                    "invalid_scope" {
                        $detailedError += "Guidance: Verify the resource URL format. For client credential flows, ensure the resource URL is correctly formatted and the requested permissions are allowed for this application."
                    }
                    "invalid_client" {
                        $detailedError += "Guidance: Check that you're using the correct client ID and client secret value (not the secret ID) and that the secret hasn't expired."
                    }
                    "unauthorized_client" {
                        $detailedError += "Guidance: Your application is not authorized to use this authentication flow. Verify the app is registered for client credentials grant type in Azure AD."
                    }
                    "invalid_grant" {
                        $detailedError += "Guidance: The authorization grant is invalid, expired, or revoked. You may need to request a new authorization."
                    }
                    "invalid_request" {
                        $detailedError += "Guidance: The request is missing a required parameter, includes an invalid parameter value, or is otherwise malformed."
                    }
                    "unsupported_grant_type" {
                        $detailedError += "Guidance: The authorization grant type is not supported by the authorization server or is incorrectly specified."
                    }
                    "access_denied" {
                        $detailedError += "Guidance: The resource owner or authorization server denied the request. Verify the application has the necessary permissions."
                    }
                    default {
                        $detailedError += "Guidance: Please review your authentication parameters and try again."
                    }
                }
                
                Write-Error $detailedError
                throw $detailedError
            }
            catch {
                # Fallback if we can't parse the error response
                $errorMessage = "Failed to obtain authentication token (400 Bad Request): $($_.Exception.Message)"
                Write-Error $errorMessage
                throw $errorMessage
            }
        }
        else {
            # Handle non-400 errors
            $errorMessage = "Failed to obtain authentication token: $($_.Exception.Message)"
            Write-Error $errorMessage
            throw $errorMessage
        }
    }
}