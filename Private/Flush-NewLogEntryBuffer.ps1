function Flush-NewLogEntryBuffer
{
    param(
        [string]$Path,
        [ValidateRange(1, 86400)]
        [int]$LockTimeoutSeconds = 30
    )

    Initialize-NewLogEntryState

    # Serialize snapshot, write, and removal with other operations on this buffer.
    # A failed write leaves entries available for a later retry.
    [System.Threading.Monitor]::Enter($script:NewLogEntryBufferLock)
    try
    {
        $lines = $script:NewLogEntryBuffer.ToArray()
        if ($lines.Count -eq 0)
        {
            return
        }

        Write-NewLogEntryLines -Lines $lines -Path $Path -LockTimeoutSeconds $LockTimeoutSeconds

        # Remove only the written prefix, preserving any reentrant append during writing.
        $script:NewLogEntryBuffer.RemoveRange(0, $lines.Count)
        $script:messageBuffer = $script:NewLogEntryBuffer -join [Environment]::NewLine
        if ($script:messageBuffer.Length -gt 0)
        {
            $script:messageBuffer += [Environment]::NewLine
        }
    }
    finally
    {
        [System.Threading.Monitor]::Exit($script:NewLogEntryBufferLock)
    }

    return $lines
}
