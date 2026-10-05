function Write-NewLogEntryConsole
{
    param
    (
        [string]$Line,

        [ValidateSet('INFO', 'WARNING', 'ERROR')]
        [string]$Level
    )

    switch ($Level)
    {
        'WARNING' { Write-Warning -Message $Line }
        'ERROR' { Write-Error -Message $Line }
        default { Write-Host $Line }
    }
}
