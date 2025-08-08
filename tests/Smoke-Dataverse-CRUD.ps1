#requires -Version 5.1
<#
.SYNOPSIS
  Simple Dataverse CRUD smoke test using PipeDream module.

.DESCRIPTION
  Creates an entity record, retrieves it, updates it, and deletes it.
  Minimal parameters; uses module functions:
    - Get-DataverseAuthToken
    - Invoke-DataversePost
    - Invoke-DataverseGet
    - Invoke-DataversePatch
    - Invoke-DataverseDelete

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

.PARAMETER NamePrefix
  Name prefix for the test record. Defaults to 'PipeDream Test'.

.EXAMPLE
  # Set parameters then run
  $TenantId = "00000000-0000-0000-0000-000000000000"
  $Url = "https://yourorg.crm.dynamics.com"
  $ClientId = "00000000-0000-0000-0000-000000000000"
  $ClientSecret = "<secret>"
  ./Smoke-Dataverse-CRUD.ps1 -TenantId $TenantId -Url $Url -ClientId $ClientId -ClientSecret $ClientSecret -Verbose

#>
[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]$TenantId,

  [Parameter(Mandatory)]
  [string]$Url,

  [Parameter(Mandatory)]
  [string]$ClientId,

  [Parameter(Mandatory)]
  [string]$ClientSecret,

  [Parameter()]
  [string]$EntitySet = 'accounts',

  [Parameter()]
  [string]$NamePrefix = 'PipeDream Test'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Note($msg) { Write-Host "[Smoke] $msg" -ForegroundColor Cyan }

try {
  # Import the module from repo relative path
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\src\PipeDream\PipeDream.psd1'
  if (-not (Test-Path $modulePath)) {
    throw "PipeDream module not found at $modulePath"
  }
  Import-Module $modulePath -Force -ErrorAction Stop
  Write-Verbose "Imported module: $modulePath"

  # 1) Auth
  Write-Note "Requesting token for $Url"
  $token = Get-DataverseAuthToken -TenantId $TenantId -Url $Url -ClientId $ClientId -ClientSecret $ClientSecret -Verbose:$VerbosePreference

  if (-not $token -or [string]::IsNullOrWhiteSpace($token.AccessToken)) {
    throw "Failed to acquire access token."
  }

  # Helper to build v9.2 path
  function Get-EntityPath([string]$suffix) {
    if (-not $suffix.StartsWith('/')) { $suffix = '/' + $suffix }
    return "/api/data/v9.2$($suffix)"
  }

  # 2) Create
  $name = "$NamePrefix $(Get-Date -Format 's')"
  $createBody = @{ name = $name }
  $createQuery = Get-EntityPath("/$EntitySet")
  Write-Note "Creating $EntitySet with name '$name'"
  $create = Invoke-DataversePost -AccessToken $token.AccessToken -Url $Url -Query $createQuery -Body $createBody -Verbose:$VerbosePreference
  if (-not $create.Success) { throw "Create failed: $($create.Error) | $($create.RawContent)" }

  # Extract GUID id; prefer OData-EntityId header, then entity's primary id property, then any *id GUID
  $guid = $null
  $guidRegex = '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'

  if ($create.Headers) {
    $entityIdHeader = $create.Headers['OData-EntityId']
    if (-not $entityIdHeader) { $entityIdHeader = $create.Headers['OData-EntityID'] }
    if ($entityIdHeader -and ($entityIdHeader -match "\(($guidRegex)\)")) {
      $guid = $Matches[1]
      Write-Verbose "GUID extracted from OData-EntityId header: $guid"
    }
  }

  if (-not $guid -and $create.Content) {
    $singular = if ($EntitySet.ToLower().EndsWith('s')) { $EntitySet.Substring(0, $EntitySet.Length - 1) } else { $EntitySet }
    $primaryIdPropName = ($singular + 'id').ToLower()
    $idProp = $create.Content.PSObject.Properties | Where-Object { $_.Name.ToLower() -eq $primaryIdPropName -and ("" + $_.Value) -match "^$guidRegex$" } | Select-Object -First 1
    if ($idProp) {
      $guid = $idProp.Value
      Write-Verbose "GUID extracted from primary id property '$($idProp.Name)': $guid"
    }
  }

  if (-not $guid -and $create.Content) {
    $idProp = $create.Content.PSObject.Properties | Where-Object { $_.Name -match 'id$' -and ("" + $_.Value) -match "^$guidRegex$" } | Select-Object -First 1
    if ($idProp) {
      $guid = $idProp.Value
      Write-Verbose "GUID extracted from first '*id' property '$($idProp.Name)': $guid"
    }
  }

  if (-not $guid) { throw "Could not determine created record id from response." }
  Write-Note "Created id: $guid"

  # 3) Retrieve
  # Use backtick to escape $select in the interpolated string to avoid PS variable expansion
  $getQuery = Get-EntityPath("/$EntitySet($guid)?`$select=name")
  Write-Note "Retrieving $EntitySet($guid)"
  $get = Invoke-DataverseGet -AccessToken $token.AccessToken -Url $Url -Query $getQuery -Verbose:$VerbosePreference
  if (-not $get.Success) { throw "Get failed: $($get.Error) | $($get.RawContent)" }
  Write-Verbose ("GET Content: " + ($get.RawContent | Out-String))

  # 4) Update
  $updatedName = "$name (Updated)"
  $patchBody = @{ name = $updatedName }
  $patchQuery = Get-EntityPath("/$EntitySet($guid)")
  Write-Note "Updating name to '$updatedName'"
  $patch = Invoke-DataversePatch -AccessToken $token.AccessToken -Url $Url -Query $patchQuery -Body $patchBody -Verbose:$VerbosePreference
  if (-not $patch.Success) { throw "Patch failed: $($patch.Error) | $($patch.RawContent)" }

  # Verify update
  $get2 = Invoke-DataverseGet -AccessToken $token.AccessToken -Url $Url -Query $getQuery -Verbose:$VerbosePreference
  if (-not $get2.Success) { throw "Get after patch failed: $($get2.Error) | $($get2.RawContent)" }
  $actualName = $get2.Content.name
  if ($actualName -ne $updatedName) {
    throw "Update verification failed. Expected '$updatedName', got '$actualName'"
  }
  Write-Note "Update verified"

  # 5) Delete
  $deleteQuery = Get-EntityPath("/$EntitySet($guid)")
  Write-Note "Deleting $EntitySet($guid)"
  $del = Invoke-DataverseDelete -AccessToken $token.AccessToken -Url $Url -Query $deleteQuery -Verbose:$VerbosePreference
  if (-not $del.Success) { throw "Delete failed: $($del.Error) | $($del.RawContent)" }

  Write-Host "Smoke test succeeded: $EntitySet($guid) created, read, updated, and deleted." -ForegroundColor Green
}
catch {
  Write-Error $_
}
