function Test-FileName
{
    <#
    .SYNOPSIS
        Tests one filename component without accessing the filesystem.

    .DESCRIPTION
        Uses native invalid characters by default. WindowsCompatible additionally
        rejects Windows reserved device names, control characters, and trailing dots or spaces.
        It does not test existence, permissions, or filesystem length limits.
    #>

    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Filename,

        [switch]$WindowsCompatible
    )

    # Reject empty input and the special relative-path entries that are not valid file names.
    if ([string]::IsNullOrWhiteSpace($Filename) -or $Filename -in @('.', '..'))
    {
        return $false
    }

    # Check the platform-specific invalid-name characters for a single file component.
    if ($Filename.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0)
    {
        return $false
    }

    if ($IsWindows -or $WindowsCompatible)
    {
        # Windows validation is stricter and rejects reserved names and trailing punctuation.
        if ($Filename -match '[<>:"/\\|?*\x00-\x1f]' -or $Filename -match '[. ]$')
        {
            return $false
        }

        # Reject Windows reserved device names such as CON, AUX, and LPT1, whether they are standalone or followed by a dot.
        if ($Filename -match '^(?i:CON|PRN|AUX|NUL|COM[1-9¹²³]|LPT[1-9¹²³])(?:\.|$)')
        {
            return $false
        }
    }

    return $true
}
