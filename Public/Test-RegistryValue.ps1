function Test-RegistryValue
{
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Path,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Value
	)
	
	try
	{
		Get-ItemProperty -Path $Path | Select-Object -ExpandProperty $Value -ErrorAction Stop | Out-Null
		
		return $true
	}
	
	catch
	{
		return $false
	}
}