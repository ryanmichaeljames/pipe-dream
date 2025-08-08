
BeforeAll {
    # Import the module containing the function to test
    $modulePath = "$PSScriptRoot\..\..\src\PipeDream\PipeDream.psm1"
    Import-Module $modulePath -Force
}

Describe "Get-DataverseAuthToken" {
    BeforeAll {
        # Mock Invoke-RestMethod to avoid actual API calls during testing
        Mock Invoke-RestMethod -ModuleName PipeDream {
            return @{
                access_token = "mock-access-token"
                token_type   = "Bearer"
                expires_in   = 3600
            }
        }
    }

    It "Returns a token object with expected properties and future ExpiresOn" {
        $result = Get-DataverseAuthToken -TenantId "mock-tenant-id" -Url "https://mock-org.crm.dynamics.com" -ClientId "mock-client-id" -ClientSecret "mock-secret"
        $result | Should -Not -BeNullOrEmpty
        $result.AccessToken | Should -Be "mock-access-token"
        $result.TokenType   | Should -Be "Bearer"
        $result.ExpiresIn   | Should -Be 3600
        [datetime]::Parse($result.ExpiresOn.ToString()) | Should -BeGreaterThan (Get-Date)
    }

    It "Normalizes trailing slash in Url for scope" {
        $null = Get-DataverseAuthToken -TenantId "mock-tenant-id" -Url "https://mock-org.crm.dynamics.com/" -ClientId "mock-client-id" -ClientSecret "mock-secret"
        Should -Invoke Invoke-RestMethod -ModuleName PipeDream -ParameterFilter {
            $Body.scope -eq "https://mock-org.crm.dynamics.com/.default"
        } -Times 1 -Exactly
    }

    It "Calls token endpoint with correct body" {
        $null = Get-DataverseAuthToken -TenantId "mock-tenant-id" -Url "https://mock-org.crm.dynamics.com" -ClientId "mock-client-id" -ClientSecret "mock-secret"
        Should -Invoke Invoke-RestMethod -ModuleName PipeDream -ParameterFilter {
            $Uri -eq "https://login.microsoftonline.com/mock-tenant-id/oauth2/v2.0/token" -and
            $Method -eq "Post" -and
            $Body.grant_type -eq "client_credentials" -and
            $Body.client_id -eq "mock-client-id" -and
            $Body.client_secret -eq "mock-secret" -and
            $Body.scope -eq "https://mock-org.crm.dynamics.com/.default"
        }
    }
}
