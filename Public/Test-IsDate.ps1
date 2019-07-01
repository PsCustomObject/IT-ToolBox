function Test-IsDate
{
	[OutputType([Boolean])]
	param ([string]
		$Date)
	
	return [DateTime]::TryParse($Date, [ref](New-Object System.DateTime))
}