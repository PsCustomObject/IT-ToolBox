function Resolve-ITToolBoxScriptPath {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [AllowEmptyString()]
        [string]$ScriptPath,
        [AllowEmptyString()]
        [string]$CallerScriptPath
    )

    $path = if ($ScriptPath) { $ScriptPath } else { $CallerScriptPath }
    if ([string]::IsNullOrEmpty($path)) { return }

    $provider = $null
    $drive = $null
    $resolved = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(
        $path, [ref]$provider, [ref]$drive
    )
    if ($provider.Name -ne 'FileSystem') {
        throw 'ScriptPath must be a filesystem path.'
    }
    if ([string]::IsNullOrEmpty([System.IO.Path]::GetFileName($resolved))) {
        throw 'ScriptPath must include a filename.'
    }
    $resolved
}
