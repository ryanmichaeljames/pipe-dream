![PipeDream Logo](/assets/logo_banner.png)

# PipeDream

[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=ryanmichaeljames_pipe-dream&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=ryanmichaeljames_pipe-dream)
[![Security Rating](https://sonarcloud.io/api/project_badges/measure?project=ryanmichaeljames_pipe-dream&metric=security_rating)](https://sonarcloud.io/summary/new_code?id=ryanmichaeljames_pipe-dream)
[![Vulnerabilities](https://sonarcloud.io/api/project_badges/measure?project=ryanmichaeljames_pipe-dream&metric=vulnerabilities)](https://sonarcloud.io/summary/new_code?id=ryanmichaeljames_pipe-dream)
[![Tests](https://github.com/ryanmichaeljames/pipe-dream/actions/workflows/tests.yml/badge.svg)](https://github.com/ryanmichaeljames/pipe-dream/actions/workflows/tests.yml)

![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/PipeDream)
![GitHub commits since latest release](https://img.shields.io/github/commits-since/ryanmichaeljames/pipe-dream/latest)
![PowerShell Gallery Downloads](https://img.shields.io/powershellgallery/dt/PipeDream)
![GitHub License](https://img.shields.io/github/license/ryanmichaeljames/pipe-dream)

> A PowerShell module for automating Power Platform deployments

## Installation

### From PowerShell Gallery

```powershell
Install-Module -Name PipeDream
```

### Manual Installation

Clone this repository and import the module:

```powershell
Import-Module -Path "C:\path\to\pipe-dream\src\PipeDream\PipeDream.psm1"
```

## Usage

### Authentication

```powershell
$token = Get-DataverseAuthToken `
  -TenantId "00000000-0000-0000-0000-000000000000" `
  -Url "https://ORG.crm.dynamics.com" `
  -ClientId "00000000-0000-0000-0000-000000000000" `
  -ClientSecret "CLIENT_SECRET"
```

### Azure DevOps Pipeline

```yml
steps:

# Install Power Platform Build Tools
- task: microsoft-IsvExpTools.PowerPlatform-BuildTools.tool-installer.PowerPlatformToolInstaller@2
  inputs:
    AddToolsToPath: true

# Set Power Platform connection variables
- task: microsoft-IsvExpTools.PowerPlatform-BuildTools.set-connection-variables.PowerPlatformSetConnectionVariables@2
  inputs:
    authenticationType: PowerPlatformSPN
    PowerPlatformSPN: SERVICE_CONNECTION

# Use PipeDream to get auth token
- powershell: |
    Install-Module PipeDream -Force
    Import-Module PipeDream -Force
    
    # Get authentication token using variables set by PowerPlatformSetConnectionVariables
    $token = Get-DataverseAuthToken `
      -TenantId "$(PowerPlatformSetConnectionVariables.BuildTools.TenantId)" `
      -Url "$(BuildTools.EnvironmentUrl)" `
      -ClientId "$(PowerPlatformSetConnectionVariables.BuildTools.ApplicationId)" `
      -ClientSecret "$(PowerPlatformSetConnectionVariables.BuildTools.ClientSecret)"
```

## Functions

### Get-DataverseAuthToken

Obtains an authentication token for Dataverse API access.

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `TenantId` | string | :white_check_mark: | The Azure AD tenant ID |
| `Url` | string | :white_check_mark: | The URL of the Power Platform environment (for example: `https://ORG.crm.dynamics.com`) |
| `ClientId` | string | :white_check_mark: | The Application/Client ID for authentication |
| `ClientSecret` | string | :white_check_mark: | The Client secret for service principal authentication |

#### Return Value

The function returns a PSCustomObject with the following properties:

| Property | Description |
|----------|-------------|
| `AccessToken` | The JWT access token for authenticating Dataverse API requests |
| `TokenType` | The token type, typically `Bearer` |
| `ExpiresIn` | The token validity duration in seconds |
| `ExpiresOn` | A DateTime object indicating when the token will expire |

### Invoke-DataverseGet

Performs a GET request to the Dataverse API.

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `AccessToken` | string | :white_check_mark: | The authentication token string (access token) obtained from Get-DataverseAuthToken |
| `Url` | string | :x: | The base URL of the Power Platform environment (for example: `https://ORG.crm.dynamics.com`). If not provided, the function will extract it from the AccessToken's audience (`aud`) claim |
| `Query` | string | :white_check_mark: | The OData query to append to the base URL (for example: `/api/data/v9.2/accounts`) |
| `Headers` | hashtable | :x: | Additional headers to include in the request |

#### Return Value

The function returns a PSCustomObject with the following properties:

| Property | Description |
|----------|-------------|
| `StatusCode` | HTTP status code of the response |
| `Headers` | Response headers |
| `Content` | Parsed response content (if JSON) |
| `RawContent` | Raw response content string |
| `Success` | Boolean indicating if the request was successful |
| `Error` | Error message (only if Success is $false) |

#### Example Usage

```powershell
$authResult = Get-DataverseAuthToken `
  -TenantId "00000000-0000-0000-0000-000000000000" `
  -Url "https://ORG.crm.dynamics.com" `
  -ClientId "00000000-0000-0000-0000-000000000000" `
  -ClientSecret "CLIENT_SECRET"
  
# Using the URL from the token (extracted from aud claim)
$result = Invoke-DataverseGet `
  -AccessToken $authResult.AccessToken `
  -Query "/api/data/v9.2/accounts"

# Access the returned data
$accounts = $result.Content.value
```

### Invoke-DataversePost

Performs a POST request to the Dataverse API to create new records.

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `AccessToken` | string | :white_check_mark: | The authentication token string (access token) obtained from Get-DataverseAuthToken |
| `Url` | string | :x: | The base URL of the Power Platform environment (for example: `https://ORG.crm.dynamics.com`). If not provided, the function will extract it from the AccessToken's audience (`aud`) claim |
| `Query` | string | :white_check_mark: | The OData query to append to the base URL (for example: `/api/data/v9.2/accounts`) |
| `Body` | object | :white_check_mark: | The request body as a hashtable or PSObject containing the data for the new record |
| `Headers` | hashtable | :x: | Additional headers to include in the request |

#### Return Value

The function returns a PSCustomObject with the following properties:

| Property | Description |
|----------|-------------|
| `StatusCode` | HTTP status code of the response |
| `Headers` | Response headers including the OData-EntityId header with the URL of the created record |
| `Content` | Parsed response content (if JSON) |
| `RawContent` | Raw response content string |
| `Success` | Boolean indicating if the request was successful |
| `Error` | Error message (only if Success is $false) |

#### Example Usage

```powershell
$authResult = Get-DataverseAuthToken `
  -TenantId "00000000-0000-0000-0000-000000000000" `
  -Url "https://ORG.crm.dynamics.com" `
  -ClientId "00000000-0000-0000-0000-000000000000" `
  -ClientSecret "CLIENT_SECRET"

$body = @{
    name = "New Account Name"
    telephone1 = "555-123-4567"
    accountcategorycode = 1
}
  
# Using the URL from the token (extracted from aud claim)
$result = Invoke-DataversePost `
  -AccessToken $authResult.AccessToken `
  -Query "/api/data/v9.2/accounts" `
  -Body $body

# Check if creation was successful and get the new record ID
if ($result.Success) {
    $entityId = $result.Headers["OData-EntityId"]
    Write-Output "Record created successfully with ID: $entityId"
    
    # If return=representation was used in the request, access the returned record
    if ($result.Content) {
        $newRecord = $result.Content
        Write-Output "New record details: $($newRecord | ConvertTo-Json)"
    }
}
```

### Invoke-DataversePatch

Performs a PATCH request to the Dataverse API to update existing records.

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `AccessToken` | string | :white_check_mark: | The authentication token string (access token) obtained from Get-DataverseAuthToken |
| `Url` | string | :x: | The base URL of the Power Platform environment (for example: `https://ORG.crm.dynamics.com`). If not provided, the function will extract it from the AccessToken's audience (`aud`) claim |
| `Query` | string | :white_check_mark: | The OData query to append to the base URL (for example: `/api/data/v9.2/accounts(00000000-0000-0000-0000-000000000000)`) |
| `Body` | object | :white_check_mark: | The request body as a hashtable or PSObject containing the fields to update |
| `Headers` | hashtable | :x: | Additional headers to include in the request |

#### Return Value

The function returns a PSCustomObject with the following properties:

| Property | Description |
|----------|-------------|
| `StatusCode` | HTTP status code of the response |
| `Headers` | Response headers |
| `Success` | Boolean indicating if the request was successful |
| `Error` | Error message (only if Success is $false) |

#### Example Usage

```powershell
$authResult = Get-DataverseAuthToken `
  -TenantId "00000000-0000-0000-0000-000000000000" `
  -Url "https://ORG.crm.dynamics.com" `
  -ClientId "00000000-0000-0000-0000-000000000000" `
  -ClientSecret "CLIENT_SECRET"

$body = @{
    name = "Updated Account Name"
    telephone1 = "555-123-4567"
}
  
# Using the URL from the token (extracted from aud claim) 
$result = Invoke-DataversePatch `
  -AccessToken $authResult.AccessToken `
  -Query "/api/data/v9.2/accounts(00000000-0000-0000-0000-000000000000)" `
  -Body $body

# Check if update was successful
if ($result.Success) {
    Write-Output "Record updated successfully!"
}
```

### Invoke-DataverseDelete

Performs a DELETE request to the Dataverse API.

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `AccessToken` | string | :white_check_mark: | The authentication token string (access token) obtained from Get-DataverseAuthToken |
| `Url` | string | :x: | The base URL of the Power Platform environment (for example: `https://ORG.crm.dynamics.com`). If not provided, the function will extract it from the AccessToken's audience (`aud`) claim |
| `Query` | string | :white_check_mark: | The OData query to append to the base URL (for example: `/api/data/v9.2/accounts(00000000-0000-0000-0000-000000000000)`) |
| `Headers` | hashtable | :x: | Additional headers to include in the request |

#### Return Value

The function returns a PSCustomObject with the following properties:

| Property | Description |
|----------|-------------|
| `StatusCode` | HTTP status code of the response |
| `Headers` | Response headers (if available) |
| `Success` | Boolean indicating if the request was successful |
| `Error` | Error message (only if Success is $false) |

#### Example Usage

```powershell
$authResult = Get-DataverseAuthToken `
  -TenantId "00000000-0000-0000-0000-000000000000" `
  -Url "https://ORG.crm.dynamics.com" `
  -ClientId "00000000-0000-0000-0000-000000000000" `
  -ClientSecret "CLIENT_SECRET"
  
# Using the URL from the token (extracted from aud claim)
$result = Invoke-DataverseDelete `
  -AccessToken $authResult.AccessToken `
  -Query "/api/data/v9.2/accounts(00000000-0000-0000-0000-000000000000)"

# Check if deletion was successful
if ($result.Success) {
    Write-Output "Record deleted successfully!"
}
```

## Contributing

Contributions are welcome!

### How to

- Fork the repository
- Create a feature or bugfix branch
- Submit a pull request to the `main` branch

### Pester Tests

If you are adding or modifying code, include Pester tests to cover your changes.

To run tests locally:

```powershell
Invoke-Pester -Path ./tests
```

## Roadmap

The following features are planned for future releases:
1. Token caching to minimize authentication requests
2. Automatic token refresh for long-running operations
3. Implementation of Dataverse Web API wrapper functions
4. Bulk data operations

## Attributions

[![SonarQube Cloud](https://sonarcloud.io/images/project_badges/sonarcloud-light.svg)](https://sonarcloud.io/summary/new_code?id=ryanmichaeljames_pipe-dream)