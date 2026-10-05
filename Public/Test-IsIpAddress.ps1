function Test-IsIP
{
    <#
    .SYNOPSIS
        Tests IPv4 and IPv6 address literals.

    .DESCRIPTION
        IPv4 must contain four decimal octets without leading zeros. IPv6 uses .NET
        parsing and can include a numeric scope ID. Hostnames, CIDR, bracketed IPv6,
        surrounding whitespace, and abbreviated or hexadecimal IPv4 values are rejected.
    #>

    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [AllowNull()]
        [AllowEmptyString()]
        [string]$IP
    )

    # Reject null, blank, surrounding whitespace, and CIDR/bracket syntax that is not a literal address.
    if ([string]::IsNullOrWhiteSpace($IP) -or $IP -ne $IP.Trim() -or $IP -match '[/\[\]]')
    {
        return $false
    }

    [System.Net.IPAddress]$address = $null

    if (-not [System.Net.IPAddress]::TryParse($IP, [ref]$address))
    {
        return $false
    }

    # IPv4 values must use a dotted-quad pattern with no leading-zero octets.
    $dottedQuadIpv4Pattern = '^(?:0|[1-9][0-9]{0,2})(?:\.(?:0|[1-9][0-9]{0,2})){3}$'

    if ($address.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork)
    {
        return $IP -cmatch $dottedQuadIpv4Pattern
    }

    # IPv4-mapped IPv6 addresses must still use decimal dotted-quad notation in their final segment.
    if ($IP.Contains('.'))
    {
        $tail = ($IP -split ':')[-1] -replace '%.*$', ''

        if ($tail -cnotmatch $dottedQuadIpv4Pattern)
        {
            return $false
        }
    }

    return $true
}
