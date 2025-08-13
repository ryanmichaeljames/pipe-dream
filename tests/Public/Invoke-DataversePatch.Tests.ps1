BeforeAll {
    $modulePath = "$PSScriptRoot\..\..\src\PipeDream\PipeDream.psm1"
    Import-Module $modulePath -Force
}

Describe "Invoke-DataversePatch" {
    BeforeEach {
        # Default successful mock
        Mock Invoke-WebRequest -ModuleName PipeDream {
            [pscustomobject]@{
                StatusCode = 204
                Headers    = @{ 'ETag' = 'W/"12345"' }
                Content    = ''
            }
        }
    }

    It "Requires Url parameter (no derivation)" {
        $AccessToken = 'tok'
        $Body = @{ name = 'x' }
        { Invoke-DataversePatch -AccessToken $AccessToken -Url '' -Query '/api/data/v9.2/accounts(11111111-1111-1111-1111-111111111111)' -Body $Body } | Should -Throw
    }

    It "Returns success on 204 No Content" {
        $AccessToken = 'tok'
        $Url = 'https://org.crm.dynamics.com'
        $Body = @{ name = 'New Name' }
        $res = Invoke-DataversePatch -AccessToken $AccessToken -Url $Url -Query '/api/data/v9.2/accounts(11111111-1111-1111-1111-111111111111)' -Body $Body
        $res.Success | Should -BeTrue
        $res.StatusCode | Should -Be 204
    }

    It "Merges custom headers (If-Match)" {
        $AccessToken = 'tok'
        $Url = 'https://org.crm.dynamics.com'
        $Body = @{ name = 'New Name' }
        $null = Invoke-DataversePatch -AccessToken $AccessToken -Url $Url -Query '/api/data/v9.2/accounts(11111111-1111-1111-1111-111111111111)' -Body $Body -Headers @{ 'If-Match' = '*' }
        Should -Invoke Invoke-WebRequest -ModuleName PipeDream -ParameterFilter {
            $Headers['If-Match'] -eq '*' -and $Headers['Authorization'] -like 'Bearer *'
        }
    }

    It "Returns structured error on failure" {
        Mock Invoke-WebRequest -ModuleName PipeDream { throw (New-Object System.Exception 'HTTP 412') }
        $AccessToken = 'tok'
        $Url = 'https://org.crm.dynamics.com'
        $Body = @{ name = 'New Name' }
        $res = Invoke-DataversePatch -AccessToken $AccessToken -Url $Url -Query '/api/data/v9.2/accounts(11111111-1111-1111-1111-111111111111)' -Body $Body
        $res.Success | Should -BeFalse
        $res.Error | Should -Match 'HTTP 412'
    }
}
