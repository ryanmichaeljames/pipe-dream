BeforeAll {
    $modulePath = "$PSScriptRoot\..\..\src\PipeDream\PipeDream.psm1"
    Import-Module $modulePath -Force
}

Describe "Invoke-DataverseHttp (private)" {
    BeforeEach {
        Mock Invoke-WebRequest -ModuleName PipeDream {
            [pscustomobject]@{
                StatusCode = 200
                Headers    = @{ 'x-ms-service-request-id' = 'req-1'; 'x-ms-client-request-id' = 'corr-1' }
                Content    = '{"ok":true}'
            }
        }
    }

    It "Normalizes URL and query and returns output shape" {
        $res = InModuleScope PipeDream {
            Invoke-DataverseHttp -Method GET -AccessToken 'tok' -Url 'https://org.crm.dynamics.com/' -Query 'api/data/v9.2/WhoAmI'
        }
        $res.Success | Should -BeTrue
        $res.StatusCode | Should -Be 200
        $res.Content.ok | Should -BeTrue
        $res.RequestId | Should -Be 'req-1'
        $res.CorrelationId | Should -Be 'corr-1'
    }

    It "Adds Content-Type and serializes body when provided" {
        $null = InModuleScope PipeDream {
            Invoke-DataverseHttp -Method POST -AccessToken 'tok' -Url 'https://org.crm.dynamics.com' -Query '/api/data/v9.2/accounts' -Body @{ name = 'x' }
        }
        Should -Invoke Invoke-WebRequest -ModuleName PipeDream -ParameterFilter { $Headers['Content-Type'] -eq 'application/json' -and $Method -eq 'POST' }
    }
}
