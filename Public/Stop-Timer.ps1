function Stop-Timer
{
    <#
    .SYNOPSIS
        Stops a stopwatch.

    .DESCRIPTION
        Requires a [System.Diagnostics.Stopwatch] object and calls its Stop() method.
        If no exception is raised, the function returns $true.

    .PARAMETER Timer
        The stopwatch instance to stop.

    .EXAMPLE
        Stop-Timer -Timer $Timer

    .OUTPUTS
        System.Boolean
    #>

    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [System.Diagnostics.Stopwatch]$Timer
    )

    Begin
    {
        # Preserve the caller's current preference so it can be restored after the stop attempt.
        [string]$currentConfig = $ErrorActionPreference

        # Fail fast so the catch block can report stopwatch-stop errors consistently.
        $ErrorActionPreference = 'Stop'
    }

    Process
    {
        try
        {
            # Stop the supplied stopwatch.
            $Timer.Stop()

            return $true
        }
        catch
        {
            # Capture the exception text for verbose output without changing the caller's state.
            [string]$reportedException = $Error[0].Exception.Message

            Write-Warning -Message 'Exception reported while halting stopwatch - Use the -Verbose parameter for more details'

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

    End
    {
        # Restore the original error-action preference after the stopwatch operation finishes.
        $ErrorActionPreference = $currentConfig
    }
}