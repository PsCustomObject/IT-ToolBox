function New-StringEncryption
{
<#
	.SYNOPSIS
		Encryps a string using RijndaelManaged Cryptography
	
	.DESCRIPTION
		New-StringEncryption is used to encrypt a string using RijndaelManaged Cryptography allowing
		user to specify Salt, Passphrase and Intersecting Vector values.
		
		For security reason Intersecting Vector (IV) value should be changed on each machine.
	
	.PARAMETER StringToEncrypt
		Any string that needs to be encrypted. Parameter is mandatory and cannot be empty.
	
	.PARAMETER EncryptPassPhrase
		An optional passphrase to be used during the encryption process.
		
		If parameter is not specified hostname value will be used.
	
	.PARAMETER EncryptSalt
		Specify a custom string to use as the Encryption Salt will
		default to computername if not specified
	
	.PARAMETER IntersectingVector
		Intersecting Vector value used in the encryption process. If parameter is not used a
		default value is used but for security reasons this should be updated to a custom value.
	
	.EXAMPLE
		PS C:\> New-StringEncryption
	
	.NOTES
		Additional information about the function.
#>
	
	[OutputType([string])]
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[Alias('string')]
		[string]
		$StringToEncrypt,
		[ValidateNotNullOrEmpty()]
		[Alias('PassPhrase', 'EncryptionPassPhrase')]
		[string]
		$EncryptPassPhrase,
		[ValidateNotNullOrEmpty()]
		[Alias('Salt', 'SaltValue')]
		[string]
		$EncryptSalt,
		[ValidateNotNullOrEmpty()]
		[Alias('Vector')]
		[string]
		$IntersectingVector = 'Q!L@2QTCYgsG'
	)
	
	# Instantiate empty return value
	[string]$returnValue = $null
	
	# Instantiate COM Object for RijndaelManaged Cryptography
	[System.Security.Cryptography.RijndaelManaged]$encryptionObject = New-Object System.Security.Cryptography.RijndaelManaged
	
	# Check if we have a passphrase
	if ([string]::IsNullOrEmpty($EncryptPassPhrase) -eq $true)
	{
		$EncryptPassPhrase = $env:Computername
		#$PassPhrase = New-RandomString -StringLength 14
	}
	
	# Check if we have a salt value
	if ([string]::IsNullOrEmpty($EncryptSalt) -eq $true)
	{
		$EncryptSalt = $env:Computername
		#$EncryptSalt = New-RandomString -StringLength 12
	}
	
	# Convert Salt and Passphrase to UTF8 Bytes array
	[System.Byte[]]$byteEncryptSalt = [Text.Encoding]::UTF8.GetBytes($EncryptSalt)
	[System.Byte[]]$bytePassPhrase = [Text.Encoding]::UTF8.GetBytes($EncryptPassPhrase)
	
	# Create the Encryption Key using the passphrase, salt and SHA1 algorithm at 256 bits 
	$encryptionObject.Key = (New-Object Security.Cryptography.PasswordDeriveBytes $bytePassPhrase,
										$byteEncryptSalt,
										'SHA1',
										5).GetBytes(32) # 256/8 - 32bytes
	
	# Create the Intersecting Vector (IV) Cryptology Hash with the init value
	$paramNewObject = @{
		TypeName = 'Security.Cryptography.SHA1Managed'
	}
	$encryptionObject.IV = (New-Object @paramNewObject).ComputeHash([Text.Encoding]::UTF8.GetBytes($IntersectingVector))[0 .. 15]
	
	# Starts the New Encryption using the Key and IV
	$encryptorObject = $encryptionObject.CreateEncryptor()
	
	# Creates a MemoryStream for encryption
	[System.IO.MemoryStream]$memoryStream = New-Object IO.MemoryStream
	
	# Creates the new Cryptology Stream --> Outputs to $MS or Memory Stream 
	[System.Security.Cryptography.CryptoStream]$cryptoStream = New-Object Security.Cryptography.CryptoStream $memoryStream, $encryptorObject, 'Write'
	
	# Starts the new Cryptology Stream
	$cryptoStreamWriter = New-Object IO.StreamWriter $cryptoStream
	
	# Writes the string in the Cryptology Stream 
	$cryptoStreamWriter.Write($StringToEncrypt)
	
	# Stops the stream writer 
	$cryptoStreamWriter.Close()
	
	# Stops the Cryptology Stream 
	$cryptoStream.Close()
	
	# Stops writing to Memory 
	$memoryStream.Close()
	
	# Clears the IV and HASH from memory to prevent memory read attacks 
	$encryptionObject.Clear()
	
	# Takes the MemoryStream and puts it to an array 
	[byte[]]$result = $memoryStream.ToArray()
	
	# Converts the array from Base 64 to a string and returns 
	$returnValue = $([Convert]::ToBase64String($result))
	
	# Return value
	return $returnValue
}