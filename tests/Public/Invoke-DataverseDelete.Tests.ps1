BeforeAll {
    $modulePath = "$PSScriptRoot\..\..\src\PipeDream\PipeDream.psm1"
    Import-Module $modulePath -Force
}

Describe "Invoke-DataverseDelete" {
    BeforeEach {
        # Default successful mock
        Mock Invoke-WebRequest -ModuleName PipeDream {
            [pscustomobject]@{
                StatusCode = 204
                Headers    = @{}
                Content    = ''
            }
        }
    }

    It "Returns success on 204 No Content" {
        $AccessToken = 'tok'
        $Url = 'https://org.crm.dynamics.com'
        $res = Invoke-DataverseDelete -AccessToken $AccessToken -Url $Url -Query '/api/data/v9.2/accounts(11111111-1111-1111-1111-111111111111)'
        $res.Success | Should -BeTrue
        $res.StatusCode | Should -Be 204
    }

    It "Merges custom headers (If-Match)" {
        $AccessToken = 'tok'
        $Url = 'https://org.crm.dynamics.com'
        $null = Invoke-DataverseDelete -AccessToken $AccessToken -Url $Url -Query '/api/data/v9.2/accounts(11111111-1111-1111-1111-111111111111)' -Headers @{ 'If-Match' = '*' }
        Should -Invoke Invoke-WebRequest -ModuleName PipeDream -ParameterFilter {
            $Headers['If-Match'] -eq '*' -and $Headers['Authorization'] -like 'Bearer *'
        }
    }

    It "Returns structured error on failure" {
        Mock Invoke-WebRequest -ModuleName PipeDream { throw (New-Object System.Exception 'HTTP 404') }
        $AccessToken = 'tok'
        $Url = 'https://org.crm.dynamics.com'
        $res = Invoke-DataverseDelete -AccessToken $AccessToken -Url $Url -Query '/api/data/v9.2/accounts(11111111-1111-1111-1111-111111111111)'
        $res.Success | Should -BeFalse
        $res.Error | Should -Match 'HTTP 404'
    }
}
