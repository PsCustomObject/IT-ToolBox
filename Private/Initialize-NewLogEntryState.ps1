function Initialize-NewLogEntryState
{
    if ($null -eq $script:NewLogEntryBuffer)
    {
        $script:NewLogEntryBuffer = [System.Collections.Generic.List[string]]::new()
    }

    if ($null -eq $script:NewLogEntryBufferLock)
    {
        $script:NewLogEntryBufferLock = [object]::new()
    }
}
