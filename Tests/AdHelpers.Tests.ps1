BeforeAll { Import-Module (Join-Path $PSScriptRoot '../IT-ToolBox.psd1') -Force -ErrorAction Stop }

Describe 'Distinguished-name syntax policy' {
    It 'accepts supported syntax: <Value>' -ForEach @(
        @{ Value = 'CN=Person,OU=People,DC=example,DC=com' }
        @{ Value = 'cn=Person,dc=example,dc=technology' }
        @{ Value = 'CN=Last\, First,OU=People,DC=example' }
        @{ Value = 'CN=Last\2C First,DC=example' }
        @{ Value = 'CN=A\+B+UID=123,OU=People,DC=example' }
        @{ Value = 'CN=\ Leading\ ,DC=example' }
        @{ Value = 'CN=\#literal,DC=example' }
        @{ Value = 'CN=A=B,DC=example' }
        @{ Value = 'CN=Jörg,DC=example' }
        @{ Value = '2.5.4.3=#04024869,DC=example' }
        @{ Value = 'CN=Standalone' }
        @{ Value = 'CN=Back\\Slash,DC=example' }
    ) { Test-IsValidDn $Value | Should -BeTrue }
    It 'rejects malformed or unsupported syntax: <Value>' -ForEach @(
        @{ Value = $null }; @{ Value = '' }; @{ Value = ' ' }
        @{ Value = 'Person' }; @{ Value = 'CN=' }; @{ Value = 'CN=Person,' }
        @{ Value = ',CN=Person' }; @{ Value = 'CN=Person,,DC=example' }
        @{ Value = 'CN=Person+,DC=example' }; @{ Value = 'CN=Person,DC=' }
        @{ Value = ' CN=Person' }; @{ Value = 'CN= Person' }; @{ Value = 'CN=Person ' }
        @{ Value = 'CN=Person\' }; @{ Value = 'CN=A\z,DC=example' }
        @{ Value = 'CN=A\2Z,DC=example' }; @{ Value = 'CN="Last, First",DC=example' }
        @{ Value = 'CN=#odd' }; @{ Value = 'CN=#123' }; @{ Value = 'CN=A<B' }
        @{ Value = "CN=A`nB,DC=example" }; @{ Value = "CN=A$([char]0)B" }
    ) { Test-IsValidDn $Value | Should -BeFalse }
    It 'preserves aliases and produces one boolean per pipeline record' {
        Test-IsValidDN -DistinguishedName 'CN=Person' | Should -BeTrue
        Test-IsValidDn -DN 'CN=Person' | Should -BeTrue
        $result = @('CN=Person', '', 'bad') | Test-IsValidDn
        ($result -join ',') | Should -Be 'True,False,False'
    }
}

Describe 'UPN syntax policy' {
    It 'accepts supported usernames and suffixes: <Value>' -ForEach @(
        @{ Value = 'alice@example.com' }; @{ Value = 'a@localhost' }
        @{ Value = 'first.last@example.technology' }; @{ Value = 'first_last@sub-domain.example' }
        @{ Value = "o'brien@example.com" }; @{ Value = 'alice@bücher.example' }
    ) { Test-IsValidUpn $Value | Should -BeTrue }
    It 'rejects unsupported UPN syntax: <Value>' -ForEach @(
        @{ Value = $null }; @{ Value = '' }; @{ Value = ' ' }
        @{ Value = 'alice' }; @{ Value = '@example.com' }; @{ Value = 'alice@' }
        @{ Value = 'alice@@example.com' }; @{ Value = ' alice@example.com' }
        @{ Value = 'alice@example.com ' }; @{ Value = 'a..b@example.com' }
        @{ Value = '.alice@example.com' }; @{ Value = 'alice.@example.com' }
        @{ Value = 'alice@bad_domain.example' }; @{ Value = 'alice@example..com' }
        @{ Value = 'alice@-bad.example' }; @{ Value = 'alice@[127.0.0.1]' }
        @{ Value = '"alice"@example.com' }; @{ Value = 'alice+tag@example.com' }
    ) { Test-IsValidUpn $Value | Should -BeFalse }
    It 'preserves aliases and returns independent pipeline results' {
        Test-IsValidUpn -UPN 'alice@example.com' | Should -BeTrue
        Test-IsValidUpn -ADUpn 'alice@example.com' | Should -BeTrue
        Test-IsValidUpn -UniversalPrincipalName 'alice@example.com' | Should -BeTrue
        $result = @('a@example.com', '', 'bad') | Test-IsValidUpn
        ($result -join ',') | Should -Be 'True,False,False'
    }
}

Describe 'Report chain query construction' {
    BeforeEach {
        Mock Invoke-ITToolBoxAdUser -ModuleName IT-ToolBox {
            param($Query)
            if ($Query.LDAPFilter -like '(&(manager:*') {
                [pscustomobject]@{ SamAccountName = 'report'; UserPrincipalName = 'report@example.com'; Mail = 'report@example.com'; Manager = 'CN=Boss,DC=example'; DirectReports = @(); DistinguishedName = 'CN=Report,DC=example' }
            }
            else { [pscustomobject]@{ DistinguishedName = 'CN=Boss,DC=example' } }
        }
    }
    It 'resolves SAM literally and returns default properties in order' {
        $result = Get-ReportChain -SAM boss
        $result.SamAccountName | Should -Be 'report'
        ($result.PSObject.Properties.Name -join ',') | Should -Be 'SamAccountName,UserPrincipalName,Mail,Manager,DirectReports'
        Should -Invoke Invoke-ITToolBoxAdUser -ModuleName IT-ToolBox -Times 1 -ParameterFilter { $Query.Identity -eq 'boss' }
        Should -Invoke Invoke-ITToolBoxAdUser -ModuleName IT-ToolBox -Times 1 -ParameterFilter {
            $Query.LDAPFilter -eq '(&(manager:1.2.840.113556.1.4.1941:=CN=Boss,DC=example)(!(distinguishedName=CN=Boss,DC=example)))'
        }
    }
    It 'uses an LDAP UPN equality filter without PowerShell expression interpolation' {
        Get-ReportChain -UserUPN "o'brien@example.com" | Out-Null
        Should -Invoke Invoke-ITToolBoxAdUser -ModuleName IT-ToolBox -Times 1 -ParameterFilter { $Query.LDAPFilter -eq "(userPrincipalName=o'brien@example.com)" }
    }
    It 'supports DN identity, custom property order and Server on both calls' {
        $result = Get-ReportChain -DN 'CN=Boss,DC=example' -DomainController dc01 -Properties Mail,SamAccountName
        ($result.PSObject.Properties.Name -join ',') | Should -Be 'Mail,SamAccountName'
        Should -Invoke Invoke-ITToolBoxAdUser -ModuleName IT-ToolBox -Times 2 -Exactly -ParameterFilter { $Query.Server -eq 'dc01' -and $Query.ErrorAction -eq 'Stop' }
    }
    It 'supports all-property projection' {
        (Get-ReportChain -UserSam boss -Properties '*').DistinguishedName | Should -Be 'CN=Report,DC=example'
    }
    It 'escapes resolved manager DN metacharacters and Unicode' {
        Mock Invoke-ITToolBoxAdUser -ModuleName IT-ToolBox {
            param($Query)
            if ($Query.Identity) { [pscustomobject]@{ DistinguishedName = 'CN=Jörg*(Boss)\, One,DC=example' } }
        }
        Get-ReportChain -SAM boss | Out-Null
        Should -Invoke Invoke-ITToolBoxAdUser -ModuleName IT-ToolBox -Times 1 -ParameterFilter {
            $Query.LDAPFilter -like '*CN=J\c3\b6rg\2a\28Boss\29\5c, One,DC=example*'
        }
    }
    It 'rejects malformed identities and options before querying' {
        { Get-ReportChain -DN 'bad' } | Should -Throw
        { Get-ReportChain -UPN 'bad' } | Should -Throw
        { Get-ReportChain -SAM ' ' } | Should -Throw
        { Get-ReportChain -SAM boss -DomainController ' ' } | Should -Throw
        { Get-ReportChain -SAM boss -Properties ' ' } | Should -Throw
        Should -Invoke Invoke-ITToolBoxAdUser -ModuleName IT-ToolBox -Times 0 -Exactly
    }
    It 'rejects missing and ambiguous manager results' {
        Mock Invoke-ITToolBoxAdUser -ModuleName IT-ToolBox {}
        { Get-ReportChain -SAM boss } | Should -Throw '*exactly one*'
        Mock Invoke-ITToolBoxAdUser -ModuleName IT-ToolBox { @([pscustomobject]@{ DistinguishedName = 'CN=A' }, [pscustomobject]@{ DistinguishedName = 'CN=B' }) }
        { Get-ReportChain -SAM boss } | Should -Throw '*exactly one*'
    }
    It 'rejects a malformed resolved manager DN' {
        Mock Invoke-ITToolBoxAdUser -ModuleName IT-ToolBox { [pscustomobject]@{ DistinguishedName = 'bad' } }
        { Get-ReportChain -SAM boss } | Should -Throw '*resolved manager*'
    }
    It 'propagates lookup and report-query failures without changing caller preference' {
        $preference = $ErrorActionPreference
        Mock Invoke-ITToolBoxAdUser -ModuleName IT-ToolBox { throw 'lookup failed' }
        { Get-ReportChain -SAM boss } | Should -Throw '*lookup failed*'
        Mock Invoke-ITToolBoxAdUser -ModuleName IT-ToolBox {
            param($Query)
            if ($Query.Identity) { [pscustomobject]@{ DistinguishedName = 'CN=Boss' } } else { throw 'report failed' }
        }
        { Get-ReportChain -SAM boss } | Should -Throw '*report failed*'
        $ErrorActionPreference | Should -Be $preference
    }
    It 'returns no records when the manager has no reports' {
        Mock Invoke-ITToolBoxAdUser -ModuleName IT-ToolBox {
            param($Query)
            if ($Query.Identity) { [pscustomobject]@{ DistinguishedName = 'CN=Boss' } }
        }
        @(Get-ReportChain -SAM boss).Count | Should -Be 0
    }
}

Describe 'Private LDAP escaping and AD dependency' {
    It 'escapes all assertion metacharacters and Unicode UTF-8 bytes' {
        InModuleScope IT-ToolBox {
            ConvertTo-ITToolBoxLdapFilterValue "a$([char]0)*()\é" | Should -Be 'a\00\2a\28\29\5c\c3\a9'
        }
    }
    It 'reports an unavailable AD command only when the AD helper is invoked' {
        InModuleScope IT-ToolBox {
            Mock Get-Command { $null } -ParameterFilter { $Name -eq 'Get-ADUser' }
            { Invoke-ITToolBoxAdUser -Query @{ Identity = 'boss' } } | Should -Throw '*requires Get-ADUser*'
        }
    }
    It 'does not export private helpers' {
        Get-Command ConvertTo-ITToolBoxLdapFilterValue -Module IT-ToolBox -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        Get-Command Invoke-ITToolBoxAdUser -Module IT-ToolBox -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }
}
