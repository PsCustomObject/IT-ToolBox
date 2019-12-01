function Close-AzureSession
{
	<#
	.SYNOPSIS
		Will close any open AzureAD session
	
	.DESCRIPTION
		Function is designed as support function for automation scripts to check if an open AzureAD Session is found on the system and close it.
		
		Function does not accept nor require any input parameter and will return True if a session is found on the system and correctly closed and False if any exception is reported while closing an open sesison. 
		
		If no valid session are found on the system function will return True despite no action being taken.
	#>
	
	[CmdletBinding()]
	[OutputType([bool])]
	param ()
	
	Begin
	{
		# Get current configuration  
		[string]$currentConfig = $ErrorActionPreference
		
		# Set error action preference
		$ErrorActionPreference = 'Stop'
	}
	
	Process
	{
		# Check if a session is oepn
		[bool]$isValidSession = Test-AzureSession
		
		if ($isValidSession)
		{
			Write-Verbose -Message 'An open AzureAD Session found - Attempting to close'
			
			try
			{
				# Close connection
				Disconnect-AzureAD -Confirm:$false
				
				Write-Verbose -Message 'AzureAD Session correctly closed'
				
				return $true
			}
			catch
			{
				# Save exception
				[string]$reportedException = $Error[0].Exception.Message
				
				Write-Warning -Message 'Exception reported while closing AzureAD connection- Use the -Verbose parameter for more detail'
				
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
		else
		{
			Write-Verbose -Message 'No open AzureAD sessions found on the system'
			
			return $true
		}
	}
	End
	{
		# Set error action preference
		$ErrorActionPreference = $currentConfig
	}
}