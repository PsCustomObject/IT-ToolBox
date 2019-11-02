function New-StringDecryption
{
  <#
      .SYNOPSIS
      Cmdlet will decode a base64 encrypted string
	
      .DESCRIPTION
      Function will take as input a base64 encrypted string and output the unencrypted string
	
      .PARAMETER EncryptedString
      The string to be decrypted
	
      .PARAMETER EncryptPassPhrase
      A string representing the encryption passphrase to be used to decrypt the string.
		
      If not specified hostname of the computer where function is invoked will be used.
	
      .PARAMETER EncryptSalt
      A string representing the encryption salt to use to decrypt the string.
		
      If not specified hostname of the computer where function is invoked will be used.
	
      .PARAMETER IntersectingVector
      A string representing the intersecting vector to be used during strict decryption.
		
      If not specified it will default to a standard value which must match the one used to encrypt the string.
		
      For better security this should be changed to a custom string eatch time.
	
      .EXAMPLE
      PS C:\> New-StringDecryption
	
      .OUTPUTS
      System.String
  #>
	
	[OutputType([string])]
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$EncryptedString,
		[ValidateNotNullOrEmpty()]
		[string]
		$EncryptPassPhrase = $env:Computername,
		[ValidateNotNullOrEmpty()]
		[string]
		$EncryptSalt = $env:Computername,
		[ValidateNotNullOrEmpty()]
		[string]
		$IntersectingVector = 'Q!L@2QTCYgsG'
	)
	
	# Instantiate empty return value
	[string]$DecryptedString = $null
	
	# Regex to check if string is in the correct format
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
	[System.Security.Cryptography.RijndaelManagedTransform]$objectDecryptor = $encryptionObject.CreateDecryptor()
	
	# Create a New memory stream with the encrypted value
	[System.IO.MemoryStream]$memoryStream = New-Object IO.MemoryStream  @( ,$encryptedStringByte)
	
	# Read the new memory stream and read it in the cryptology stream
	[System.Security.Cryptography.CryptoStream]$cryptoStream = New-Object Security.Cryptography.CryptoStream $memoryStream, $objectDecryptor, 'Read'
	
	# Read the new decrypted stream 
	[System.IO.StreamReader]$streamReader = New-Object IO.StreamReader $cryptoStream
	
	try
	{
		# Return from the function the stream 
		[string]$DecryptedString = $streamReader.ReadToEnd()
		
		# Stop the stream     
		$streamReader.Close()
		
		# Stop the crypto stream 
		$cryptoStream.Close()
		
		# Stop the memory stream 
		$memoryStream.Close()
		
		# Clears all crypto objects 
		$encryptionObject.Clear()
		
		# Return decrypted string
		return $DecryptedString
	}
	
	catch
	{
		# Save exception
		[string]$reportedException = $Error[0].Exception.Message
		
		Write-Warning -Message "String $EncryptedString could not be decripted - Use the -Verbose paramter for more details"
		
		# Check we have an exception message
		if ([string]::IsNullOrEmpty($reportedException) -eq $false)
		{
			Write-Verbose -Message $reportedException
		}
		else
		{
			Write-Verbose -Message 'No inner exception reported by Disconnect-AzureAD cmdlet'
		}
		
		return [string]::Empty
	}	
}