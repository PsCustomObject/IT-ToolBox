function New-RandomString
{
	param
	(
		[int]
		$StringLength = 12
	)
	
	# Instantiate return value
	[string]$retval = ''
	
	# Characters to user
	[string]$chars = 'ABCDE@#FGH]IJKL12MNOP_!Q{RSTUV89WXYZa}bcd67ef[ghijklmnopq(rs%^&tuvwxyz)03$*45'
	
	# Instantiate byte array object
	[byte[]]$bytes = New-Object 'System.Byte[]' $StringLength
	
	# Create RngObject
	[System.Security.Cryptography.RNGCryptoServiceProvider]$randomObject = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
	
	# Get bytes in random Object
	$randomObject.GetBytes($bytes)
	
	for ($index = 0; $index -lt $StringLength; $index++)
	{
		$retval += $chars[$bytes[$index] % $chars.Length]
	}
	
	return $retval
}