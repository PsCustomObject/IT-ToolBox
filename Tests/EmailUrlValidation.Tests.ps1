BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../IT-ToolBox.psd1') -Force -ErrorAction Stop
}

Describe 'Bare email-address validation' {
    It 'accepts a common bare address: <Value>' -ForEach @(
        @{ Value = 'person@example.com' }
        @{ Value = 'Person.Name+tag@EXAMPLE.COM' }
        @{ Value = "a!#$%&'*+-/=?^_``{|}~@example.com" }
        @{ Value = 'person@localhost' }
        @{ Value = 'person@bücher.example' }
        @{ Value = 'person@xn--bcher-kva.example' }
        @{ Value = 'person@sub-domain.example' }
    ) {
        Test-IsEmail -EmailAddress $Value | Should -BeTrue
    }

    It 'rejects a malformed or unsupported address: <Value>' -ForEach @(
        @{ Value = $null }; @{ Value = '' }; @{ Value = ' ' }
        @{ Value = 'not-an-email' }; @{ Value = 'person@' }; @{ Value = '@example.com' }
        @{ Value = ' person@example.com' }; @{ Value = 'person@example.com ' }
        @{ Value = "person@example.com`r`nBcc: other@example.com" }
        @{ Value = "per$([char]0)son@example.com" }
        @{ Value = 'Person <person@example.com>' }; @{ Value = '<person@example.com>' }
        @{ Value = 'person(comment)@example.com' }; @{ Value = 'person@example.com(comment)' }
        @{ Value = 'a@example.com,b@example.com' }; @{ Value = 'a@example.com;b@example.com' }
        @{ Value = 'a..b@example.com' }; @{ Value = '.person@example.com' }; @{ Value = 'person.@example.com' }
        @{ Value = '"person name"@example.com' }; @{ Value = 'pérson@example.com' }
        @{ Value = 'person@[127.0.0.1]' }; @{ Value = 'person@[IPv6:::1]' }
        @{ Value = 'person@-bad.example' }; @{ Value = 'person@bad-.example' }
        @{ Value = 'person@bad_domain.example' }; @{ Value = 'person@example..com' }
        @{ Value = 'person@example.com.' }; @{ Value = 'person@bad/example.com' }
    ) {
        Test-IsEmail -EmailAddress $Value | Should -BeFalse
    }

    It 'preserves the Email, Mail and Address parameter aliases' {
        Test-IsEmail -Email 'person@example.com' | Should -BeTrue
        Test-IsEmail -Mail 'person@example.com' | Should -BeTrue
        Test-IsEmail -Address 'person@example.com' | Should -BeTrue
    }

    It 'returns one boolean per pipeline record, including blank input' {
        $results = @('person@example.com', '', 'bad', 'person@localhost') | Test-IsEmail
        $results.Count | Should -Be 4
        ($results -join ',') | Should -Be 'True,False,False,True'
        foreach ($result in $results) { $result | Should -BeOfType ([bool]) }
    }

    It 'enforces local-part, DNS-label and complete-address length boundaries' {
        Test-IsEmail (('a' * 64) + '@example.com') | Should -BeTrue
        Test-IsEmail (('a' * 65) + '@example.com') | Should -BeFalse
        Test-IsEmail ('a@' + ('b' * 63) + '.example') | Should -BeTrue
        Test-IsEmail ('a@' + ('b' * 64) + '.example') | Should -BeFalse
        $domain = ('b' * 63) + '.' + ('c' * 63) + '.' + ('d' * 61)
        Test-IsEmail (('a' * 64) + '@' + $domain) | Should -BeTrue
        Test-IsEmail (('a' * 64) + '@' + $domain + 'e') | Should -BeFalse
        # IDN length is measured after conversion, not from the Unicode spelling.
        Test-IsEmail ('a@' + ('é' * 60) + '.example') | Should -BeFalse
    }
}

Describe 'Absolute network URL validation' {
    It 'accepts supported absolute URL syntax: <Value>' -ForEach @(
        @{ Value = 'https://example.com' }; @{ Value = 'HTTP://EXAMPLE.COM' }
        @{ Value = 'ftp://example.com/file.txt' }; @{ Value = 'ftps://example.com:990/file.txt' }
        @{ Value = 'https://example.com:8443/api?name=value&limit=10#section' }
        @{ Value = 'https://example.com:0/' }; @{ Value = 'https://example.com:65535/' }
        @{ Value = 'http://localhost:8080/health' }; @{ Value = 'http://192.168.1.10/' }
        @{ Value = 'https://[2001:db8::1]:443/path' }; @{ Value = 'http://[::1]:8080/' }
        @{ Value = 'http://[::ffff:192.168.1.10]/' }
        @{ Value = 'https://bücher.example/über' }; @{ Value = 'https://xn--bcher-kva.example/' }
        @{ Value = 'https://example.com./' }; @{ Value = 'https://example.com/a%20b?q=%2F' }
    ) {
        Test-IsUrl -Url $Value | Should -BeTrue
    }

    It 'rejects malformed or unsupported URL syntax: <Value>' -ForEach @(
        @{ Value = $null }; @{ Value = '' }; @{ Value = ' ' }
        @{ Value = '/relative/path' }; @{ Value = 'example.com' }; @{ Value = '//example.com/path' }
        @{ Value = 'mailto:person@example.com' }; @{ Value = 'file:///tmp/file' }
        @{ Value = 'ssh://example.com' }; @{ Value = 'javascript:alert(1)' }
        @{ Value = 'https://' }; @{ Value = 'https:///example.com' }
        @{ Value = ' https://example.com' }; @{ Value = 'https://example.com ' }
        @{ Value = 'https://example.com/a b' }; @{ Value = "https://example.com/`npath" }
        @{ Value = "https://example.com/$([char]0)" }; @{ Value = 'https://example.com\path' }
        @{ Value = 'https://example.com/%zz' }; @{ Value = 'https://example.com/%' }
        @{ Value = 'https://user:password@example.com/' }; @{ Value = 'ftp://user@example.com/file' }
        @{ Value = 'https://@example.com/' }
        @{ Value = 'https://example.com:' }; @{ Value = 'https://example.com:abc/' }
        @{ Value = 'https://example.com:-1/' }; @{ Value = 'https://example.com:65536/' }
        @{ Value = 'https://256.1.1.1/' }; @{ Value = 'https://127.1/' }
        @{ Value = 'https://0x7f000001/' }; @{ Value = 'https://01.2.3.4/' }
        @{ Value = 'https://[2001:db8:::1]/' }; @{ Value = 'https://[fe80::1%251]/' }
        @{ Value = 'https://[example.com]/' }; @{ Value = 'https://[127.0.0.1]/' }
        @{ Value = 'https://-bad.example/' }; @{ Value = 'https://bad-.example/' }
        @{ Value = 'https://bad_domain.example/' }; @{ Value = 'https://example..com/' }
    ) {
        Test-IsUrl -Url $Value | Should -BeFalse
    }

    It 'returns one boolean per pipeline record and preserves case-insensitive command calls' {
        $results = @('https://example.com', '', '/relative', 'ftp://localhost/file') | Test-IsURL
        $results.Count | Should -Be 4
        ($results -join ',') | Should -Be 'True,False,False,True'
        foreach ($result in $results) { $result | Should -BeOfType ([bool]) }
    }

    It 'enforces DNS label boundaries for URL hosts' {
        Test-IsUrl ('https://' + ('a' * 63) + '.example/') | Should -BeTrue
        Test-IsUrl ('https://' + ('a' * 64) + '.example/') | Should -BeFalse
    }
}
