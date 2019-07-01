function Test-EmailFormat
{
	<#
		.SYNOPSIS
			Function will check format of an email address.
	
		.DESCRIPTION
			Function will return $True if input string is a RFC
			compliant email address or $False if not.
		
		.PARAMETER EmailAddress
			A string representing the email address to be tested.
		
		.EXAMPLE
			PS C:\> Test-EmailFormat -EmailAddress 'test@sample.com'
		
		.NOTES
			Additional information about the function.
	#>
	
	[OutputType([Boolean])]
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[Alias('Email', 'Mail', 'MailAddress', 'Address')]
		[string]$EmailAddress
	)
	
	try
	{
		# Check email is RFC compliant address
		[void]::([mailaddress]$EmailAddress)
		
		return $truee
	}
	catch
	{
		# Invalid email
		return $false
	}
}