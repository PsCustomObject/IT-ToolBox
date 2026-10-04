function Test-FileName
{
	<#
		.SYNOPSIS
			Tests if the file name has valid characters
	
		.DESCRIPTION
			Tests if the file name has valid characters
	
		.PARAMETER  FileName
			A string containing a file name
	
		.INPUTS
			System.String
	
		.OUTPUTS
			System.Boolean
	#>
	[OutputType([Boolean])]
	param ([string]
		$Filename)
	
	if (-not $Filename)
	{
		return $false
	}
	
	$invalidChars = [System.IO.Path]::GetInvalidFileNameChars();
	
	foreach ($fileChar in $Filename)
	{
		foreach ($invalid in $invalidChars)
		{
			if ($fileChar -eq $invalid)
			{
				return $false
			}
		}
	}
	
	return $true
}