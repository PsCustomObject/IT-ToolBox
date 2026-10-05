function Test-IsDate
{
    <#
    .SYNOPSIS
        Tests a date using a selected culture and optional exact format.

    .DESCRIPTION
        Default parsing uses the current culture, retaining v2 behavior.
        Supply Culture and Format for reproducible validation; no date is returned.
    #>

    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Date,

        [System.Globalization.CultureInfo]$Culture = [System.Globalization.CultureInfo]::CurrentCulture,

        [ValidateNotNullOrEmpty()]
        [string]$Format
    )

    # Empty or whitespace values cannot be valid dates.
    if ([string]::IsNullOrWhiteSpace($Date))
    {
        return $false
    }

    [datetime]$parsed = [datetime]::MinValue

    if ($PSBoundParameters.ContainsKey('Format'))
    {
        # Require the value to match the specified format exactly for the supplied culture.
        return [datetime]::TryParseExact($Date, $Format, $Culture, [System.Globalization.DateTimeStyles]::None, [ref]$parsed)
    }

    # Otherwise, use the culture-aware general parser.
    return [datetime]::TryParse($Date, $Culture, [System.Globalization.DateTimeStyles]::None, [ref]$parsed)
}
