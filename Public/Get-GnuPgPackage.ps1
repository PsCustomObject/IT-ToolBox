function Get-GnuPgPackage
{
<#
	.SYNOPSIS
		Function allows download and installation of the GnuPg Package
	
	.DESCRIPTION
		Function Get-GnupgPackage allows download and optionally installation
		of the GnuPg Ppackage.
		
		By default function will download latest version of the package
		available on the GnuPg webserver but optionally a specific
		version/link can be used to download older versions.
	
	.PARAMETER DownloadFolderPath
		Path where binary installers should be downloaded. If not
		specified a default path will be used.
	
	.PARAMETER DownloadUrl
		The URL that will be used to download the EXE setup installer.
		If not specified latest package version will be downloaded.
	
	.PARAMETER DownloadOnly
		If specified Gpg4Win package will be downloaded only.
	
	.PARAMETER DownloadInstall
		If specified Gpg4Win package will be downloaded and
		installed silently
	
	.EXAMPLE
		PS> Get-GnuPgPackage -DownloadFolderPath C:\Downloads
		
		This will download the Gpg4Win-Latest.exe  in the specified folder
		without installing it. If file is already present in the destination
		folder it will be overwritten.
	
	.EXAMPLE
		PS> Get-GnuPgPackage -DownloadInstall -DownloadFolderPath C:\Downloads
		
		This will download the Gpg4Win-Latest.exe  in the specified folder and
		perform a silent installation. If file is already present in the
		destination folder it will be overwritten.
	
	.OUTPUTS
		None. Any error will be printed on screen and available in the
		$Error stream.
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding(DefaultParameterSetName = 'DownloadOnly')]
	param
	(
		[Parameter(ParameterSetName = 'DownloadAndInstall',
				   Mandatory = $false)]
		[Parameter(ParameterSetName = 'DownloadOnly')]
		[ValidateNotNullOrEmpty()]
		[string]
		$DownloadFolderPath,
		[Parameter(ParameterSetName = 'DownloadAndInstall',
				   Mandatory = $false)]
		[Parameter(ParameterSetName = 'DownloadOnly')]
		[ValidateNotNullOrEmpty()]
		[string]
		$DownloadUrl = 'https://files.gpg4win.org/gpg4win-latest.exe',
		[Parameter(ParameterSetName = 'DownloadOnly')]
		[switch]
		$DownloadOnly,
		[Parameter(ParameterSetName = 'DownloadAndInstall')]
		[switch]
		$DownloadInstall
	)
	
	process
	{
		# Define file name 
		[string]$downloadFileName = Split-Path -Path $DownloadUrl -Leaf
		
		try
		{
			if ([string]::IsNullOrEmpty($DownloadFolderPath) -eq $true)
			{
				# Use default path
				$DownloadFolderPath = 'C:\Temp\'
				
				$DownloadFilePath = $DownloadFolderPath + $downloadFileName
				
				Write-Verbose -Message 'No download folder specified - C:\Temp\ will be used'
				
				# Create folder if does not exist
				if (!(Test-Path -Path $DownloadFolderPath))
				{
					try
					{
						New-Item -Path $DownloadFolderPath -ItemType 'Directory'
						
						Write-Verbose -Message "Folder $DownloadFolderPath correctly created"
					}
					catch
					{
						Write-Warning "Could not create $DownloadFolderPath - Script will now exit"
						
						return
					}
				}
				
				# Download package isntaller
				Invoke-WebRequest -Uri $DownloadUrl -OutFile $DownloadFilePath
			}
			else
			{
				Write-Verbose -Message "Folder $DownloadFolderPath has been specified"
				
				if ($DownloadFolderPath.EndsWith('\'))
				{
					$DownloadFilePath = $DownloadFolderPath + $downloadFileName
				}
				else
				{
					$DownloadFilePath = $DownloadFolderPath + '\' + $downloadFileName
				}
				
				# Download package isntaller
				Invoke-WebRequest -Uri $DownloadUrl -OutFile $DownloadFilePath
			}
			
			if ($DownloadInstall)
			{
				try
				{
					# Install package
					$paramStartProcess = @{
						FilePath	 = $DownloadFilePath
						ArgumentList = '/S'
						#NoNewWindow  = $true
						Wait		 = $true
						PassThru	 = $true
						WindowStyle  = 'Hidden'
						Verb		 = 'RunAs'
					}
					
					Start-Process @paramStartProcess
					
					Write-Verbose -Message 'GPG4Win installed'
				}
				catch
				{
					Write-Error $_.Exception.Message
				}
			}
		}
		catch
		{
			Write-Warning "Could not create $DownloadFilePath - Script will now exit"
			
			return
		}
	}
}