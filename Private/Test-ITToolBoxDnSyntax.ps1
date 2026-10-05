function Test-ITToolBoxDnSyntax
{
    param
    (
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value) -or $Value -match '\p{Cc}')
    {
        return $false
    }

    $parts = [System.Collections.Generic.List[string]]::new()
    $start = 0

    for ($i = 0; $i -lt $Value.Length; $i++)
    {
        if ($Value[$i] -eq '\')
        {
            $i++
            continue
        }

        if ($Value[$i] -in @(',', '+'))
        {
            $parts.Add($Value.Substring($start, $i - $start))
            $start = $i + 1
        }
    }

    $parts.Add($Value.Substring($start))

    foreach ($part in $parts)
    {
        if ($part -cnotmatch '^(?:[a-zA-Z][a-zA-Z0-9-]*|[0-9]+(?:\.[0-9]+)+)=(.*)$')
        {
            return $false
        }

        $text = $Matches[1]

        if ($text.Length -eq 0)
        {
            return $false
        }

        if ($text.StartsWith('#'))
        {
            # Validate hex-string notation only; do not claim to validate ASN.1/BER contents.
            if ($text -cnotmatch '^#(?:[a-fA-F0-9]{2})+$')
            {
                return $false
            }

            continue
        }

        for ($j = 0; $j -lt $text.Length; $j++)
        {
            $ch = $text[$j]

            if ($ch -eq '\')
            {
                if ($j + 1 -ge $text.Length)
                {
                    return $false
                }

                if ($j + 2 -lt $text.Length -and $text.Substring($j + 1, 2) -cmatch '^[a-fA-F0-9]{2}$')
                {
                    $j += 2
                }
                elseif ($text[$j + 1] -in @(' ', '"', '#', '+', ',', ';', '<', '=', '>', '\'))
                {
                    $j++
                }
                else
                {
                    return $false
                }
            }
            elseif ($ch -in @('"', '+', ',', ';', '<', '>') -or
                ($ch -eq ' ' -and ($j -eq 0 -or $j -eq $text.Length - 1)))
            {
                return $false
            }
        }
    }

    return $true
}
