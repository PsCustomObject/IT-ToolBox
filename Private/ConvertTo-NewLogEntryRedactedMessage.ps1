function ConvertTo-NewLogEntryRedactedMessage
{
    param(
        [string]$Message,

        [string[]]$Pattern,

        [ValidateNotNull()]
        [string]$Replacement = '[REDACTED]'
    )

    $redactedMessage = $Message

    foreach ($item in $Pattern)
    {
        if ([string]::IsNullOrWhiteSpace($item))
        {
            continue
        }

        $redactedMessage = [regex]::Replace($redactedMessage, $item, $Replacement)
    }

    return $redactedMessage
}
