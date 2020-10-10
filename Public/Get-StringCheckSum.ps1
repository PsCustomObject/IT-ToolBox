function Get-StringCheckSum
{
<#
    .SYNOPSIS
        Cmdlet calculate MD5 checksum of a string.
    
    .DESCRIPTION
        Cmdlet calculate MD5 checksum of a string.
    
    .PARAMETER StringToCheck
        A string representing the text for which the checksum should be calculated.
    
    .EXAMPLE
        PS C:\> Get-StringCheckSum -StringToCheck 'Value1'
#>
    
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $StringToCheck
    )
    
    # Instantiate required objects
    $md5Object = [System.Security.Cryptography.MD5CryptoServiceProvider]::Create()
    $encodingObject = [System.Text.UTF8Encoding]::UTF8
    
    return [System.BitConverter]::ToString($md5Object.ComputeHash($encodingObject.GetBytes($StringToCheck)))
}