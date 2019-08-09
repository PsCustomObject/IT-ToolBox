function New-ScpDownload
{
	[OutputType([WinSCP.TransferOperationResult], ParameterSetName = 'AcceptAnyKey')]
	[OutputType([WinSCP.TransferOperationResult], ParameterSetName = 'ValidateRemoteKey')]
	[OutputType([WinSCP.TransferOperationResult])]
	param
	(
		[Parameter(ParameterSetName = 'AcceptAnyKey',
				   Mandatory = $true)]
		[Parameter(ParameterSetName = 'ValidateRemoteKey')]
		[ValidateNotNullOrEmpty()]
		[string]
		$RemoteHost,
		[Parameter(ParameterSetName = 'AcceptAnyKey')]
		[Parameter(ParameterSetName = 'ValidateRemoteKey')]
		[string]
		$UserName,
		[Parameter(ParameterSetName = 'AcceptAnyKey')]
		[Parameter(ParameterSetName = 'ValidateRemoteKey')]
		[string]
		$Password,
		[Parameter(ParameterSetName = 'AcceptAnyKey')]
		[Parameter(ParameterSetName = 'ValidateRemoteKey')]
		[ValidateNotNullOrEmpty()]
		[securestring]
		$SecurePassword,
		[Parameter(ParameterSetName = 'ValidateRemoteKey',
				   Mandatory = $true)]
		[string]
		$HostFingerPrint,
		[Parameter(ParameterSetName = 'AcceptAnyKey')]
		[Parameter(ParameterSetName = 'ValidateRemoteKey')]
		[ValidateSet('Scp', 'Sftp', IgnoreCase = $true)]
		[string]
		$Protocol = 'Scp',
		[Parameter(ParameterSetName = 'AcceptAnyKey')]
		[switch]
		$AcceptAnyKey,
		[Parameter(Mandatory = $true)]
		[string]
		$LocalPath,
		[Parameter(Mandatory = $true)]
		[string]
		$RemotePath,
		[switch]
		$DeleteSource,
		[switch]
		$CloseSession
	)
	
	# Define session parameters
	[hashtable]$SessionParameters = @{ }
	$SessionParameters.Add('HostName', $RemoteHost)
	
	if ([string]::IsNullOrEmpty($UserName) -eq $false)
	{
		$SessionParameters.Add('UserName', $UserName)
	}
	
	if (-not ($AcceptAnyKey))
	{
		$SessionParameters.Add('SshHostKeyFingerprint', $HostFingerPrint)
	}
	else
	{
		# Don't check remote server identity
		$SessionParameters.Add('GiveUpSecurityAndAcceptAnySshHostKey', $true)
	}
	
	if ($SecurePassword)
	{
		$SessionParameters.Add('SecurePassword', $SecurePassword)
		#TODO: Not yet implemented
	}
	else
	{
		$SessionParameters.Add('Password', $Password)
	}
	
	try
	{
		# Create session options object
		[WinSCP.SessionOptions]$SessionOptions = New-Object -TypeName WinSCP.SessionOptions -Property $SessionParameters
		
		# Create new session
		[WinSCP.Session]$ScpSession = New-Object -TypeName WinSCP.Session
		
		# Open session
		$ScpSession.Open($SessionOptions)
		
		if ($DeleteSource)
		{
			# Download files and delete source
			$ScpSession.GetFiles($RemotePath, $LocalPath, $true)
		}
		else
		{
			# Download files only
			$ScpSession.GetFiles($RemotePath, $LocalPath)
		}
	}
	catch
	{
		# Save exception message
		[string]$reportedException = $_.Exception.Message
		
		Write-Warning -Message 'Session could not be opened - Reported exception is'
		Write-Warning -Message $reportedException
	}
	
	finally
	{
		if ($CloseSession)
		{
			# Close session
			$ScpSession.Dispose()
		}
	}
}