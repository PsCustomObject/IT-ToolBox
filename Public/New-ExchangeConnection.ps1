function New-ExchangeConnection
{
	<#
	.SYNOPSIS
		Creates a remote session to an on-prem Exchange Server.
	
	.DESCRIPTION
		Simple function to create an import a new PowerShell sesssion to a on-prem Exchange Server.
		
		If an open session to an Exchange server is already found a warning is printed on screen and no further action is taken unless the -Force parameter is specified.
	
	.PARAMETER ServerName
		A string representing the Exchange server name.
	
	.PARAMETER UseHttp
		When parameter is specified it will force a connection over HTTP rather than HTTPS.
		
		Switch is intended for use in all situations where server certificate is not trusted or an HTTPS connection cannot be correctly completed.
	
	.PARAMETER AuthenticationProtocol
		A string representing the authentication protocol to use while connecting to an on-prem Exchange server.
		
		If not specified Kerberos will be used by default.
	
	.PARAMETER AskCredentials
		When parameter is specified user will be prompted to enter credentials.
		
		If not specified it will default to currently logged on user credentials.
	
	.PARAMETER Force
		When used checks on open connections will be skipped function will try to establish a new one.
		
		Use with caution as this will cause cmdlets clobber.
	
	.PARAMETER UserName
		A description of the UserName parameter.
	
	.PARAMETER UserPassword
		A description of the UserPassword parameter.
	
	.PARAMETER SecurePassword
		A description of the SecurePassword parameter.
	
	.EXAMPLE
		PS C:\> New-ExchangeConnection
	
	.OUTPUTS
		object, object
	
	.NOTES
		By default HTTPS and Kerberos will be used to establish the connection.
#>
	
	[CmdletBinding(DefaultParameterSetName = 'AskCredentials',
				   SupportsPaging = $false,
				   SupportsShouldProcess = $false)]
	[OutputType([object], ParameterSetName = 'AskCredentials')]
	[OutputType([object], ParameterSetName = 'UserNamePassword')]
	[OutputType([object])]
	param
	(
		[Parameter(ParameterSetName = 'AskCredentials',
				   Mandatory = $true)]
		[Parameter(ParameterSetName = 'UserNamePassword')]
		[ValidateNotNullOrEmpty()]
		[string]$ServerName,
		[Parameter(ParameterSetName = 'AskCredentials')]
		[Parameter(ParameterSetName = 'UserNamePassword')]
		[switch]$UseHttp,
		[Parameter(ParameterSetName = 'AskCredentials')]
		[Parameter(ParameterSetName = 'UserNamePassword')]
		[ValidateSet('Basic', 'Credssp', 'Default', 'Digest', 'Kerberos', 'Negotiate', 'NegotiateWithImplicitCredential', IgnoreCase = $true)]
		[Alias('Protocol')]
		[string]$AuthenticationProtocol = 'Kerberos',
		[Parameter(ParameterSetName = 'AskCredentials')]
		[switch]$AskCredentials,
		[Parameter(ParameterSetName = 'AskCredentials')]
		[Parameter(ParameterSetName = 'UserNamePassword')]
		[switch]$Force,
		[Parameter(ParameterSetName = 'UserNamePassword',
				   Mandatory = $true)]
		[string]$UserName,
		[Parameter(ParameterSetName = 'UserNamePassword',
				   Mandatory = $true)]
		[string]$UserPassword,
		[Parameter(ParameterSetName = 'UserNamePassword',
				   Mandatory = $true)]
		[securestring]$SecurePassword
	)
	
	Begin
	{
		# Get current configuration  
		[string]$currentConfig = $ErrorActionPreference
		
		# Set error action preference
		$ErrorActionPreference = 'Stop'
		
		# Define conneciton URI
		[string]$ConnectionUri = 'https://'
		
		# Define session command
		$paramNewPSSession = @{
			ConfigurationName = 'Microsoft.Exchange'
		}
	}
}

Process
{
	switch ($PSCmdlet.ParameterSetName)
	{
		'AskCredentials'
		{
			# Get credentials from user
			[System.Management.Automation.PSCredential]$AskCredentials = Get-Credential
			
			# Add to command splat
			$paramNewPSSession.Add('Credential', $AskCredentials)
			
			break
		}
		'UserNamePassword'
		{
			if ($PSBoundParameters.ContainsKey('SecurePassword'))
			{
				# Create the credential object
				$paramNewObject = @{
					TypeName	 = 'System.Management.Automation.PSCredential'
					ArgumentList = ($UserName, $SecurePassword)
				}
				
				[pscredential]$UserCredential = New-Object @paramNewObject
				
				# Add to command splat
				$paramNewPSSession.Add('Credential', $UserCredential)
			}
			else
			{
				# Convert password to securestring
				$paramConvertToSecureString = @{
					String	    = $UserPassword
					AsPlainText = $true
					Force	    = $true
				}
				
				[securestring]$SecurePassword = ConvertTo-SecureString @paramConvertToSecureString
				
				# Create the credential object
				$paramNewObject = @{
					TypeName	 = 'System.Management.Automation.PSCredential'
					ArgumentList = ($UserName, $SecurePassword)
				}
				
				[pscredential]$UserCredential = New-Object @paramNewObject
				
				# Add to command splat
				$paramNewPSSession.Add('Credential', $UserCredential)
			}
			
			break
		}
	}
	
	if ($PSBoundParameters.ContainsKey('Force'))
	{
		Write-Verbose -Message 'The Force paramter has been specified - Ignoring open sessions'
	}
	else
	{
		# Check if a session is already open
		[array]$CurrentSessions = Get-PSSession
		
		if (($CurrentSessions.ConfigurationName -like '*Exchange*') -and
			($CurrentSessions.State -eq 'Opened') -and
			($CurrentSessions.ComputerName -notlike '*Office365*'))
		{
			# Get total session count
			[int]$sessionsCount = $CurrentSessions.Count
			
			Write-Warning -Message "$sessionsCount open session(s) have been found"
			Write-Warning -Message 'Use the -Force paramter to ignore or the -Verbose parameter for more details'
			
			if ($PSBoundParameters.ContainsKey('Verbose'))
			{
				foreach ($session in $CurrentSessions)
				{
					# Get session details
					[string]$SessionName = $session.ComputerName
					[string]$SessionId = $session.Id
					[string]$SessionStatus = $session.State
					
					Write-Verbose -Message "Session Name: $SessionName - Session ID: $SessionId - Session Status: $SessionStatus"
				}
			}
			
			return
		}
	}
	
	switch ($PSBoundParameters.Keys)
	{
		'UseHttp'
		{
			# Define connection URI protocol
			[string]$ConnectionUri = 'http://'
			
			break
		}
		'AuthenticationProtocol'
		{
			# User custom authentication protocol
			[string]$AuthenticationProtocol = $AuthenticationProtocol
			
			# Add to command splat
			$paramNewPSSession.Add('Authentication', $AuthenticationProtocol)
			
			break
		}
		'AskCredentials'
		{
			# Get credentials from user
			[System.Management.Automation.PSCredential]$AskCredentials = Get-Credential
			
			# Add to command splat
			$paramNewPSSession.Add('Credential', $AskCredentials)
			
			break
		}
	}
	
	# Fill up connection URL
	$ConnectionUri += "$ServerName/PowerShell"
	
	# Add to command splat
	$paramNewPSSession.Add('ConnectionUri', $ConnectionUri)
	
	# Create new session
	[System.Management.Automation.Runspaces.PSSession]$exSession = New-PSSession @paramNewPSSession
	
	return $exSession
}