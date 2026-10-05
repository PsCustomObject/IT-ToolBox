function New-LogEntry
{
    <#
    .SYNOPSIS
        Writes PowerShell automation log entries to a file, console, or in-memory buffer.

    .DESCRIPTION
        New-LogEntry writes timestamped log entries with INFO, WARNING, or ERROR tags.
        File writes are protected by a named system mutex so concurrent PowerShell processes
        do not interleave or lose log lines. The mutex name is derived from the log file path,
        which keeps unrelated log files from blocking each other.

        Buffered entries are retained in the function's script scope and can be retrieved,
        flushed to disk, or cleared with -GetBuffer, -FlushBuffer, and -ClearBuffer. This works
        when the function is dot-sourced into a script or loaded from a module because callers
        do not need direct access to the backing variable.

    .PARAMETER LogMessage
        Message text to write. Multiline messages are split so every physical log line receives
        its own timestamp and severity prefix.

    .PARAMETER LogFilePath
        Path to the log file. If omitted, a log file is created beside the running script when
        possible, or in the current directory when running interactively.

    .PARAMETER Level
        Severity level for the entry. Defaults to INFO.

    .PARAMETER IsErrorMessage
        Compatibility switch for older callers. Sets -Level to ERROR.

    .PARAMETER IsWarningMessage
        Compatibility switch for older callers. Sets -Level to WARNING.

    .PARAMETER BufferOnly
        Adds the entry to the in-memory buffer without writing it to file or console.

    .PARAMETER BufferOnlyInfo
        Adds the entry to the buffer as INFO. This is retained for compatibility; -BufferOnly
        alone also uses INFO.

    .PARAMETER BufferOnlyWarning
        Adds the entry to the buffer as WARNING.

    .PARAMETER BufferOnlyError
        Adds the entry to the buffer as ERROR.

    .PARAMETER GetBuffer
        Returns buffered log entries without clearing them.

    .PARAMETER FlushBuffer
        Writes buffered entries to the log file and removes the written entries after a successful write.
        A failed file write retains the buffer for retry. A partial filesystem write can leave
        content on disk, so a retry after an I/O failure can duplicate that content.

    .PARAMETER ClearBuffer
        Clears buffered entries without writing them.

    .PARAMETER NoConsole
        Suppresses console output for non-buffered writes and buffer flushes.

    .PARAMETER PassThru
        Returns formatted log lines on the success output stream. INFO console output is written
        with Write-Host by default so logs do not pollute pipeline output unless -PassThru is used.

    .PARAMETER LockTimeoutSeconds
        Maximum number of seconds to wait for the log file mutex before failing. Defaults to 30.

    .PARAMETER RedactSecrets
        Applies built-in redaction patterns for common secrets such as bearer tokens, password
        assignments, API keys, and Authorization headers before formatting or writing the message.

    .PARAMETER RedactPattern
        Additional regular expression patterns to redact before formatting or writing the message.

    .PARAMETER RedactionText
        Literal replacement text used for redacted content (regex substitutions are not expanded). Defaults to [REDACTED].

    .PARAMETER NoTag
        Omits the severity tag from the formatted entry.

    .EXAMPLE
        New-LogEntry -LogMessage 'This is a test message' -LogFilePath '/tmp/TestLog.log'

    .EXAMPLE
        New-LogEntry -LogMessage 'Start' -BufferOnly
        New-LogEntry -LogMessage 'End' -BufferOnly
        New-LogEntry -GetBuffer
        New-LogEntry -FlushBuffer -LogFilePath '/tmp/TestLog.log'
    #>

    [CmdletBinding(DefaultParameterSetName = 'Write')]
    param (
        [Parameter(ParameterSetName = 'Write', Mandatory = $true, ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'BufferOnly', Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('Log', 'Message')]
        [string]$LogMessage,

        [Parameter(ParameterSetName = 'Write')]
        [Parameter(ParameterSetName = 'FlushBuffer')]
        [ValidateNotNullOrEmpty()]
        [string]$LogFilePath,

        [Parameter(ParameterSetName = 'Write')]
        [Parameter(ParameterSetName = 'BufferOnly')]
        [ValidateSet('INFO', 'WARNING', 'ERROR')]
        [string]$Level = 'INFO',

        [Parameter(ParameterSetName = 'Write')]
        [Alias('IsError', 'WriteError')]
        [switch]$IsErrorMessage,

        [Parameter(ParameterSetName = 'Write')]
        [Alias('Warning', 'IsWarning', 'WriteWarning')]
        [switch]$IsWarningMessage,

        [Parameter(ParameterSetName = 'BufferOnly')]
        [switch]$BufferOnlyInfo,

        [Parameter(ParameterSetName = 'Write')]
        [Parameter(ParameterSetName = 'FlushBuffer')]
        [switch]$NoConsole,

        [Parameter(ParameterSetName = 'BufferOnly')]
        [switch]$BufferOnlyWarning,

        [Parameter(ParameterSetName = 'BufferOnly')]
        [switch]$BufferOnlyError,

        [Parameter(ParameterSetName = 'BufferOnly')]
        [switch]$BufferOnly,

        [Parameter(ParameterSetName = 'GetBuffer', Mandatory = $true)]
        [switch]$GetBuffer,

        [Parameter(ParameterSetName = 'FlushBuffer', Mandatory = $true)]
        [switch]$FlushBuffer,

        [Parameter(ParameterSetName = 'ClearBuffer', Mandatory = $true)]
        [switch]$ClearBuffer,

        [Parameter(ParameterSetName = 'Write')]
        [Parameter(ParameterSetName = 'FlushBuffer')]
        [switch]$PassThru,

        [Parameter(ParameterSetName = 'Write')]
        [Parameter(ParameterSetName = 'FlushBuffer')]
        [ValidateRange(1, 86400)]
        [int]$LockTimeoutSeconds = 30,

        [Parameter(ParameterSetName = 'Write')]
        [Parameter(ParameterSetName = 'BufferOnly')]
        [switch]$RedactSecrets,

        [Parameter(ParameterSetName = 'Write')]
        [Parameter(ParameterSetName = 'BufferOnly')]
        [ValidateNotNull()]
        [string[]]$RedactPattern,

        [Parameter(ParameterSetName = 'Write')]
        [Parameter(ParameterSetName = 'BufferOnly')]
        [ValidateNotNull()]
        [string]$RedactionText = '[REDACTED]',

        [Parameter(ParameterSetName = 'Write')]
        [Parameter(ParameterSetName = 'BufferOnly')]
        [Alias('SuppressTag')]
        [switch]$NoTag
    )

    begin
    {
        $callerScriptPath = $MyInvocation.ScriptName
        $pendingEntries = [System.Collections.Generic.List[string]]::new()
        $activeRedactPatterns = [System.Collections.Generic.List[string]]::new()

        if ($IsWarningMessage -and $IsErrorMessage)
        {
            throw 'Use either -IsWarningMessage or -IsErrorMessage, not both.'
        }

        $bufferSeverityCount = [int]$BufferOnlyInfo.IsPresent + [int]$BufferOnlyWarning.IsPresent + [int]$BufferOnlyError.IsPresent
        if ($bufferSeverityCount -gt 1)
        {
            throw 'Use only one of -BufferOnlyInfo, -BufferOnlyWarning, or -BufferOnlyError.'
        }

        if ($PSBoundParameters.ContainsKey('Level') -and ($IsWarningMessage -or $IsErrorMessage -or $BufferOnlyWarning -or $BufferOnlyError -or $BufferOnlyInfo))
        {
            throw 'Use either -Level or a compatibility severity switch, not both.'
        }

        if ($IsWarningMessage)
        {
            $Level = 'WARNING'
        }
        elseif ($IsErrorMessage)
        {
            $Level = 'ERROR'
        }
        elseif ($BufferOnlyWarning)
        {
            $Level = 'WARNING'
        }
        elseif ($BufferOnlyError)
        {
            $Level = 'ERROR'
        }

        if ($RedactSecrets)
        {
            $activeRedactPatterns.Add('(?i)\bbearer\s+[a-z0-9._~+/=-]+')
            $activeRedactPatterns.Add('(?i)\b(password|passwd|pwd|secret|token|apikey|api_key|client_secret)\b\s*[:=]\s*("[^"]*"|''[^'']*''|\S+)')
            $activeRedactPatterns.Add('(?i)\bauthorization\s*:\s*(basic|digest|ntlm|negotiate)\s+\S+')
        }

        if ($RedactPattern)
        {
            foreach ($pattern in $RedactPattern)
            {
                $activeRedactPatterns.Add($pattern)
            }
        }
    }

    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'GetBuffer'
            {
                Get-NewLogEntryBuffer
                return
            }

            'ClearBuffer'
            {
                Clear-NewLogEntryBuffer
                return
            }

            'FlushBuffer'
            {
                $resolvedLogPath = Resolve-NewLogEntryPath -Path $LogFilePath -CallerScriptPath $callerScriptPath
                $bufferedLines = @(Flush-NewLogEntryBuffer -Path $resolvedLogPath -LockTimeoutSeconds $LockTimeoutSeconds)

                if ($bufferedLines.Count -eq 0)
                {
                    return
                }

                if (-not $NoConsole)
                {
                    foreach ($line in $bufferedLines)
                    {
                        Write-Host $line
                    }
                }

                if ($PassThru)
                {
                    $bufferedLines
                }

                return
            }
        }

        $messageToLog = if ($activeRedactPatterns.Count -gt 0)
        {
            ConvertTo-NewLogEntryRedactedMessage -Message $LogMessage -Pattern $activeRedactPatterns.ToArray() -Replacement $RedactionText
        }
        else
        {
            $LogMessage
        }

        $entries = @(Format-NewLogEntry -Message $messageToLog -Level $Level -SuppressTag:$NoTag)

        foreach ($entry in $entries)
        {
            $pendingEntries.Add($entry)
        }
    }

    end
    {
        if ($pendingEntries.Count -eq 0)
        {
            return
        }

        $entries = $pendingEntries.ToArray()

        if ($PSCmdlet.ParameterSetName -eq 'BufferOnly')
        {
            Add-NewLogEntryBuffer -Lines $entries
            return
        }

        $resolvedLogPath = Resolve-NewLogEntryPath -Path $LogFilePath -CallerScriptPath $callerScriptPath
        Write-NewLogEntryLines -Lines $entries -Path $resolvedLogPath -LockTimeoutSeconds $LockTimeoutSeconds

        if (-not $NoConsole)
        {
            foreach ($entry in $entries)
            {
                Write-NewLogEntryConsole -Line $entry -Level $Level
            }
        }

        if ($PassThru)
        {
            $entries
        }
    }
}