BeforeAll {
    $modulePath = "$PSScriptRoot\..\..\src\PipeDream\PipeDream.psm1"
    Import-Module $modulePath -Force
}

Describe "Invoke-DataversePost" {
    BeforeEach {
        # Default successful mock
        Mock Invoke-WebRequest -ModuleName PipeDream {
            [pscustomobject]@{
                StatusCode = 201
                Headers    = @{ 'OData-EntityId' = 'https://org.crm.dynamics.com/api/data/v9.2/accounts(11111111-1111-1111-1111-111111111111)' }
                Content    = '{"accountid":"11111111-1111-1111-1111-111111111111","name":"Acme"}'
            }
        }
    }

    It "Parses JSON content and returns success on 201" {
    $AccessToken = 'tok'
    $Url = 'https://org.crm.dynamics.com'
    $Body = @{ name = 'Acme' }
    $res = Invoke-DataversePost -AccessToken $AccessToken -Url $Url -Query '/api/data/v9.2/accounts' -Body $Body
        $res.Success | Should -BeTrue
        $res.StatusCode | Should -Be 201
        $res.Content.name | Should -Be 'Acme'
        $res.Headers.'OData-EntityId' | Should -Match 'accounts\('
    }

    It "Merges custom headers (Prefer)" {
    $AccessToken = 'tok'
    $Url = 'https://org.crm.dynamics.com'
    $Body = @{ name = 'Acme' }
    $null = Invoke-DataversePost -AccessToken $AccessToken -Url $Url -Query '/api/data/v9.2/accounts' -Body $Body -Headers @{ Prefer = 'return=representation' }
        Should -Invoke Invoke-WebRequest -ModuleName PipeDream -ParameterFilter {
            $Headers['Prefer'] -eq 'return=representation' -and $Headers['Authorization'] -like 'Bearer *'
        }
    }

    It "Returns structured error on failure" {
        Mock Invoke-WebRequest -ModuleName PipeDream { throw (New-Object System.Exception 'HTTP 400') }
    $AccessToken = 'tok'
    $Url = 'https://org.crm.dynamics.com'
    $Body = @{ name = 'Acme' }
    $res = Invoke-DataversePost -AccessToken $AccessToken -Url $Url -Query '/api/data/v9.2/accounts' -Body $Body
        $res.Success | Should -BeFalse
        $res.Error | Should -Match 'HTTP 400'
    }
}
