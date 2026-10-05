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
| AzureAD session helper | Removed | Use Microsoft Graph or Microsoft Entra PowerShell directly |
| Azure resource sessions | No wrapper | Az.Accounts owns its Azure context; it is distinct from Graph |
| Exchange Server remoting | Legacy wrappers removed | Use the documented Exchange Server management workflow for the target environment |
| Exchange Online | No wrapper | ExchangeOnlineManagement owns authentication and disconnection |
| Global certificate bypass | Removed | Configure certificate trust for the endpoint instead |

## Why the old session helpers are excluded

The former Close-AzureSession helper called the absent Test-AzureSession command and
Disconnect-AzureAD. It has been removed from the current tree. Git history retains
the source for reference; it is not part of the supported v3 API.

Microsoft Graph and Microsoft Entra PowerShell own directory authentication. Az
PowerShell owns Azure resource contexts. These contexts are distinct and must be
managed explicitly by the service-specific module.

New-ExchangeSession and Close-ExchangeSession have also been removed. Use
Connect-ExchangeOnline and Disconnect-ExchangeOnline directly from Microsoft's
ExchangeOnlineManagement module for Exchange Online. IT-ToolBox does not wrap these
commands or install that module. Exchange Server on-premises has a separate
management workflow.

The removed Enable-SelfSignedCertificate snippet registered a global certificate
validation bypass. No replacement bypass is provided; configure certificate trust
for the endpoint instead.

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
