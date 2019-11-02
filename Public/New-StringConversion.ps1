function New-StringConversion
{
	<#
	.SYNOPSIS
		Function to remove any non-unicode character from a string.
	
	.DESCRIPTION
		Function is used to sanitize non-unicode characters from a string.
	
		Function supports ignoring white spaces in the string, complete
		removal of any white space, replacement with a default character
		or with any character specified by the user.
	
		Function supports custom characters map via the UnicodeHashTable
		parameter accepting an hashtable of characters to replace.
	
		If unknown characters, not specified in the default character map,
		are found they are replace with a question mark '?' but uer can
		specifiy any custom character of choice.
	
	.PARAMETER StringToConvert
		The string containing non unicode characters that needs to be normalized.
	
	.PARAMETER UnicodeHashTable
		Specify a custom hash of characters to replace.
	
	.PARAMETER IgnoreSpaces
		If specified white spaces will be ignored.
	
	.PARAMETER ReplaceSpace
		Used to specify character to use when string contains a white space which 
		by default are replaced by the dash '-' character.
	
	.PARAMETER RemoveSpaces
		Will return a string with any white space removed.
	
	.PARAMETER UnknownCharacter
		Allows user to specify which character to use as a replacement 
		for unrecognized characters.
		
		By default a question mark '?' is used.
	
	.EXAMPLE
		PS C:\> New-StringConversion -StringToConvert 'Große Zimmerpflanzen für daheim & Büro'
	
		Replaces any special character in string: 
	
		Grosse-Zimmerpflanzen-fur-daheim-e-Buro
		
	.EXAMPLE
		
		PS C:\> New-StringConversion -StringToConvert 'Große Zimmerpflanzen für daheim & Büro' -IgnoreSpaces
	
		Replaces any special character in string ignoring any whitespace:
	
		Grosse Zimmerpflanzen fur daheim e Buro
	
	.EXAMPLE
	
		PS C:\> New-StringConversion -StringToConvert 'Große Zimmerpflanzen für daheim & Büro' -ReplaceSpaces
		'---'
	
		Replaces any special character in string replacing any white space with three dashes:
	
		Grosse---Zimmerpflanzen---fur---daheim---e---Buro
	#>
	
	[CmdletBinding(DefaultParameterSetName = 'RemoveSpaces',
				   ConfirmImpact = 'High',
				   HelpUri = 'https://PsCustomObject.github.io',
				   PositionalBinding = $true,
				   SupportsShouldProcess = $false)]
	[OutputType([string], ParameterSetName = 'RemoveSpaces')]
	[OutputType([string], ParameterSetName = 'ReplaceSpaces')]
	[OutputType([string], ParameterSetName = 'IgnoreSpaces')]
	[OutputType([string])]
	param
	(
		[Parameter(ParameterSetName = 'IgnoreSpaces',
				   Position = 0)]
		[Parameter(ParameterSetName = 'RemoveSpaces',
				   Position = 0)]
		[Parameter(ParameterSetName = 'ReplaceSpaces',
				   Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[Alias('string')]
		[string]
		$StringToConvert,
		[Parameter(ParameterSetName = 'IgnoreSpaces')]
		[Parameter(ParameterSetName = 'RemoveSpaces')]
		[Parameter(ParameterSetName = 'ReplaceSpaces')]
		[ValidateNotNullOrEmpty()]
		[object]
		$UnicodeHashTable = $unicodeHashTable,
		[Parameter(ParameterSetName = 'IgnoreSpaces',
				   Mandatory = $false)]
		[switch]
		$IgnoreSpaces,
		[Parameter(ParameterSetName = 'ReplaceSpaces',
				   Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]
		$ReplaceSpace = '-',
		[Parameter(ParameterSetName = 'RemoveSpaces',
				   Mandatory = $false)]
		[switch]
		$RemoveSpaces,
		[Parameter(ParameterSetName = 'IgnoreSpaces')]
		[Parameter(ParameterSetName = 'RemoveSpaces')]
		[Parameter(ParameterSetName = 'ReplaceSpaces')]
		[string]
		$UnknownCharacter = '?'
	)
	
	# Set default unicode Hash
	if ($UnicodeHashTable -eq $null)
	{
		# HashTable contaning special characters to replace
		[hashtable]$unicodeHashTable = @{
			
			# a
			'æ' = 'a'
			'à' = 'a'
			'â' = 'a'
			'ã' = 'a'
			'å' = 'a'
			'ā' = 'a'
			'ă' = 'a'
			'ą' = 'a'
			'ä' = 'a'
			'á' = 'a'
			
			# b
			'ƀ' = 'b'
			'ƃ' = 'b'
			
			# Tone six
			'ƅ' = 'b'
			
			# c
			'ç' = 'c'
			'ć' = 'c'
			'ĉ' = 'c'
			'ċ' = 'c'
			'č' = 'c'
			'ƈ' = 'c'
			
			# d
			'ď' = 'd'
			'đ' = 'd'
			'ƌ' = 'd'
			
			# e
			'è' = 'e'
			'é' = 'e'
			'ê' = 'e'
			'ë' = 'e'
			'ē' = 'e'
			'ĕ' = 'e'
			'ė' = 'e'
			'ę' = 'e'
			'ě' = 'e'
			'&' = 'e'
			
			# g
			'ĝ' = 'e'
			'ğ' = 'e'
			'ġ' = 'e'
			'ģ' = 'e'
			
			# h
			'ĥ' = 'h'
			'ħ' = 'h'
			
			# i
			'ì' = 'i'
			'í' = 'i'
			'î' = 'i'
			'ï' = 'i'
			'ĩ' = 'i'
			'ī' = 'i'
			'ĭ' = 'i'
			'į' = 'i'
			'ı' = 'i'
			
			# j
			'ĳ' = 'j'
			'ĵ' = 'j'
			
			# k
			'ķ' = 'k'
			'ĸ' = 'k'
			
			# l
			'ĺ' = 'l'
			'ļ' = 'l'
			'ľ' = 'l'
			'ŀ' = 'l'
			'ł' = 'l'
			
			# n
			'ñ' = 'n'
			'ń' = 'n'
			'ņ' = 'n'
			'ň' = 'n'
			'ŉ' = 'n'
			'ŋ' = 'n'
			
			# o
			'ð' = 'o'
			'ó' = 'o'
			'õ' = 'o'
			'ô' = 'o'
			'ö' = 'o'
			'ø' = 'o'
			'ō' = 'o'
			'ŏ' = 'o'
			'ő' = 'o'
			'œ' = 'o'
			
			# r
			'ŕ' = 'r'
			'ŗ' = 'r'
			'ř' = 'r'
			
			# s
			'ś' = 's'
			'ŝ' = 's'
			'ş' = 's'
			'š' = 's'
			'ß' = 'ss'
			'ſ' = 's'
			
			# t
			'ţ' = 't'
			'ť' = 't'
			'ŧ' = 't'
			
			# u
			'ù' = 'u'
			'ú' = 'u'
			'û' = 'u'
			'ü' = 'u'
			'ũ' = 'u'
			'ū' = 'u'
			'ŭ' = 'u'
			'ů' = 'u'
			'ű' = 'u'
			'ų' = 'u'
			
			# w
			'ŵ' = 'w'
			
			# y
			'ý' = 'y'
			'ÿ' = 'y'
			'ŷ' = 'y'
			
			# z
			'ź' = 'z'
			'ż' = 'z'
			'ž' = 'z'
		}
	}
	
	# Check if we have a custom regex
	if ([string]::IsNullOrEmpty($RegExCharacters) -eq $true)
	{
		# Set a regex for additional special characters
		[string]$unicodeRegExString = "^([0-9a-zA-Z!#$@.'^_`~-])*$"
		
		$RegExCharacters = $unicodeRegExString
	}
	
	# Handle white spaces
	if ($IgnoreSpaces)
	{
		$UnicodeHashTable.Add(' ', ' ')
	}
	elseif ($ReplaceSpace)
	{
		$UnicodeHashTable.Add(' ', $ReplaceSpace)
	}
	elseif ($RemoveSpaces)
	{
		$StringToConvert = $StringToConvert.Replace(' ', '')
	}
	else
	{
		$UnicodeHashTable.Add(' ', '-')
	}
	
	# Check if user wants custom special char
	if ([string]::IsNullOrEmpty($UnknownCharacter) -eq $false)
	{
		$UnknownCharacter = $UnknownCharacter
	}
	
	# Check if we have special characters
	if (!($StringToConvert -match $RegExCharacters))
	{
		$CharArray = $StringToConvert.ToCharArray()
		
		# Declare new character array
		[array]$NewCharArray = @()
		
		# Parse the string
		foreach ($Char in $CharArray)
		{
			[bool]$ToUpper = $False
			
			# Set Char ref with current value
			$CharCurrent = $Char.ToString()
			$CharLower = $Char.ToString().ToLower()
			
			# Run a compare to check character case 
			[int]$CharComp = $CharCurrent.CompareTo($CharLower)
			
			# Upper character for rendering
			if ($CharComp -eq 1)
			{
				$ToUpper = $True
			}
			
			# Check we have a match
			if (!($Char.ToString() -match $RegExCharacters))
			{
				if ($UnicodeHashTable.ContainsKey($Char.ToString().ToLower()) -eq $true)
				{
					$Char = $UnicodeHashTable["$($Char)"]
					if ($ToUpper)
					{
						$Char = $Char.ToString().ToUpper()
					}
					
					$NewCharArray += $Char
				}
				else
				{
					$NewCharArray += $UnknownCharacter
				}
			}
			else
			{
				if ($ToUpper)
				{
					$Char = $Char.ToString().ToUpper()
				}
				
				$NewCharArray += $Char
			}
		}
		
		# Format return value
		#$unicodeString = -join [char[]]$NewCharArray
		$unicodeString = -join [array]$NewCharArray
	}
	else
	{
		$unicodeString = $StringToConvert
	}
	return $unicodeString
}