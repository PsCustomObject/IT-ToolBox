function Format-NewLogEntry {
    param(
        [string]$Message,

        [ValidateSet('INFO', 'WARNING', 'ERROR')]
        [string]$Level,

        [bool]$SuppressTag
    )

    $currentDate = [DateTime]::Now.ToString('[MM/dd/yyyy hh:mm:ss tt]')
    $messageLines = [regex]::Split($Message, '\r\n|\n|\r')

    foreach ($messageLine in $messageLines) {
        if ($SuppressTag) {
            '{0} - {1}' -f $currentDate, $messageLine
            continue
        }

        '{0} - [{1}]: {2}' -f $currentDate, $Level, $messageLine
    }
}
