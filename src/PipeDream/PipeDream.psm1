# Import all public functions (from the root instead of Public folder)
Get-ChildItem -Path $PSScriptRoot\scripts -Filter *.ps1 | ForEach-Object { . $_.FullName }
