function Get-StringHashCode
{
<#
    .SYNOPSIS
        Cmdlet will return hash of the supplied string.
    
    .DESCRIPTION
        Cmdlet will return hash of the supplied string.
    
    .PARAMETER StringToHash
        A string representing text to hash.
    
    .EXAMPLE
        PS C:\> Get-StringHashCode -TextToHash 'value1'
#>
    
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $StringToHash
    )
    
    # Crete new string builder
    [System.Text.StringBuilder]$hashString = [System.Text.StringBuilder]::new()
    
    # Get bytes
    [byte[]]$hashText = [System.Text.Encoding]::UTF8.GetBytes($StringToHash)
    
    # Instantiate new object instance
    [System.Security.Cryptography.SHA256Managed]$textHasher = New-Object -TypeName System.Security.Cryptography.SHA256Managed
    
    [array]$hashByteArray = $textHasher.ComputeHash($hashText)
    
    foreach ($byte in $hashByteArray)
    {
        # Append value
        [void]($hashString.Append($byte.ToString()))
    }
    
    return $hashString.ToString()
}