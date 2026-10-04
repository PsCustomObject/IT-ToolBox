BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../IT-ToolBox.psd1') -Force -ErrorAction Stop
}
Describe 'Filename validation' {
    It 'accepts ordinary names without requiring a file' {
        Test-FileName 'report.txt' | Should -BeTrue
        Test-FileName 'résumé.txt' | Should -BeTrue
    }
    It 'rejects empty, navigation and separator names' {
        foreach ($name in @('', ' ', '.', '..', 'folder/file', "bad$([char]0)name")) {
            Test-FileName $name | Should -BeFalse
        }
    }
    It 'supports Windows-compatible names on every platform' {
        foreach ($name in @('CON', 'con.txt', 'NUL.log', 'COM1', 'LPT9.doc', 'a:b', 'a?b', 'a\b', 'name.', 'name ')) {
            Test-FileName $name -WindowsCompatible | Should -BeFalse
        }
        Test-FileName 'console.txt' -WindowsCompatible | Should -BeTrue
        Test-FileName 'COM10.txt' -WindowsCompatible | Should -BeTrue
    }
    It 'uses native platform character rules by default' {
        Test-FileName 'a:b' | Should -Be (-not $IsWindows)
    }
}
Describe 'Path validation' {
    It 'accepts nonexistent relative and absolute paths' {
        Test-IsValidPath 'nonexistent/child.txt' | Should -BeTrue
        Test-IsValidPath (Join-Path $TestDrive 'missing/file.txt') | Should -BeTrue
    }
    It 'rejects blank and NUL-containing paths' {
        foreach ($path in @('', ' ', "bad$([char]0)path")) {
            Test-IsValidPath $path | Should -BeFalse
        }
    }
}
Describe 'IP address validation' {
    It 'accepts standard IPv4, IPv6 and mapped addresses' {
        foreach ($ip in @('0.0.0.0', '192.168.1.10', '255.255.255.255', '::1', '2001:db8::1', '::ffff:192.168.1.10')) {
            Test-IsIP $ip | Should -BeTrue
        }
    }
    It 'rejects malformed and ambiguous address formats' {
        foreach ($ip in @('', 'localhost', '256.1.1.1', '127.1', '65535', '0x7f000001', '01.2.3.4', '1.2.3.4 ', '1.2.3.4/24', '[::1]', '2001:db8:::1')) {
            Test-IsIP $ip | Should -BeFalse
        }
    }
}
Describe 'Date validation' {
    It 'validates leap days with an exact format' {
        Test-IsDate '2024-02-29' -Format 'yyyy-MM-dd' -Culture '' | Should -BeTrue
        Test-IsDate '2023-02-29' -Format 'yyyy-MM-dd' -Culture '' | Should -BeFalse
        Test-IsDate '29/02/2024' -Format 'yyyy-MM-dd' -Culture '' | Should -BeFalse
    }
    It 'honors an explicitly selected culture' {
        Test-IsDate '31/12/2026' -Culture 'en-GB' | Should -BeTrue
        Test-IsDate '31/12/2026' -Culture 'en-US' | Should -BeFalse
    }
    It 'returns false for blank and invalid dates' {
        foreach ($date in @('', ' ', 'not a date')) {
            Test-IsDate $date | Should -BeFalse
        }
    }
}
