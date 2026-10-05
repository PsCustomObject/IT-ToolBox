function New-Timer
{
    <#
    .SYNOPSIS
        Creates a new stopwatch.

    .DESCRIPTION
        This function creates a new stopwatch using the System.Diagnostics.Stopwatch class,
        allowing elapsed time to be measured inside scripts.

    .EXAMPLE
        PS C:\> New-Timer

    .NOTES
        This function takes no parameters and starts a new stopwatch object.
    #>

    [OutputType([System.Diagnostics.Stopwatch])]
    param ()

    # Start a fresh stopwatch for measuring elapsed time.
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    return $stopwatch
}