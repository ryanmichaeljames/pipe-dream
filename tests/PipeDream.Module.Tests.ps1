BeforeAll {
    # Import the module
    $ModulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\src\PipeDream\PipeDream.psd1"
    Import-Module $ModulePath -Force
    # Read the manifest for metadata checks
    $ManifestData = Import-PowerShellDataFile -Path $ModulePath
}

Describe "PipeDream Module Tests" {
    Context "Module Loading" {
        It "Should load the module without errors" {
            { Import-Module $ModulePath -Force } | Should -Not -Throw
        }

        It "Should export the expected functions" {
            $expectedFunctions = @(
                'Get-DataverseAuthToken',
                'Invoke-DataverseDelete',
                'Invoke-DataverseGet',
                'Invoke-DataversePatch',
                'Invoke-DataversePost'
            )

            $exportedFunctions = (Get-Module PipeDream).ExportedFunctions.Keys
            
            foreach ($function in $expectedFunctions) {
                $exportedFunctions | Should -Contain $function
            }

            # No unexpected extras: exact match of exported surface
            $exportedFunctions.Count | Should -Be $expectedFunctions.Count
            foreach ($function in $exportedFunctions) {
                $expectedFunctions | Should -Contain $function
            }
        }
    }

    Context "Manifest metadata" {
        It "Should have correct module name and version" {
            $mod = Get-Module PipeDream
            $mod | Should -Not -BeNullOrEmpty
            $mod.Name | Should -Be 'PipeDream'
            $mod.Version.ToString() | Should -Be $ManifestData.ModuleVersion
        }

        It "Manifest should point to the correct RootModule file" {
            $ManifestData.RootModule | Should -Be 'PipeDream.psm1'
            $rootPath = Join-Path -Path (Split-Path -Path $ModulePath -Parent) -ChildPath $ManifestData.RootModule
            Test-Path $rootPath | Should -BeTrue
        }
    }
}
