function Test-IsEmail
{
	<#
	.SYNOPSIS
		Function to check if a string is an RFC email address.
	
	.DESCRIPTION
		Function will check if an input string is an RFC complient email address. 
	
	.PARAMETER EmailAddress
		A string representing the email address to be checked
	
	.EXAMPLE
		PS C:\> Test-IsEmail -EmailAddress 'value1'
	
	.OUTPUTS
		System.Boolean
	
	.LINK
		Restrictions on email addresses
		https://tools.ietf.org/html/rfc3696#section-3
	#>
	
	[OutputType([bool])]
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[Alias('Email', 'Mail', 'Address')]
		[string]
		$EmailAddress
	)
	
	try
	{
		# Check if address is RFC compliant	
		[void]([mailaddress]$EmailAddress)
		
		Write-Verbose -Message "Address $EmailAddress is an RFC compliant address"
		
		return $true
	}
	catch
	{
		Write-Verbose -Message "Address $EmailAddress is not an RFC compliant address"
		
		return $false
	}
}