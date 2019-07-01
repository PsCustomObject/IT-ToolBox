function Test-IsValidUpn
{
	<#
		.SYNOPSIS
			Function will check if string is a valid UPN.
		
		.DESCRIPTION
			Function is similar to Test-IsValidUpn but used to check
			if input string is a valid Active Directory UPN using
			a regex.
		
		.PARAMETER UserUpn
			A string containing an AD UPN (Universal Principal
			Name)
		
		.NOTES
			Function is using a different mechanism than the Test-IsValidUpn
			on as a valid email address could be an invalid AD UPN.
		
			Example: me@myself..com # Valid email address but invalid
			AD UPN
		
		.OUTPUTS
			System.Boolean
	#>
	
	[OutputType([Boolean])]
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[Alias('UPN', 'ADUpn', 'UniversalPrincipalName')]
		[string]$UserUpn
	)
	
	[string]$UpnRegEx = "^(?("")("".+?""@)|(([0-9a-zA-Z]((\.(?!\.))|"
	$UpnRegEx += "[-!#\$%&'\*\+/=\?\^`\{\}\|~\w])*)(?<=[0-9a-zA-Z])@))"
	$UpnRegEx += "(?(\[)(\[(\d{1,3}\.){3}\d{1,3}\])|"
	$UpnRegEx += "(([0-9a-zA-Z][-\w]*[0-9a-zA-Z]\.)+[a-zA-Z]{2,6}))$"
	
	# Return $true if valid
	return $UserUpn -match $UpnRegEx
}