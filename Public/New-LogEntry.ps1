function New-LogEntry
{
	[CmdletBinding(ConfirmImpact = 'High',
				   PositionalBinding = $true,
				   SupportsShouldProcess = $true)]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true)]
		[AllowNull()]
		[Alias('Log', 'Message')]
		[string]
		$LogMessage,
		[Alias('Print', 'Echo', 'Console')]
		[switch]
		$WriteToConsole = $false,
		[AllowNull()]
		[Alias('Path', 'LogFile', 'File', 'LogPath')]
		[string]
		$LogFilePath,
		[Alias('Error', 'IsError', 'WriteError')]
		[switch]
		$IsErrorMessage = $false,
		[Alias('Warning', 'IsWarning', 'WriteWarning')]
		[switch]
		$IsWarningMessage = $false,
		[Alias('EchoOnly')]
		[switch]
		$ConsoleOnly = $false,
		[switch]
		$BufferOnly = $false,
		[switch]
		$SaveToBuffer = $false,
		[Alias('Nodate', 'NoStamp')]
		[switch]
		$NoTimeStamp = $false
	)
	
	# Use script path if no filepath is specified
	if (([string]::IsNullOrEmpty($logFilePath) -eq $true) -and
		(!($ConsoleOnly)))
	{
		$logFilePath = $PSCommandPath + '-LogFile-' + $(Get-Date -Format 'yyyy-MM-dd') + '.log'
	}
	
	# Don't do anything on empty Log Message
	if ([string]::IsNullOrEmpty($logMessage) -eq $true)
	{
		return
	}
	
	# Format log message
	if (($isErrorMessage) -and
		(!($ConsoleOnly)))
	{
		if ($NoTimeStamp)
		{
			$tmpMessage = "[Error] - $logMessage"
		}
		else
		{
			$tmpMessage = "[$(Get-Date -Format 'MM-dd hh:mm:ss')] : [Error] - $logMessage"
		}
	}
	elseif (($IsWarningMessage -eq $true) -and
		(!($ConsoleOnly)))
	{
		if ($NoTimeStamp)
		{
			$tmpMessage = "[Warning] - $logMessage"
		}
		else
		{
			$tmpMessage = "[$(Get-Date -Format 'MM-dd hh:mm:ss')] : [Warning] - $logMessage"
		}
	}
	else
	{
		if (!($ConsoleOnly))
		{
			if ($NoTimeStamp)
			{
				$tmpMessage = $logMessage
			}
			else
			{
				$tmpMessage = "[$(Get-Date -Format 'MM-dd hh:mm:ss')] : $logMessage"
			}
		}
	}
	
	# Write log messages to console
	if (($ConsoleOnly) -or
		($WriteToConsole))
	{
		if ($IsErrorMessage)
		{
			Write-Error $logMessage
		}
		elseif ($IsWarningMessage)
		{
			Write-Warning $logMessage
		}
		else
		{
			Write-Output -InputObject $logMessage
		}
		
		# Write to console and exit
		if ($ConsoleOnly -eq $true)
		{
			return
		}
	}
	
	# Write log messages to file
	if (([string]::IsNullOrEmpty($logFilePath) -eq $false) -and
		($BufferOnly -ne $true))
	{
		$paramOutFile = @{
			InputObject = $tmpMessage
			FilePath    = $LogFilePath
			Append	    = $true
			Encoding    = 'utf8'
		}
		
		Out-File @paramOutFile
	}
	
	# Save message to buffer
	if (($BufferOnly -eq $true) -or
		($SaveToBuffer -eq $true))
	{
		$script:messageBuffer += $tmpMessage + '`r`n'
		
		# Remove blank lines
		$script:messageBuffer = $script:messageBuffer -creplace '(?m)^\s*\r?\n', ''
	}
}