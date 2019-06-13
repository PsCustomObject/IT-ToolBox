function New-RandomPassword
{
	[CmdletBinding()]
	param
	(
		[int]
		$passwordLength,
		[switch]
		$complex
	)
	
	if ($passwordLength)
	{
		$passwordLength = $passwordLength
	}
	else
	{
		$passwordLength = 8
	}
	
	#ToDo
	# Create variable to hold charactersets for the various tyepe of passwords
	# like complex, special chars and so on. This will then be passed to the ForEach loop
	
	# Punctuation Characters like comma column etc.
	$punctuationChars = 33 .. 47 #Add 32 to also include spaces
	
	# Digit characters 0 to 9
	$digitChars = 48 .. 57
	
	# Special characters
	$specialChars = 58 .. 64 + 92 .. 96 + 123 .. 126
	
	# Both lower and upper case letters
	$letterChars = 65 .. 90 + 97 .. 122
	
	$password = Get-Random -Count $passwordLength -InputObject `
	($punctuationChars + $digitChars + $specialChars + $letterChars) |
	ForEach-Object -Begin {
		$tempPassword = $null
	} -Process {
		$tempPassword += [char]$_
	} -End {
		$tempPassword
	}
	
	return $password
}