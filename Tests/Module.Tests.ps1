BeforeAll {
    $manifestPath = Join-Path $PSScriptRoot '../IT-ToolBox.psd1'
    $module = Import-Module $manifestPath -Force -PassThru -ErrorAction Stop
}

Describe 'IT-ToolBox module boundary' {
    It 'has a valid manifest' {
        $manifest = Test-ModuleManifest $manifestPath -ErrorAction Stop
        $manifest.Version | Should -Be ([version]'3.0.0')
    }

    It 'exports exactly the supported commands' {
        $expected = @('New-LogEntry', 'New-Timer', 'Get-TimerStatus', 'Stop-Timer', 'Get-ElapsedTime', 'Test-FileName', 'Test-IsValidPath', 'Test-IsIP', 'Test-IsDate', 'New-StringEncryption', 'New-StringDecryption', 'New-RandomString', 'New-RandomPassword', 'New-PhoneticPassword') | Sort-Object
        $actual = @($module.ExportedFunctions.Keys | Sort-Object)
        ($actual -join ',') | Should -Be ($expected -join ',')
        $module.ExportedVariables.Count | Should -Be 0
        $module.ExportedAliases.Count | Should -Be 0
        $module.ExportedCmdlets.Count | Should -Be 0
    }

    It 'keeps logging helpers private' {
        Get-Command Get-NewLogEntryMutexName -Module IT-ToolBox -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        Get-Command Initialize-NewLogEntryState -Module IT-ToolBox -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'has no mandatory external dependencies' {
        $data = Import-PowerShellDataFile $manifestPath
        @($data.RequiredAssemblies).Where({ $null -ne $_ }).Count | Should -Be 0
        @($data.RequiredModules).Where({ $null -ne $_ }).Count | Should -Be 0
    }
}

Describe 'Timers' {
    It 'starts, measures and stops a timer' {
        $timer = New-Timer
        $timer | Should -BeOfType ([System.Diagnostics.Stopwatch])
        Get-TimerStatus -Timer $timer | Should -BeTrue
        Get-ElapsedTime -ElapsedTime $timer | Should -BeOfType ([timespan])
        Get-ElapsedTime -ElapsedTime $timer -Seconds | Should -BeOfType ([int])
        Get-ElapsedTime -ElapsedTime $timer -TotalMilliseconds | Should -BeGreaterOrEqual 0
        Stop-Timer -Timer $timer | Should -BeTrue
        Get-TimerStatus -Timer $timer | Should -BeFalse
    }
}
