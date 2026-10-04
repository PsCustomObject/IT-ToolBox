function New-StringDecryption {
    <#
    .SYNOPSIS
    Authenticates and decrypts an ITTB1 string produced by New-StringEncryption.
    .DESCRIPTION
    Wrong passphrases and modified payloads throw without returning plaintext.
    Unknown versions and historical v2 ciphertext are rejected. No automatic fallback.
    Legacy ciphertext must be migrated separately using the original v2 decoder.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$EncryptedString,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][ValidateLength(1,4096)]
        [Alias('PassPhrase', 'EncryptionPassPhrase')][string]$EncryptPassPhrase
    )
    # Check limits before decoding or performing expensive key derivation.
    if ($EncryptedString.Length -gt 1398166 -or -not $EncryptedString.StartsWith('ITTB1.', [StringComparison]::Ordinal)) {
        throw [FormatException]::new('Expected an ITTB1 ciphertext within the 1 MiB plaintext limit. Legacy ciphertext requires separate migration.')
    }
    $encoded = $EncryptedString.Substring(6)
    try { [byte[]]$payload = [Convert]::FromBase64String($encoded) }
    catch { throw [FormatException]::new('Invalid ITTB1 Base64 payload.') }
    if ($payload.Length -lt 44 -or $payload.Length -gt 1048620 -or [Convert]::ToBase64String($payload) -cne $encoded) {
        throw [FormatException]::new('Invalid ITTB1 payload size or encoding.')
    }
    if (-not [System.Security.Cryptography.AesGcm]::IsSupported) {
        throw [PlatformNotSupportedException]::new('AES-GCM is unavailable on this platform.')
    }
    $utf8 = [System.Text.UTF8Encoding]::new($false, $true)
    [byte[]]$salt = [byte[]]::new(16)
    [byte[]]$nonce = [byte[]]::new(12)
    [byte[]]$ciphertext = [byte[]]::new($payload.Length - 44)
    [byte[]]$tag = [byte[]]::new(16)
    [Array]::Copy($payload, 0, $salt, 0, 16)
    [Array]::Copy($payload, 16, $nonce, 0, 12)
    [Array]::Copy($payload, 28, $ciphertext, 0, $ciphertext.Length)
    [Array]::Copy($payload, 28 + $ciphertext.Length, $tag, 0, 16)
    [byte[]]$plaintext = [byte[]]::new($ciphertext.Length)
    [byte[]]$key = $null
    $aes = $null
    try {
        $key = Get-ITToolBoxStringKey -PassPhrase $EncryptPassPhrase -Salt $salt
        [byte[]]$aad = $utf8.GetBytes('IT-ToolBox:string:v1:AES-256-GCM:PBKDF2-SHA256:600000')
        $aes = [System.Security.Cryptography.AesGcm]::new($key, 16)
        try { $aes.Decrypt($nonce, $ciphertext, $tag, $plaintext, $aad) }
        catch [System.Security.Cryptography.CryptographicException] {
            throw [System.Security.Cryptography.CryptographicException]::new('Authentication failed: incorrect passphrase or modified ciphertext.')
        }
        return $utf8.GetString($plaintext)
    }
    finally {
        if ($null -ne $aes) { $aes.Dispose() }
        if ($null -ne $key) { [Array]::Clear($key, 0, $key.Length) }
        [Array]::Clear($plaintext, 0, $plaintext.Length)
    }
}
