function Get-ElapsedTime
{
	<#
		.SYNOPSIS
			Will return information about elapsed time for the given StopWatch.
		
		.DESCRIPTION
			Function requires a [System.Diagnostics.Stopwatch] object as input and will output information about elapsed time.
			
			By default a [TimeSpan] object is returned containing all information about elapsed time.
			
			If any other parameter like -Days is used function will return an Int or Double instead depending on the switch used.
		
		.PARAMETER ElapsedTime
			Will return a [TimeSpan] object representing the elapsed time for the given stopwatch.
		
		.PARAMETER Days
			Will return an [Int] object representing the number of days since the stopwatch was started.
		
		.PARAMETER Hours
			Will return an [Int] object representing the number of hours since the stopwatch was started.
		
		.PARAMETER Minutes
			Will return an [Int] object representing the number of minutes since the stopwatch was started.
		
		.PARAMETER Seconds
			Will return an [Int] object representing the number of seconds since the stopwatch was started.
		
		.PARAMETER TotalDays
			Will return a [Double] object representing the number of TotalDays since the stopwatch was started.
		
		.PARAMETER TotalHours
			Will return a [Double] object representing the number of TotalHours since the stopwatch was started.
		
		.PARAMETER TotalMinutes
			Will return a [Double] object representing the number of TotalMinutes since the stopwatch was started.
		
		.PARAMETER TotalSeconds
			Will return a [Double] object representing the number of TotalSeconds since the stopwatch was started.
		
		.PARAMETER TotalMilliseconds
			Will return a [Double] object representing the number of TotalMilliseconds since the stopwatch was started.
		
		.EXAMPLE
			PS C:\> Get-ElapsedTime -ElapsedTime $ElapsedTime -Days
		
		.OUTPUTS
			System.TimeSpan, System.Double, System.Int32
	#>
		
	[CmdletBinding(DefaultParameterSetName = 'FullOutput',
				   ConfirmImpact = 'High',
				   SupportsPaging = $false,
				   SupportsShouldProcess = $false)]
	[OutputType([timespan], ParameterSetName = 'FullOutput')]
	[OutputType([int], ParameterSetName = 'Days')]
	[OutputType([int], ParameterSetName = 'Hours')]
	[OutputType([int], ParameterSetName = 'Minutes')]
	[OutputType([int], ParameterSetName = 'Seconds')]
	[OutputType([double], ParameterSetName = 'TotalDays')]
	[OutputType([double], ParameterSetName = 'TotalHours')]
	[OutputType([double], ParameterSetName = 'TotalMinutes')]
	[OutputType([double], ParameterSetName = 'TotalSeconds')]
	[OutputType([double], ParameterSetName = 'TotalMilliseconds')]
	[OutputType([timespan])]
	param
	(
		[Parameter(ParameterSetName = 'FullOutput',
				   Mandatory = $true)]
		[Parameter(ParameterSetName = 'Days')]
		[Parameter(ParameterSetName = 'Hours')]
		[Parameter(ParameterSetName = 'Minutes')]
		[Parameter(ParameterSetName = 'Seconds')]
		[Parameter(ParameterSetName = 'TotalDays')]
		[Parameter(ParameterSetName = 'TotalHours')]
		[Parameter(ParameterSetName = 'TotalMilliseconds')]
		[Parameter(ParameterSetName = 'TotalMinutes')]
		[Parameter(ParameterSetName = 'TotalSeconds')]
		[System.Diagnostics.Stopwatch]
		$ElapsedTime,
		[Parameter(ParameterSetName = 'Days')]
		[switch]
		$Days,
		[Parameter(ParameterSetName = 'Hours')]
		[switch]
		$Hours,
		[Parameter(ParameterSetName = 'Minutes')]
		[switch]
		$Minutes,
		[Parameter(ParameterSetName = 'Seconds')]
		[swith]
		$Seconds,
		[Parameter(ParameterSetName = 'TotalDays')]
		[switch]
		$TotalDays,
		[Parameter(ParameterSetName = 'TotalHours')]
		[switch]
		$TotalHours,
		[Parameter(ParameterSetName = 'TotalMinutes')]
		[switch]
		$TotalMinutes,
		[Parameter(ParameterSetName = 'TotalSeconds')]
		[switch]
		$TotalSeconds,
		[Parameter(ParameterSetName = 'TotalMilliseconds')]
		[switch]
		$TotalMilliseconds
	)
	
	switch ($PsCmdlet.ParameterSetName)
	{
		'FullOutput'
		{
			# Return full timespan object
			return $ElapsedTime.Elapsed
			
			break
		}
		'Days'
		{
			# Return days with no decimals
			return $ElapsedTime.Elapsed.Days
			
			break
		}
		'Hours'
		{
			# Return hours with no decimals
			return $ElapsedTime.Elapsed.Hours
			
			break
		}
		'Minutes'
		{
			# Return minutes with no decimals
			return $ElapsedTime.Elapsed.Minutes
			
			break
		}
		'Seconds'
		{
			# Return seconds with no decimals
			return $ElapsedTime.Elapsed.Seconds
			
			break
		}
		'TotalDays'
		{
			# Return days with double precision
			return $ElapsedTime.Elapsed.TotalDays
			
			break
		}
		'TotalHours'
		{
			# Return hours with double precision
			return $ElapsedTime.Elapsed.TotalHours
			
			break
		}
		'TotalMinutes'
		{
			# Return minutes with double precision
			return $ElapsedTime.Elapsed.TotalMinutes
			
			break
		}
		'TotalSeconds'
		{
			# Return seconds with double precision
			return $ElapsedTime.Elapsed.TotalSeconds
			
			break
		}
		'TotalMilliseconds'
		{
			# Return milliseconds with double precision
			return $ElapsedTime.Elapsed.TotalMilliseconds
			
			break
		}
	}
}