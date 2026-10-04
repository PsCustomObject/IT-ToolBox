function New-StringEncryption {
    <#
    .SYNOPSIS
    Encrypts a UTF-8 string using passphrase-derived AES-256-GCM.
    .DESCRIPTION
    Returns ITTB1. followed by Base64(salt[16] || nonce[12] || ciphertext || tag[16]).
    Version 1 fixes PBKDF2-HMAC-SHA256 at 600000 iterations and uses random salt/nonce.
    Plaintext is limited to 1 MiB of UTF-8. This format is not OpenPGP or v2 ciphertext.
    .PARAMETER EncryptPassPhrase
    Required passphrase. No computer-name default is used. Choose a strong passphrase.
    Strings remain in managed memory; this function is not a secret vault.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][AllowEmptyString()][ValidateNotNull()][Alias('string')]
        [string]$StringToEncrypt,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][ValidateLength(1,4096)]
        [Alias('PassPhrase', 'EncryptionPassPhrase')][string]$EncryptPassPhrase
    )
    if (-not [System.Security.Cryptography.AesGcm]::IsSupported) {
        throw [PlatformNotSupportedException]::new('AES-GCM is unavailable on this platform.')
    }
    $utf8 = [System.Text.UTF8Encoding]::new($false, $true)
    if ($utf8.GetByteCount($StringToEncrypt) -gt 1048576) {
        throw [ArgumentException]::new('Plaintext exceeds the 1 MiB UTF-8 limit.')
    }
    [byte[]]$plaintext = $utf8.GetBytes($StringToEncrypt)
    [byte[]]$key = $null
    $aes = $null
    try {
        [byte[]]$salt = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes(16)
        [byte[]]$nonce = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes(12)
        $key = Get-ITToolBoxStringKey -PassPhrase $EncryptPassPhrase -Salt $salt
        [byte[]]$ciphertext = [byte[]]::new($plaintext.Length)
        [byte[]]$tag = [byte[]]::new(16)
        [byte[]]$aad = $utf8.GetBytes('IT-ToolBox:string:v1:AES-256-GCM:PBKDF2-SHA256:600000')
        $aes = [System.Security.Cryptography.AesGcm]::new($key, 16)
        $aes.Encrypt($nonce, $plaintext, $ciphertext, $tag, $aad)
        [byte[]]$payload = [byte[]]::new(44 + $ciphertext.Length)
        [Array]::Copy($salt, 0, $payload, 0, 16)
        [Array]::Copy($nonce, 0, $payload, 16, 12)
        [Array]::Copy($ciphertext, 0, $payload, 28, $ciphertext.Length)
        [Array]::Copy($tag, 0, $payload, 28 + $ciphertext.Length, 16)
        return 'ITTB1.' + [Convert]::ToBase64String($payload)
    }
    finally {
        if ($null -ne $aes) { $aes.Dispose() }
        if ($null -ne $key) { [Array]::Clear($key, 0, $key.Length) }
        [Array]::Clear($plaintext, 0, $plaintext.Length)
    }
}
