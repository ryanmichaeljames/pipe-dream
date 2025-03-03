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

```powershell
# Get an authentication token
Get-DataverseAuthToken `
  -TenantId "00000000-0000-0000-0000-000000000000" `
  -ResourceUrl "https://your-org.crm.dynamics.com" `
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

```powershell
# Create a batch that updates a record and retrieves it in a single operation
# Update an account
$request1 = New-DataverseBatchRequest `
  -Method "PUT" `
  -Path "/api/data/v9.2/accounts(00000000-0000-0000-0000-000000000000)" `
  -Body @{ name = "Evil Corp" }

# Get the account
$request2 = New-DataverseBatchRequest `
  -Method "GET" `
  -Path "/api/data/v9.2/accounts(00000000-0000-0000-0000-000000000000)"

# Use the requests in a batch operation
Invoke-DataverseBatchRequest -Token "AUTH_TOKEN" -Requests @($request1, $request2)
```

[Reference URIs](https://learn.microsoft.com/en-us/power-apps/developer/data-platform/webapi/execute-batch-operations-using-web-api#reference-uris-in-an-operation) are supported: 

```powershell
# Create a changeset that references the result of the first request in subsequent requests
# Create an account
$request1 = New-DataverseBatchRequest `
  -Method "POST" `
  -Path "/api/data/v9.2/accounts" `
  -Body @{ name = "Evil Corp" } `
  -ContentId "1"

# Create a contact and links it to the newly created account using $1 reference syntax
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