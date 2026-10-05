# Historical commands

These two commands are reference implementations, not a supported compatibility
layer. They are never loaded or exported by v3.

| Command | Status |
| --- | --- |
| New-StringEncryption | Historical unauthenticated encryption; use only to migrate existing data in a separate session |
| New-StringDecryption | Historical decryption; original passphrase/salt/vector required |

The former Exchange and AzureAD session wrappers have been removed. Their source
remains in Git history. Use ExchangeOnlineManagement or Microsoft Graph directly
for those services.
