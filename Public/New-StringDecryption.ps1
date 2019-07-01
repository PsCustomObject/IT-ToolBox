function New-StringDecryption
{
	[OutputType([string])]
	param
	(
		[string]
		$EncryptedString,
		[string]
		$EncryptPassPhrase,
		[string]
		$EncryptSalt,
		[string]
		$IntersectingVector = 'Q!L@2QTCYgsG'
	)
	
	# Instantiate empty return value
	[string]$returnValue = $null
	
	# Reg
	[regex]$base64RegEx = '^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{2}==)?$'
	
	# Instantiate COM Object for RijndaelManaged Cryptography 
	[System.Security.Cryptography.RijndaelManaged]$encryptionObject = New-Object System.Security.Cryptography.RijndaelManaged
	
	# If the value in the Encrypted is a string, convert it to Base64
	if ($EncryptedString -is [string])
	{
		# Check string is in correct format
		if ($EncryptedString -match $base64RegEx)
		{
			[byte[]]$encryptedStringByte = [Convert]::FromBase64String($EncryptedString)
		}
		else
		{
			Write-Warning -Message 'String is not base64 encoded!'
			
			return
		}
	}
	else
	{
		Write-Warning 'Input is not a string!'
		
		return
	}
	
	# Check if we have a passphrase
	if ([string]::IsNullOrEmpty($EncryptPassPhrase) -eq $true)
	{
		$EncryptPassPhrase = $env:Computername
	}
	
	# Check if we have a salt value
	if ([string]::IsNullOrEmpty($EncryptSalt) -eq $true)
	{
		$EncryptSalt = $env:Computername
	}
	
	# Convert Salt and Passphrase to UTF8 Bytes array
	[System.Byte[]]$byteEncryptSalt = [Text.Encoding]::UTF8.GetBytes($EncryptSalt)
	[System.Byte[]]$bytePassPhrase = [Text.Encoding]::UTF8.GetBytes($EncryptPassPhrase)
	
	
	# Create the Encryption Key using the passphrase, salt and SHA1 algorithm at 256 bits
	$encryptionObject.Key = (New-Object Security.Cryptography.PasswordDeriveBytes $bytePassPhrase,
										$byteEncryptSalt,
										'SHA',
										5).GetBytes(32) # 256/8 - 32byts
	
	# Create the Intersecting Vector Cryptology Hash with the init 
	$encryptionObject.IV = (New-Object Security.Cryptography.SHA1Managed).ComputeHash([Text.Encoding]::UTF8.GetBytes($IntersectingVector))[0 .. 15]
	
	# Create new decryptor Key and IV
	$objectDecryptor = $encryptionObject.CreateDecryptor()
	
	# Create a New memory stream with the encrypted value
	[System.IO.MemoryStream]$memoryStream = New-Object IO.MemoryStream  @( ,$encryptedStringByte)
	
	# Read the new memory stream and read it in the cryptology stream
	[System.Security.Cryptography.CryptoStream]$cryptoStream = New-Object Security.Cryptography.CryptoStream $memoryStream, $objectDecryptor, 'Read'
	
	# Read the new decrypted stream 
	[System.IO.StreamReader]$streamReader = New-Object IO.StreamReader $cryptoStream
	
	# Return from the function the stream 
	$returnValue = $streamReader.ReadToEnd()
	
	# Stops the stream     
	$streamReader.Close()
	
	# Stops the crypto stream 
	$cryptoStream.Close()
	
	# Stops the memory stream 
	$memoryStream.Close()
	
	# Clears all crypto objects 
	$encryptionObject.Clear()
	
	# Return 
	return $returnValue
}