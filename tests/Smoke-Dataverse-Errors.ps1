#requires -Version 5.1
<#
.SYNOPSIS
  Dataverse error-handling smoke test using PipeDream module.

.DESCRIPTION
  Intentionally triggers common error scenarios and validates that Invoke-Dataverse* return
  structured error responses (Success=$false, StatusCode when available, Error, RawContent/Content).

.PARAMETER TenantId
  Azure AD tenant ID (GUID).

.PARAMETER Url
  Dataverse environment URL (e.g., https://contoso.crm.dynamics.com).

.PARAMETER ClientId
  App registration Client ID.

.PARAMETER ClientSecret
  App registration Client Secret value.

.PARAMETER EntitySet
  Dataverse entity set name (plural). Defaults to 'accounts'.



.EXAMPLE
  ./Smoke-Dataverse-Errors.ps1 -TenantId $TenantId -Url $Url -ClientId $ClientId -ClientSecret $ClientSecret -Verbose
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory)] [string]$TenantId,
  [Parameter(Mandatory)] [string]$Url,
  [Parameter(Mandatory)] [string]$ClientId,
  [Parameter(Mandatory)] [string]$ClientSecret,
  [Parameter()] [string]$EntitySet = 'accounts'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Note($msg) { Write-Host "[Errors] $msg" -ForegroundColor Cyan }
function Write-Pass($msg) { Write-Host "[PASS] $msg" -ForegroundColor Green }
function Write-Fail($msg) { Write-Host "[FAIL] $msg" -ForegroundColor Red }

function Get-EntityPath([string]$suffix) {
  if (-not $suffix.StartsWith('/')) { $suffix = '/' + $suffix }
  return "/api/data/v9.2$($suffix)"
}

function Assert-ErrorResult {
  param(
    [string]$Label,
    [object]$Result,
    [int[]]$ExpectedStatusCodes = @()
  )

  if ($Result -and $Result.Success -eq $false) {
    if ($ExpectedStatusCodes -and $Result.StatusCode) {
      if ($ExpectedStatusCodes -contains [int]$Result.StatusCode) {
        Write-Pass "$Label (StatusCode=$($Result.StatusCode))"
        return $true
      }
      else {
        Write-Fail "$Label expected StatusCode in [$($ExpectedStatusCodes -join ',')], got $($Result.StatusCode). Error=$($Result.Error)"
        return $false
      }
    }
    elseif (-not $ExpectedStatusCodes) {
      Write-Pass "$Label (non-HTTP error)"
      return $true
    }
    else {
      Write-Fail "$Label expected HTTP error, got Success=$($Result.Success), StatusCode=$($Result.StatusCode)"
      return $false
    }
  }
  else {
    Write-Fail "$Label expected error, got success or null."
    if ($Result) { Write-Verbose ("Result: " + ($Result | ConvertTo-Json -Depth 5)) }
    return $false
  }
}

try {
  # Import the module from repo relative path
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\src\PipeDream\PipeDream.psd1'
  if (-not (Test-Path $modulePath)) { throw "PipeDream module not found at $modulePath" }
  # Ensure we aren't using a globally installed PipeDream; then import from repo
  Remove-Module PipeDream -ErrorAction SilentlyContinue
  Import-Module $modulePath -Force -ErrorAction Stop
  $loaded = Get-Module PipeDream
  if ($loaded) {
    Write-Host ("[Smoke] Using PipeDream module: {0} (v{1})" -f $loaded.Path, $loaded.Version) -ForegroundColor Yellow
  }
  Write-Verbose "Imported module: $modulePath"

  # Acquire a valid token for HTTP error tests requiring auth
  Write-Note "Requesting token for $Url"
  $token = Get-DataverseAuthToken -TenantId $TenantId -Url $Url -ClientId $ClientId -ClientSecret $ClientSecret -Verbose:$VerbosePreference
  if (-not $token -or [string]::IsNullOrWhiteSpace($token.AccessToken)) { throw "Failed to acquire access token." }

  $allPass = $true

  # 1) Unauthorized (401/403) with intentionally bad token
  Write-Note "Testing Unauthorized with invalid access token"
  $badAuth = Invoke-DataverseGet -AccessToken 'invalid.token.value' -Url $Url -Query (Get-EntityPath("/$($EntitySet)?`$top=1")) -Verbose:$VerbosePreference
  $allPass = (Assert-ErrorResult -Label 'Unauthorized (bad token)' -Result $badAuth -ExpectedStatusCodes @(401, 403)) -and $allPass

  # 2) NotFound (404) for a random GUID
  $randomGuid = [Guid]::NewGuid().Guid
  Write-Note "Testing NotFound with random id $randomGuid"
  $notFound = Invoke-DataverseGet -AccessToken $token.AccessToken -Url $Url -Query (Get-EntityPath("/$($EntitySet)($randomGuid)?`$select=name")) -Verbose:$VerbosePreference
  $allPass = (Assert-ErrorResult -Label 'NotFound (random id)' -Result $notFound -ExpectedStatusCodes @(404)) -and $allPass

  # 3) BadRequest (400) invalid select property
  Write-Note 'Testing BadRequest with invalid $select property'
  $badRequest = Invoke-DataverseGet -AccessToken $token.AccessToken -Url $Url -Query (Get-EntityPath("/$($EntitySet)?`$select=thisfielddoesnotexist")) -Verbose:$VerbosePreference
  $allPass = (Assert-ErrorResult -Label 'BadRequest (invalid $select)' -Result $badRequest -ExpectedStatusCodes @(400)) -and $allPass

  # 4) BadRequest (400) invalid property on POST
  Write-Note "Testing BadRequest on POST with invalid field"
  $postBody = @{ thisfielddoesnotexist = 'x' }
  $postBad = Invoke-DataversePost -AccessToken $token.AccessToken -Url $Url -Query (Get-EntityPath("/$EntitySet")) -Body $postBody -Verbose:$VerbosePreference
  $allPass = (Assert-ErrorResult -Label 'BadRequest (POST invalid field)' -Result $postBad -ExpectedStatusCodes @(400)) -and $allPass

  # 5) Non-HTTP network error (invalid host) - mandatory
  Write-Note "Testing non-HTTP network error (invalid host)"
  $invalidHostUrl = 'https://nonexistent-host-for-pd-tests.invalid'
  $netErr = Invoke-DataverseGet -AccessToken $token.AccessToken -Url $invalidHostUrl -Query (Get-EntityPath("/$($EntitySet)?`$top=1")) -Verbose:$VerbosePreference
  $allPass = (Assert-ErrorResult -Label 'Network error (no HTTP response)' -Result $netErr -ExpectedStatusCodes @()) -and $allPass

  # Throttling test removed by request.

  if ($allPass) {
    Write-Host "Error-handling smoke test: ALL PASS" -ForegroundColor Green
  }
  else {
    Write-Error "Error-handling smoke test: FAILED"
  }
}
catch {
  Write-Error $_
}
