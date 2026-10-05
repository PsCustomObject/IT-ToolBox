function Convert-LogonTimestamp {
    <#
    .SYNOPSIS
    Converts an AD logon FILETIME into a DateTime or formatted string.
    .DESCRIPTION
    Accepts an unsigned decimal string or an Int64 FILETIME value, with pipeline
    support. Returns local DateTime by default; -Utc returns UTC instead. Zero
    means no recorded logon and produces no output. Invalid or out-of-range input
    throws. This converts the value only; lastLogonTimestamp is replicated and is
    not a precise real-time record of a user's most recent authentication.
    .PARAMETER StringOutput
    Returns text instead of DateTime. Formatting uses invariant culture.
    .PARAMETER DateFormat
    .NET date format; specifying this also selects string output. Defaults to yyyy-MM-dd.
    .EXAMPLE
    Convert-LogonTimestamp -TimeStamp 133801632000000000 -Utc
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([datetime], ParameterSetName = 'Default')]
    [OutputType([string], ParameterSetName = 'StringOutput')]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$TimeStamp,
        [Parameter(ParameterSetName = 'StringOutput')]
        [switch]$StringOutput,
        [Parameter(ParameterSetName = 'StringOutput')]
        [ValidateNotNullOrEmpty()]
        [string]$DateFormat = 'yyyy-MM-dd',
        [switch]$Utc
    )

    process {
        [long]$fileTime = 0
        if (-not [long]::TryParse($TimeStamp, [System.Globalization.NumberStyles]::None,
                [System.Globalization.CultureInfo]::InvariantCulture, [ref]$fileTime)) {
            throw [System.FormatException]::new('TimeStamp must be an unsigned decimal Int64 FILETIME value.')
        }
        if ($fileTime -eq 0) { return }
        $date = [datetime]::FromFileTimeUtc($fileTime)
        if (-not $Utc) { $date = $date.ToLocalTime() }
        if ($PSCmdlet.ParameterSetName -eq 'StringOutput') {
            return $date.ToString($DateFormat, [System.Globalization.CultureInfo]::InvariantCulture)
        }
        return $date
    }
}
