function Clear-NewLogEntryBuffer
{
    Initialize-NewLogEntryState

    [System.Threading.Monitor]::Enter($script:NewLogEntryBufferLock)
    try
    {
        $script:NewLogEntryBuffer.Clear()
        $script:messageBuffer = [string]::Empty
    }
    finally
    {
        [System.Threading.Monitor]::Exit($script:NewLogEntryBufferLock)
    }
}
