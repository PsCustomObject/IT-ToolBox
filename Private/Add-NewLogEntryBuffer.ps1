function Add-NewLogEntryBuffer
{
    param([string[]]$Lines)

    Initialize-NewLogEntryState

    [System.Threading.Monitor]::Enter($script:NewLogEntryBufferLock)
    try
    {
        $script:NewLogEntryBuffer.AddRange($Lines)
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
}
