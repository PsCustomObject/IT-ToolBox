# Historical commands

These three commands are reference implementations, not a supported compatibility
layer. They are never loaded or exported by v3.

| Command | Status |
| --- | --- |
| New-StringEncryption | Historical unauthenticated encryption; use only to migrate existing data in a separate session |
| New-StringDecryption | Historical decryption; original passphrase/salt/vector required |
| Close-AzureSession | AzureAD dependency and absent Test-AzureSession helper |

See [the integration review](../docs/Integrations.md) before planning a replacement.
The root README documents supported encryption and script-context replacements.

The former Exchange session wrappers have been removed. Their source remains in Git
history; use ExchangeOnlineManagement directly for Exchange Online operations.
