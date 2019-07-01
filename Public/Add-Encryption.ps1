function Add-Encryption
{
<#
	.SYNOPSIS
		This function uses the GnuPG for Windows application to symmetrically encrypt a set of files in a folder.
	
	.DESCRIPTION
		A detailed description of the function.
	
	.PARAMETER FolderPath
		This is the folder path that contains all of the files you'd like to encrypt.
	
	.PARAMETER KeyRingPassPhrase
		This is the password that will be used to encrypt the files.
	
	.PARAMETER GpgPath
		Allows user to specify a custom path for the gpg2.exe executable path
	
	.PARAMETER FilePath
		Specifies the path of the file to encrypt/sign
	
	.PARAMETER SymmetricEncrypt
		Specifies if file/folder should be encrypted with symmetric encryption.
	
	.PARAMETER Sign
		Specifies if file/folder should be signed. Will default to $true if not specified
	
	.PARAMETER SymmetricEncryptOnly
		A description of the EncryptOnly parameter.
	
	.PARAMETER Recipient
		Validate parameter is a valid email address.
	
	.PARAMETER AsymmetricEncrypt
		A description of the AsymmetricEncrypt parameter.
	
	.PARAMETER OverwriteOutput
		A description of the OverwriteOutput parameter.
	
	.PARAMETER SignOnly
		A description of the SignOnly parameter.
	
	.PARAMETER OutputFile
		A description of the OutputFile parameter.
	
	.EXAMPLE
		PS> Add-Encryption -FolderPath C:\TestFolder -Password secret
		
		This example would encrypt all of the files in the C:\TestFolder folder with the password of 'secret'.  The encrypted
		files would be created with the same name as the original files only with a GPG file extension.
	
	.OUTPUTS
		System.IO.FileInfo
	
	.NOTES
		Additional information about the function.
	
	.INPUTS
		None. This function does not accept pipeline input.
#>
	
	[CmdletBinding(DefaultParameterSetName = 'AsymmetricEncryptFile')]
	[OutputType([System.IO.FileInfo])]
	param
	(
		[Parameter(ParameterSetName = 'SymmetricEncryptFolder',
				   Mandatory = $true,
				   ValueFromPipeline = $false)]
		[Parameter(ParameterSetName = 'SymmetricEncryptOnly',
				   Mandatory = $false)]
		[Parameter(ParameterSetName = 'SignOnly',
				   Mandatory = $false)]
		[Parameter(ParameterSetName = 'AsymmetricEncryptFolder',
				   Mandatory = $true)]
		[ValidateScript({ Test-Path -Path $_ -PathType Container })]
		[ValidateNotNullOrEmpty()]
		[string]
		$FolderPath,
		[Parameter(ParameterSetName = 'SymmetricEncryptFile',
				   Mandatory = $true)]
		[Parameter(ParameterSetName = 'SymmetricEncryptFolder',
				   Mandatory = $true)]
		[Parameter(ParameterSetName = 'SymmetricEncryptOnly',
				   Mandatory = $true)]
		[Parameter(ParameterSetName = 'SignOnly',
				   Mandatory = $true)]
		[Parameter(ParameterSetName = 'AsymmetricEncryptFile',
				   Mandatory = $true)]
		[Parameter(ParameterSetName = 'AsymmetricEncryptFolder',
				   Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[Alias('Password', 'PassPhrase', 'Pwd', 'KeyRingPwd')]
		[string]
		$KeyRingPassPhrase,
		[Parameter(ParameterSetName = 'SymmetricEncryptFile')]
		[Parameter(ParameterSetName = 'SymmetricEncryptFolder')]
		[Parameter(ParameterSetName = 'SymmetricEncryptOnly')]
		[Parameter(ParameterSetName = 'SignOnly')]
		[Parameter(ParameterSetName = 'AsymmetricEncryptFile')]
		[Parameter(ParameterSetName = 'AsymmetricEncryptFolder')]
		[ValidateNotNullOrEmpty()]
		[string]
		$GpgPath = "${env:ProgramFiles(x86)}\GnuPG\bin\gpg.exe",
		[Parameter(ParameterSetName = 'SymmetricEncryptFile',
				   Mandatory = $true,
				   ValueFromPipeline = $false)]
		[Parameter(ParameterSetName = 'SymmetricEncryptOnly',
				   Mandatory = $false)]
		[Parameter(ParameterSetName = 'SignOnly',
				   Mandatory = $false)]
		[Parameter(ParameterSetName = 'AsymmetricEncryptFile',
				   Mandatory = $true)]
		[ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
		[ValidateNotNullOrEmpty()]
		[string]
		$FilePath,
		[Parameter(ParameterSetName = 'SymmetricEncryptFile')]
		[Parameter(ParameterSetName = 'SymmetricEncryptFolder')]
		[switch]
		$SymmetricEncrypt = $false,
		[Parameter(ParameterSetName = 'SymmetricEncryptFile')]
		[Parameter(ParameterSetName = 'SymmetricEncryptFolder')]
		[Parameter(ParameterSetName = 'AsymmetricEncryptFile')]
		[Parameter(ParameterSetName = 'AsymmetricEncryptFolder')]
		[switch]
		$Sign = $false,
		[Parameter(ParameterSetName = 'SymmetricEncryptOnly',
				   Mandatory = $false)]
		[switch]
		$SymmetricEncryptOnly = $false,
		[Parameter(ParameterSetName = 'SymmetricEncryptFile',
				   ValueFromPipeline = $false,
				   HelpMessage = 'A valid email address')]
		[Parameter(ParameterSetName = 'SymmetricEncryptFolder',
				   Mandatory = $false)]
		[Parameter(ParameterSetName = 'SymmetricEncryptOnly',
				   Mandatory = $false)]
		[Parameter(ParameterSetName = 'AsymmetricEncryptFile',
				   Mandatory = $true)]
		[Parameter(ParameterSetName = 'AsymmetricEncryptFolder',
				   Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Recipient,
		[Parameter(ParameterSetName = 'AsymmetricEncryptFile')]
		[Parameter(ParameterSetName = 'AsymmetricEncryptFolder')]
		[switch]
		$AsymmetricEncrypt = $false,
		[Parameter(ParameterSetName = 'AsymmetricEncryptFile')]
		[Parameter(ParameterSetName = 'AsymmetricEncryptFolder')]
		[Parameter(ParameterSetName = 'SignOnly')]
		[Parameter(ParameterSetName = 'SymmetricEncryptFile')]
		[Parameter(ParameterSetName = 'SymmetricEncryptFolder')]
		[Parameter(ParameterSetName = 'SymmetricEncryptOnly')]
		[switch]
		$OverwriteOutput = $false,
		[Parameter(ParameterSetName = 'SignOnly')]
		[switch]
		$SignOnly,
		[Parameter(ParameterSetName = 'AsymmetricEncryptFile')]
		[Parameter(ParameterSetName = 'SymmetricEncryptFile')]
		[ValidateNotNullOrEmpty()]
		[string]
		$OutputFile
	)
	
	process
	{
		# Create parameter list for GPG
		[System.Collections.ArrayList]$gpgParameters = @()
		[void]::($gpgParameters.Add("--passphrase $KeyRingPassPhrase "))
		[void]::($gpgParameters.Add('--pinentry-mode=loopback '))
		
		if ([string]::IsNullOrEmpty($OutputFile) -eq $false)
		{
			[void]::($gpgParameters.Add("--output $OutputFile"))
		}
		
		if ($OverwriteOutput)
		{
			[void]::($gpgParameters.Add('--batch '))
			[void]::($gpgParameters.Add('--yes '))
		}
		else
		{
			[void]::($gpgParameters.Add('--batch '))
		}
		
		if (($Sign) -or
			($SignOnly))
		{
			[void]::($gpgParameters.Add('--sign '))
		}
		
		if (($SymmetricEncrypt) -or
			($SymmetricEncryptOnly))
		{
			[void]::($gpgParameters.Add('--symmetric '))
		}
		
		if ($AsymmetricEncrypt)
		{
			[void]::($gpgParameters.Add('--encrypt '))
		}
		
		if ($Recipient)
		{
			[void]::($gpgParameters.Add("--recipient $Recipient "))
		}
		
		if ([string]::IsNullOrEmpty($FolderPath) -eq $false)
		{
			try
			{
				# Get list of files to encrypt
				$paramGetChildItem = @{
					Path    = $FolderPath
					Exclude = '*.gpg'
				}
				
				[array]$fileList = Get-ChildItem @paramGetChildItem
				
				foreach ($file in $fileList)
				{
					Write-Verbose "Encrypting [$($file.FullName)]"
					
					$paramStartProcess = @{
						FilePath	 = $GpgPath
						ArgumentList = "$gpgParameters $($file.FullName)"
						Wait		 = $true
						WindowStyle  = 'Hidden'
					}
					
					Start-Process @paramStartProcess
				}
				
				Get-ChildItem -Path $FolderPath -Filter '*.gpg'
			}
			catch
			{
				Write-Error $_.Exception.Message
			}
		}
		elseif ([string]::IsNullOrEmpty($FilePath) -eq $false)
		{
			try
			{
				
				# Take action on the file
				$paramStartProcess = @{
					FilePath	 = $GpgPath
					ArgumentList = "$gpgParameters $FilePath"
					Wait		 = $true
					WindowStyle  = 'Hidden'
				}
				
				Start-Process @paramStartProcess
				
				Write-Verbose -Message "File $FilePath correctly encrypted/signed"
			}
			catch
			{
				Write-Error $_.Exception.Message
			}
		}
		else
		{
			Write-Warning 'FilePath or FolderPath argument required!'
			
			return 1
		}
	}
}