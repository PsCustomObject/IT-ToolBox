function Remove-SpecialCharacters
{
<#
	.SYNOPSIS
		Removes invalid characters from files/folders names
	
	.DESCRIPTION
		A detailed description of the Remove-SpecialCharacters function.
	
	.PARAMETER ItemsPath
		Specifies the ItemsPath to scan for files/folders
	
	.PARAMETER AutoFix
		If specified function will automatically replace characters in the file/directory name
	
	.PARAMETER LogActivites
		If used all activies will be logged to C:\Temp
	
	.EXAMPLE
		PS C:\> Remove-SpecialCharacters -ItemsPath $value1
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $false,
				   ValueFromPipelineByPropertyName = $false,
				   ValueFromRemainingArguments = $false,
				   HelpMessage = 'Specifies the path to scan for files/folders')]
		[string]
		$ItemsPath,
		[Parameter(Mandatory = $false,
				   ValueFromPipeline = $false,
				   ValueFromPipelineByPropertyName = $false,
				   ValueFromRemainingArguments = $false,
				   HelpMessage = 'If specified function will automatically replace characters in the file/directory name')]
		[switch]
		$AutoFix,
		[Parameter(Mandatory = $false,
				   ValueFromPipeline = $false,
				   ValueFromPipelineByPropertyName = $false,
				   ValueFromRemainingArguments = $false,
				   HelpMessage = 'If used all activies will be logged to C:\Temp')]
		[switch]
		$LogActivites
	)
	
	# Define invalid characters to replace
	#[char[]]$invalidChars = '!@#$%^&*(){}[]":;,<>/|\+=`~ ''' # Match spaces
	[char[]]$invalidChars = '!@#$%^&*(){}[]":;,<>/|\+=`~'''
	
	# Build up a regex to characters
	[string]$charsRegex = ($invalidChars | ForEach-Object { [regex]::Escape($_) }) -join '|'
	
	# Define a static path for activities log file
	[string]$logFilePath = 'C:\Temp\' + $env:COMPUTERNAME + '-' + $(Get-Date -Format "yyyy-MM-dd") + ".log"
	
	# Get all items in the specified path
	try
	{
		$itemsToProcess = Get-ChildItem -Path $ItemsPath -Recurse | Sort-Object FullName -Descending
		
		foreach ($item in $itemsToProcess)
		{
			if (($item.Name -match $charsRegex) -and ($AutoFix))
			{
				# Rename the offending item
				Rename-Item -Path $item.FullName -NewName $($item.Name -replace $charsRegex, '-')
				
				#$itemsToProcess = Get-ChildItem -Path $ItemsPath -Recurse
				
				# Check if we should log the task 
				if ($LogActivites)
				{
					New-LogEntry -LogFilePath $logFilePath -LogMessage "Item $item contains invalid chars!"
					New-LogEntry -LogFilePath $logFilePath -LogMessage "Invalid characters will be replaced with a '-'"
				}
			}
			elseif (($item.Name -match $charsRegex) -and ($LogActivites))
			{
				New-LogEntry -LogFilePath $logFilePath -LogMessage "File/Directory $item contains invalid characters!"
			}
			else
			{
				if ($LogActivites)
				{
					New-LogEntry -LogFilePath $logFilePath -LogMessage "File/Directory $item - Does not contain invalid characters. Nothing to do"
				}
			}
		}
	}
	catch
	{
		New-LogEntry -LogFilePath $logFilePath -LogMessage "Path not found or permissions issue!" -IsErrorMessage
	}
}