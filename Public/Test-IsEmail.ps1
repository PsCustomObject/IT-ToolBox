function Test-IsEmail
{
    <#
    .SYNOPSIS
        Tests common bare email-address syntax without contacting a mail server.

    .DESCRIPTION
        Accepts an ASCII dot-atom local part and a DNS domain, including an IDN domain
        and single-label names. The local part is limited to 64 ASCII characters and
        the complete address to 254 characters after IDN conversion.
        Rejects display names, comments, quoted local parts, address literals, Unicode
        local parts, surrounding whitespace and controls. This is a practical subset,
        not a complete RFC parser or proof of mailbox existence or deliverability.

    .PARAMETER EmailAddress
        A bare email address. Null, empty and malformed values return false.

    .EXAMPLE
        Test-IsEmail -EmailAddress 'person+tag@example.com'

    .EXAMPLE
        'person@example.com', 'invalid' | Test-IsEmail
    #>

    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        [Alias('Email', 'Mail', 'Address')]
        [string]$EmailAddress
    )

    process
    {
        # Reject blank values and any embedded whitespace or control characters.
        if ([string]::IsNullOrWhiteSpace($EmailAddress) -or $EmailAddress -match '[\s\p{Cc}]')
        {
            return $false
        }

        [System.Net.Mail.MailAddress]$parsed = $null

        # Use the framework parser to reject malformed addresses and non-bare syntaxes.
        if (-not [System.Net.Mail.MailAddress]::TryCreate($EmailAddress, [ref]$parsed) -or
            $parsed.Address -cne $EmailAddress -or $parsed.DisplayName.Length -gt 0)
        {
            return $false
        }

        # ASCII dot-atom policy deliberately excludes quoted and internationalized local parts.
        if ($parsed.User.Length -gt 64 -or
            $parsed.User -cnotmatch '^[a-zA-Z0-9!#$%&''*+/=?^_`{|}~-]+(?:\.[a-zA-Z0-9!#$%&''*+/=?^_`{|}~-]+)*$')
        {
            return $false
        }

        if (-not (Test-ITToolBoxDnsName -Name $parsed.Host))
        {
            return $false
        }

        # Convert the domain to its ASCII form for the final total-length check.
        $asciiDomain = [System.Globalization.IdnMapping]::new().GetAscii($parsed.Host)

        return ($parsed.User.Length + 1 + $asciiDomain.Length -le 254)
    }
}
