function Get-ScriptDirectory {
    <#
    .SYNOPSIS
        Return the directory of the calling script or an explicit script path.
    .DESCRIPTION
        Uses the immediately calling script, including dot-sourced scripts and functions
        defined in a script. Interactive calls without ScriptPath produce no output.
        Explicit paths are literal filesystem paths, resolved against the current location;
        the target need not exist. No hostinvocation variable is required.
    .PARAMETER ScriptPath
        Optional explicit script filename, with an absolute or relative filesystem path.
    .EXAMPLE
        Get-ScriptDirectory
    .EXAMPLE
        Get-ScriptDirectory -ScriptPath './scripts/automation.ps1'
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string]$ScriptPath
    )

    process {
        $path = Resolve-ITToolBoxScriptPath -ScriptPath $ScriptPath -CallerScriptPath $MyInvocation.ScriptName
        if ($path) { [System.IO.Path]::GetDirectoryName($path) }
    }
}
