function Test-IsURL
{
	<#
	.SYNOPSIS
		Tests if input is an URL
	
	.DESCRIPTION
		Tests if input is an URL
	
	.PARAMETER Url
		A string containing an URL address to check
	
	.OUTPUTS
		System.Boolean
	#>
	
	[OutputType([Boolean])]
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Url
	)
	
	# Check we have something
	if ([string]::IsNullOrEmpty($Url) -eq $true)
	{
		return $false
	}
	
	# Check Url is valid
	return $Url -match "^(ht|f)tp(s?)\:\/\/[0-9a-zA-Z]([-.\w]*[0-9a-zA-Z])*(:(0-9)*)*(\/?)([a-zA-Z0-9\-\.\?\,\'\/\\\+&amp;%\$#_]*)?$"
}