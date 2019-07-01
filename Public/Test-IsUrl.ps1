function Test-IsURL
{
	<#
		.SYNOPSIS
			Tests if input is an URL
	
		.DESCRIPTION
			Tests if input is an URL
	
		.PARAMETER  Url
			A string containing an URL address
	
		.INPUTS
			System.String
	
		.OUTPUTS
			System.Boolean
	#>
	[OutputType([Boolean])]
	param ([string]
		$Url)
	
	if ($Url -eq $null)
	{
		return $false
	}
	
	return $Url -match "^(ht|f)tp(s?)\:\/\/[0-9a-zA-Z]([-.\w]*[0-9a-zA-Z])*(:(0-9)*)*(\/?)([a-zA-Z0-9\-\.\?\,\'\/\\\+&amp;%\$#_]*)?$"
}