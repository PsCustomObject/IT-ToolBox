function Write-NewLogEntryLines
{
    param(
        [string[]]$Lines,

        [string]$Path,

        [ValidateRange(1, 86400)]
        [int]$LockTimeoutSeconds = 30
    )

    if ($Lines.Count -eq 0)
    {
        return
    }

    $resolvedPath = Resolve-NewLogEntryPath -Path $Path
    $directory = Split-Path -Path $resolvedPath -Parent

    if (-not [string]::IsNullOrWhiteSpace($directory))
    {
        [System.IO.Directory]::CreateDirectory($directory) > $null
    }

    $mutexName = Get-NewLogEntryMutexName -Path $resolvedPath
    $mutex = [System.Threading.Mutex]::new($false, $mutexName)
    $hasLock = $false

    try
    {
        try
        {
            $hasLock = $mutex.WaitOne([TimeSpan]::FromSeconds($LockTimeoutSeconds))
        }
        catch [System.Threading.AbandonedMutexException]
        {
            $hasLock = $true
        }

        if (-not $hasLock)
        {
            throw [System.TimeoutException]::new(
                'Timed out waiting {0} seconds for the log file lock: {1}' -f $LockTimeoutSeconds, $resolvedPath
            )
        }

        [System.IO.File]::AppendAllText(
            $resolvedPath,
            (($Lines -join [Environment]::NewLine) + [Environment]::NewLine),
            [System.Text.UTF8Encoding]::new($false)
        )
    }
    finally
    {
        if ($hasLock)
        {
            $mutex.ReleaseMutex()
        }

        $mutex.Dispose()
    }
}
