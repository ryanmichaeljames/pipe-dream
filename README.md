<a href="https://gitmoji.dev">
  <img
    src="https://img.shields.io/badge/gitmoji-%20😜%20😍-FFDD67.svg?style=flat-square"
    alt="Gitmoji"
  />
</a>

# PipeDream

PipeDream is a collection of PowerShell tools that make interaction with the Power Platform, Azure DevOps easier.

## Installation

```powershell
# Install the module
Install-Module -Name PipeDream
```

## Import Module

```powershell
# Import the module
Import-Module -Name PipeDream
```

## Get-DataverseAuthToken

Obtains an OAuth authentication token for Microsoft Dataverse using client credentials flow. The returned token can be used to authenticate API requests to Dataverse environments.

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| TenantId | String | The tenant ID of the Azure Active Directory. |
| EnvironmentUrl | String | The URL of the Dataverse environment. For example: `https://your-org.crm.dynamics.com`. |
| ClientId | String | The client ID of the application. |
| ClientSecret | String | The client secret of the application. |

### Examples

```powershell
# Get an authentication token
Get-DataverseAuthToken `
  -TenantId "00000000-0000-0000-0000-000000000000" `
  -EnvironmentUrl "https://your-org.crm.dynamics.com" `
  -ClientId "00000000-0000-0000-0000-000000000000" `
  -ClientSecret "your-client-secret"

# access_token  : eyJ0eXAiOiJKV1QiLCJhbGciOi...
# token_type    : Bearer
# expires_in    : 3599
# expires_at    : 2025-03-02T02:17:16Z
# resource      : https://your-ord.crm.dynamics.com
```

## New-DataverseBatchRequest

Creates a request object that can be used in batch operations with `Invoke-DataverseBatchRequest`.

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| Method    | String | The HTTP method for the request . Accepted values: `GET`, `POST`, `PATCH`, `DELETE` and `PUT`. |
| Path      | String | The relative path for the request. For example: `/api/data/v9.2/accounts`. |
| Body      | Object | **Optional:** The request body for `POST`, `PATCH`, or `PUT` operations. |
| ContentId | String | **Optional:** Content ID for referencing within changesets. |
| Headers   | Hashtable | **Optional:** additional headers for the request. |


### Examples
```powershell
# Create POST request
$request1 = New-DataverseBatchRequest `
  -Method "POST" `
  -Path "/api/data/v9.2/accounts" `
  -Body @{ name = "Evil Corp" } `
  -ContentId "1"
```

```powershell
# Create GET request
$request1 = New-DataverseBatchRequest `
  -Method "GET" `
  -Path "/api/data/v9.2/accounts(00000000-0000-0000-0000-000000000000)"
```

## Invoke-DataverseBatchRequest

Executes multiple Dataverse API requests in a single HTTP request, improving performance and enabling transaction-like operations with changesets.

[Reference URIs](https://learn.microsoft.com/en-us/power-apps/developer/data-platform/webapi/execute-batch-operations-using-web-api#reference-uris-in-an-operation) are supported.

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| Token     | PSCustomObject | The authentication token object obtained from Get-DataverseAuthToken. This object must contain `access_token`, `token_type`, `expires_in`, `expires_at`, and `resource` properties. |
| Requests  | Array | An array of request objects. Each request should have `Method`, `Path`, and optionally `Body`, `Headers`, and `ContentId` properties. |
| UseChangeset | Switch | When specified, all requests are included in a single changeset, making them transactional. All operations will succeed or fail together. |
| ContinueOnError | Switch | When specified, batch execution will continue even if individual requests fail. |

### Examples

```powershell
# Create a batch that updates a record and retrieves it in a single operation
$request1 = New-DataverseBatchRequest `
  -Method "PUT" `
  -Path "/api/data/v9.2/accounts(00000000-0000-0000-0000-000000000000)" `
  -Body @{ name = "Evil Corp" }

$request2 = New-DataverseBatchRequest `
  -Method "GET" `
  -Path "/api/data/v9.2/accounts(00000000-0000-0000-0000-000000000000)"

# Use the requests in a batch operation
Invoke-DataverseBatchRequest -Token "AUTH_TOKEN" -Requests @($request1, $request2)
```

```powershell
# Create a changeset that references the result of the first request in subsequent requests
$request1 = New-DataverseBatchRequest `
  -Method "POST" `
  -Path "/api/data/v9.2/accounts" `
  -Body @{ name = "Evil Corp" } `
  -ContentId "1"

$request2 = New-DataverseBatchRequest `
  -Method "POST" `
  -Path "/api/data/v9.2/contacts" `
  -Body @{
    firstname = "Phillip"
    "parentcustomerid_account@odata.bind" = "$1"  # References the account created in request with ContentId "1"
  }

# Use the requests in a batch operation with changeset enabled
Invoke-DataverseBatchRequest -Token "AUTH_TOKEN" -Requests @($request1, $request2) -UseChangeset
```

```powershell
# Create requests using hash tables directly
$requests = @(
    @{
        Method = "GET"
        Path = "/api/data/v9.2/accounts"
    },
    @{
        Method = "GET"
        Path = "/api/data/v9.2/contacts"
    }
)

Invoke-DataverseBatchRequest -Token "AUTH_TOKEN" -Requests $requests
```

## Pipeline Usage

PipeDream can be used in Azure DevOps pipelines and works with the [Microsoft Power Platform Build Tools](https://learn.microsoft.com/en-us/power-platform/alm/devops-build-tool-tasks).

### Example

This example shows how to use PipeDream in an Azure DevOps pipeline to fetch a Dataverse authentication token and perform batch operations:

```yaml
# azure-pipelines.yml
trigger:
- main

pool:
  vmImage: 'windows-latest'

steps:
# Install Power Platform Build Tools
- task: microsoft-IsvExpTools.PowerPlatform-BuildTools.tool-installer.PowerPlatformToolInstaller@2
  displayName: 'Install Power Platform Tools'
  inputs:
    AddToolsToPath: true

# Set Power Platform Connection Variables
- task: microsoft-IsvExpTools.PowerPlatform-BuildTools.set-connection-variables.PowerPlatformSetConnectionVariables@2
  displayName: 'Set Power Platform Connection Variables'
  inputs:
    authenticationType: PowerPlatformSPN
    PowerPlatformSPN: "power-platform-service-connection"

# Use PipeDream to interact with Dataverse
- pwsh: |
    # Install PipeDream module
    Install-Module -Name PipeDream -Force -Scope CurrentUser
    Import-Module -Name PipeDream -Force

    # Get authentication token using connection variables from Build Tools
    $token = Get-DataverseAuthToken `
      -TenantId "$(PowerPlatformSetConnectionVariables.BuildTools.TenantId)" `
      -EnvironmentUrl "$(BuildTools.EnvironmentUrl)" `
      -ClientId "$(PowerPlatformSetConnectionVariables.BuildTools.ApplicationId)" `
      -ClientSecret "$(PowerPlatformSetConnectionVariables.BuildTools.ClientSecret)"
    
    Write-Host "Authentication token obtained successfully. Expires at: $($token.expires_at)"
    
    # Example of using the token for batch operations
    $requests = @(
        $(New-DataverseBatchRequest -Method "GET" -Path "/api/data/v9.2/accounts?$top=5"),
        $(New-DataverseBatchRequest -Method "GET" -Path "/api/data/v9.2/contacts?$top=5")
    )
    
    $results = Invoke-DataverseBatchRequest -Token $token -Requests $requests
    
    # Process results
    Write-Host "Retrieved $($results[0].value.Count) accounts and $($results[1].value.Count) contacts"
  displayName: 'Execute PipeDream Operations'
```

## License

The code is available under the [MIT](https://github.com/ryanmichaeljames/pipe-dream/blob/master/LICENSE.md) license.