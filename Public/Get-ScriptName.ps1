function Get-ScriptName
{
    <#
    .SYNOPSIS
        Return the filename (including its extension) of the calling script or an explicit script path.

    .DESCRIPTION
        Uses the immediately calling script, including dot-sourced scripts and functions
        defined in a script. Interactive calls without ScriptPath produce no output.
        Explicit paths are literal filesystem paths, resolved against the current location;
        the target need not exist. No host invocation variable is required.

    .PARAMETER ScriptPath
        Optional explicit script filename, with an absolute or relative filesystem path.

    .EXAMPLE
        Get-ScriptName

    .EXAMPLE
        Get-ScriptName -ScriptPath './scripts/automation.ps1'
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string]$ScriptPath
    )

    process
    {
        # Resolve the caller's script path, allowing an explicit override when provided.
        $path = Resolve-ITToolBoxScriptPath -ScriptPath $ScriptPath -CallerScriptPath $MyInvocation.ScriptName

        if ($path)
        {
            [System.IO.Path]::GetFileName($path)
        }
    }
}
