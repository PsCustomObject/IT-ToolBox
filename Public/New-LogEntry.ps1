function New-LogEntry
{
    <#
	.SYNOPSIS
		Function serves as logging framework for PowerShell scripts.
	
	.DESCRIPTION
		Function allows writing log messages to a log file that can be located locally or an UNC Path additionally using buffers is supported
		to allow loggin in situations where PsProvider does not allow access to the local system for example when working with SCCM cmdlets.
		
		By default all log messages are prepended with the [INFO] tag, see -IsError or -IsWarning parameters for more details on additional tags,
		unless the -NoTag parameter is specified.
	
	.PARAMETER LogMessage
		A string representing the message to be written to the lot stream.
	
	.PARAMETER LogFilePath
		A string representing the path and file name to be used for writing log messages.
		
		If parameter is not specified $PSCommandPath will be used.
	
	.PARAMETER IsErrorMessage
		When parameter is specified log message will be prepended with the [Error] tag additionally Write-Error will be used to print
		error on console.
	
	.PARAMETER IsWarningMessage
		When parameter is specified log message will be prepended with the [Warning] tag additionally Write-Warning will be used to print
		error on console.
	
	.PARAMETER BufferOnlyInfo
		When parameter is specified log message will be saved to a temporary log-buffer with script scope for later retrieval.
	
	.PARAMETER NoConsole
		When parameter is specified console output will be suppressed.
	
	.PARAMETER BufferOnlyWarning
		When parameter is specified log message will be saved to a temporary log-buffer with script scope for later retrieval and
		message will be repended with the [Warning] tag
	
	.PARAMETER BufferOnlyError
		When parameter is specified log message will be saved to a temporary log-buffer with script scope for later retrieval and
		message will be repended with the [Error] tag
	
	.PARAMETER BufferOnly
		When parameter is specified log message will only be written to a temporary buffer that can be forwarded to file or printed on screen.
	
	.PARAMETER NoTag
		When parameter is specified tag representing message severity will be not be part of the log message.
	
	.EXAMPLE
		PS C:\> New-LogEntry -LogMessage 'This is a test message' -LogFilePath  'C:\Temp\TestLog.log'
		
		[02.29.2020 08:27:01 AM] - [INFO]: This is a test message
#>
    
    [CmdletBinding(DefaultParameterSetName = 'Info')]
    [OutputType([string], ParameterSetName = 'Info')]
    [OutputType([string], ParameterSetName = 'Error')]
    [OutputType([string], ParameterSetName = 'Warning')]
    [OutputType([string], ParameterSetName = 'NoConsole')]
    [OutputType([string], ParameterSetName = 'BufferOnly')]
    param
    (
        [Parameter(ParameterSetName = 'Error')]
        [Parameter(ParameterSetName = 'Info')]
        [Parameter(ParameterSetName = 'NoConsole')]
        [Parameter(ParameterSetName = 'Warning',
                   Mandatory = $true)]
        [Parameter(ParameterSetName = 'BufferOnly')]
        [ValidateNotNullOrEmpty()]
        [Alias('Log', 'Message')]
        [string]
        $LogMessage,
        [Parameter(ParameterSetName = 'Error',
                   Mandatory = $false)]
        [Parameter(ParameterSetName = 'Info')]
        [Parameter(ParameterSetName = 'Warning')]
        [ValidateNotNullOrEmpty()]
        [string]
        $LogFilePath,
        [Parameter(ParameterSetName = 'Error')]
        [Alias('IsError', 'WriteError')]
        [switch]
        $IsErrorMessage,
        [Parameter(ParameterSetName = 'Warning')]
        [Alias('Warning', 'IsWarning', 'WriteWarning')]
        [switch]
        $IsWarningMessage,
        [Parameter(ParameterSetName = 'BufferOnly')]
        [switch]
        $BufferOnlyInfo,
        [Parameter(ParameterSetName = 'Error')]
        [Parameter(ParameterSetName = 'Info')]
        [Parameter(ParameterSetName = 'Warning')]
        [Parameter(ParameterSetName = 'NoConsole')]
        [switch]
        $NoConsole,
        [Parameter(ParameterSetName = 'BufferOnly')]
        [switch]
        $BufferOnlyWarning,
        [Parameter(ParameterSetName = 'BufferOnly')]
        [switch]
        $BufferOnlyError,
        [Parameter(ParameterSetName = 'BufferOnly')]
        [switch]
        $BufferOnly,
        [Parameter(ParameterSetName = 'Error')]
        [Parameter(ParameterSetName = 'Info')]
        [Parameter(ParameterSetName = 'NoConsole')]
        [Parameter(ParameterSetName = 'Warning')]
        [Alias('SuppressTag')]
        [switch]
        $NoTag
    )
    
    begin
    {
        # Instantiate new mutex to implement lock
        [System.Threading.Mutex]$logMutex = New-Object System.Threading.Mutex($false, 'LogSemaphore')
        
        # Check if file locked
        [void]$logMutex.WaitOne()
        
        # Get current date timestamp
        [string]$currentDate = [System.DateTime]::Now.ToString('[MM/dd/yyyy hh:mm:ss tt]')
        
        # Use script path if no filepath is specified
        if ([string]::IsNullOrEmpty($LogFilePath) -eq $true)
        {
            # Generate log file path and name
            $LogFilePath = '{0}{1}{2}{3}' -f $PSCommandPath, '-LogFile-', $currentDate, '.log'
        }
    }
    
    process
    {
        # Initialize commandsplat 
        $paramOutFile = @{
            LiteralPath = $LogFilePath
            Append      = $true
            Encoding    = 'utf8'
        }
        
        switch ($PsCmdlet.ParameterSetName)
        {
            'Info'
            {
                switch ($PSBoundParameters.Keys)
                {
                    'NoTag'
                    {
                        # Format log message
                        [string]$tmpLogMessage = '{0} - : {1}' -f $currentDate, $LogMessage
                        
                        break
                    }
                    default
                    {
                        # Format log message
                        [string]$tmpLogMessage = '{0} - [INFO]: {1}' -f $currentDate, $LogMessage
                    }
                }
                
                # Append to log
                $paramOutFile.Add('InputObject', $tmpLogMessage)
                
                # Suppress console output
                if (!($NoConsole))
                {
                    Write-Output -InputObject $tmpLogMessage
                }
                
                Out-File @paramOutFile
                
                break
            }
            'Warning'
            {
                switch ($PSBoundParameters.Keys)
                {
                    'NoTag'
                    {
                        # Format log message
                        [string]$tmpLogMessage = '{0} - : {1}' -f $currentDate, $LogMessage
                        
                        break
                    }
                    default
                    {
                        # Format log message
                        [string]$tmpLogMessage = '{0} - [WARNING]:  {1}' -f $currentDate, $LogMessage
                    }
                }
                
                # Append to log
                $paramOutFile.Add('InputObject', $tmpLogMessage)
                
                # Suppress console output
                if (!($NoConsole))
                {
                    Write-Warning -Message $tmpLogMessage
                }
                
                Out-File @paramOutFile
                
                break
            }
            'Error'
            {
                
                switch ($PSBoundParameters.Keys)
                {
                    'NoTag'
                    {
                        # Format log message
                        [string]$tmpLogMessage = '{0} - : {1}' -f $currentDate, $LogMessage
                        
                        break
                    }
                    default
                    {
                        # Format log message
                        [string]$tmpLogMessage = '{0} - [ERROR]: {1}' -f $currentDate, $LogMessage
                    }
                }
                
                # Append to log
                $paramOutFile.Add('InputObject', $tmpLogMessage)
                
                # Suppress console output
                if (!($NoConsole))
                {
                    Write-Error -Message $tmpLogMessage
                }
                
                Out-File @paramOutFile
                
                break
            }
            
            'BufferOnly' {
                
                switch ($PSBoundParameters.Keys)
                {
                    'BufferOnlyWarning'
                    {
                        # Format log message
                        [string]$tmpLogMessage = '{0} - [WARNING]: {1}' -f $currentDate, $LogMessage
                    }
                    'BufferOnlyError'
                    {
                        # Format log message
                        [string]$tmpLogMessage = '{0} - [ERROR]: {1}' -f $currentDate, $LogMessage
                    }
                    default
                    {
                        # Format log message
                        [string]$tmpLogMessage = '{0} - [INFO]: {1}' -f $currentDate, $LogMessage
                    }
                }
                
                # Format message for buffer
                [string]$script:messageBuffer += $tmpLogMessage + [Environment]::NewLine
                
                break
            }
        }
    }
}