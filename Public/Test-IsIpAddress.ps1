function Test-IsIP {
    <#
    .SYNOPSIS
    Tests IPv4 and IPv6 address literals.
    .DESCRIPTION
    IPv4 must contain four decimal octets, without leading zeros. IPv6 uses .NET
    parsing and can include a numeric scope ID. Hostnames, CIDR, bracketed IPv6,
    surrounding whitespace and abbreviated/hexadecimal IPv4 are rejected.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param([AllowNull()][AllowEmptyString()][string]$IP)

    if ([string]::IsNullOrWhiteSpace($IP) -or $IP -ne $IP.Trim() -or $IP -match '[/\[\]]') { return $false }
    [System.Net.IPAddress]$address = $null
    if (-not [System.Net.IPAddress]::TryParse($IP, [ref]$address)) { return $false }
    if ($address.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork) {
        return $IP -cmatch '^(?:0|[1-9][0-9]{0,2})(?:\.(?:0|[1-9][0-9]{0,2})){3}$'
    }
    # Also enforce decimal dotted notation inside IPv4-mapped IPv6.
    if ($IP.Contains('.')) {
        $tail = ($IP -split ':')[-1] -replace '%.*$', ''
        if ($tail -cnotmatch '^(?:0|[1-9][0-9]{0,2})(?:\.(?:0|[1-9][0-9]{0,2})){3}$') { return $false }
    }
    return $true
}
