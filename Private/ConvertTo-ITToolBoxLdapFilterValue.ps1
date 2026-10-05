function ConvertTo-ITToolBoxLdapFilterValue {
    param([string]$Value)
    $builder = [System.Text.StringBuilder]::new()
    foreach ($byte in [System.Text.UTF8Encoding]::new($false, $true).GetBytes($Value)) {
        if ($byte -in @(0, 40, 41, 42, 92) -or $byte -ge 128) {
            [void]$builder.Append('\').Append($byte.ToString('x2'))
        }
        else { [void]$builder.Append([char]$byte) }
    }
    return $builder.ToString()
}
