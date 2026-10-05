function Clear-NewLogEntryBuffer
{
    Initialize-NewLogEntryState

    # Reset the shared buffer under the same lock used for appends to avoid a race with writers.
    [System.Threading.Monitor]::Enter($script:NewLogEntryBufferLock)
    try
    {
        # Clear both the list and the flattened string so the in-memory state stays consistent.
        $script:NewLogEntryBuffer.Clear()
        $script:messageBuffer = [string]::Empty
    }
    finally
    {
        [System.Threading.Monitor]::Exit($script:NewLogEntryBufferLock)
    }
}
