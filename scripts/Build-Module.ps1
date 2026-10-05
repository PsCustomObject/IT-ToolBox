#Requires -Version 7.4
<#
.SYNOPSIS
    Build a local installable ZIP from supported module files only.
.DESCRIPTION
    Does not publish, install, sign or change the module version. Existing archives
    are never overwritten. Build staging is removed even when packaging fails.
#>
[CmdletBinding()]
param
(
    [ValidateNotNullOrEmpty()]
    [string]$OutputDirectory = (Join-Path $PSScriptRoot '../artifacts')
)

$ErrorActionPreference = 'Stop'
$sourceRoot = Split-Path $PSScriptRoot -Parent
$manifest = Import-PowerShellDataFile (Join-Path $sourceRoot 'IT-ToolBox.psd1')
$version = [string]$manifest.ModuleVersion
$prerelease = [string]$manifest.PrivateData.PSData.Prerelease

if ($prerelease)
{
    $version += "-$prerelease"
}

if ($version -notmatch '^\d+\.\d+\.\d+(\.\d+)?(-[A-Za-z0-9]+)?$')
{
    throw 'Manifest version cannot be used as an archive filename.'
}

$provider = $null
$drive = $null
$outputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(
    $OutputDirectory,
    [ref]$provider,
    [ref]$drive
)

if ($provider.Name -ne 'FileSystem')
{
    throw 'OutputDirectory must be a filesystem path.'
}

$archivePath = Join-Path $outputPath "IT-ToolBox-$version.zip"

if (Test-Path -LiteralPath $archivePath)
{
    throw "Archive already exists: $archivePath"
}

$stageRoot = Join-Path ([IO.Path]::GetTempPath()) ('ITToolBox-build-' + [guid]::NewGuid())
$packageRoot = Join-Path $stageRoot 'package'
$moduleRoot = Join-Path $packageRoot (Join-Path 'IT-ToolBox' ([string]$manifest.ModuleVersion))

try
{
    $null = [IO.Directory]::CreateDirectory($moduleRoot)

    $files = @(foreach ($name in @('IT-ToolBox.psd1', 'IT-ToolBox.psm1', 'LICENSE', 'README.md', 'CHANGELOG.md'))
        {
            Get-Item -LiteralPath (Join-Path $sourceRoot $name)
        })

    foreach ($directory in @('Public', 'Private', 'docs'))
    {
        $filter = if ($directory -eq 'docs') { '*.md' } else { '*.ps1' }
        $files += @(Get-ChildItem -LiteralPath (Join-Path $sourceRoot $directory) -Filter $filter -File | Sort-Object Name)
    }

    foreach ($file in $files)
    {
        if ($file.Attributes -band [IO.FileAttributes]::ReparsePoint)
        {
            throw "Packaging symbolic links is not supported: $($file.FullName)"
        }

        $relative = [IO.Path]::GetRelativePath($sourceRoot, $file.FullName)
        $destination = Join-Path $moduleRoot $relative
        $null = [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination))
        [IO.File]::Copy($file.FullName, $destination, $false)

        if ($file.Extension -in @('.ps1', '.psm1', '.psd1'))
        {
            $tokens = $null
            $parseErrors = $null
            $null = [Management.Automation.Language.Parser]::ParseFile($destination, [ref]$tokens, [ref]$parseErrors)

            if ($parseErrors.Count)
            {
                throw ($parseErrors | Out-String)
            }
        }
    }

    $null = Test-ModuleManifest -Path (Join-Path $moduleRoot 'IT-ToolBox.psd1') -ErrorAction Stop
    $temporaryArchive = Join-Path $stageRoot 'module.zip'
    [IO.Compression.ZipFile]::CreateFromDirectory($packageRoot, $temporaryArchive)
    $null = [IO.Directory]::CreateDirectory($outputPath)
    [IO.File]::Move($temporaryArchive, $archivePath, $false)

    [pscustomobject]@{
        ArchivePath   = $archivePath
        Version       = $version
        ModuleVersion = [string]$manifest.ModuleVersion
        FileCount     = $files.Count
    }
}
finally
{
    if ([IO.Directory]::Exists($stageRoot))
    {
        [IO.Directory]::Delete($stageRoot, $true)
    }
}
