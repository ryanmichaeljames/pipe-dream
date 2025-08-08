BeforeAll {
    $modulePath = "$PSScriptRoot\..\..\src\PipeDream\PipeDream.psm1"
    Import-Module $modulePath -Force
}

Describe "New-DataverseHeaders (private)" {
    It "Builds defaults with auth and OData" {
        $result = InModuleScope PipeDream {
            New-DataverseHeaders -AccessToken 'tok'
        }
        $result['Authorization'] | Should -BeLike 'Bearer *'
        $result['Accept'] | Should -Be 'application/json'
        $result['OData-Version'] | Should -Be '4.0'
        $result['OData-MaxVersion'] | Should -Be '4.0'
    }

    It "Composes Prefer values and merges ExtraHeaders" {
        $result = InModuleScope PipeDream {
            New-DataverseHeaders -AccessToken 'tok' -PreferReturnRepresentation -PreferODataMaxPageSize 10 -PreferIncludeAnnotations '*' -ExtraHeaders @{ Prefer = 'odata.include-annotations=@Microsoft.Dynamics.CRM.formattedvalue' }
        }
        $result['Prefer'] | Should -Match 'return=representation'
        $result['Prefer'] | Should -Match 'odata.maxpagesize=10'
        # Respect existing provided Prefer and merge
        $result['Prefer'] | Should -Match 'odata.include-annotations='
    }

    It "Sets conditional, correlation, and localization headers" {
        $cid = [guid]::NewGuid().ToString()
        $h = InModuleScope PipeDream {
            param($cid)
            New-DataverseHeaders -AccessToken 'tok' -IfMatch '*' -IfNoneMatch 'W/"123"' -CorrelationId $cid -SuppressDuplicateDetection -AcceptLanguage 'en-US'
        } -ArgumentList $cid
        $h['If-Match'] | Should -Be '*'
        $h['If-None-Match'] | Should -Be 'W/"123"'
        $h['x-ms-client-request-id'] | Should -Be $cid
        $h['MSCRM.SuppressDuplicateDetection'] | Should -Be 'true'
        $h['Accept-Language'] | Should -Be 'en-US'
    }
}
