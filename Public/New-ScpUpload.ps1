function New-ScpUpload
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
	
	# Check assembly is available
	try
	{
		# Import required assembly
		Add-Type -Path 'C:\Program Files (x86)\WinSCP\WinSCPnet.dll'
	}
	catch
	{
		throw [System.IO.FileNotFoundException] 'C:\Program Files (x86)\WinSCP\WinSCPnet.dll not found!'
		
		return
	}
	
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
		[WinSCP.SessionOptions]$SessionOptions = New-Object -TypeName WinSCP.SessionOptions -Property $SessionParameters
		
		[WinSCP.Session]$ScpSession = New-Object -TypeName WinSCP.Session
		
		$ScpSession.Open($SessionOptions)
		
		if ($DeleteSource)
		{
			$ScpSession.PutFiles($RemotePath, $LocalPath, $true)
		}
		else
		{
			[void]::($ScpSession.PutFiles($LocalPath, $RemotePath))
		}
	}
	catch
	{
		Write-Error $_.Exception.Message
	}
	
	finally
	{
		# Close session
		$ScpSession.Dispose()
	}
}