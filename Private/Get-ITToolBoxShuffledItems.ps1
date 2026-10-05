function Get-ITToolBoxShuffledItems
{
    param
    (
        [object[]]$Items
    )

    # Fisher-Yates: shuffle a copy without changing the caller's collection.
    [object[]]$result = $Items.Clone()

    for ($index = $result.Length - 1; $index -gt 0; $index--)
    {
        $other = Get-ITToolBoxRandomIndex -UpperBound ($index + 1)
        $temporary = $result[$index]
        $result[$index] = $result[$other]
        $result[$other] = $temporary
    }

    return $result
}
