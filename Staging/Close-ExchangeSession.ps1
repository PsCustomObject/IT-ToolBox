function Close-ExchangeSession
{
	<#
	.SYNOPSIS
		Closes an open Exchange session.
	
	.DESCRIPTION
		Function is used to close an open session to a remote Exchange server.
		
		Sessions can be specified by ID or Name, by default all sessions with a ConfigurationName of Microsoft.Exchange will be returned and removed.
	
	.PARAMETER SessionId
		An integer value representing the Sesison ID to remove.
	
	.PARAMETER SessionName
		A string value representing the Session Name to remove.
	
	.EXAMPLE
		PS C:\> Close-ExchangeSession
	
	.OUTPUTS
		System.Boolean
	
	.NOTES
		If no SessionName or SessionId parameter is used function will close any remote PowerShell session (Skype Online, Exchange Online, Sharepoint Online etc.)
	#>
	
	[CmdletBinding(DefaultParameterSetName = 'ReturnAllSessions')]
	param
	(
		[Parameter(ParameterSetName = 'SessionById')]
		[ValidateNotNullOrEmpty()]
		[int]$SessionId,
		[Parameter(ParameterSetName = 'SessionByName')]
		[ValidateNotNullOrEmpty()]
		[string]$SessionName
	)
	
	Begin
	{
		# Get current configuration  
		[string]$currentConfig = $ErrorActionPreference
		
		# Set error action preference
		$ErrorActionPreference = 'Stop'
	}
	
	Process
	{
		switch ($PsCmdlet.ParameterSetName)
		{
			'SessionById'
			{
				try
				{
					# Check we have a valid session
					[System.Management.Automation.Runspaces.PSSession]$sessionObject = Get-PSSession -Id $SessionId
					[string]$sessionConfiguration = $sessionObject.ConfigurationName
					
					# Check session is the correct type
					if ($sessionConfiguration -like '*Exchange*')
					{
						$paramRemovePSSession = @{
							Session = $sessionObject
							Confirm = $false
						}
						
						Remove-PSSession @paramRemovePSSession
						
						return $true
					}
					else
					{
						Write-Warning -Message "Session $SessionId is not an Exchange session"
						
						return $false
					}
				}
				catch
				{
					Write-Warning -Message "No PsSession with ID $SessionId found!"
					
					return $false
				}
				
				break
			}
			'SessionByName'
			{
				try
				{
					# Get session by name
					[System.Management.Automation.Runspaces.PSSession]$sessionObject = Get-PSSession -Name $SessionName
					[string]$sessionConfiguration = $sessionObject.ConfigurationName
					
					# Check session is the correct type
					if ($sessionConfiguration -like '*Exchange*')
					{
						$paramRemovePSSession = @{
							Session = $sessionObject
							Confirm = $false
						}
						
						Remove-PSSession @paramRemovePSSession
						
						return $true
					}
					else
					{
						Write-Warning -Message "Session $SessionId is not an Exchange session"
						
						return $false
					}
				}
				catch
				{
					Write-Warning -Message "No PsSession with Name $SessionName found!"
					
					return $false
				}
				
				break
			}
			
			'ReturnAllSessions'
			{
				# Get all seesions
				[array]$psSessions = Get-PSSession
				
				# Cycle through sessions
				foreach ($session in $psSessions)
				{
					# Get configuration name
					[string]$sessionConfiguration = $session.ConfigurationName
					[string]$sessionId = $sessionObject.ID #TODO: review this property
					
					try
					{
						# Check session is the correct type
						if ($sessionConfiguration -like '*Exchange*')
						{
							$paramRemovePSSession = @{
								Session = $session
								Confirm = $false
							}
							
							Remove-PSSession @paramRemovePSSession
							
							return $true
						}
					}
					catch
					{
						Write-Warning -Message "Session $SessionName and ID $sessionId could not be removed"
						
						return $false
					}
				}
				
				break
			}
		}
	}
	
	End
	{
		# Revert back setting
		$ErrorActionPreference = $currentConfig
	}
}