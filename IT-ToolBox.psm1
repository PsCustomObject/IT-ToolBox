#Requires -Version 7.4

# Import implementation files only; legacy and staged commands are never loaded.
foreach ($directory in @('Private', 'Public')) {
    $sourcePath = Join-Path $PSScriptRoot $directory
    foreach ($file in Get-ChildItem -LiteralPath $sourcePath -Filter '*.ps1' -File | Sort-Object Name) {
        . $file.FullName
    }
}

Export-ModuleMember -Function @(
    'New-LogEntry'
    'New-Timer'
    'Get-TimerStatus'
    'Stop-Timer'
    'Get-ElapsedTime'
)
