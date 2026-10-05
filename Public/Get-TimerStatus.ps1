function Get-TimerStatus
{
    <#
    .SYNOPSIS
        Returns a boolean indicating whether an existing stopwatch is running.

    .DESCRIPTION
        This function requires a [System.Diagnostics.Stopwatch] object as input and returns
        $True if the stopwatch is running, or $False otherwise.

    .PARAMETER Timer
        A [System.Diagnostics.Stopwatch] object representing the stopwatch to check.

    .EXAMPLE
        PS C:\> Get-TimerStatus -Timer $Timer

    .OUTPUTS
        System.Boolean
    #>

    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [System.Diagnostics.Stopwatch]
        $Timer
    )

    # Return the current running state of the supplied stopwatch.
    return $Timer.IsRunning
}