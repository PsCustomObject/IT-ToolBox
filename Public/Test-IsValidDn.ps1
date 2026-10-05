function Test-IsValidDn {
    <#
    .SYNOPSIS
    Tests a practical nonempty distinguished-name string syntax.
    .DESCRIPTION
    Supports attribute descriptors/OIDs, escaped separators, hex escapes and
    multi-valued RDNs. Does not require CN/OU/DC attributes or a DC suffix. Rejects
    empty attribute values, literal controls, dangling/invalid escapes, unescaped
    edge spaces and legacy quoted values. Hex-string notation is checked without
    validating BER contents. No schema, directory existence, canonical equality
    or decoded UTF-8 validation is performed; this is not a complete RFC parser.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowNull()][AllowEmptyString()]
        [Alias('DN', 'DistinguishedName')]
        [string]$ObjectDN
    )
    process { return (Test-ITToolBoxDnSyntax -Value $ObjectDN) }
}
