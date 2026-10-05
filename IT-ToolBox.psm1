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
    'Get-ScriptDirectory'
    'Get-ScriptName'
    'Test-FileName'
    'Test-IsValidPath'
    'Test-IsIP'
    'Test-IsDate'
    'Test-IsEmail'
    'Test-IsUrl'
    'Convert-LogonTimestamp'
    'Get-OsUpTime'
    'Remove-SpecialCharacters'
    'Test-RegistryValue'
    'Test-IsValidDn'
    'Test-IsValidUpn'
    'Get-ReportChain'
    'New-StringEncryption'
    'New-StringDecryption'
    'New-RandomString'
    'New-RandomPassword'
    'New-PhoneticPassword'
    'New-ApiRequest'
    'New-StringConversion'
    'Get-StringCheckSum'
    'Get-StringHashCode'
)
