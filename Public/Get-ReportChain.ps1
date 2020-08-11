function Get-ReportChain
{
    <#
        .SYNOPSIS
            Cmdlet will get a complete report of all users reporting to a specific manager.
        
        .DESCRIPTION
            Cmdlet will get a complete report of all users reporting to a specific manager.
            
            By default the following properties are returned:
            
            - SamAccountName
            - UserPrincipalName
            - Mail
            - Manager
            - DirectReports
            
            Custom properties can be returned via the -Properties parameter
        
        .PARAMETER SamAccountName
            A string representing the SamAccountName of the mager for which reports should be enumerated.
        
        .PARAMETER UserPrincipalName
            A string representing the UserPrincipalName of the mager for which reports should be enumerated.
        
        .PARAMETER UserDN
            A string representing the UserPrincipalName of the mager for which reports should be enumerated.
        
        .PARAMETER DomainController
            A string representing the name of the domain controller that should be used to query Active Directory.
            
            If parameter is not specified a random domain controller will be automatically used.
        
        .PARAMETER Properties
            An array object representing user properties that should be returned as part of the results.
            
            Result array will be ordered by the Properties parameter.
    
            If all objects should be returned the * character can be used with the parameter.
        
        .EXAMPLE
            PS C:\> Get-ReportChain -UserDN 'value1'
        
        .OUTPUTS
            System.Array
    #>
    
    [CmdletBinding(DefaultParameterSetName = 'DistinguishedName',
                   SupportsPaging = $false,
                   SupportsShouldProcess = $false)]
    [OutputType([array])]
    param
    (
        [Parameter(ParameterSetName = 'SamAccountNAme',
                   Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('UserSam', 'SAM')]
        [string]
        $SamAccountName,
        [Parameter(ParameterSetName = 'UserPrincipalName',
                   Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('UPN', 'UserUPN')]
        [string]
        $UserPrincipalName,
        [Parameter(ParameterSetName = 'DistinguishedName',
                   Mandatory = $true)]
        [Alias('DN', 'DistinguishedName')]
        [string]
        $UserDN,
        [Parameter(ParameterSetName = 'DistinguishedName')]
        [Parameter(ParameterSetName = 'SamAccountNAme')]
        [Parameter(ParameterSetName = 'UserPrincipalName')]
        [ValidateNotNullOrEmpty()]
        [string]
        $DomainController,
        [Parameter(ParameterSetName = 'DistinguishedName')]
        [Parameter(ParameterSetName = 'SamAccountNAme')]
        [Parameter(ParameterSetName = 'UserPrincipalName')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Properties = @(
            'SamAccountName',
            'UserPrincipalName',
            'Mail',
            'Manager',
            'DirectReports'
        )
    )
    
    begin
    {
        # Prepare command hash
        [hashtable]$paramGetUserDn = @{
            Properties = $Properties
        }
        
        # Prepare command hash
        [hashtable]$paramGetADReportChain = @{
            Properties = $Properties
        }
        
        switch ($PsCmdlet.ParameterSetName)
        {
            'UserPrincipalName'
            {
                # Check if UPN is valid
                if (!(Test-IsEmail -EmailAddress $UserPrincipalName))
                {
                    throw "$UserPrincipalName is not a valid UPN"                    
                }
                else
                {
                    # Append to command hash
                    $paramGetUserDn.Add('Filter', "UserPrincipalName -eq '$UserPrincipalName'")
                }
            }
            'DistinguishedName'
            {
                # Check if DN is in the correct format
                if (!(Test-IsValidDN -ObjectDN $UserDN))
                {
                    throw "$UserDN is not a valid object DN"
                }
                else
                {
                    # Append to command hash
                    $paramGetUserDn.Add('Identity', $UserDN)
                }
            }
            'SamAccountName'
            {
                # Append to command hash
                $paramGetUserDn.Add('Identity', $SamAccountName)
            }
        }
    }
    
    process
    {
        try
        {
            # Check if we should use specific DC
            if ($PSBoundParameters.ContainsKey('DomainController'))
            {
                # Append parameter
                $paramGetUserDn.Add('Server', $DomainController)
                $paramGetADReportChain.Add('Server', $DomainController)
            }
            
            # Get object DN
            [string]$objectDn = (Get-ADUser @paramGetUserDn).'DistinguishedName'
            
            # Define LDAP filter
            [string]$ldapFilter = "(manager:1.2.840.113556.1.4.1941:=$objectDn)"
            
            # Append paramter
            $paramGetADReportChain.Add('LDAPFilter', $ldapFilter)
            
            [array]$reportChain = Get-ADUser @paramGetADReportChain | Select-Object -Property $Properties
        }
        catch
        {
            Write-Warning -Message "Could not find identity $object in AD"
        }
    }
    
    end
    {
        return $reportChain
    }
}