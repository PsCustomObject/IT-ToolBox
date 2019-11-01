function Stop-Timer
{
	<#
		.SYNOPSIS
			Function will halt a stopwatch.
		
		.DESCRIPTION
			Function requires a [System.Diagnostics.Stopwatch] object as input and will invoke the stop() method to hald its execution.
		
			If no exceptions are returned function will return $True.
		
		.PARAMETER Timer
			A [System.Diagnostics.Stopwatch] representing the stopwatch to stop.
		
		.EXAMPLE
			PS C:\> Stop-Timer -Timer $Timer
		
		.OUTPUTS
			System.Boolean
	#>
	
	[OutputType([bool])]
	param
	(
		[Parameter(Mandatory = $true)]
		[System.Diagnostics.Stopwatch]$Timer
	)
	
	Begin
	{
		# Save current configuration
		[string]$currentConfig = $ErrorActionPreference
		
		# Update configuration
		$ErrorActionPreference = 'Stop'
	}
	
	Process
	{
		try
		{
			# Stop timer
			$Timer.Stop()
			
			return $true
		}
		catch
		{
			# Save exception
			[string]$reportedException = $Error[0].Exception.Message
			
			Write-Warning -Message 'Exception reported while halting stopwatch - Use the -Verbose parameter for more details'
			
			# Check we have an exception message
			if ([string]::IsNullOrEmpty($reportedException) -eq $false)
			{
				Write-Verbose -Message $reportedException
			}
			else
			{
				Write-Verbose -Message 'No inner exception reported by Disconnect-AzureAD cmdlet'
			}
			
			return $false
		}
	}
	
	End
	{
		# Revert back configuration
		$ErrorActionPreference = $currentConfig
	}
}