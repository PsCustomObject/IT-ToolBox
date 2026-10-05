function New-RandomPassword
{
    <#
    .SYNOPSIS
        Generates a password from the original punctuation, digit, and letter alphabet.

    .DESCRIPTION
        Retains the 8-character default and Complex switch for compatibility.
        Complex did not change the historical character selection and remains equivalent
        to the default. Use New-PhoneticPassword for exact character-category counts.
        Characters are independently selected with replacement using a cryptographic RNG.
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param (
        [ValidateRange(1, 4096)]
        [int]$PasswordLength = 8,

        [switch]$Complex
    )

    # Build the full character set and select each character at random with replacement.
    [char[]]$characters = @(33..47) + @(48..57) + @(58..64) + @(92..96) + @(123..126) + @(65..90) + @(97..122)
    $result = [System.Text.StringBuilder]::new($PasswordLength)

    for ($index = 0; $index -lt $PasswordLength; $index++)
    {
        [void]$result.Append($characters[(Get-ITToolBoxRandomIndex -UpperBound $characters.Length)])
    }

    return $result.ToString()
}
