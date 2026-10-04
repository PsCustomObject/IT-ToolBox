function New-RandomString {
    <#
    .SYNOPSIS
    Generates a string using the original character alphabet and secure random selection.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param([ValidateRange(1,4096)][int]$StringLength = 12)
    [string]$characters = 'ABCDE@#FGH]IJKL12MNOP_!Q{RSTUV89WXYZa}bcd67ef[ghijklmnopq(rs%^&tuvwxyz)03$*45'
    $result = [System.Text.StringBuilder]::new($StringLength)
    for ($index = 0; $index -lt $StringLength; $index++) {
        [void]$result.Append($characters[(Get-ITToolBoxRandomIndex -UpperBound $characters.Length)])
    }
    return $result.ToString()
}
