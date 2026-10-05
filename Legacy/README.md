# Historical commands

These five commands are reference implementations, not a supported compatibility
layer. They are never loaded or exported by v3.

| Command | Status |
| --- | --- |
| New-StringEncryption | Historical unauthenticated encryption; use only to migrate existing data in a separate session |
| New-StringDecryption | Historical decryption; original passphrase/salt/vector required |
| New-ExchangeSession | Unreviewed on-premises remoting, credential and authentication behavior |
| Close-ExchangeSession | Known session-selection and error-reporting defects |
| Close-AzureSession | AzureAD dependency and absent Test-AzureSession helper |

See [the integration review](../docs/Integrations.md) before planning a replacement.
The root README documents supported encryption and script-context replacements.
