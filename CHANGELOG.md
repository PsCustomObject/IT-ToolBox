# IT-ToolBox - Change History

## Version 2.2.0.0 - 05.12.2019

- **New** cmdlet *New-ExchangeSession* to create a remote PowerShell session to an on-premise Exchange server [2](https://github.com/PsCustomObject/IT-ToolBox/issues/2)
- **New** cmdlet *Close-ExchangeSession* to close a remote PowerShell session to an on-premise or online Exchange server

## Version 2.1.0.0 - 02.11.2019

- **New** cmdlet *New-ApiRequest* to create OAuth2 API requests
- **Fixed** comment based help for *New-StringEncryption* cmdlet
- **Fixed** comment based help for *New-StringDecryption* cmdlet
- **Fixed** wrong return data type for *Test-IsEmail* cmdlet
- **Updated** cmdlet *Test-IsUrl* to implement better checks on empty string

## Version 2.0.2.0 - 01.11.2019

- **New** created change-log file
- **New** cmdlet *New-Timer* to create a new *stopwatch* object
- **New** cmdlet *Get-TimerStatus* to get status of an existing *stopwatch* object
- **New** cmdlet *Stop-Timer* to stop an existing *stopwatch* object
- **New** cmdlet *Get-ElapsedTime* to get statistics from an existing *stopwatch* object
- **Updated** module manifest version number to be aligned with public changelog file
- **Added** bin folder for external dependencies binary files

## Version 2.0.1.2 - 09.08.2019

- **Updated** cmdlet *New-ScpDownload* exception handling code

## Version 2.0.1.1 - 06.08.2019

- **New** cmdlet *New-ScpDownload* to support download from remote SFTP Servers via WinSCP assembly
- **Updated** *WinSCPnet.dll* assembly library

## Version 2.0.1.0 - 01.07.2019

- **New** cmdlet *Test-IsValidUpn* to validate string is a valid UPN
- **New** cmdlet *Add-Encryption* to PGP encrypt a file (external dependencies required)
- **New** cmdlet *Get-GnuPgPackage* to install *GnuPg Win* package for PGP encryption
- **New** cmdlet *New-ScpUpload* to support upload fo files to remote SFTP Servers via WinSCP assembly
- **New** cmdlet *New-ScpSession* to support sessions to remote SFTP Servers via WinSCP assembly 

## Version 2.0.0.0 - 13.06.2019

- **Updated** module file structure to use *Public* and *Private* folders for cmdlets distribution

## Version 1.1.0.0 - 01.03.2019

- **Updated** cmdlet name from *Test-Path* to *Test-IsValidPath* to solve name collision issue with built-in PowerShell cmdlet

## Version 1.0.0.1 - 21.02.2019

- **Fixed** and issue in *New-StringConversion* causing incorrect data type to be returned

## Version 1.0.0.0 - 01.02.2019

- Initial module release
