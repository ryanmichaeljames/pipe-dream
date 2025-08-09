# Changelog

## v4.3.0-alpha
- Refactor HTTP logic and add private helpers for Dataverse
- Improve error handling in Dataverse functions

## v4.2.1
- Improved error handling
- Added unit tests:
  - `Invoke-DataverseGet`
  - `Invoke-DataversePost`
  - `Invoke-DataversePatch`
  - `Invoke-DataverseDelete`
  - `Get-UrlFromAccessToken`
- Updated `Get-DataverseAuthToken` unit tests
- Added exact exported surface and manifest checks (name, version, RootModule) to tests

## v4.2.0
- Added Dataverse HTTP functions:
  - `Invoke-DataverseGet`
  - `Invoke-DataversePost`
  - `Invoke-DataversePatch`
  - `Invoke-DataverseDelete`
- Added ability to get the Dataverse URL from the bearer token

## v4.1.0
- Initial release of PipeDream PowerShell module v4
- Like Star Wars Episodes I, II and III we dont talk about v1, v2 and v3