function Test-IsValidDN
{
    <#
        .SYNOPSIS
            Cmdlet will check if the input string is a valid distinguishedname.
        
        .DESCRIPTION
            Cmdlet will check if the input string is a valid distinguishedname.
            
            Cmdlet is intended as a dignostic tool for input validation
        
        .PARAMETER ObjectDN
            A string representing the object distinguishedname.
        
        .EXAMPLE
            PS C:\> Test-IsValidDN -ObjectDN 'Value1'
        
        .NOTES
            Additional information about the function.
    #>
    
    [OutputType([bool])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('DN', 'DistinguishedName')]
        [string]
        $ObjectDN
    )
    
    # Define DN Regex
    [regex]$distinguishedNameRegex = '^(?:(?<cn>CN=(?<name>(?:[^,]|\,)*)),)?(?:(?<path>(?:(?:CN|OU)=(?:[^,]|\,)+,?)+),)?(?<domain>(?:DC=(?:[^,]|\,)+,?)+)$'
    
    return $ObjectDN -match $distinguishedNameRegex
}