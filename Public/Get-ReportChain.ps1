function Get-ReportChain
{
    <#
    .SYNOPSIS
    Returns users reporting directly or transitively to an AD manager.

    .DESCRIPTION
    Resolves exactly one manager and queries AD's matching-rule-in-chain manager
    relationship. Excludes the manager from results. Escapes LDAP assertion values,
    applies DomainController to both queries and propagates errors. Requires the
    optional ActiveDirectory Get-ADUser command at invocation, not module import.
    Results are selected in Properties order; * returns all requested properties.
    #>

    [CmdletBinding(DefaultParameterSetName = 'DistinguishedName')]
    [OutputType([pscustomobject])]
    param(
        [Parameter(ParameterSetName = 'SamAccountName', Mandatory = $true)]
        [ValidateNotNullOrEmpty()][Alias('UserSam', 'SAM')]
        [string]$SamAccountName,
        [Parameter(ParameterSetName = 'UserPrincipalName', Mandatory = $true)]
        [ValidateNotNullOrEmpty()][Alias('UPN', 'UserUPN')]
        [string]$UserPrincipalName,
        [Parameter(ParameterSetName = 'DistinguishedName', Mandatory = $true)]
        [ValidateNotNullOrEmpty()][Alias('DN', 'DistinguishedName')]
        [string]$UserDN,
        [ValidateNotNullOrEmpty()]
        [string]$DomainController,
        [ValidateNotNullOrEmpty()]
        [string[]]$Properties = @('SamAccountName', 'UserPrincipalName', 'Mail', 'Manager', 'DirectReports')
    )
    foreach ($property in $Properties)
    {
        if ([string]::IsNullOrWhiteSpace($property))
        {
            throw 'Properties must contain nonempty property names.'
        }
    }

    if ($PSBoundParameters.ContainsKey('DomainController') -and [string]::IsNullOrWhiteSpace($DomainController))
    {
        throw 'DomainController cannot be whitespace.'
    }

    # Build the identity query used to resolve exactly one manager.
    $lookup = @{ Properties = $Properties; ErrorAction = 'Stop' }

    switch ($PSCmdlet.ParameterSetName)
    {
        'SamAccountName'
        {
            if ([string]::IsNullOrWhiteSpace($SamAccountName))
            {
                throw 'SamAccountName cannot be whitespace.'
            }
            $lookup.Identity = $SamAccountName
        }

        'UserPrincipalName'
        {
            if (-not (Test-IsValidUpn $UserPrincipalName))
            {
                throw 'UserPrincipalName does not match the supported UPN syntax policy.'
            }

            $escapedUpn = ConvertTo-ITToolBoxLdapFilterValue $UserPrincipalName

            $lookup.LDAPFilter = '(userPrincipalName={0})' -f $escapedUpn
        }

        'DistinguishedName'
        {
            if (-not (Test-IsValidDn $UserDN))
            {
                throw 'UserDN does not match the supported DN syntax policy.'
            }

            $lookup.Identity = $UserDN
        }
    }

    if ($DomainController)
    {
        $lookup.Server = $DomainController
    }

    $managers = @(Invoke-ITToolBoxAdUser -Query $lookup)

    if ($managers.Count -ne 1)
    {
        throw 'Manager lookup must resolve exactly one user.'
    }

    $managerDn = [string]$managers[0].DistinguishedName

    if (-not (Test-IsValidDn $managerDn))
    {
        throw 'The resolved manager did not return a supported distinguished name.'
    }

    $escapedDn = ConvertTo-ITToolBoxLdapFilterValue $managerDn

    # Find the manager's direct and indirect reports, excluding the manager.
    $query = @{
        Properties  = $Properties
        LDAPFilter  = '(&(manager:1.2.840.113556.1.4.1941:={0})(!(distinguishedName={0})))' -f $escapedDn
        ErrorAction = 'Stop'
    }

    if ($DomainController)
    {
        $query.Server = $DomainController
    }

    Invoke-ITToolBoxAdUser -Query $query | Select-Object -Property $Properties
}
