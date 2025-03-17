# Script module for PipeDream
# Module for facilitating deployment pipelines for Power Platform environments

#Region Import Functions
Write-Verbose "Importing functions for PipeDream module..."

# Get all script files in the Public folder and its subfolders
$publicFunctions = @(Get-ChildItem -Path $PSScriptRoot\Public -Recurse -Include "*.ps1" -ErrorAction SilentlyContinue)

# Get all script files in the Private folder and its subfolders
$privateFunctions = @(Get-ChildItem -Path $PSScriptRoot\Private -Recurse -Include "*.ps1" -ErrorAction SilentlyContinue)

# Import all private function scripts first
foreach ($function in $privateFunctions) {
    try {
        Write-Verbose "Importing private function: $($function.BaseName)"
        . $function.FullName
    }
    catch {
        Write-Error "Failed to import private function $($function.FullName): $_"
    }
}

# Import all public function scripts and add to export list
$functionsToExport = @()
foreach ($function in $publicFunctions) {
    try {
        Write-Verbose "Importing public function: $($function.BaseName)"
        . $function.FullName
        $functionsToExport += $function.BaseName
    }
    catch {
        Write-Error "Failed to import public function $($function.FullName): $_"
    }
}
#EndRegion Import Functions

# Export public functions
Export-ModuleMember -Function $functionsToExport