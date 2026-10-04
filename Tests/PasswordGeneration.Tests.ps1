BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../IT-ToolBox.psd1') -Force -ErrorAction Stop
}
Describe 'Random string and password generation' {
    It 'keeps default lengths and returns only one string' {
        $a = @(New-RandomString)
        $b = @(New-RandomPassword)
        $a.Count | Should -Be 1
        $a[0].Length | Should -Be 12
        $b.Count | Should -Be 1
        $b[0].Length | Should -Be 8
    }
    It 'supports lengths longer than the alphabet' {
        (New-RandomString -StringLength 200).Length | Should -Be 200
        (New-RandomPassword -PasswordLength 200 -Complex).Length | Should -Be 200
    }
    It 'retains the original random-string alphabet' {
        $alphabet = 'ABCDE@#FGH]IJKL12MNOP_!Q{RSTUV89WXYZa}bcd67ef[ghijklmnopq(rs%^&tuvwxyz)03$*45'
        foreach ($character in (New-RandomString -StringLength 200).ToCharArray()) {
            $alphabet.Contains($character) | Should -BeTrue
        }
    }
    It 'rejects invalid requested lengths' {
        foreach ($length in @(0, -1, 4097)) {
            { New-RandomString -StringLength $length } | Should -Throw
            { New-RandomPassword -PasswordLength $length } | Should -Throw
        }
    }
}
Describe 'Phonetic password compatibility' {
    BeforeEach {
        Mock Write-Host {} -ModuleName IT-ToolBox
        Mock Set-Clipboard {} -ModuleName IT-ToolBox
    }
    It 'keeps the default and length alias' {
        (New-PhoneticPassword -NoPasswordSpell).Length | Should -Be 12
        (New-PhoneticPassword -length 20 -NoPasswordSpell).Length | Should -Be 20
    }
    It 'keeps exact category counts and all composition aliases' {
        $password = New-PhoneticPassword -Small 3 -Capital 4 -NumberDigits 2 -SpecialLetter 5 -NoPasswordSpell
        $password.Length | Should -Be 14
        [regex]::Matches($password, '[a-z]').Count | Should -Be 3
        [regex]::Matches($password, '[A-Z]').Count | Should -Be 4
        [regex]::Matches($password, '[0-9]').Count | Should -Be 2
        [regex]::Matches($password, '[^a-zA-Z0-9]').Count | Should -Be 5
    }
    It 'keeps excluded grave-accent and tilde characters excluded' {
        $password = New-PhoneticPassword -Symbol 200 -NoPasswordSpell
        $password.Contains([char]96) | Should -BeFalse
        $password.Contains('~') | Should -BeFalse
    }
    It 'preserves one combined output for pipeline lengths' {
        $password = @(3,4 | New-PhoneticPassword -NoPasswordSpell)
        $password.Count | Should -Be 1
        $password[0].Length | Should -Be 7
    }
    It 'accepts composition counts from pipeline object properties' {
        $inputCounts = [pscustomobject]@{ LowerCaseLetters = 2; CapitalCaseLetters = 3; NumberDigits = 1; Symbol = 2 }
        $password = $inputCounts | New-PhoneticPassword -NoPasswordSpell
        $password.Length | Should -Be 8
        [regex]::Matches($password, '[a-z]').Count | Should -Be 2
        [regex]::Matches($password, '[A-Z]').Count | Should -Be 3
    }
    It 'does not duplicate prior composition counts across pipeline records' {
        $counts = @(
            [pscustomobject]@{ LowerCaseLetters = 2; CapitalCaseLetters = 1; NumberDigits = 1; Symbol = 0 }
            [pscustomobject]@{ LowerCaseLetters = 2; CapitalCaseLetters = 1; NumberDigits = 1; Symbol = 0 }
        )
        $result = @($counts | New-PhoneticPassword -NoPasswordSpell)
        $result.Count | Should -Be 1
        $result[0].Length | Should -Be 8
        [regex]::Matches($result[0], '[a-z]').Count | Should -Be 4
    }
    It 'displays the phonetic table without polluting success output' {
        Mock Get-ITToolBoxRandomIndex { 0 } -ModuleName IT-ToolBox
        $result = @(New-PhoneticPassword -PasswordLength 3)
        $result.Count | Should -Be 1
        $result[0] | Should -BeExactly '!!!'
        Should -Invoke Write-Host -ModuleName IT-ToolBox -Times 1 -Exactly -ParameterFilter { "$Object" -match 'Character' -and "$Object" -match 'Exclamation point' }
        Should -Invoke Write-Host -ModuleName IT-ToolBox -Times 1 -Exactly -ParameterFilter { "$Object" -match 'Final password is:' }
    }
    It 'keeps the green display option' {
        $null = New-PhoneticPassword -ColorOutput
        Should -Invoke Write-Host -ModuleName IT-ToolBox -Times 1 -Exactly -ParameterFilter { $ForegroundColor -eq 'Green' }
    }
    It 'suppresses spelling and display through the historical alias' {
        $null = New-PhoneticPassword -NoOuput
        Should -Invoke Write-Host -ModuleName IT-ToolBox -Times 0 -Exactly
    }
    It 'copies the returned password without using the real clipboard' {
        $password = New-PhoneticPassword -PasswordToClipboard -NoPasswordSpell -Confirm:$false
        Should -Invoke Set-Clipboard -ModuleName IT-ToolBox -Times 1 -Exactly -ParameterFilter { $Value -ceq $password }
    }
    It 'reports an unavailable clipboard backend' {
        Mock Set-Clipboard { throw 'Clipboard unavailable' } -ModuleName IT-ToolBox
        { New-PhoneticPassword -PasswordToClipboard -NoPasswordSpell -Confirm:$false } | Should -Throw '*Clipboard unavailable*'
    }
    It 'honors WhatIf for the clipboard while returning a password' {
        $password = New-PhoneticPassword -PasswordToClipboard -NoPasswordSpell -WhatIf
        $password.Length | Should -Be 12
        Should -Invoke Set-Clipboard -ModuleName IT-ToolBox -Times 0 -Exactly
    }
    It 'rejects negative and empty composition requests' {
        { New-PhoneticPassword -LowerCaseLetters -1 -NoPasswordSpell } | Should -Throw
        { New-PhoneticPassword -LowerCaseLetters 0 -NoPasswordSpell } | Should -Throw
        { New-PhoneticPassword -LowerCaseLetters 4096 -Symbol 1 -NoPasswordSpell } | Should -Throw
    }
}
Describe 'Secure shuffle contract' {
    It 'preserves every supplied item without mutating the input' {
        & (Get-Module IT-ToolBox) {
            $source = @('a', 'b', 'c', 'd')
            $result = @(Get-ITToolBoxShuffledItems -Items $source)
            ($source -join '') | Should -BeExactly 'abcd'
            (($result | Sort-Object) -join '') | Should -BeExactly 'abcd'
        }
    }
}
