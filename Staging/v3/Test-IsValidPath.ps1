function Test-IsValidPath
{
	[OutputType([Boolean])]
	param ([string]
		$Path)
	
	if ($Path -eq $null -or $Path -eq '')
	{
		return $false
	}
	
	$invalidChars = [System.IO.Path]::GetInvalidPathChars();
	
	for ($i = 0; $i -lt $Path.Length; $i++)
	{
		$pathChar = $Path[$i]
		foreach ($invalid in $invalidChars)
		{
			if ($pathChar -eq $invalid)
			{
				return $false
			}
		}
	}
	
	return $true
}