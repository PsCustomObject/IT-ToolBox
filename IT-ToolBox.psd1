@{
	
	# Script module or binary module file associated with this manifest
	RootModule = 'IT-ToolBox.psm1'
	
	# Version number of this module.
	ModuleVersion = '2.2.0.0'
	
	# ID used to uniquely identify this module
	GUID = '02c0c748-00ba-4e8f-b8ce-6aa7e4cefe08'
	
	# Author of this module
	Author = 'Daniele Catanesi - PsCustomObject'
	
	# Company or vendor of this module
	CompanyName = 'https://pscustomobject.github.io/'
	
	# Copyright statement for this module
	Copyright = '(c) 2019. All rights reserved.'
	
	# Description of the functionality provided by this module
	Description = 'Swiss Army Knife Module for any IT Professional'
	
	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion = '3.0'
	
	# Name of the Windows PowerShell host required by this module
	PowerShellHostName = ''
	
	# Minimum version of the Windows PowerShell host required by this module
	PowerShellHostVersion = ''
	
	# Minimum version of the .NET Framework required by this module
	DotNetFrameworkVersion = '4.0'
	
	# Minimum version of the common language runtime (CLR) required by this module
	CLRVersion = '2.0.50727'
	
	# Processor architecture (None, X86, Amd64, IA64) required by this module
	ProcessorArchitecture = 'None'
	
	# Modules that must be imported into the global environment prior to importing
	# this module
	RequiredModules = @()
	
	# Assemblies that must be loaded prior to importing this module
	RequiredAssemblies	   = @(
		'lib\WinSCPNet.dll'
	)
	
	# Script files (.ps1) that are run in the caller's environment prior to
	# importing this module
	ScriptsToProcess = @()
	
	# Type files (.ps1xml) to be loaded when importing this module
	TypesToProcess = @()
	
	# Format files (.ps1xml) to be loaded when importing this module
	FormatsToProcess = @()
	
	# Modules to import as nested modules of the module specified in
	# ModuleToProcess
	NestedModules = @()
	
	# Functions to export from this module
	FunctionsToExport = '*' #For performance, list functions explicitly
	
	# Cmdlets to export from this module
	CmdletsToExport = '*' 
	
	# Variables to export from this module
	VariablesToExport = '*'
	
	# Aliases to export from this module
	AliasesToExport = '*' #For performance, list alias explicitly
	
	# DSC class resources to export from this module.
	#DSCResourcesToExport = ''
	
	# List of all modules packaged with this module
	ModuleList = @()
	
	# List of all files packaged with this module
	FileList = @(
		'Public\New-LogEntry.ps1',
		'Public\New-RandomPassword.ps1',
		'Public\New-StringConversion.ps1',
		'Public\Test-IsEmail.ps1',
		'Public\Test-IsIpAddress.ps1',
		'Public\Test-FileName.ps1',
		'Public\Test-IsUrl.ps1',
		'Public\New-PhoneticPassword.ps1',
		'Public\Remove-SpecialCharacters.ps1',
		'Public\Get-OsUpTime.ps1',
		'Public\Test-IsDate.ps1',
		'Public\Test-IsValidPath.ps1',
		'Public\Get-ScriptDirectory.ps1',
		'Public\Get-ScriptName.ps1',
		'Public\Test-RegistryValue.ps1',
		'Public\New-ExchangeSession.ps1',
		'Public\Close-ExchangeSession',
		'Public\New-RandomString.ps1',
		'Public\New-StringEncryption.ps1',
		'Public\New-StringDecryption.ps1',
		'Public\Get-GnuPgPackage.ps1',
		'Public\Add-Encryption.ps1',
		'Public\Remove-Encryption.ps1',
		'Public\New-ScpUpload.ps1',
		'Public\Test-IsValidUpn.ps1',
    	'Public\New-Timer.ps1',
    	'Public\Stop-Timer.ps1',
    	'Public\Get-ElapsedTime.ps1'
	)
	
	# Private data to pass to the module specified in ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData = @{
		
		#Support for PowerShellGet galleries.
		PSData = @{
			
			# Tags applied to this module. These help with module discovery in online galleries.
			# Tags = @()
			
			# A URL to the license for this module.
			# LicenseUri = ''
			
			# A URL to the main website for this project.
			# ProjectUri = ''
			
			# A URL to an icon representing this module.
			# IconUri = ''
			
			# ReleaseNotes of this module
			# ReleaseNotes = ''
			
		} # End of PSData hashtable
		
	} # End of PrivateData hashtable
}







