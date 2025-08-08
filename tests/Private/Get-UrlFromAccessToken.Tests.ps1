BeforeAll {
    $modulePath = "$PSScriptRoot\..\..\src\PipeDream\PipeDream.psm1"
    Import-Module $modulePath -Force
}

Describe "Get-UrlFromAccessToken (private)" {
    It "Returns audience from valid JWT" {
        $result = InModuleScope PipeDream {
            $aud = 'https://org.crm.dynamics.com'
            $header = (@{ alg = 'none'; typ = 'JWT' } | ConvertTo-Json -Compress)
            $payload = (@{ aud = $aud } | ConvertTo-Json -Compress)
            $toB64Url = { param($s) $b=[Text.Encoding]::UTF8.GetBytes($s); $x=[Convert]::ToBase64String($b); $x.TrimEnd('=') -replace '\\+', '-' -replace '/', '_' }
            $h = & $toB64Url $header
            $p = & $toB64Url $payload
            $token = "$h.$p.x"
            Get-UrlFromAccessToken -AccessToken $token
        }
        $result | Should -Be 'https://org.crm.dynamics.com'
    }

    It "Returns $null when 'aud' is missing" {
        $result = InModuleScope PipeDream {
            $header = (@{ alg = 'none'; typ = 'JWT' } | ConvertTo-Json -Compress)
            $payload = (@{ sub = 'user'; iss = 'issuer' } | ConvertTo-Json -Compress)
            $toB64Url = { param($s) $b=[Text.Encoding]::UTF8.GetBytes($s); $x=[Convert]::ToBase64String($b); $x.TrimEnd('=') -replace '\\+', '-' -replace '/', '_' }
            $h = & $toB64Url $header
            $p = & $toB64Url $payload
            $token = "$h.$p.x"
            Get-UrlFromAccessToken -AccessToken $token
        }
        $null -eq $result | Should -BeTrue
    }

    It "Returns $null for invalid token format (not 3 parts)" {
        $result = InModuleScope PipeDream { Get-UrlFromAccessToken -AccessToken 'aa.bb' }
        $null -eq $result | Should -BeTrue
    }

    It "Returns $null on base64 decode error" {
        $result = InModuleScope PipeDream { Get-UrlFromAccessToken -AccessToken 'a.b.c' }
        $null -eq $result | Should -BeTrue
    }
}
