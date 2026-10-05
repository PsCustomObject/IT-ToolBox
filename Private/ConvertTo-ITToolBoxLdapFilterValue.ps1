function ConvertTo-ITToolBoxLdapFilterValue
{
    param ([string]$Value)

    $builder = [System.Text.StringBuilder]::new()

    # LDAP filter values escape control bytes and special characters before the value is returned.
    foreach ($byte in [System.Text.UTF8Encoding]::new($false, $true).GetBytes($Value))
    {
        # These bytes are reserved by the filter syntax or are outside the printable ASCII range.
        if ($byte -in @(0, 40, 41, 42, 92) -or $byte -ge 128)
        {
            [void]$builder.Append('\').Append($byte.ToString('x2'))
        }
        else
        {
            # Keep printable characters as-is so the output stays readable.
            [void]$builder.Append([char]$byte)
        }
    }

    return $builder.ToString()
}
