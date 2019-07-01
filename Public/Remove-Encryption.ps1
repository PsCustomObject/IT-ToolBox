function Remove-Encryption
{
<#
	.SYNOPSIS
		This function decrypts all files encrypted with the Add-Encryption function. Once decrypted, it will add the files
		to the same directory that contains the encrypted files and will remove the GPG file extension.
	
	.DESCRIPTION
		A detailed description of the Remove-Encryption function.
	
	.PARAMETER FolderPath
		The folder path that contains all of the encrypted *.gpg files.
	
	.PARAMETER Password
		The password that was used to encrypt the files.
	
	.PARAMETER GpgPath
		A description of the GpgPath parameter.
	
	.PARAMETER FilePath
		A description of the FilePath parameter.
	
	.PARAMETER OverwriteOutput
		A description of the OverwriteOutput parameter.
	
	.EXAMPLE
		PS> Remove-Encryption -FolderPath C:\MyFolder -Password secret
		
		This example will attempt to decrypt all files inside of the C:\MyFolder folder using the password of 'secret'
	
	.OUTPUTS
		System.IO.FileInfo
	
	.NOTES
		Additional information about the function.
	
	.INPUTS
		None. This function does not accept pipeline input.
#>
	
	[CmdletBinding(DefaultParameterSetName = 'DecryptFolder')]
	[OutputType([System.IO.FileInfo])]
	param
	(
		[Parameter(ParameterSetName = 'DecryptFolder',
				   Mandatory = $true,
				   ValueFromPipeline = $false)]
		[ValidateScript({ Test-Path -Path $_ -PathType Container })]
		[ValidateNotNullOrEmpty()]
		[string]
		$FolderPath,
		[Parameter(ParameterSetName = 'DecryptFile',
				   Mandatory = $true)]
		[Parameter(ParameterSetName = 'DecryptFolder')]
		[ValidateNotNullOrEmpty()]
		[string]
		$Password,
		[Parameter(ParameterSetName = 'DecryptFile')]
		[Parameter(ParameterSetName = 'DecryptFolder')]
		[ValidateNotNullOrEmpty()]
		[string]
		$GpgPath = "${env:ProgramFiles(x86)}\GnuPG\bin\gpg.exe",
		[Parameter(ParameterSetName = 'DecryptFile',
				   Mandatory = $true,
				   ValueFromPipeline = $false)]
		[ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
		[ValidateNotNullOrEmpty()]
		[string]
		$FilePath,
		[Parameter(ParameterSetName = 'DecryptFile')]
		[Parameter(ParameterSetName = 'DecryptFolder')]
		[switch]
		$OverwriteOutput
	)
	
	process
	{
		# Create parameter list for GPG
		[System.Collections.ArrayList]$gpgParameters = @()
		[void]::($gpgParameters.Add("--passphrase $Password "))
		[void]::($gpgParameters.Add('--pinentry-mode=loopback '))
		
		if ($OverwriteOutput)
		{
			[void]::($gpgParameters.Add('--batch '))
			[void]::($gpgParameters.Add('--yes '))
		}
		else
		{
			[void]::($gpgParameters.Add('--batch '))
		}
		
		if ([string]::IsNullOrEmpty($FolderPath) -eq $false)
		{
			# Get list of encrypted files
			$paramGetChildItem = @{
				Path   = $FolderPath
				Filter = '*.gpg'
			}
			
			[array]$fileList = Get-ChildItem @paramGetChildItem
			
			# Define list of files decrypted
			[array]$decryptedFiles = @()
			
			try
			{
				foreach ($file in $fileList)
				{
					# Get encrypted file path
					[string]$decryptFilePath = $file.FullName.Replace('.gpg', '')
					
					# Add file to Array list
					$decryptedFiles += $file
					
					Write-Verbose "Processing file [$($file.FullName)]"
					
					# Process file
					$paramStartProcess = @{
						FilePath	 = $GpgPath
						ArgumentList = "$gpgParameters $($file.FullName)"
						Wait		 = $true
						WindowStyle  = 'Hidden'
					}
					
					Start-Process @paramStartProcess
				}
			}
			catch
			{
				Write-Error $_.Exception.Message
			}
		}
		else
		{
			try
			{
				# Get encrypted file path
				[string]$decryptFilePath = $FilePath.Replace('.gpg', '')
				
				# Process file
				$paramStartProcess = @{
					FilePath	 = $GpgPath
					ArgumentList = "$gpgParameters $FilePath"
					Wait		 = $true
					WindowStyle  = 'Hidden'
				}
				
				Start-Process @paramStartProcess
			}
			catch
			{
				Write-Error $_.Exception.Message
			}
		}
	}
}