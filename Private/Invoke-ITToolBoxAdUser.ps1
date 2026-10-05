function Invoke-ITToolBoxAdUser
{
    param
    (
        [hashtable]$Query
    )

    if (-not (Get-Command Get-ADUser -ErrorAction SilentlyContinue))
    {
        throw [InvalidOperationException]::new('Get-ReportChain requires Get-ADUser from the ActiveDirectory module and a reachable AD endpoint.')
    }

    Get-ADUser @Query
}
