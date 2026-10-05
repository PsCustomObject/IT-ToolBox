BeforeAll {
    $sourceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $fixtureRoot = Join-Path $TestDrive 'isolated-module'
    $null = New-Item -ItemType Directory -Path $fixtureRoot
    foreach ($item in @('IT-ToolBox.psd1', 'IT-ToolBox.psm1', 'Public', 'Private', 'Legacy', 'Staging')) {
        Copy-Item -LiteralPath (Join-Path $sourceRoot $item) -Destination $fixtureRoot -Recurse
    }
    # Fail loudly if a future loader starts executing either excluded directory.
    Set-Content -LiteralPath (Join-Path $fixtureRoot 'Legacy/ImportBoundaryProbe.ps1') -Value "throw 'Legacy code must not execute during import.'"
    Set-Content -LiteralPath (Join-Path $fixtureRoot 'Staging/ImportBoundaryProbe.ps1') -Value "throw 'Staging code must not execute during import.'"
    $fixtureManifest = (Join-Path $fixtureRoot 'IT-ToolBox.psd1').Replace("'", "''")
    $executable = Join-Path $PSHOME $(if ($IsWindows) { 'pwsh.exe' } else { 'pwsh' })
}

Describe 'Service integration import boundary' {
    It 'preserves caller state on <Mode>' -ForEach @(
        @{ Mode = 'initial import'; ImportCount = 1 }
        @{ Mode = 'forced reload'; ImportCount = 2 }
    ) {
        $code = @'
$global:integrationCalls = 0
foreach ($name in @(
    'Get-PSSession', 'New-PSSession', 'Remove-PSSession', 'Import-PSSession',
    'Connect-AzureAD', 'Disconnect-AzureAD', 'Test-AzureSession',
    'Connect-MgGraph', 'Disconnect-MgGraph', 'Get-MgContext',
    'Connect-AzAccount', 'Disconnect-AzAccount', 'Clear-AzContext',
    'Connect-ExchangeOnline', 'Disconnect-ExchangeOnline', 'Install-Module'
)) {
    Set-Item -Path ('Function:global:' + $name) -Value {
        $global:integrationCalls++
        throw 'Import must not manage service connections or dependencies.'
    }
}
$ErrorActionPreference = 'Continue'
$WarningPreference = 'Continue'
$originalCallback = [Net.ServicePointManager]::ServerCertificateValidationCallback
$sentinel = [Net.Security.RemoteCertificateValidationCallback]{ param($sender, $certificate, $chain, $errors) return $false }
[Net.ServicePointManager]::ServerCertificateValidationCallback = $sentinel
try {
    $location = (Get-Location).Path
    for ($i = 0; $i -lt __IMPORT_COUNT__; $i++) {
        $module = Import-Module '__MANIFEST__' -Force -PassThru -ErrorAction Stop
    }
    [pscustomobject]@{
        ServiceCalls = $global:integrationCalls
        TlsCallbackPreserved = [object]::ReferenceEquals($sentinel, [Net.ServicePointManager]::ServerCertificateValidationCallback)
        BypassTypeAbsent = $null -eq ('ServerCertificateValidationCallback' -as [type])
        ErrorPreference = [string]$ErrorActionPreference
        WarningPreference = [string]$WarningPreference
        LocationPreserved = $location -eq (Get-Location).Path
        ExportCount = $module.ExportedFunctions.Count
        HistoricalExports = @($module.ExportedFunctions.Keys | Where-Object { $_ -in @('Close-AzureSession', 'New-ExchangeSession', 'Close-ExchangeSession', 'Enable-SelfSignedCertificate') }).Count
    } | ConvertTo-Json -Compress
}
finally {
    [Net.ServicePointManager]::ServerCertificateValidationCallback = $originalCallback
}
'@
        $code = $code.Replace('__MANIFEST__', $fixtureManifest).Replace('__IMPORT_COUNT__', [string]$ImportCount)
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($code))
        $output = & $executable -NoProfile -NonInteractive -EncodedCommand $encoded
        $LASTEXITCODE | Should -Be 0
        $result = $output | ConvertFrom-Json
        $result.ServiceCalls | Should -Be 0
        $result.TlsCallbackPreserved | Should -BeTrue
        $result.BypassTypeAbsent | Should -BeTrue
        $result.ErrorPreference | Should -Be 'Continue'
        $result.WarningPreference | Should -Be 'Continue'
        $result.LocationPreserved | Should -BeTrue
        $result.ExportCount | Should -Be 29
        $result.HistoricalExports | Should -Be 0
    }
}
