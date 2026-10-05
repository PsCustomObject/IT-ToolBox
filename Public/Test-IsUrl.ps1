function Test-IsUrl
{
    <#
    .SYNOPSIS
        Tests absolute HTTP, HTTPS, FTP and FTPS URL syntax without network access.

    .DESCRIPTION
        Accepts DNS/IDN names, localhost, strict dotted IPv4, bracketed IPv6, optional
        numeric ports (0-65535), paths, query strings and fragments. DNS root dots are
        accepted. Rejects credentials, whitespace, controls, backslashes, malformed
        escapes, IPv4 shorthand and IPv6 scope identifiers. This does not test endpoint
        availability or establish that a URL is safe to fetch.

    .PARAMETER Url
        An absolute URL. Null, empty and malformed values return false.

    .EXAMPLE
        Test-IsUrl -Url 'https://example.com:8443/api?name=value#section'

    .EXAMPLE
        'https://example.com', '/relative' | Test-IsUrl
    #>

    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Url
    )

    process
    {
        # Reject blank values, whitespace, control characters, and non-literal URL syntax.
        if ([string]::IsNullOrWhiteSpace($Url) -or $Url -match '[\s\p{Cc}\\]')
        {
            return $false
        }

        [System.Uri]$parsed = $null

        if (-not [System.Uri]::TryCreate($Url, [System.UriKind]::Absolute, [ref]$parsed))
        {
            return $false
        }

        if ($parsed.Scheme -notin @('http', 'https', 'ftp', 'ftps') -or
            -not $parsed.IsWellFormedOriginalString() -or $parsed.UserInfo.Length -gt 0)
        {
            return $false
        }

        # Validate the original authority because Uri may normalize shorthand IPv4 and omit an empty port.
        if ($Url -notmatch '^[a-zA-Z]+://([^/?#]+)')
        {
            return $false
        }

        $authority = $Matches[1]

        if ($authority -notmatch '^(?<host>\[[^\]]+\]|[^:]+)(?::(?<port>[0-9]+))?$')
        {
            return $false
        }

        $hostText = $Matches['host']
        $portText = $Matches['port']

        if ($portText)
        {
            [int]$port = 0

            if (-not [int]::TryParse($portText, [ref]$port) -or $port -gt 65535)
            {
                return $false
            }
        }

        if ($hostText.StartsWith('['))
        {
            # Bracketed IPv6 literal hosts are validated as raw IP addresses without scope identifiers.
            $ip = $hostText.Substring(1, $hostText.Length - 2)
            return ($ip.Contains(':') -and -not $ip.Contains('%') -and (Test-IsIP -IP $ip))
        }

        if ($parsed.HostNameType -eq [System.UriHostNameType]::IPv4 -or $hostText -match '^[0-9.]+$')
        {
            return (Test-IsIP -IP $hostText)
        }

        return (Test-ITToolBoxDnsName -Name $hostText -AllowRootDot)
    }
}
