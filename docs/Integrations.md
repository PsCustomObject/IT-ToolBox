# Integration review and ownership

IT-ToolBox v3 exports 29 utility commands. Importing the module must not connect,
disconnect, install external modules, change certificate validation, or manage a
caller's existing service sessions. Get-ReportChain and remote Get-OsUpTime retain
their documented optional dependencies when explicitly invoked.

## Current boundaries

| Integration | v3 disposition | Supported direction |
| --- | --- | --- |
| SCP / WinSCP | Excluded | Dedicated transfer module; no bundled WinSCP binaries here |
| PGP / OpenPGP | Excluded | Dedicated encryption module; backend design is separate from string AES-GCM |
| AzureAD session helper | Historical source in Legacy/ | Explicit Graph or Entra authentication for directory operations |
| Azure resource sessions | No wrapper | Az.Accounts owns its Azure context; it is distinct from Graph |
| Exchange Server remoting | Legacy wrappers removed | Use the documented Exchange Server management workflow for the target environment |
| Exchange Online | No wrapper | ExchangeOnlineManagement owns authentication and disconnection |
| Global certificate bypass | Removed | Configure certificate trust for the endpoint instead |

## Why the old session helpers are excluded

Close-AzureSession calls Test-AzureSession, which is absent from this repository,
and Disconnect-AzureAD. Microsoft documents migration from the deprecated AzureAD
module to Graph PowerShell; this is more than a command-name substitution.
Graph/Entra directory authentication and Az resource contexts are distinct. The old command must not be
aliased to a function that clears a different service's credentials or context.

New-ExchangeSession and Close-ExchangeSession have been removed from the repository's
current tree. Their historical implementations targeted on-premises remoting and
had credential handling, session-selection and error-reporting defects. Git history
retains the source if needed; they are not part of the supported v3 API.

Use Connect-ExchangeOnline and Disconnect-ExchangeOnline directly from Microsoft's
ExchangeOnlineManagement module for Exchange Online. IT-ToolBox does not wrap these
commands, install that module or manage its sessions. Exchange Server on-premises
has a separate management workflow; ExchangeOnlineManagement is not a general
replacement for its remote PowerShell endpoint.

The removed Enable-SelfSignedCertificate snippet registered a type whose Ignore
method could accept every server certificate through ServicePointManager. The
filename suggested endpoint-specific self-signed certificate support, but the
implementation was a global validation bypass. No replacement bypass is provided.
The old source remains in Git history.

## Requirements for future session wrappers

- Choose the service and supported client/server environments explicitly.
- Keep dependencies optional until the operation is invoked; never install them during import.
- Accept service-appropriate authentication without introducing plaintext-password parameters.
- Track the session/context created by the helper; clean up only resources it owns.
- Use explicit disconnect operations and terminating errors; preserve caller preferences.
- Test authentication forwarding, multiple contexts, partial failures and cleanup.
- Verify against a real endpoint before claiming that integration is supported.

These are implementation requirements for future additions, not new exported APIs.

## Official references

- [AzureAD to Microsoft Graph migration](https://learn.microsoft.com/en-us/powershell/microsoftgraph/migration-steps)
- [Microsoft Entra PowerShell overview](https://learn.microsoft.com/en-us/powershell/entra-powershell/overview)
- [Az.Accounts context management](https://learn.microsoft.com/en-us/powershell/azure/context-persistence)
- [Connect-ExchangeOnline](https://learn.microsoft.com/en-us/powershell/module/exchangepowershell/connect-exchangeonline)
- [On-premises Exchange remote PowerShell](https://learn.microsoft.com/en-us/powershell/exchange/connect-to-exchange-servers-using-remote-powershell)
