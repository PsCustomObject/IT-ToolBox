function Get-ITToolBoxRandomIndex
{
    param
    (
        [int]$UpperBound
    )

    return [System.Security.Cryptography.RandomNumberGenerator]::GetInt32($UpperBound)
}
