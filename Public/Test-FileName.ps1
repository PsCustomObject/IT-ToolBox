function Test-FileName {
    <#
    .SYNOPSIS
    Tests one filename component, without accessing the filesystem.
    .DESCRIPTION
    Uses native invalid characters by default. WindowsCompatible additionally
    rejects Windows reserved device names, control characters and trailing dots/spaces.
    Does not test existence, permissions or filesystem length limits.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param([AllowNull()][AllowEmptyString()][string]$Filename, [switch]$WindowsCompatible)

    if ([string]::IsNullOrWhiteSpace($Filename) -or $Filename -in @('.', '..')) { return $false }
    if ($Filename.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) { return $false }
    if ($IsWindows -or $WindowsCompatible) {
        if ($Filename -match '[<>:"/\\|?*\x00-\x1f]' -or $Filename -match '[. ]$') { return $false }
        if ($Filename -match '^(?i:CON|PRN|AUX|NUL|COM[1-9¹²³]|LPT[1-9¹²³])(?:\.|$)') { return $false }
    }
    return $true
}
