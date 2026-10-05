function Get-StringHashCode
{
    <#
    .SYNOPSIS
        Returns the SHA-256 digest of UTF-8 text as 64 uppercase hexadecimal characters.

    .DESCRIPTION
        This is SHA-256, not .NET GetHashCode. LegacyFormat returns the historical
        delimiter-free decimal byte concatenation for migration/comparison only.
        Legacy output is an ambiguous encoding and should not be used for new identifiers.
        No Unicode normalization is performed. This is not password hashing or authentication.
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$StringToHash,

        [switch]$LegacyFormat
    )

    # Generate the SHA-256 digest and optionally return the historical legacy byte-concatenation format.
    [byte[]]$digest = Get-ITToolBoxStringDigest -Text $StringToHash -Algorithm SHA256

    if ($LegacyFormat)
    {
        $result = [System.Text.StringBuilder]::new()

        foreach ($value in $digest)
        {
            [void]$result.Append($value.ToString([System.Globalization.CultureInfo]::InvariantCulture))
        }

        return $result.ToString()
    }

    return [Convert]::ToHexString($digest)
}
