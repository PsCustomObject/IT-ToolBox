# IT-ToolBox

Reusable infrastructure automation utilities originally developed for Windows
enterprise administration. Version 3 modernizes the module in small, tested steps.

## Status and requirements

This is the **3.0.0-alpha1 foundation**, not the completed modernization release.
Requires PowerShell 7.4 or later (Core edition). Windows PowerShell 5.1 is not supported.
The foundation imports without WinSCP, GnuPG, Active Directory or Exchange dependencies.

## Supported commands in this foundation

| Command | Purpose |
| --- | --- |
| New-LogEntry | File and console logging, buffering, redaction and pipeline input |
| New-Timer | Start a Stopwatch |
| Get-TimerStatus | Check whether a Stopwatch is running |
| Stop-Timer | Stop a Stopwatch |
| Get-ElapsedTime | Retrieve elapsed time or individual components |

```powershell
Import-Module ./IT-ToolBox.psd1
New-LogEntry -LogMessage 'Started' -LogFilePath './automation.log' -NoConsole
$timer = New-Timer
Get-ElapsedTime -ElapsedTime $timer
Stop-Timer -Timer $timer
```

Logging output only enters the success pipeline when requested with `-PassThru`.
Use `New-LogEntry -GetBuffer`, `-FlushBuffer` and `-ClearBuffer` rather than accessing
module variables. Redaction is opt-in and does not guarantee detection of every secret.

## Migration from v2

- SCP and GnuPG wrappers and bundled WinSCP binaries are removed. Separate modules
  will own file transfer and OpenPGP; no replacement is bundled here.
- `Legacy/` retains string encryption, Exchange and script-context helpers for reference.
- `Staging/v3/` retains 20 candidate commands pending tests and compatibility fixes.
  These include existing validators, strings, password generation, API requests,
  registry, uptime and AD utilities. They are not currently exported.
- Only the five listed commands are exported. Private helpers, variables and aliases
  are not exported. Existing calls to other v2 commands require the v2 release until
  those commands return to the supported API.
- The module GUID and Git history are preserved.

## Tests and CI

```powershell
Install-Module Pester -RequiredVersion 5.7.1 -Scope CurrentUser
Invoke-Pester ./Tests
```

CI runs syntax validation, isolated import and Pester on Windows, Linux and macOS
using each hosted runner's installed PowerShell. It does not test every PowerShell
release. The inherited ten logger tests now exercise the command through module import.
Concurrency stress tests and Windows/AD integration tests are future work.

The logger is adopted from `PowerShell-Functions/New-LogEntry` at commit `d5a9edd`.
The source and helper implementations are unchanged; integration tests import this module.

See [CHANGELOG.md](./CHANGELOG.md) for history. Released under the [MIT License](./LICENSE).
