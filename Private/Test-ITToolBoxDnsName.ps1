function Test-ITToolBoxDnsName {
    param([string]$Name, [switch]$AllowRootDot)

    if ([string]::IsNullOrWhiteSpace($Name)) { return $false }
    if ($AllowRootDot -and $Name.EndsWith('.')) { $Name = $Name.Substring(0, $Name.Length - 1) }

    try {
        $idn = [System.Globalization.IdnMapping]::new()
        $idn.UseStd3AsciiRules = $true
        $ascii = $idn.GetAscii($Name)
    }
    catch [System.ArgumentException] { return $false }

    if ($ascii.Length -gt 253) { return $false }
    foreach ($label in $ascii.Split('.')) {
        if ($label.Length -gt 63 -or $label -cnotmatch '^[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?$') {
            return $false
        }
    }
    return $true
}
