# PipeDream

PipeDream is a PowerShell module designed to facilitate deployment pipelines for Power Platform environments. It provides tools for authentication, data manipulation, and API interaction with Dataverse.

## Features

- Service principal authentication with Dataverse APIs
- Token caching and automatic refresh
- Simplified Dataverse Web API operations:
  - GET (data retrieval)
  - POST (record creation)
  - PATCH (record updates)
  - DELETE (record removal)
- Error handling and verbose logging

## Installation

### From PowerShell Gallery (Coming Soon)

```powershell
Install-Module -Name PipeDream -Scope CurrentUser
```

### Manual Installation

1. Clone this repository
2. Import the module:

```powershell
Import-Module -Path "C:\path\to\pipe-dream\src\PipeDream\PipeDream.psm1"
```

## Usage Examples

### Authentication

```powershell
# Authenticate to a Dataverse environment
$token = Get-DataverseAuthToken -EnvironmentUrl "https://myorg.crm.dynamics.com" `
                               -ClientId "00000000-0000-0000-0000-000000000000" `
                               -ClientSecret "mySecret" `
                               -TenantId "00000000-0000-0000-0000-000000000000"
```

### Working with Records

```powershell
# Retrieve records
$accounts = Invoke-DataverseGet -EnvironmentUrl "https://myorg.crm.dynamics.com" `
                               -RelativeUrl "/api/data/v9.2/accounts?$select=name,revenue&$top=10" `
                               -Token $token

# Create a new record
$newAccount = @{
    name = "Contoso Ltd."
    telephone1 = "555-0100"
    revenue = 10000000
}
$result = Invoke-DataversePost -EnvironmentUrl "https://myorg.crm.dynamics.com" `
                              -RelativeUrl "/api/data/v9.2/accounts" `
                              -Token $token `
                              -Body $newAccount

# Update an existing record
$accountUpdate = @{
    telephone1 = "555-0200"
    revenue = 15000000
}
Invoke-DataversePatch -EnvironmentUrl "https://myorg.crm.dynamics.com" `
                     -RelativeUrl "/api/data/v9.2/accounts(00000000-0000-0000-0000-000000000000)" `
                     -Token $token `
                     -Body $accountUpdate

# Delete a record
Invoke-DataverseDelete -EnvironmentUrl "https://myorg.crm.dynamics.com" `
                      -RelativeUrl "/api/data/v9.2/accounts(00000000-0000-0000-0000-000000000000)" `
                      -Token $token
```

## Available Functions

### Get-DataverseAuthToken

Obtains an authentication token for Dataverse API access.

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| EnvironmentUrl | string | Yes | The URL of the Power Platform environment (e.g., "https://myorg.crm.dynamics.com") |
| ClientId | string | Yes | The Application/Client ID for authentication |
| ClientSecret | string | Yes | The Client secret for service principal authentication |
| TenantId | string | Yes | The Azure AD tenant ID |

### Invoke-DataverseGet

Performs GET requests to retrieve data from Dataverse Web API.

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| EnvironmentUrl | string | Yes | The URL of the Power Platform environment |
| RelativeUrl | string | Yes | The API endpoint relative to the environment URL (e.g., "/api/data/v9.2/accounts") |
| Token | PSCustomObject | Yes | The authentication token object from Get-DataverseAuthToken |
| Headers | hashtable | No | Additional headers to include in the request |

### Invoke-DataversePost

Performs POST requests to create new records in Dataverse.

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| EnvironmentUrl | string | Yes | The URL of the Power Platform environment |
| RelativeUrl | string | Yes | The API endpoint relative to the environment URL |
| Token | PSCustomObject | Yes | The authentication token object from Get-DataverseAuthToken |
| Body | object | Yes | The request body object containing the data to send (automatically serialized to JSON) |
| Headers | hashtable | No | Additional headers to include in the request (defaults to empty hashtable) |
| ContentType | string | No | The content type for the request (defaults to "application/json") |

### Invoke-DataversePatch

Performs PATCH requests to update existing records in Dataverse.

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| EnvironmentUrl | string | Yes | The URL of the Power Platform environment |
| RelativeUrl | string | Yes | The API endpoint relative to the environment URL, including record ID |
| Token | PSCustomObject | Yes | The authentication token object from Get-DataverseAuthToken |
| Body | object | Yes | The request body object containing the data to update (automatically serialized to JSON) |
| Headers | hashtable | No | Additional headers to include in the request (defaults to empty hashtable) |
| ContentType | string | No | The content type for the request (defaults to "application/json") |

### Invoke-DataverseDelete

Performs DELETE requests to remove records from Dataverse.

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| EnvironmentUrl | string | Yes | The URL of the Power Platform environment |
| RelativeUrl | string | Yes | The API endpoint relative to the environment URL, including record ID |
| Token | PSCustomObject | Yes | The authentication token object from Get-DataverseAuthToken |
| Headers | hashtable | No | Additional headers to include in the request (defaults to empty hashtable) |

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

[MIT License](LICENSE)
