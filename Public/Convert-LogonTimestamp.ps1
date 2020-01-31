function Convert-LogonTimeStamp
{
<#
    .SYNOPSIS
        Will convert a logontimstamp to human redeable format.
    
    .DESCRIPTION
        LastLoginTimeStamp attribute in AD stores the time a user last authenticated to the domain in LONG format
        which is hard to parse and read.
        
        Function will take the attribute value, either as a string or long value, and return a DateTimeObject by default
        or a string.
    
    .PARAMETER TimeStamp
        The value to convert to human redeable format.
    
    .PARAMETER StringOutput
        When specified paramater will convert output to string rather than datetime.
    
    .PARAMETER DateFormat
        Available only when -StringOutput parameter is specified allows user to format the format of return string
        if not specified date string will be formatted as YYYY-MM-dd
    
    .EXAMPLE
        PS C:\> Convert-LogonTimeStamp -TimeStamp $lastLogin
    
    .OUTPUTS
        System.String, System.DateTime
#>
    
    [CmdletBinding(DefaultParameterSetName = 'Default',
                   HelpUri = 'https://PsCustomObject.github.io',
                   SupportsShouldProcess = $true)]
    [OutputType([datetime], ParameterSetName = 'Default')]
    [OutputType([string], ParameterSetName = 'StringOutput')]
    param
    (
        [Parameter(ParameterSetName = 'Default',
                   Mandatory = $true)]
        [Parameter(ParameterSetName = 'StringOutput',
                   Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $TimeStamp,
        [Parameter(ParameterSetName = 'StringOutput')]
        [switch]
        $StringOutput,
        [Parameter(ParameterSetName = 'StringOutput')]
        [ValidateNotNullOrEmpty()]
        [string]
        $DateFormat = 'yyyy-MM-dd'
    )
    
    switch ($PsCmdlet.ParameterSetName)
    {
        'Default'
        {
            try
            {
                # Return the datetime object
                return [datetime]::FromFileTime($TimeStamp)
            }
            catch
            {
                throw
            }
            
            break
        }
        'StringOutput'
        {
            try
            {
                if ($PSBoundParameters.ContainsKey('DateFormat'))
                {
                    # Format according to user passed format
                    return [datetime]::FromFileTime($TimeStamp).ToString($DateFormat)
                }
                else
                {
                    # Use default format
                    return [datetime]::FromFileTime($TimeStamp).ToString($DateFormat)
                }                
            }
            
            catch
            {
                throw
            }
            
            break
        }
    }
}