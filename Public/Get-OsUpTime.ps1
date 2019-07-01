function Get-OsUptime
{
	[CmdletBinding(DefaultParameterSetName = 'LocalMachine',
				   ConfirmImpact = 'None')]
	param
	(
		[Parameter(ParameterSetName = 'RemoteMachine')]
		[ValidateNotNullOrEmpty()]
		[string]
		$ComputerName,
		[Parameter(ParameterSetName = 'LocalMachine')]
		[Parameter(ParameterSetName = 'RemoteMachine')]
		[switch]
		$FullOutput,
		[Parameter(ParameterSetName = 'RemoteMachine')]
		[switch]
		$Credentials
	)
	
	if ($Credentials)
	{
		$userCredentials = Get-Credential -Message 'Please specify alternate credentials to be used:'
	}
	
	if ($ComputerName)
	{
		if ($userCredentials)
		{
			try
			{
				# Catch non terminating errrors
				$ErrorActionPreference = 'Stop'
				
				# Get releavant OS Info from WMI
				$paramGetWmiObject = @{
					Namespace    = 'root\cimv2'
					Class	     = 'Win32_OperatingSystem'
					ComputerName = $ComputerName
					Credential   = $userCredentials
				}
				
				[System.Management.ManagementObject]$osInfo = Get-WmiObject @paramGetWmiObject
			}
			
			catch [System.UnauthorizedAccessException]
			{
				[string]$reportedException = $Error[0].Exception.Message
				
				Write-Warning "Could not get remote machine $ComputerName uptime"
				Write-Warning 'Access Denied error was returned - Try to use the -Credentials parameter'
				Write-Warning 'Use -Credentials parameter to specify alternate credentials'
				
				# Revert change
				$ErrorActionPreference = 'Continue'
				
				return
			}
			
			catch
			{
				Write-Warning "Could not get remote machine $ComputerName uptime"
				Write-Warning "Reported exception is $reportedException"
				
				# Revert change
				$ErrorActionPreference = 'Continue'
				
				return
			}
			
			finally
			{
				$ErrorActionPreference = 'Continue'
			}
			
		}
		else
		{
			try
			{
				# Catch non terminating errrors
				$ErrorActionPreference = 'Stop'
				
				# Get releavant OS Info from WMI
				$paramGetWmiObject = @{
					Namespace    = 'root\cimv2'
					Class	     = 'Win32_OperatingSystem'
					ComputerName = $ComputerName
				}
				
				[System.Management.ManagementObject]$osInfo = Get-WmiObject @paramGetWmiObject
			}
			
			# Catch access denied
			catch [System.UnauthorizedAccessException]
			{
				[string]$reportedException = $Error[0].Exception.Message
				
				Write-Warning "Could not get remote machine $ComputerName uptime"
				Write-Warning 'Access Denied error was returned'
				Write-Warning 'Use -Credentials parameter to specify alternate credentials'
				
				# Revert change
				$ErrorActionPreference = 'Continue'
				
				return
			}
			
			# Catch all
			catch
			{
				
				[string]$reportedException = $Error[0].Exception.Message
				
				if ($reportedException.Contains('Access denied'))
				{
					Write-Warning "Could not get remote machine $ComputerName uptime"
					Write-Warning 'Access Denied error was returned'
					Write-Warning 'Use -Credentials parameter to specify alternate credentials'
				}
				else
				{
					Write-Warning "Could not get remote machine $ComputerName uptime"
					Write-Warning "Reported exception is $reportedException"
				}
				
				# Revert change
				$ErrorActionPreference = 'Continue'
				
				return
			}
			
			finally
			{
				$ErrorActionPreference = 'Continue'
			}
		}
	}
	else
	{
		# Get releavant OS Info from WMI
		$paramGetWmiObject = @{
			Namespace    = 'root\cimv2'
			Class	     = 'Win32_OperatingSystem'
			ComputerName = 'localhost'
		}
		
		[System.Management.ManagementObject]$osInfo = Get-WmiObject @paramGetWmiObject
	}
	
	# Convert uptime to proper type
	[timespan]$totalUptime = (Get-Date) - ($osInfo.ConvertToDateTime($osInfo.lastbootuptime))
	
	if ($FullOutput)
	{
		return [timespan]$totalUptime
	}
	else
	{
		return [int]$totalUptime.Days
	}
}