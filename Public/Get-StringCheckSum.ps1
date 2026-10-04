function Get-StringCheckSum {
    <#
    .SYNOPSIS
    Returns a UTF-8 text checksum as uppercase hyphen-separated hexadecimal bytes.
    .DESCRIPTION
    MD5 remains the default for compatibility with existing checksums. It is for
    non-security comparison only. SHA256, SHA384 and SHA512 can be selected explicitly.
    An unkeyed digest does not authenticate data or provide password storage.
    Text is encoded as supplied without Unicode normalization or a BOM.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$StringToCheck,
        [ValidateSet('MD5','SHA256','SHA384','SHA512')][string]$Algorithm = 'MD5'
    )
    [byte[]]$digest = Get-ITToolBoxStringDigest -Text $StringToCheck -Algorithm $Algorithm
    return [BitConverter]::ToString($digest)
}
