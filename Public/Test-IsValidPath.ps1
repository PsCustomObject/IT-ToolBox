function Test-IsValidPath {
    <#
    .SYNOPSIS
    Tests whether a string can be interpreted as a native filesystem path.
    .DESCRIPTION
    Accepts absolute and relative paths without checking existence or permissions.
    This is not validation of PowerShell provider paths or each filename component.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param([AllowNull()][AllowEmptyString()][string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    if ($Path.IndexOfAny([IO.Path]::GetInvalidPathChars()) -ge 0) { return $false }
    try {
        $null = [IO.Path]::GetFullPath($Path)
        return $true
    }
    catch [System.ArgumentException] { return $false }
    catch [System.NotSupportedException] { return $false }
    catch [System.IO.PathTooLongException] { return $false }
}
