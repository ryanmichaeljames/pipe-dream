BeforeAll {
    # Import the module
    $ModulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\src\PipeDream\PipeDream.psd1"
    Import-Module $ModulePath -Force
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
        }
    }
}
