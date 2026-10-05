BeforeAll {
    $manifestPath = (Resolve-Path (Join-Path $PSScriptRoot '../IT-ToolBox.psd1')).Path
    Import-Module $manifestPath -Force -ErrorAction Stop
    $fixtureDirectory = Join-Path $TestDrive 'scripts with spaces'
    $null = New-Item -ItemType Directory -Path $fixtureDirectory
    $callerPath = Join-Path $fixtureDirectory 'caller.ps1'
    $nestedPath = Join-Path $fixtureDirectory 'nested.ps1'
    $functionPath = Join-Path $fixtureDirectory 'definition.ps1'
    Set-Content -LiteralPath $callerPath -Value @'
[pscustomobject]@{ Directory = Get-ScriptDirectory; Name = Get-ScriptName }
'@
    Set-Content -LiteralPath $nestedPath -Value @'
[pscustomobject]@{ Directory = Get-ScriptDirectory; Name = Get-ScriptName }
'@
    Set-Content -LiteralPath $functionPath -Value @'
function Get-DefinedScriptContext {
    [pscustomobject]@{ Directory = Get-ScriptDirectory; Name = Get-ScriptName }
}
'@
}

Describe 'Script-context helpers' {
    It 'resolves the script calling the imported module' {
        $result = & $callerPath
        $result.Directory | Should -Be $fixtureDirectory
        $result.Name | Should -Be 'caller.ps1'
    }

    It 'resolves a dot-sourced script' {
        $result = . $callerPath
        $result.Directory | Should -Be $fixtureDirectory
        $result.Name | Should -Be 'caller.ps1'
    }

    It 'resolves the innermost nested script' {
        $outerPath = Join-Path $TestDrive 'outer.ps1'
        Set-Content -LiteralPath $outerPath -Value '& (Join-Path $PSScriptRoot ''scripts with spaces/nested.ps1'')'
        $result = & $outerPath
        $result.Directory | Should -Be $fixtureDirectory
        $result.Name | Should -Be 'nested.ps1'
    }

    It 'resolves the script defining a calling function' {
        . $functionPath
        $result = Get-DefinedScriptContext
        $result.Directory | Should -Be $fixtureDirectory
        $result.Name | Should -Be 'definition.ps1'
    }

    It 'lets an explicit path override caller context' {
        $explicitPath = Join-Path $TestDrive 'not-created.ps1'
        Get-ScriptDirectory -ScriptPath $explicitPath | Should -Be $TestDrive
        Get-ScriptName -ScriptPath $explicitPath | Should -Be 'not-created.ps1'
        Test-Path -LiteralPath $explicitPath | Should -BeFalse
    }

    It 'resolves relative paths against the current location' {
        Push-Location $TestDrive
        try {
            Get-ScriptDirectory -ScriptPath './absent/example.ps1' | Should -Be (Join-Path $TestDrive 'absent')
            Get-ScriptName -ScriptPath './absent/example.ps1' | Should -Be 'example.ps1'
        }
        finally { Pop-Location }
    }

    It 'treats wildcard characters literally' {
        $path = Join-Path $TestDrive 'absent[12].ps1'
        Get-ScriptName -ScriptPath $path | Should -Be 'absent[12].ps1'
        Get-ScriptDirectory -ScriptPath $path | Should -Be $TestDrive
    }

    It 'returns one string per explicit pipeline path' {
        $paths = @((Join-Path $TestDrive 'one.ps1'), (Join-Path $fixtureDirectory 'two.ps1'))
        $names = @($paths | Get-ScriptName)
        $directories = @($paths | Get-ScriptDirectory)
        $names.Count | Should -Be 2
        ($names -join ',') | Should -Be 'one.ps1,two.ps1'
        $directories.Count | Should -Be 2
        $directories[0] | Should -Be $TestDrive
        $directories[1] | Should -Be $fixtureDirectory
    }

    It 'rejects explicit empty or null paths for <Command>' -ForEach @(
        @{ Command = 'Get-ScriptDirectory' }; @{ Command = 'Get-ScriptName' }
    ) {
        { & $Command -ScriptPath '' } | Should -Throw
        { & $Command -ScriptPath $null } | Should -Throw
    }

    It 'rejects a non-filesystem provider for <Command>' -ForEach @(
        @{ Command = 'Get-ScriptDirectory' }; @{ Command = 'Get-ScriptName' }
    ) {
        { & $Command -ScriptPath 'Env:PATH' } | Should -Throw '*filesystem*'
    }

    It 'rejects a trailing directory separator for <Command>' -ForEach @(
        @{ Command = 'Get-ScriptDirectory' }; @{ Command = 'Get-ScriptName' }
    ) {
        { & $Command -ScriptPath ($TestDrive + [IO.Path]::DirectorySeparatorChar) } | Should -Throw '*filename*'
    }

    It 'returns no interactive output and ignores hostinvocation in an isolated process' {
        $escapedManifest = $manifestPath.Replace("'", "''")
        $code = @"
Import-Module '$escapedManifest' -ErrorAction Stop
`$global:hostinvocation = @{ MyCommand = @{ Path = '/incorrect/host.ps1'; Name = 'host.ps1' } }
[pscustomobject]@{
    DirectoryCount = @(Get-ScriptDirectory).Count
    NameCount = @(Get-ScriptName).Count
} | ConvertTo-Json -Compress
"@
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($code))
        $executable = Join-Path $PSHOME $(if ($IsWindows) { 'pwsh.exe' } else { 'pwsh' })
        $output = & $executable -NoProfile -NonInteractive -EncodedCommand $encoded
        $LASTEXITCODE | Should -Be 0
        $result = $output | ConvertFrom-Json
        $result.DirectoryCount | Should -Be 0
        $result.NameCount | Should -Be 0
    }
}
