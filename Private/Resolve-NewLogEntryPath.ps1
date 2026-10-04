function Resolve-NewLogEntryPath
{
    param([string]$Path)

    if (-not [string]::IsNullOrWhiteSpace($Path))
    {
        return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    }

    $basePath = if (-not [string]::IsNullOrWhiteSpace($script:PSCommandPath))
    {
        $script:PSCommandPath
    }
    elseif (-not [string]::IsNullOrWhiteSpace($PSCommandPath))
    {
        $PSCommandPath
    }
    else
    {
        Join-Path -Path (Get-Location).ProviderPath -ChildPath 'PowerShell'
    }

    $directory = Split-Path -Path $basePath -Parent
    $fileName = Split-Path -Path $basePath -Leaf

    if ([string]::IsNullOrWhiteSpace($directory))
    {
        $directory = (Get-Location).ProviderPath
    }

    if ([string]::IsNullOrWhiteSpace($fileName))
    {
        $fileName = 'PowerShell'
    }

    $safeTimestamp = [DateTime]::Now.ToString('yyyyMMdd-HHmmss')
    return Join-Path -Path $directory -ChildPath ('{0}-LogFile-{1}.log' -f $fileName, $safeTimestamp)
}
