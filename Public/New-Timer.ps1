function New-Timer
{
	<#
		.SYNOPSIS
			Creates a new stopwatch.
	
		.DESCRIPTION
			Function will create a new time, using the StopWatch class, allowing measurement of elapsed time in scripts.
	
		.EXAMPLE
			PS C:\> New-Timer
	
		.NOTES
			Function takes no parameters and will start a new StopWatch object.
	#>
	
	[OutputType([System.Diagnostics.Stopwatch])]
	param ()
	
	$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
	
	return $stopwatch
}