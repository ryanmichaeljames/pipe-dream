BeforeAll {
    $modulePath = "$PSScriptRoot\..\..\src\PipeDream\PipeDream.psm1"
    Import-Module $modulePath -Force
}

Describe "Invoke-DataverseGet" {
    BeforeEach {
        # Default mock returns 200 success with simple JSON
        Mock Invoke-WebRequest -ModuleName PipeDream {
            return [pscustomobject]@{
                StatusCode = 200
                Headers    = @{ 'x-test' = 'ok' }
                Content    = '{"value":[{"name":"n1"}]}'
            }
        }
        # Provide a deterministic access token
        $AccessToken = 'tok'
        $Url = 'https://org.crm.dynamics.com'
    }

    It "Requires Url parameter (no derivation)" {
        { Invoke-DataverseGet -AccessToken $AccessToken -Url '' -Query '/api/data/v9.2/WhoAmI' } | Should -Throw
    }

    It "Builds full URL and returns parsed JSON content on success" {
        $res = Invoke-DataverseGet -AccessToken $AccessToken -Url $Url -Query '/api/data/v9.2/accounts?$top=1'
        $res.Success | Should -BeTrue
        $res.StatusCode | Should -Be 200
        $res.Headers['x-test'] | Should -Be 'ok'
        $res.Content.value[0].name | Should -Be 'n1'
    }

    It "Merges custom headers" {
        $null = Invoke-DataverseGet -AccessToken $AccessToken -Url $Url -Query '/q' -Headers @{ 'Prefer' = 'odata.maxpagesize=1' }
        Should -Invoke Invoke-WebRequest -ModuleName PipeDream -ParameterFilter {
            $Headers['Prefer'] -eq 'odata.maxpagesize=1' -and $Headers['Authorization'] -like 'Bearer *'
        }
    }

    It "Returns structured error on HTTP failure" {
        # Simulate a failure; function should catch and return Success=$false
        Mock Invoke-WebRequest -ModuleName PipeDream { throw (New-Object System.Exception 'HTTP 404') }
        $res = Invoke-DataverseGet -AccessToken $AccessToken -Url $Url -Query '/x'
        $res.Success | Should -BeFalse
        $res.Error   | Should -Match 'HTTP 404'
    }
}
