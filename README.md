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
| New-RandomString | Secure random selection from the historical alphabet |
| New-RandomPassword | Secure random passwords from the historical mixed alphabet |
| New-PhoneticPassword | Passwords with phonetic spelling and exact category counts |
| New-ApiRequest | OAuth-style form/JSON client requests |
| New-StringConversion | Domain-specific character mapping and space handling |
| Get-StringCheckSum | UTF-8 checksums with selectable digest algorithms |
| Get-StringHashCode | Standard SHA-256 hex with explicit legacy output mode |

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
- `Staging/v3/` retains 9 candidate commands pending tests and compatibility fixes.
  These include existing validators, strings, password generation, API requests,
  registry, uptime and AD utilities. They are not currently exported.
- Only the eighteen listed commands are exported. Private helpers, variables and aliases
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

## Password generation

`New-PhoneticPassword` retains its 12-character default, phonetic character table,
category-count parameters, aliases, color/display switches, clipboard option and
string return value. The original symbol exclusions and phonetic spellings are
unchanged. Numeric pipeline inputs accumulate into one returned password, as before.

```powershell
New-PhoneticPassword -LowerCaseLetters 6 -CapitalCaseLetters 4 -NumberDigits 4 -Symbol 4
New-PhoneticPassword -PasswordLength 20 -NoPasswordSpell
New-PhoneticPassword -PasswordToClipboard -NoPasswordSpell
```

Characters are selected using .NET `RandomNumberGenerator.GetInt32`; composition
mode uses a Fisher-Yates shuffle. Clipboard writes use `Set-Clipboard` and honor
`-WhatIf`/`-Confirm`; an available platform clipboard backend is required. An
explicit clipboard failure throws rather than claiming a successful copy. CI mocks
clipboard writes and does not verify a desktop clipboard backend.

`New-RandomString` retains its alphabet and default length 12. `New-RandomPassword`
retains its alphabet and default length 8. Its historical `-Complex` switch remains
accepted with the same behavior; exact category guarantees are provided by
`New-PhoneticPassword`. Defaults are preserved for compatibility, not recommended
as universal password policies.

Lengths must be 1–4,096; composition counts must be nonnegative and total 1–4,096
per pipeline input. Independent secure selection allows repeated characters, fixing
the old random-password length cap caused by sampling without replacement.

## API request helper

`New-ApiRequest` constructs a client request with `client_id`, `grant_type` and
optional `client_secret`, and returns the endpoint response. It is not a general
REST client or an automatic token-acquisition/refresh workflow.

```powershell
$response = New-ApiRequest -ApiKey 'client-id' -ApiSecret $secret -ApiUrl 'https://example.invalid/oauth/token'
$response = New-ApiRequest -ApiKey 'client-id' -ApiSecret $secret -ApiUrl 'https://example.invalid/token' -ContentType 'application/json' -Headers @{ 'X-Request-ID' = 'request-id' }
```

The default is POST with `application/x-www-form-urlencoded`. JSON content type
serializes the same authentication fields as JSON. `Headers` must be an IDictionary
(e.g. a hashtable); specify Content-Type with `-ContentType`, not inside Headers.
Only form and JSON bodies are supported.

Migration changes: GET no longer defaults, and a GET request cannot include
`ApiSecret`. Secret-free GET remains available and delegates dictionary query
encoding to Invoke-RestMethod. Requests with a client secret or Authorization
header require HTTPS. Other custom headers are not inspected for secrets; callers
should use HTTPS for sensitive requests. Automatic redirects are disabled; use
the final endpoint explicitly. URLs must be absolute HTTP(S) without user-info.

Connection timeout defaults to 30 seconds and can be configured with
`-ConnectionTimeoutSeconds` (alias `-TimeoutSec`). This is not a guaranteed total
wall-clock deadline. Failures terminate with the original Invoke-RestMethod error;
no retries or custom logging are added. Tests mock all HTTP calls: real endpoint
behavior and TLS are not integration-tested.

## String conversion and hashing

`New-StringConversion` retains the original character map, custom-map parameter,
unknown-character replacement and space options. Its default now matches the
documented behavior: spaces become hyphens. It returns exactly one string rather
than leaking collection indices. The map remains domain-specific (for example,
`&` maps to `e`); it is not a general-purpose transliteration or safe-path generator.

Custom maps replace the default map and are copied internally. Space policy
overrides an existing space mapping without mutating the caller's table. Conversion
normalizes text to Form C and handles unsupported Unicode text elements once,
including supplementary characters. This changes output for decomposed accents
and surrogate pairs compared with the old UTF-16 character loop.

`Get-StringCheckSum` retains uppercase hyphen-separated MD5 output by default for
existing non-security comparisons. Select `-Algorithm SHA256`, `SHA384` or `SHA512`
when needed. MD5 is unsuitable for adversarial integrity checks.

`Get-StringHashCode` returns 64 uppercase SHA-256 hexadecimal characters by default.
Use `-LegacyFormat` only when comparing with old delimiter-free decimal output.
The hash algorithm remains SHA-256; the default representation intentionally changes.
Both hash commands use UTF-8 without a BOM and do not normalize text. Neither is
a password-storage function or an authentication mechanism.
