function Test-DataverseToken {
    <#
    .SYNOPSIS
        Validates if a Dataverse authentication token is valid and not expired.
    
    .DESCRIPTION
        Internal function that checks if the provided token is valid and not expired.
        Includes a buffer time to prevent using tokens that are about to expire.
    
    .PARAMETER Token
        The authentication token object to validate.
    
    .PARAMETER BufferSeconds
        Number of seconds to use as a buffer when checking token expiration.
        Default is 300 seconds (5 minutes).
    
    .EXAMPLE
        $isValid = Test-DataverseToken -Token $tokenObject
    
    .NOTES
        This is an internal helper function not exported by the module.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSCustomObject]$Token,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$BufferSeconds = 300
    )
    
    Write-Verbose "Testing Dataverse token validation"
    
    # Check if the token object has the required properties
    if (-not $Token.AccessToken -or -not $Token.ExpiresOn) {
        Write-Verbose "Token object is invalid - missing required properties"
        return $false
    }
    
    # Check if the token is expired or about to expire
    $timeSpan = New-TimeSpan -Start (Get-Date) -End $Token.ExpiresOn
    $timeRemaining = $timeSpan.TotalSeconds
    
    if ($timeRemaining -le $BufferSeconds) {
        Write-Verbose "Token is expired or about to expire in $timeRemaining seconds"
        return $false
    }
    
    Write-Verbose "Token is valid with $timeRemaining seconds remaining until expiration"
    return $true
}