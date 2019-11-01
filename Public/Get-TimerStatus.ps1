function Get-TimerStatus
{
	<#
		.SYNOPSIS
			Will return boolean value representing status of an existing stopwatch.
		
		.DESCRIPTION
			Function requires a [System.Diagnostics.Stopwatch] object as input and will return $True if stopwatch is running or $False otherwise.
		
		.PARAMETER Timer
			A [System.Diagnostics.Stopwatch] object representing the StopWatch to check status for.
		
		.EXAMPLE
			PS C:\> Get-TimerStatus -Timer $Timer
		
		.OUTPUTS
			System.Boolean
	#>
	
	[OutputType([bool])]
	param
	(
		[Parameter(Mandatory = $true)]
		[System.Diagnostics.Stopwatch]
		$Timer
	)
	
	return $Timer.IsRunning
}