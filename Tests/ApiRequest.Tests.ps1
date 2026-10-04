BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../IT-ToolBox.psd1') -Force -ErrorAction Stop
}
Describe 'OAuth-style request construction' {
    BeforeEach {
        Mock Invoke-RestMethod { [pscustomobject]@{ access_token = 'mock-token'; token_type = 'Bearer' } } -ModuleName IT-ToolBox
    }
    It 'defaults to a form POST and returns the endpoint response' {
        $response = New-ApiRequest -ApiKey 'client-id' -ApiUrl 'https://example.invalid/token'
        $response.access_token | Should -BeExactly 'mock-token'
        Should -Invoke Invoke-RestMethod -ModuleName IT-ToolBox -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $ContentType -eq 'application/x-www-form-urlencoded' -and
            $Body.client_id -eq 'client-id' -and $Body.grant_type -eq 'client_credentials' -and
            -not $Body.ContainsKey('client_secret')
        }
    }
    It 'processes secret, headers, method and content type together regardless of argument order' {
        $headers = @{ 'X-Request-ID' = 'test-id' }
        New-ApiRequest -ContentType 'application/json' -Method POST -Headers $headers -ApiSecret 'test-secret' -ApiUrl 'https://example.invalid/token' -ApiKey 'client-id' | Out-Null
        Should -Invoke Invoke-RestMethod -ModuleName IT-ToolBox -Times 1 -Exactly -ParameterFilter {
            $json = ConvertFrom-Json $Body
            $Method -eq 'POST' -and $ContentType -eq 'application/json' -and
            $Headers['X-Request-ID'] -eq 'test-id' -and $json.client_secret -eq 'test-secret' -and
            $json.client_id -eq 'client-id' -and $json.grant_type -eq 'client_credentials'
        }
        $headers.Count | Should -Be 1
        $headers['X-Request-ID'] | Should -BeExactly 'test-id'
    }
    It 'keeps ContentType outside the authentication body' {
        New-ApiRequest -ApiKey 'client-id' -ApiSecret 'test-secret' -ApiUrl 'https://example.invalid/token' | Out-Null
        Should -Invoke Invoke-RestMethod -ModuleName IT-ToolBox -Times 1 -Exactly -ParameterFilter {
            $Body -is [System.Collections.IDictionary] -and $Body.Count -eq 3 -and
            -not $Body.ContainsKey('ContentType') -and $Body.client_secret -eq 'test-secret'
        }
    }
    It 'accepts a custom grant type' {
        New-ApiRequest -ApiKey 'client-id' -ApiUrl 'https://example.invalid/token' -GrantType 'custom_grant' | Out-Null
        Should -Invoke Invoke-RestMethod -ModuleName IT-ToolBox -Times 1 -Exactly -ParameterFilter { $Body.grant_type -eq 'custom_grant' }
    }
    It 'allows a secret-free GET dictionary for query encoding' {
        New-ApiRequest -ApiKey 'client-id' -ApiUrl 'https://example.invalid/token' -Method GET | Out-Null
        Should -Invoke Invoke-RestMethod -ModuleName IT-ToolBox -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'GET' -and $Body -is [System.Collections.IDictionary] -and $Body.client_id -eq 'client-id'
        }
    }
    It 'rejects GET secrets before issuing any request' {
        { New-ApiRequest -ApiKey 'client-id' -ApiSecret 'test-secret' -ApiUrl 'https://example.invalid/token' -Method GET } | Should -Throw '*cannot be sent with GET*'
        Should -Invoke Invoke-RestMethod -ModuleName IT-ToolBox -Times 0 -Exactly
    }
    It 'rejects a secret sent over plain HTTP' {
        { New-ApiRequest -ApiKey 'client-id' -ApiSecret 'test-secret' -ApiUrl 'http://example.invalid/token' } | Should -Throw '*require HTTPS*'
        Should -Invoke Invoke-RestMethod -ModuleName IT-ToolBox -Times 0 -Exactly
    }
    It 'rejects an Authorization header sent over plain HTTP' {
        { New-ApiRequest -ApiKey 'client-id' -ApiUrl 'http://example.invalid/token' -Headers @{ Authorization = 'Bearer test-token' } } | Should -Throw '*require HTTPS*'
        Should -Invoke Invoke-RestMethod -ModuleName IT-ToolBox -Times 0 -Exactly
    }
    It 'rejects conflicting header content type and GET content type' {
        { New-ApiRequest -ApiKey 'client-id' -ApiUrl 'https://example.invalid/token' -Headers @{ 'content-type' = 'application/json' } } | Should -Throw '*ContentType parameter*'
        { New-ApiRequest -ApiKey 'client-id' -ApiUrl 'https://example.invalid/token' -Method GET -ContentType 'application/json' } | Should -Throw '*applies to POST*'
        Should -Invoke Invoke-RestMethod -ModuleName IT-ToolBox -Times 0 -Exactly
    }
    It 'disables redirects and forwards the connection timeout' {
        New-ApiRequest -ApiKey 'client-id' -ApiUrl 'https://example.invalid/token' -ConnectionTimeoutSeconds 15 | Out-Null
        Should -Invoke Invoke-RestMethod -ModuleName IT-ToolBox -Times 1 -Exactly -ParameterFilter { $MaximumRedirection -eq 0 -and $ConnectionTimeoutSeconds -eq 15 }
    }
    It 'preserves terminating endpoint errors without retrying' {
        Mock Invoke-RestMethod { throw 'Mock endpoint failure' } -ModuleName IT-ToolBox
        { New-ApiRequest -ApiKey 'client-id' -ApiUrl 'https://example.invalid/token' } | Should -Throw '*Mock endpoint failure*'
        Should -Invoke Invoke-RestMethod -ModuleName IT-ToolBox -Times 1 -Exactly
    }
    It 'validates URLs, dictionaries, methods, formats and timeout ranges' {
        foreach ($url in @('relative/path', 'ftp://example.invalid/token', 'https://user:password@example.invalid/token')) {
            { New-ApiRequest -ApiKey 'client-id' -ApiUrl $url } | Should -Throw
        }
        { New-ApiRequest -ApiKey 'client-id' -ApiUrl 'https://example.invalid/token' -Headers 'not-a-dictionary' } | Should -Throw
        { New-ApiRequest -ApiKey 'client-id' -ApiUrl 'https://example.invalid/token' -Method PATCH } | Should -Throw
        { New-ApiRequest -ApiKey 'client-id' -ApiUrl 'https://example.invalid/token' -ContentType 'text/xml' } | Should -Throw
        { New-ApiRequest -ApiKey 'client-id' -ApiUrl 'https://example.invalid/token' -TimeoutSec 0 } | Should -Throw
        Should -Invoke Invoke-RestMethod -ModuleName IT-ToolBox -Times 0 -Exactly
    }
}
