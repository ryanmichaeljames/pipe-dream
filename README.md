# PipeDream

PipeDream is a PowerShell module designed to facilitate deployment pipelines for Power Platform environments. It provides tools for authentication, data manipulation, and API interaction with Dataverse.

# Installation

## From PowerShell Gallery

```powershell
Install-Module -Name PipeDream -Scope CurrentUser
```

## Manual Installation

1. Clone this repository
2. Import the module:
    ```powershell
    Import-Module -Path "C:\path\to\pipe-dream\src\PipeDream\PipeDream.psm1"
    ```

# Usage

## Authentication

```powershell
$token = Get-DataverseAuthToken `
  -TenantId "00000000-0000-0000-0000-000000000000" `
  -Url "https://myorg.crm.dynamics.com" `
  -ClientId "00000000-0000-0000-0000-000000000000" `
  -ClientSecret "mySecret"
```

# Functions

## Get-DataverseAuthToken

Obtains an authentication token for Dataverse API access.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `TenantId` | string | :white_check_mark: | The Azure AD tenant ID |
| `Url` | string | :white_check_mark: | The URL of the Power Platform environment (for example: `https://myorg.crm.dynamics.com`) |
| `ClientId` | string | :white_check_mark: | The Application/Client ID for authentication |
| `ClientSecret` | string | :white_check_mark: | The Client secret for service principal authentication |

### Return Value

The function returns a PSCustomObject with the following properties:

| Property | Description |
|----------|-------------|
| `AccessToken` | The JWT access token for authenticating Dataverse API requests |
| `TokenType` | The token type, typically `Bearer` |
| `ExpiresIn` | The token validity duration in seconds |
| `ExpiresOn` | A DateTime object indicating when the token will expire |

# Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

# Roadmap

The following features are planned for future releases:
1. Token caching to minimize authentication requests
2. Automatic token refresh for long-running operations
3. Implementation of Dataverse Web API wrapper functions
4. Bulk data operations

# License

[MIT License](LICENSE)
