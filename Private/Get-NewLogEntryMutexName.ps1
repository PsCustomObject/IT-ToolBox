function Get-NewLogEntryMutexName
{
    param([string]$Path)

    $normalizedPath = if ($IsWindows) { $Path.ToUpperInvariant() } else { $Path }
    $bytes = [System.Security.Cryptography.SHA256]::HashData([System.Text.Encoding]::UTF8.GetBytes($normalizedPath))
    $hash = [Convert]::ToHexString($bytes).Substring(0, 32)

    if ($IsWindows)
    {
        return 'Global\NewLogEntry-{0}' -f $hash
    }

    return 'NewLogEntry-{0}' -f $hash
}
