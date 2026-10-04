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
| Test-FileName | Native filename validation; optional Windows-compatible rules |
| Test-IsValidPath | Native filesystem path syntax; no existence check |
| Test-IsIP | Standard IPv4/IPv6 literals; strict dotted IPv4 |
| Test-IsDate | Culture-aware date validation with optional exact format |
| New-StringEncryption | Passphrase-based AES-256-GCM string encryption |
| New-StringDecryption | Authenticate and decrypt the versioned string format |

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
- `Staging/v3/` retains 16 candidate commands pending tests and compatibility fixes.
  These include existing validators, strings, password generation, API requests,
  registry, uptime and AD utilities. They are not currently exported.
- Only the eleven listed commands are exported. Private helpers, variables and aliases
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

## Validation semantics

Filename and path checks are lexical checks, not guarantees of existence, permissions
or filesystem limits. Filename rules default to the host platform; use
`-WindowsCompatible` to validate Windows names on another platform. Path checks do
not validate each component as a filename.

`Test-IsIP` retains its historical command name; `Test-IsIpAddress.ps1` is the source
filename. IPv4 shorthand accepted by .NET is deliberately rejected.

`Test-IsDate` defaults to the current culture. For deterministic input, use
`Test-IsDate '2026-10-04' -Format 'yyyy-MM-dd' -Culture ''` (invariant culture).

## String encryption

The modern commands retain their names but intentionally change the encryption
format and require an explicit passphrase. They use .NET AES-256-GCM, random
16-byte salt and 12-byte nonce, a 16-byte authentication tag, and PBKDF2-HMAC-SHA256
with 600,000 iterations. Wrong passphrases and changed payloads throw; unauthenticated
plaintext is never returned. The `ITTB1.` prefix identifies this fixed format.

```powershell
# $passphrase must come from your application's secret-handling mechanism.
$encrypted = New-StringEncryption -StringToEncrypt 'example' -EncryptPassPhrase $passphrase
$original = New-StringDecryption -EncryptedString $encrypted -EncryptPassPhrase $passphrase
```

Limits: 1 MiB of plaintext UTF-8 and 4,096 passphrase characters. Encryption
clears temporary plaintext and key byte arrays. Managed strings (including the
passphrase, input plaintext and returned plaintext) cannot be reliably erased;
this API is not a secret vault or password-storage API. Strong passphrases remain
necessary. The functions perform string encryption only, not file encryption or OpenPGP.

### Legacy migration

New ciphertext is incompatible with the historical v2 string encryption format.
There is no automatic fallback. The original functions remain in `Legacy/` solely
for decoding existing data in a separate session. Recover old plaintext with the
original passphrase, salt and vector, then encrypt it using the modern function.
If the old call used computer-name defaults, that original machine name is needed.
Legacy ciphertext lacks authentication, so successful decryption does not establish
its integrity. Do not overwrite existing encrypted data before verifying migration.
Caller-selected `EncryptSalt` and `IntersectingVector` parameters are removed;
new salts/nonces are generated automatically.

Implementation references: [.NET AES-GCM](https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.aesgcm),
[OWASP cryptographic storage](https://cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html)
and [PBKDF2 work-factor guidance](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html).
The PBKDF2 work factor is adopted from OWASP guidance; it is not a security audit
or a guarantee that every deployment meets a compliance standard.
