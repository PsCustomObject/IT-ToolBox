## Filesystem naming and registry restoration (unreleased)

- Restore Remove-SpecialCharacters and Test-RegistryValue; export twenty-four commands.
- Preserve the historical punctuation policy; return a rename preview by default.
- Honor WhatIf/Confirm, preflight collisions and rename deepest descendants first.
- Use literal paths, include hidden entries and skip symbolic links/junctions.
- Preserve LogActivites with a corrected alias and configurable portable log path.
- Check Windows registry value names regardless of data; support unnamed values.
- Propagate operational failures and document platform and non-transactional behavior.
- Add real filesystem tests and Windows-only temporary HKCU integration tests.

## Timestamp and uptime restoration (unreleased)

- Restore Convert-LogonTimestamp and Get-OsUpTime; export twenty-two supported commands.
- Preserve local DateTime and default date formatting; add UTC and pipeline conversion.
- Treat zero logon timestamps as no recorded logon; reject invalid FILETIME values.
- Use invariant string formatting and document replicated AD timestamp semantics.
- Preserve uptime days/TimeSpan outputs; support local uptime on Windows, Linux and macOS.
- Replace remote WMI with CIM, use the server clock, support explicit/prompted credentials and clean up sessions.
- Propagate errors without changing caller preferences; document remote Windows requirements.
- Add boundary, culture, local uptime and mocked CIM regression tests.

## Email and URL validation restoration (unreleased)

- Restore Test-IsEmail and Test-IsUrl; export twenty supported commands.
- Preserve email parameter aliases and the HTTP/HTTPS/FTP/FTPS scheme set.
- Define common bare email syntax with IDN-domain support and explicit length limits.
- Replace the URL regex with structured parsing and validation of hosts, ports and escapes.
- Reject malformed input with false; add per-record pipeline support without network calls.
- Document intentional validation-policy changes and reduce staged candidates to seven.
- Add 96 validator cases covering boundaries, Unicode, IPv6 and malformed inputs.

## Logging and timer audit fixes (unreleased)

- Treat redaction replacement text literally, preventing regex substitutions from reinserting secrets.
- Serialize buffer snapshot/write/removal; retain entries after failed writes and preserve appended entries.
- Resolve default log paths from the calling script, with current-directory fallback for interactive calls.
- Reject conflicting buffered severity switches while retaining individual compatibility switches.
- Require a non-null stopwatch in every Get-ElapsedTime parameter set.
- Add regression tests and concurrent-process file-write coverage.

## String utilities restoration (unreleased)

- Restore character conversion, string checksums and SHA-256 hashing.
- Preserve the character map while fixing index leakage and default space handling.
- Copy custom maps; normalize text and process Unicode text elements.
- Retain historical MD5 checksum formatting and allow stronger digest selection.
- Default SHA-256 output to hexadecimal; expose LegacyFormat for old comparisons.
- Add behavioral and known-vector tests.

## API request restoration (unreleased)

- Restore New-ApiRequest with independent optional-parameter handling.
- Accept header dictionaries; correctly serialize JSON or form authentication fields.
- Default to POST and reject secrets in GET queries or unencrypted requests.
- Disable automatic redirects and expose a connection timeout.
- Propagate request failures; add mocked tests with no network or credentials.

## Password-generation restoration (unreleased)

- Restore New-RandomString, New-RandomPassword and New-PhoneticPassword.
- Use secure unbiased integer selection and Fisher-Yates composition shuffling.
- Preserve the phonetic alphabet, labels, counts, aliases and display options.
- Use Set-Clipboard for PowerShell 7; honor WhatIf/Confirm for clipboard writes.
- Validate lengths/counts and remove the old random-password alphabet-length cap.
- Add behavioral tests with mocked console and clipboard operations.

## Authenticated string encryption (unreleased)

- Restore New-StringEncryption/New-StringDecryption with AES-256-GCM and PBKDF2-HMAC-SHA256.
- Require explicit passphrases, generate random salts/nonces, authenticate ciphertext.
- Add a bounded versioned format and independent interoperability/tampering tests.
- Preserve original legacy decoding code; document intentional ciphertext/API changes.

## Validation restoration (unreleased)

- Restore filename/path, IP and date validators with documented semantics and tests.
- Correct filename character scanning; add Windows-compatible device-name checks.
- Reject ambiguous IPv4 shorthand; allow explicit date culture and exact format.

# 3.0.0-alpha1 (unreleased)

- Establish a PowerShell 7.4 Core module foundation with five explicit exports.
- Adopt the tested New-LogEntry implementation and private helpers.
- Add module boundary, timer and inherited logger tests with cross-platform CI.
- Fix the Get-ElapsedTime Seconds parameter type typo.
- Remove SCP/GnuPG functions and bundled WinSCP binaries.
- Retain other candidate utilities in Staging/v3 and historical helpers in Legacy.
- Remove obsolete CLR/.NET Framework constraints and stale FileList entries.

# IT-ToolBox - Change History

## Version 2.2.3.3 - 10.10.2020

- **New** cmdlet *Get-StringHashCode* to calculate hascode for a string
- **New** cmdlet *Get-StringCheckSum* to calculate checksum for a string

## Version 2.2.3.2 - 11.08.2020

- **Fixed** and issue in *Get-ReportChain* cmdlet causing identity processing to continue despite input data failing validation

## Version 2.2.3.1 - 09.08.2020

- **Fixed** an issue in *Get-ReportChain* cmdlet causing the *-UserPrincipalName* parameter not to correctly retrieve identity from Active Directory
- **Updated** *-UPN* parameter renamed to *-UserPrincipalName* for better discoverability

## Version 2.2.3.0 - 09.08.2020

- **New** cmdlet *Get-ReportChain* to get a list of all *direct* and *indirect* reports for a specific manager
- **New** cmdlet *Test-IsValidDN* to check if a string is a valid AD DistinguishedName

## Version 2.2.2.0 - 17.05.2020

- **Updated** cmdlet *New-LogEntry* to use latest [function version](https://github.com/PsCustomObject/New-LogEntry)
- **Updated** cmdlet *New-StringConversion* to use latest function version including performance and reliability enhancements
- **Updated** version of *WinSCPnet.dll* assembly file

## Version 2.2.1.0 - 31.01.2020

- **New** cmdlet *Convert-LogonTimestamp* to allow easy conversion of user *LastLoginTimeStamp* to human readable format

## Version 2.2.0.0 - 05.12.2019

- **New** cmdlet *New-ExchangeSession* to create a remote PowerShell session to an on-premise Exchange server [2](https://github.com/PsCustomObject/IT-ToolBox/issues/2)
- **New** cmdlet *Close-ExchangeSession* to close a remote PowerShell session to an on-premise or online Exchange server

## Version 2.1.0.0 - 02.11.2019

- **New** cmdlet *New-ApiRequest* to create OAuth2 API requests
- **Fixed** comment based help for *New-StringEncryption* cmdlet
- **Fixed** comment based help for *New-StringDecryption* cmdlet
- **Fixed** wrong return data type for *Test-IsEmail* cmdlet
- **Updated** cmdlet *Test-IsUrl* to implement better checks on empty string

## Version 2.0.2.0 - 01.11.2019

- **New** created change-log file
- **New** cmdlet *New-Timer* to create a new *stopwatch* object
- **New** cmdlet *Get-TimerStatus* to get status of an existing *stopwatch* object
- **New** cmdlet *Stop-Timer* to stop an existing *stopwatch* object
- **New** cmdlet *Get-ElapsedTime* to get statistics from an existing *stopwatch* object
- **Updated** module manifest version number to be aligned with public changelog file
- **Added** bin folder for external dependencies binary files

## Version 2.0.1.2 - 09.08.2019

- **Updated** cmdlet *New-ScpDownload* exception handling code

## Version 2.0.1.1 - 06.08.2019

- **New** cmdlet *New-ScpDownload* to support download from remote SFTP Servers via WinSCP assembly
- **Updated** *WinSCPnet.dll* assembly library

## Version 2.0.1.0 - 01.07.2019

- **New** cmdlet *Test-IsValidUpn* to validate string is a valid UPN
- **New** cmdlet *Add-Encryption* to PGP encrypt a file (external dependencies required)
- **New** cmdlet *Get-GnuPgPackage* to install *GnuPg Win* package for PGP encryption
- **New** cmdlet *New-ScpUpload* to support upload of files to remote SFTP Servers via WinSCP assembly
- **New** cmdlet *New-ScpSession* to support sessions to remote SFTP Servers via WinSCP assembly 

## Version 2.0.0.0 - 13.06.2019

- **Updated** module file structure to use *Public* and *Private* folders for cmdlets distribution

## Version 1.1.0.0 - 01.03.2019

- **Updated** cmdlet name from *Test-Path* to *Test-IsValidPath* to solve name collision issue with built-in PowerShell cmdlet

## Version 1.0.0.1 - 21.02.2019

- **Fixed** and issue in *New-StringConversion* causing incorrect data type to be returned

## Version 1.0.0.0 - 01.02.2019

- Initial module release
