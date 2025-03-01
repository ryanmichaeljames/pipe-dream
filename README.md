# PipeDream

## Overview
PipeDream is a collection of tools that make interaction with the Power Platform, Azure DevOps, and PowerShell easier. The output is a PowerShell module that can easily be imported into PowerShell scripts and pipelines.

## Requirements
- PowerShell 5.1 or later

## Installation
To install PipeDream, download the [latest release](https://github.com/ryanmichaeljames/pipe-dream/releases), extract the release `.zip` file and import the module:
```powershell
# Import the module
Import-Module ./PipeDream.psd1 -AllowPrerelease
```

## Usage
Here is an example of how to use the functions in the PipeDream module:
```powershell
# Import the module
Import-Module PipeDream -AllowPrerelease

# Example function usage
$token = Get-DataverseToken `
    -ClientId '00000000-0000-0000-0000-000000000000' `
    -ClientSecret '00000000-0000-0000-0000-000000000000' `
    -TenantId '00000000-0000-0000-0000-000000000000'
```
