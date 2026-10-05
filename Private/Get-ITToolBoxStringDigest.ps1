function Get-ITToolBoxStringDigest
{
    param
    (
        [string]$Text,
        [string]$Algorithm
    )

    [byte[]]$bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)

    [byte[]]$digest = switch ($Algorithm.ToUpperInvariant())
    {
        'MD5' { [System.Security.Cryptography.MD5]::HashData($bytes) }
        'SHA256' { [System.Security.Cryptography.SHA256]::HashData($bytes) }
        'SHA384' { [System.Security.Cryptography.SHA384]::HashData($bytes) }
        'SHA512' { [System.Security.Cryptography.SHA512]::HashData($bytes) }
        default { throw [ArgumentException]::new('Unsupported digest algorithm.') }
    }

    return , $digest
}
