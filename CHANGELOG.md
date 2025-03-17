# Changelog

## v2.1.0
- Initial release of PipeDream PowerShell module
- Added Dataverse authentication functionality
  - Implemented `Get-DataverseAuthToken` command for obtaining authentication tokens
- Created module structure with public and private functions
- Added helper functions for token validation and management
- Implemented Basic Dataverse API Functions
  - Added `Invoke-DataverseRequest` private helper for standardized API requests
  - Implemented `Invoke-DataverseGet` for retrieving data from Dataverse
  - Implemented `Invoke-DataversePost` for creating records in Dataverse
  - Implemented `Invoke-DataversePatch` for updating existing records in Dataverse
  - Implemented `Invoke-DataverseDelete` for removing records from Dataverse