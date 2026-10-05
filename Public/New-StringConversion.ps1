function New-StringConversion
{
    <#
    .SYNOPSIS
    Converts mapped characters and replaces unsupported text elements.

    .DESCRIPTION

    Retains the historical character map and permitted ASCII punctuation.
    Default spaces become hyphens. Use IgnoreSpaces, RemoveSpaces or ReplaceSpaces
    to select another policy. Custom maps replace the default map and are not mutated.
    Input is normalized to Unicode Form C; each remaining text element is processed
    once. This is a domain-specific conversion, not general Unicode transliteration.
    Returns exactly one string, without internal collection indices.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ReplaceSpaces')]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$StringToConvert,
        [ValidateNotNull()][hashtable]$UnicodeHashTable,
        [Parameter(ParameterSetName = 'IgnoreSpaces')][switch]$IgnoreSpaces,
        [Parameter(ParameterSetName = 'RemoveSpaces')][switch]$RemoveSpaces,
        [Parameter(ParameterSetName = 'ReplaceSpaces')][AllowEmptyString()][ValidateNotNull()][string]$ReplaceSpaces = '-',
        [ValidateNotNullOrEmpty()][string]$UnknownCharacter = '?'
    )
    
    if ($PSBoundParameters.ContainsKey('UnicodeHashTable'))
    {
        # Normalize a private copy so the caller's map remains unchanged.
        $map = @{}
        foreach ($key in $UnicodeHashTable.Keys)
        {
            $normalizedKey = ([string]$key).Normalize(
                [System.Text.NormalizationForm]::FormC
            ).ToLowerInvariant()
            if ([string]::IsNullOrEmpty($normalizedKey))
            {
                throw [ArgumentException]::new('Character map keys cannot be empty.')
            }
            $map[$normalizedKey] = [string]$UnicodeHashTable[$key]
        }
    }
    else
    {
        $map = Get-ITToolBoxCharacterMap
    }

    $map[' '] = if ($IgnoreSpaces)
    {
        ' '
    }
    elseif ($RemoveSpaces)
    {
        ''
    }
    else
    {
        $ReplaceSpaces
    }

    # Canonicalize equivalent Unicode sequences so character-map lookups are consistent.
    $normalized = $StringToConvert.Normalize([System.Text.NormalizationForm]::FormC)
    
    # Enumerate text elements, such as surrogate pairs and combining sequences, as units.
    $elements = [System.Globalization.StringInfo]::GetTextElementEnumerator($normalized)
    
    # Accumulate converted text without repeatedly creating longer strings.
    $result = [System.Text.StringBuilder]::new()

    # Process text elements so surrogate pairs and combining marks stay together.
    while ($elements.MoveNext())
    {
        [string]$element = $elements.GetTextElement()
        [string]$lower = $element.ToLowerInvariant()
        if ($map.ContainsKey($lower))
        {
            [string]$replacement = $map[$lower]
            if ($element -cne $lower)
            {
                # Preserve the input element's capitalization in mapped output.
                $replacement = $replacement.ToUpperInvariant()
            }
            [void]$result.Append($replacement)
        }
        # Pass through ASCII letters, digits, and the explicitly allowed punctuation.
        elseif ($element -cmatch '^[0-9a-zA-Z!#$@.''^_~-]$')
        {
            [void]$result.Append($element)
        }
        else
        {
            [void]$result.Append($UnknownCharacter)
        }
    }
    return $result.ToString()
}
