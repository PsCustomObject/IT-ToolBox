function New-StringConversion
{
    <#
        .SYNOPSIS
            Function to remove any non-unicode character from a string.
        
        .DESCRIPTION
            Function is used to sanitize non-unicode characters from a string.
    	
    		Function supports custom characters map via the -UnicodeHashTable parameter accepting an hashtable of characters to replace.
    	
    		If characters not specified in the default character map are found they are replace with a question mark '?' unless a custom
            unknown character is specified via -UnknownCharacter parameter.
        
        .PARAMETER StringToConvert
            A string containing characters that need to be sanitized/converted.
        
        .PARAMETER UnicodeHashTable
            An hashtable containing characters that should be replaced if parameter is not specified default values will be used.
        
        .PARAMETER IgnoreSpaces
            By default spaces will be replaced with a dash '-' sign if paramter is specified function will not convert/take into consideraiotn
            spaces in the string.
        
        .PARAMETER RemoveSpaces
            If parameter is specified spaces will be removed from input string.
        
        .PARAMETER ReplaceSpaces
            By default spaces will be replaced with a dash '-' sign if parameter is specified it is possible to specify character to use when
            a space is encountered in the string.
        
        .PARAMETER UnknownCharacter
            By default any special character not found in the UnicodeHashTable will be replaced with a question mark when parameter is used
            it is possible to specify which character will be used for unknown entries.
        
        .EXAMPLE
            PS C:\> New-StringConversion
        
        .NOTES
            Additional information about the function.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ReplaceSpaces',
                   ConfirmImpact = 'High',
                   HelpUri = 'https://PsCustomObject.github.io')]
    param
    (
        [Parameter(ParameterSetName = 'IgnoreSpaces',
                   Mandatory = $true)]
        [Parameter(ParameterSetName = 'RemoveSpaces')]
        [Parameter(ParameterSetName = 'ReplaceSpaces')]
        [ValidateNotNullOrEmpty()]
        [string]
        $StringToConvert,
        [Parameter(ParameterSetName = 'IgnoreSpaces')]
        [Parameter(ParameterSetName = 'RemoveSpaces')]
        [Parameter(ParameterSetName = 'ReplaceSpaces')]
        [hashtable]
        $UnicodeHashTable,
        [Parameter(ParameterSetName = 'IgnoreSpaces')]
        [switch]
        $IgnoreSpaces,
        [Parameter(ParameterSetName = 'RemoveSpaces')]
        [switch]
        $RemoveSpaces,
        [Parameter(ParameterSetName = 'ReplaceSpaces')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ReplaceSpaces,
        [Parameter(ParameterSetName = 'IgnoreSpaces')]
        [Parameter(ParameterSetName = 'RemoveSpaces')]
        [Parameter(ParameterSetName = 'ReplaceSpaces')]
        [ValidateNotNullOrEmpty()]
        [string]
        $UnknownCharacter = '?'
    )
    
    begin
    {
        # Declare control variable
        [bool]$isUpperCase = $false
        
        # Check if we should use custom array hash
        if (-not ($PSBoundParameters.ContainsKey('UnicodeHashTable')))
        {
            # Hashtable contaning special characters to replace
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
        
        switch ($PSBoundParameters.Keys)
        {
            'IgnoreSpaces'
            {
                $UnicodeHashTable.Add(' ', ' ')
                
                break
            }
            'ReplaceSpaces'
            {
                # Replace spaces with specified character
                $UnicodeHashTable.Add(' ', $ReplaceSpaces)
                
                break
            }
            'RemoveSpaces'
            {
                # Replace spaces with specified character
                $UnicodeHashTable.Add(' ', '')
                
                break
            }
        }
        
        # Create new chararray
        [System.Collections.ArrayList]$resultStringArray = @()
        
        # Set a regex for additional special characters
        [string]$unicodeRegExString = "^([0-9a-zA-Z!#$@.'^_`~-])*$"
    }
    process
    {
        # Convert string to array
        [array]$stringCharArray = $StringToConvert.ToCharArray()
        
        foreach ($character in $stringCharArray)
        {
            # Reset control variables
            $isUpperCase = $false
            
            # Set Char ref with current value
            [string]$currentChar = $character.ToString()
            [string]$currentCharLower = $character.ToString().ToLower()
            
            # Get character case
            if ($currentChar.CompareTo($currentCharLower) -eq 1)
            {
                $isUpperCase = $true
            }
            
            # Check if character should be translated
            if ($UnicodeHashTable.ContainsKey($currentCharLower) -eq $true)
            {
                # Get unicode equivalent
                [string]$tmpChar = $UnicodeHashTable[$currentChar]
                
                # Set character case
                switch ($isUpperCase)
                {
                    $true
                    {
                        $resultStringArray.Add($tmpChar.ToUpper())
                        
                        break
                    }
                    default
                    {
                        $resultStringArray.Add($tmpChar)
                    }
                }
            }
            else
            {
                # Check if character should be translated
                if (($currentCharLower -match $unicodeRegExString) -eq $false)
                {
                    # Handle characters not in hash
                    $currentChar = $UnknownCharacter
                    
                    # Append to result array
                    $resultStringArray.Add($currentChar).ToString()
                }
                else
                {
                    # Set character case
                    switch ($isUpperCase)
                    {
                        $true
                        {
                            $resultStringArray.Add($currentChar).ToString().ToUpper()
                        }
                        default
                        {
                            $resultStringArray.Add($currentChar).ToString()
                        }
                    }
                }
            }
        }
    }
    end
    {
        # Return string
        return (-join $resultStringArray)
    }
}