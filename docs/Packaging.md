# Build and install the modernization preview

Run from the repository root using PowerShell 7.4 or later:

```powershell
Invoke-Pester ./Tests
./scripts/Build-Module.ps1
```

The script creates artifacts/IT-ToolBox-3.0.0-beta1.zip and returns its path,
version and file count. It takes the version from the manifest without modifying
it. Use -OutputDirectory to choose another local destination. An existing archive
causes a terminating error; use a different destination for another build.

The ZIP contains IT-ToolBox/3.0.0/ with the manifest, loader, Public and Private
implementation files, license, README, changelog, contributing guide, security policy and Markdown
documents in docs/.
Tests, build scripts, Legacy, Staging, Git metadata and external binaries are
excluded. Historical encryption migration requires the original repository source
in a separate session; the old decoder is not distributed in this archive.

Extract into a new directory, then verify or import the extracted manifest:

```powershell
Expand-Archive -LiteralPath './artifacts/IT-ToolBox-3.0.0-beta1.zip' -DestinationPath './preview-install'
Import-Module './preview-install/IT-ToolBox/3.0.0/IT-ToolBox.psd1' -Force
Get-Command -Module IT-ToolBox
```

For discovery by name, put the extracted IT-ToolBox directory under a directory
listed in $env:PSModulePath. Review existing installations before copying there;
this script does not install or replace a module for you.

CI runs archive-content and fresh-process import tests on Windows, Linux and macOS,
then builds the archive locally. No publishing, release creation or signing is
performed. ZIP timestamps are not normalized, so identical source builds need not
have identical archive hashes. This remains a beta preview; the package process
does not establish live AD, remote CIM or service authentication compatibility.
