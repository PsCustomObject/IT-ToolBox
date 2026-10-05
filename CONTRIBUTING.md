# Contributing to IT-ToolBox

Use PowerShell 7.4 or later and Git. Make changes on a feature branch from an
up-to-date master; avoid committing directly to master:

```bash
git switch master
git pull --ff-only
git switch -c feature/describe-your-change
```

If contributing without push access, fork the repository and clone your fork first.
Use master as the pull request target.

## Code and tests

- Use four spaces for indentation, matching .editorconfig.
- Keep exported functions in Public/ and implementation helpers in Private/.
- Update both export lists in IT-ToolBox.psd1 and IT-ToolBox.psm1 when adding a command.
- Update the expected exports in Tests/Module.Tests.ps1 with intentional API changes.
- Add regression coverage for changed behavior and keep external dependencies optional.
- Document compatibility changes in README.md and CHANGELOG.md.
- Keep WinSCP/SCP and PGP/OpenPGP development in their separate module projects.

From the repository root, run in PowerShell:

```powershell
Install-Module Pester -RequiredVersion 5.7.1 -Scope CurrentUser
Import-Module ./IT-ToolBox.psd1 -Force -ErrorAction Stop
Invoke-Pester ./Tests
```

Inspect failures before committing. Windows registry tests are skipped on Linux
and macOS; the CI matrix runs all three platforms. AD, API and remote CIM tests
use mocks and do not establish connectivity to a real endpoint. Keep credentials,
logs, local test output and editor metadata out of commits.

## Submit a pull request

```bash
git switch feature/describe-your-change
git diff --check
git status --short
git add path/to/changed-file
git diff --cached
git commit -m "Describe the change"
git push -u origin feature/describe-your-change
```

Give the PR a descriptive title. Explain the resulting behavior, relevant
compatibility changes, and which tests you ran. Wait for the Windows, Linux and
macOS checks before merging. A dependency-installation failure needs its error
log inspected; rerun if it is transient rather than assuming the tests passed.
