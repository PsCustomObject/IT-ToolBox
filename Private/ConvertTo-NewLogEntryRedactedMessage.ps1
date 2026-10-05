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

        # Escape dollar signs so replacement syntax cannot reinsert matched secrets.
        $redactedMessage = [regex]::Replace($redactedMessage, $item, $Replacement.Replace('$', '$$'))
    }

    return $redactedMessage
}
