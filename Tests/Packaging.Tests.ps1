BeforeAll {
    $sourceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $buildScript = Join-Path $sourceRoot 'scripts/Build-Module.ps1'
    $package = & $buildScript -OutputDirectory (Join-Path $TestDrive 'output [literal]')
    $extractRoot = Join-Path $TestDrive 'extracted'
    [IO.Compression.ZipFile]::ExtractToDirectory($package.ArchivePath, $extractRoot)
    $moduleRoot = Join-Path $extractRoot 'IT-ToolBox/3.0.0'
}

Describe 'Installable module packaging' {
    It 'uses the manifest preview version and conventional module layout' {
        $package.Version | Should -Be '3.0.0-alpha1'
        [IO.Path]::GetFileName($package.ArchivePath) | Should -Be 'IT-ToolBox-3.0.0-alpha1.zip'
        Test-ModuleManifest (Join-Path $moduleRoot 'IT-ToolBox.psd1') -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-Path -LiteralPath (Join-Path $moduleRoot 'LICENSE') | Should -BeTrue
    }

    It 'ships only supported code and documentation, excluding development and legacy files' {
        foreach ($directory in @('Legacy', 'Staging', 'Tests', 'scripts', '.git', '.github', 'artifacts')) {
            Test-Path -LiteralPath (Join-Path $moduleRoot $directory) | Should -BeFalse
        }
        $files = @(Get-ChildItem -LiteralPath $moduleRoot -File -Recurse -Force)
        $files.Count | Should -Be $package.FileCount
        foreach ($file in $files) {
            $relative = [IO.Path]::GetRelativePath($moduleRoot, $file.FullName).Replace('\', '/')
            $relative | Should -Match '^(IT-ToolBox\.psd1|IT-ToolBox\.psm1|LICENSE|README\.md|CHANGELOG\.md|(Public|Private)/[^/]+\.ps1|docs/[^/]+\.md)$'
            $original = Join-Path $sourceRoot $relative
            (Get-FileHash -LiteralPath $file.FullName).Hash | Should -Be (Get-FileHash -LiteralPath $original).Hash
        }
    }

    It 'imports the extracted module by name and exercises logging in a fresh process' {
        $escapedRoot = $extractRoot.Replace("'", "''")
        $code = @"
`$ErrorActionPreference = 'Stop'
`$env:PSModulePath = '$escapedRoot' + [IO.Path]::PathSeparator + `$env:PSModulePath
`$module = Import-Module IT-ToolBox -RequiredVersion 3.0.0 -Force -PassThru
New-LogEntry -LogMessage 'Packaged logger' -BufferOnly
[pscustomobject]@{
    ExportCount = `$module.ExportedFunctions.Count
    ModuleBase = `$module.ModuleBase
    Buffer = @(New-LogEntry -GetBuffer)
} | ConvertTo-Json -Compress
"@
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($code))
        $executable = Join-Path $PSHOME $(if ($IsWindows) { 'pwsh.exe' } else { 'pwsh' })
        $output = & $executable -NoProfile -NonInteractive -EncodedCommand $encoded
        $LASTEXITCODE | Should -Be 0
        $result = $output | ConvertFrom-Json
        $result.ModuleBase | Should -Be $moduleRoot
        $result.ExportCount | Should -Be 29
        $result.Buffer.Count | Should -Be 1
        $result.Buffer[0] | Should -Match '\[INFO\]: Packaged logger$'
    }

    It 'refuses to overwrite an existing archive without changing its contents' {
        $hash = (Get-FileHash -LiteralPath $package.ArchivePath).Hash
        { & $buildScript -OutputDirectory ([IO.Path]::GetDirectoryName($package.ArchivePath)) } | Should -Throw '*already exists*'
        (Get-FileHash -LiteralPath $package.ArchivePath).Hash | Should -Be $hash
    }

    It 'rejects non-filesystem output providers' {
        { & $buildScript -OutputDirectory 'Env:ITToolBoxPackage' } | Should -Throw '*filesystem*'
    }
}
