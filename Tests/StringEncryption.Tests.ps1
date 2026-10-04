BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../IT-ToolBox.psd1') -Force -ErrorAction Stop
    $passphrase = 'A deliberately long test passphrase 2026!'
}
Describe 'Authenticated string encryption' {
    It 'round trips Unicode and multiline strings' {
        $text = "café 🔐`nsecond line"
        $sealed = New-StringEncryption -StringToEncrypt $text -EncryptPassPhrase $passphrase
        $sealed | Should -Match '^ITTB1\.'
        New-StringDecryption -EncryptedString $sealed -EncryptPassPhrase $passphrase | Should -BeExactly $text
    }
    It 'round trips an empty plaintext' {
        $sealed = New-StringEncryption -StringToEncrypt '' -EncryptPassPhrase $passphrase
        New-StringDecryption -EncryptedString $sealed -EncryptPassPhrase $passphrase | Should -BeExactly ''
    }
    It 'uses fresh salts and nonces for repeated messages' {
        $first = New-StringEncryption -StringToEncrypt 'same text' -EncryptPassPhrase $passphrase
        $second = New-StringEncryption -StringToEncrypt 'same text' -EncryptPassPhrase $passphrase
        $first | Should -Not -Be $second
        $a = [Convert]::FromBase64String($first.Substring(6))
        $b = [Convert]::FromBase64String($second.Substring(6))
        [Convert]::ToBase64String($a[0..15]) | Should -Not -Be ([Convert]::ToBase64String($b[0..15]))
        [Convert]::ToBase64String($a[16..27]) | Should -Not -Be ([Convert]::ToBase64String($b[16..27]))
    }
    It 'rejects a wrong passphrase without emitting plaintext' {
        $sealed = New-StringEncryption -StringToEncrypt 'secret text' -EncryptPassPhrase $passphrase
        { New-StringDecryption -EncryptedString $sealed -EncryptPassPhrase 'wrong passphrase' } | Should -Throw '*Authentication failed*'
    }
    It 'rejects changes to salt, nonce, ciphertext and tag' {
        $sealed = New-StringEncryption -StringToEncrypt 'secret text' -EncryptPassPhrase $passphrase
        foreach ($offset in @(0, 16, 28, 44)) {
            $bytes = [Convert]::FromBase64String($sealed.Substring(6))
            $bytes[$offset] = $bytes[$offset] -bxor 1
            $modified = 'ITTB1.' + [Convert]::ToBase64String($bytes)
            { New-StringDecryption -EncryptedString $modified -EncryptPassPhrase $passphrase } | Should -Throw '*Authentication failed*'
        }
    }
    It 'rejects legacy, unknown, truncated and malformed input' {
        foreach ($sealed in @('YWJjZA==', 'ITTB2.YWJjZA==', 'ITTB1.!', 'ITTB1.AAAA', 'ITTB1.')) {
            { New-StringDecryption -EncryptedString $sealed -EncryptPassPhrase $passphrase } | Should -Throw
        }
    }
    It 'rejects empty passphrases and oversized plaintext' {
        { New-StringEncryption -StringToEncrypt 'text' -EncryptPassPhrase '' } | Should -Throw
        { New-StringEncryption -StringToEncrypt ('a' * 1048577) -EncryptPassPhrase $passphrase } | Should -Throw '*1 MiB*'
    }
    It 'decrypts an independent Python cryptography fixture' {
        # Generated with hashlib.pbkdf2_hmac and cryptography.AESGCM, not these functions.
        $fixture = 'ITTB1.AAECAwQFBgcICQoLDA0ODwABAgMEBQYHCAkKCy5HpbJV75ucCCKT8rV0DNpBa72gEFiAgfRZFUex16FfeE0X'
        New-StringDecryption -EncryptedString $fixture -EncryptPassPhrase 'Independent fixture passphrase' | Should -BeExactly 'Interop: café 🔐'
    }
}
