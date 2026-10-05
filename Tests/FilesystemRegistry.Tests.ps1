BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../IT-ToolBox.psd1') -Force -ErrorAction Stop
}

Describe 'Filesystem rename policy' {
    BeforeEach {
        $root = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $root | Out-Null
    }
    It 'previews affected names without changing files or their content' {
        $path = Join-Path $root 'a!b.txt'
        Set-Content -LiteralPath $path -Value 'original content'
        Set-Content -LiteralPath (Join-Path $root 'unchanged résumé.txt') -Value 'keep'
        $records = @(Remove-SpecialCharacters $root)
        $records.Count | Should -Be 1
        $records[0].NewName | Should -Be 'a-b.txt'
        $records[0].Status | Should -Be 'Preview'
        $records[0].HasCollision | Should -BeFalse
        Get-Content -LiteralPath $path | Should -Be 'original content'
    }
    It 'renames files before their containing directories' {
        $folder = New-Item -ItemType Directory -Path (Join-Path $root 'folder!')
        Set-Content -LiteralPath (Join-Path $folder.FullName 'report@.txt') -Value 'content'
        $records = @(Remove-SpecialCharacters $root -AutoFix -Confirm:$false)
        $records.Count | Should -Be 2
        $records[0].ItemType | Should -Be 'File'
        ($records.Status | Select-Object -Unique) | Should -Be 'Renamed'
        Get-Content -LiteralPath (Join-Path $root 'folder-/report-.txt') | Should -Be 'content'
    }
    It 'uses literal paths for wildcard-shaped names' {
        $folder = Join-Path $root '[folder]'
        [void][IO.Directory]::CreateDirectory($folder)
        Set-Content -LiteralPath (Join-Path $folder 'a[b].txt') -Value 'literal'
        Remove-SpecialCharacters $folder -AutoFix -Confirm:$false | Out-Null
        Get-Content -LiteralPath (Join-Path $folder 'a-b-.txt') | Should -Be 'literal'
        Test-Path -LiteralPath $folder | Should -BeTrue
    }
    It 'honors WhatIf for both renames and activity logs' {
        $path = Join-Path $root 'name!.txt'
        Set-Content -LiteralPath $path -Value 'keep'
        $records = @(Remove-SpecialCharacters $root -AutoFix -LogActivities -WhatIf)
        $records[0].Status | Should -Be 'Skipped'
        Test-Path -LiteralPath $path | Should -BeTrue
        @(Get-ChildItem $root -Filter '*.log').Count | Should -Be 0
    }
    It 'reports an existing destination and blocks the complete rename plan' {
        Set-Content -LiteralPath (Join-Path $root 'a!.txt') -Value 'source'
        Set-Content -LiteralPath (Join-Path $root 'a-.txt') -Value 'destination'
        Set-Content -LiteralPath (Join-Path $root 'other!.txt') -Value 'other'
        $records = @(Remove-SpecialCharacters $root)
        ($records | Where-Object HasCollision).Count | Should -Be 1
        { Remove-SpecialCharacters $root -AutoFix -Confirm:$false } | Should -Throw '*collisions*'
        Get-Content -LiteralPath (Join-Path $root 'a!.txt') | Should -Be 'source'
        Get-Content -LiteralPath (Join-Path $root 'a-.txt') | Should -Be 'destination'
        Test-Path -LiteralPath (Join-Path $root 'other!.txt') | Should -BeTrue
    }
    It 'reports both entries when two sources map to the same destination' {
        Set-Content -LiteralPath (Join-Path $root 'a!.txt') -Value 'one'
        Set-Content -LiteralPath (Join-Path $root 'a@.txt') -Value 'two'
        $records = @(Remove-SpecialCharacters $root)
        @($records | Where-Object HasCollision).Count | Should -Be 2
        { Remove-SpecialCharacters $root -AutoFix -Confirm:$false } | Should -Throw '*collisions*'
        @(Get-ChildItem $root).Count | Should -Be 2
    }
    It 'does not follow or rename directory links and junctions' {
        $target = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $target | Out-Null
        Set-Content -LiteralPath (Join-Path $target 'outside!.txt') -Value 'outside'
        $kind = if ($IsWindows) { 'Junction' } else { 'SymbolicLink' }
        New-Item -ItemType $kind -Path (Join-Path $root 'link!') -Target $target | Out-Null
        @(Remove-SpecialCharacters $root -AutoFix -Confirm:$false).Count | Should -Be 0
        Test-Path -LiteralPath (Join-Path $target 'outside!.txt') | Should -BeTrue
        { Remove-SpecialCharacters (Join-Path $root 'link!') } | Should -Throw '*link or junction*'
    }
    It 'includes hidden entries' {
        $path = Join-Path $root '.hidden!.txt'
        Set-Content -LiteralPath $path -Value 'hidden'
        if ($IsWindows) { (Get-Item -LiteralPath $path).Attributes = [IO.FileAttributes]::Hidden }
        @(Remove-SpecialCharacters $root).Count | Should -Be 1
        Remove-SpecialCharacters $root -AutoFix -Confirm:$false | Out-Null
        Test-Path -LiteralPath (Join-Path $root '.hidden-.txt') | Should -BeTrue
    }
    It 'supports the historical logging spelling and corrected alias' {
        Set-Content -LiteralPath (Join-Path $root 'name!.txt') -Value 'keep'
        $log = Join-Path $TestDrive ([guid]::NewGuid().ToString() + '.log')
        Remove-SpecialCharacters $root -LogActivites -LogFilePath $log -Confirm:$false | Out-Null
        Remove-SpecialCharacters $root -LogActivities -LogFilePath $log -Confirm:$false | Out-Null
        @(Get-Content -LiteralPath $log).Count | Should -Be 2
        Get-Content -LiteralPath $log | Should -Match 'Preview:'
    }
    It 'rejects logging paths that would move during renaming before any writes' {
        $folder = New-Item -ItemType Directory -Path (Join-Path $root 'folder!')
        Set-Content -LiteralPath (Join-Path $folder.FullName 'file!.txt') -Value 'keep'
        $log = Join-Path $folder.FullName 'activities.log'
        { Remove-SpecialCharacters $root -AutoFix -LogActivities -LogFilePath $log -Confirm:$false } | Should -Throw '*activity log path*'
        Test-Path -LiteralPath $log | Should -BeFalse
        Test-Path -LiteralPath $folder.FullName | Should -BeTrue
    }
    It 'returns no records for an empty directory' {
        @(Remove-SpecialCharacters $root).Count | Should -Be 0
    }
    It 'reports missing roots and rejects non-directory or non-filesystem roots' {
        { Remove-SpecialCharacters (Join-Path $root 'missing') } | Should -Throw
        $file = Join-Path $root 'file.txt'
        Set-Content -LiteralPath $file -Value 'file'
        { Remove-SpecialCharacters $file } | Should -Throw '*filesystem directory*'
        { Remove-SpecialCharacters 'Env:' } | Should -Throw '*filesystem directory*'
    }
    It 'propagates rename errors without fabricating success' {
        Set-Content -LiteralPath (Join-Path $root 'name!.txt') -Value 'keep'
        Mock Rename-Item -ModuleName IT-ToolBox { throw 'rename failed' }
        { Remove-SpecialCharacters $root -AutoFix -Confirm:$false } | Should -Throw '*rename failed*'
    }
}

Describe 'Registry platform boundary' {
    It 'imports and reports unsupported registry access on non-Windows hosts' -Skip:$IsWindows {
        { Test-RegistryValue -Path 'HKCU:\Software\Example' -Value 'Name' } | Should -Throw '*Windows Registry provider*'
    }
}

Describe 'Windows registry integration' -Skip:(-not $IsWindows) {
    BeforeAll {
        $registryPath = 'HKCU:\Software\ITToolBoxTests-' + [guid]::NewGuid().ToString()
        New-Item -Path $registryPath | Out-Null
        New-ItemProperty -LiteralPath $registryPath -Name Empty -Value '' -PropertyType String | Out-Null
        New-ItemProperty -LiteralPath $registryPath -Name Zero -Value 0 -PropertyType DWord | Out-Null
        New-ItemProperty -LiteralPath $registryPath -Name 'A*B' -Value 'literal' -PropertyType String | Out-Null
        $key = Get-Item -LiteralPath $registryPath
        $key.SetValue('', 'default')
        $key.Dispose()
    }
    AfterAll {
        Remove-Item -LiteralPath $registryPath -Recurse -Force
    }
    It 'detects empty and zero-valued entries case-insensitively' {
        Test-RegistryValue $registryPath Empty | Should -BeTrue
        Test-RegistryValue $registryPath zero | Should -BeTrue
    }
    It 'detects the unnamed value and literal wildcard-shaped value names' {
        Test-RegistryValue $registryPath '' | Should -BeTrue
        Test-RegistryValue $registryPath 'A*B' | Should -BeTrue
        Test-RegistryValue $registryPath 'A*' | Should -BeFalse
    }
    It 'returns false for missing keys and values' {
        Test-RegistryValue $registryPath Missing | Should -BeFalse
        Test-RegistryValue ($registryPath + '\Missing') Name | Should -BeFalse
    }
    It 'rejects paths from other providers' {
        { Test-RegistryValue $TestDrive Name } | Should -Throw '*Registry provider*'
    }
    It 'propagates access-denied errors' {
        Mock Get-Item -ModuleName IT-ToolBox { throw [UnauthorizedAccessException]::new('access denied') }
        { Test-RegistryValue $registryPath Name } | Should -Throw '*access denied*'
    }
}
