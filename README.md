# PipeDream

## Overview
PipeDream is a collection of tools that make interaction with the Power Platform, Azure DevOps, and PowerShell easier. The output is a PowerShell module that can easily be imported into PowerShell scripts and pipelines.

## Requirements
- PowerShell 5.1 or later

## Installation

To install PipeDream, download the [latest release](https://github.com/ryanmichaeljames/pipe-dream/releases), extract the release `.zip`, and import the module:
```powershell
# Import the module
Import-Module ./PipeDream_v0.0.1-alpha/PipeDream.psd1 
```

## Usage

### Get-DataverseAuthToken

```powershell
# Get authentication token
$token = Get-DataverseAuthToken `
    -TenantId "00000000-0000-0000-0000-000000000000" `
    -EnvironmentUrl "https://ORG.crm.dynamics.com" `
    -ClientId "00000000-0000-0000-0000-000000000000" `
    -ClientSecret "00000000-0000-0000-0000-000000000000"

# AccessToken : eyJ0eXAiOiJKV1QiLCJhbGciOi...
# TokenType   : Bearer
# ExpiresIn   : 3599
# ExpiresAt   : 2025-03-02T02:17:16Z
# Resource    : https://ORG.crm.dynamics.com
```