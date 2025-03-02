# PipeDream

PipeDream is a collection of PowerShell tools that make interaction with the Power Platform, Azure DevOps easier.

## Installation
```powershell
# Install the module
Install-Module -Name PipeDream
```

## Usage

### Import Module
```powershell
# Import the module
Import-Module -Name PipeDream
```

### Get-DataverseAuthToken
```powershell
# Get an authentication token for Dataverse
$authToken = Get-DataverseAuthToken `
  -TenantId "00000000-0000-0000-0000-000000000000" `
  -ResourceUrl "https://your-org.crm.dynamics.com" `
  -ClientId "00000000-0000-0000-0000-000000000000" `
  -ClientSecret "your-client-secret"

# AccessToken : eyJ0eXAiOiJKV1QiLCJhbGciOi...
# TokenType   : Bearer
# ExpiresIn   : 3599
# ExpiresAt   : 2025-03-02T02:17:16Z
# Resource    : https://ORG.crm6.dynamics.com
```
