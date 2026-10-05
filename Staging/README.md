# Staging status

There are no executable candidates in this directory. All former v3 utility
candidates have supported implementations in Public/.

Close-AzureSession and the global certificate-validation bypass snippet have been
removed. Their historical source remains available in Git history.

Future candidates belong on a feature branch with tests before entering Public/.
Staging and Legacy are never loaded by the module. See
[the integration review](../docs/Integrations.md) for the remaining service boundaries.
