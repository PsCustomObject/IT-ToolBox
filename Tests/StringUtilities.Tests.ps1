BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../IT-ToolBox.psd1') -Force -ErrorAction Stop
}
Describe 'String conversion' {
    It 'returns one string without internal array indices' {
        $result = @(New-StringConversion -StringToConvert 'café')
        $result.Count | Should -Be 1
        $result[0] | Should -BeExactly 'cafe'
    }
    It 'preserves mapped uppercase and multi-character replacements' {
        New-StringConversion -StringToConvert 'CAFÉ Straße' | Should -BeExactly 'CAFE-Strasse'
        New-StringConversion -StringToConvert 'ÀÉÖ' | Should -BeExactly 'AEO'
    }
    It 'supports default, preserved, removed and custom spaces' {
        New-StringConversion -StringToConvert 'a b' | Should -BeExactly 'a-b'
        New-StringConversion -StringToConvert 'a b' -IgnoreSpaces | Should -BeExactly 'a b'
        New-StringConversion -StringToConvert 'a b' -RemoveSpaces | Should -BeExactly 'ab'
        New-StringConversion -StringToConvert 'a b' -ReplaceSpaces '_' | Should -BeExactly 'a_b'
        New-StringConversion -StringToConvert 'a b' -ReplaceSpaces '' | Should -BeExactly 'ab'
    }
    It 'does not mutate custom maps even if a space key exists' {
        $map = @{ 'é' = 'ee'; ' ' = 'original' }
        New-StringConversion -StringToConvert 'É é' -UnicodeHashTable $map -IgnoreSpaces | Should -BeExactly 'EE ee'
        $map.Count | Should -Be 2
        $map[' '] | Should -BeExactly 'original'
    }
    It 'uses the custom map instead of silently merging defaults' {
        New-StringConversion -StringToConvert 'éö' -UnicodeHashTable @{ 'é' = 'e' } | Should -BeExactly 'e?'
    }
    It 'normalizes decomposed accents and handles supplementary text elements once' {
        New-StringConversion -StringToConvert "cafe$([char]0x301)" | Should -BeExactly 'cafe'
        New-StringConversion -StringToConvert 'a🔐b' -UnknownCharacter '<unknown>' | Should -BeExactly 'a<unknown>b'
    }
    It 'preserves the historical permitted punctuation and special mappings' {
        New-StringConversion -StringToConvert 'A1!#$@.''^_~-' | Should -BeExactly 'A1!#$@.''^_~-'
        New-StringConversion -StringToConvert '&' | Should -BeExactly 'e'
        New-StringConversion -StringToConvert ':' | Should -BeExactly '?'
    }
    It 'rejects conflicting space policies and empty map keys' {
        { New-StringConversion -StringToConvert 'a b' -IgnoreSpaces -RemoveSpaces } | Should -Throw
        { New-StringConversion -StringToConvert 'a' -UnicodeHashTable @{ '' = 'x' } } | Should -Throw '*keys cannot be empty*'
    }
}
Describe 'Checksums and SHA-256 hashes' {
    It 'preserves the known MD5 checksum format' {
        Get-StringCheckSum -StringToCheck 'abc' | Should -BeExactly '90-01-50-98-3C-D2-4F-B0-D6-96-3F-7D-28-E1-7F-72'
    }
    It 'returns the standard SHA-256 test vector' {
        Get-StringHashCode -StringToHash 'abc' | Should -BeExactly 'BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD'
        Get-StringCheckSum -StringToCheck 'abc' -Algorithm SHA256 | Should -BeExactly 'BA-78-16-BF-8F-01-CF-EA-41-41-40-DE-5D-AE-22-23-B0-03-61-A3-96-17-7A-9C-B4-10-FF-61-F2-00-15-AD'
    }
    It 'matches the <Algorithm> test vector' -TestCases @(
        @{ Algorithm = 'SHA384'; Expected = 'CB-00-75-3F-45-A3-5E-8B-B5-A0-3D-69-9A-C6-50-07-27-2C-32-AB-0E-DE-D1-63-1A-8B-60-5A-43-FF-5B-ED-80-86-07-2B-A1-E7-CC-23-58-BA-EC-A1-34-C8-25-A7' }
        @{ Algorithm = 'SHA512'; Expected = 'DD-AF-35-A1-93-61-7A-BA-CC-41-73-49-AE-20-41-31-12-E6-FA-4E-89-A9-7E-A2-0A-9E-EE-E6-4B-55-D3-9A-21-92-99-2A-27-4F-C1-A8-36-BA-3C-23-A3-FE-EB-BD-45-4D-44-23-64-3C-E8-0E-2A-9A-C9-4F-A5-4C-A4-9F' }
    ) {
        param($Algorithm, $Expected)
        Get-StringCheckSum -StringToCheck 'abc' -Algorithm $Algorithm | Should -BeExactly $Expected
    }
    It 'preserves historical decimal output explicitly' {
        Get-StringHashCode -StringToHash 'abc' -LegacyFormat | Should -BeExactly '186120221911431207234656564222931743435176397163150231221561801625597242021173'
    }
    It 'hashes UTF-8 Unicode without a BOM' {
        Get-StringHashCode -StringToHash 'café 🔐' | Should -BeExactly '288B0200DB21EE3277629FA955AC8B340CEB775FCC303F89D90A4D1245309093'
    }
    It 'does not silently normalize text before hashing' {
        $composed = Get-StringHashCode -StringToHash 'é'
        $decomposed = Get-StringHashCode -StringToHash "e$([char]0x301)"
        $composed | Should -Not -Be $decomposed
    }
    It 'validates inputs and algorithm selection' {
        { Get-StringCheckSum -StringToCheck '' } | Should -Throw
        { Get-StringHashCode -StringToHash '' } | Should -Throw
        { Get-StringCheckSum -StringToCheck 'abc' -Algorithm 'SHA1' } | Should -Throw
    }
}
