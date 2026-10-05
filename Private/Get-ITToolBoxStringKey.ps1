function Get-ITToolBoxStringKey
{
    param
    (
        [string]$PassPhrase,
        [byte[]]$Salt
    )

    $utf8 = [System.Text.UTF8Encoding]::new($false, $true)
    [byte[]]$passwordBytes = $utf8.GetBytes($PassPhrase)

    try
    {
        # Keep the byte array intact when returning through PowerShell's pipeline.
        return , ([System.Security.Cryptography.Rfc2898DeriveBytes]::Pbkdf2(
                $passwordBytes,
                $Salt,
                600000,
                [System.Security.Cryptography.HashAlgorithmName]::SHA256,
                32
            ))
    }
    finally
    {
        [Array]::Clear($passwordBytes, 0, $passwordBytes.Length)
    }
}
