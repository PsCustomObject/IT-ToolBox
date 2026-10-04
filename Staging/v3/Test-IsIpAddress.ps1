function Test-IsIP
{
	<#
		.SYNOPSIS
			Tests if input is an IP Address
	
		.DESCRIPTION
			Tests if input is an IP Address
	
		.PARAMETER  IP
			A string containing an IP address
	
		.INPUTS
			System.String
	
		.OUTPUTS
			System.Boolean
	#>	
	[OutputType([Boolean])]
	param ([string]
		$IP)
	
	#Regular Express
	#return $IP -match "\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b"
	
	#Parse using a IPAddress static method
	try
	{
		return ($null -ne [System.Net.IPAddress]::Parse($IP))
	}
	catch
	{
		Out-Null
	}
	
	return $false
}