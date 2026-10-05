function Test-IsValidUpn {
    <#
    .SYNOPSIS
    Tests a practical UPN syntax policy without directory access.
    .DESCRIPTION
    Requires one @ separator. The ASCII username starts/ends with a letter or
    digit and may contain dots, underscores, hyphens and apostrophes internally;
    consecutive dots are rejected. The suffix is a DNS/IDN name, including a
    single-label name or long suffix. No email parsing, account existence, suffix
    registration or complete AD/Entra account-creation policy is implied.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowNull()][AllowEmptyString()]
        [Alias('UPN', 'ADUpn', 'UniversalPrincipalName')]
        [string]$UserUpn
    )
    process {
        if ([string]::IsNullOrWhiteSpace($UserUpn) -or $UserUpn -match '[\s\p{Cc}]') { return $false }
        $parts = $UserUpn.Split('@')
        if ($parts.Count -ne 2 -or $parts[0].Contains('..') -or
            $parts[0] -cnotmatch '^[a-zA-Z0-9](?:[a-zA-Z0-9._''-]*[a-zA-Z0-9])?$') { return $false }
        return (Test-ITToolBoxDnsName -Name $parts[1])
    }
}
