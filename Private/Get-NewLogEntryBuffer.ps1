function Get-NewLogEntryBuffer
{
    Initialize-NewLogEntryState

    [System.Threading.Monitor]::Enter($script:NewLogEntryBufferLock)
    try
    {
        return $script:NewLogEntryBuffer.ToArray()
    }
    finally
    {
        [System.Threading.Monitor]::Exit($script:NewLogEntryBufferLock)
    }
}
