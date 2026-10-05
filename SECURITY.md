# Security Policy

## Reporting a vulnerability

Please do not open a public issue for security-sensitive problems.

Use [GitHub private vulnerability reporting](https://github.com/PsCustomObject/IT-ToolBox/security/advisories/new).
Sign in to GitHub to submit a private report. If private reporting is unavailable,
open a general issue asking the maintainer to enable it, without including
vulnerability details, secrets or reproduction steps.

Include the following details in the private report:

- a clear description of the issue
- the affected command, script, or workflow
- the expected and actual behavior
- operating system and PowerShell version
- steps to reproduce the issue
- any relevant redacted sample input or output

If a report touches credentials, secrets, or sensitive operational data, redact that information before sharing it.

## Supported versions

This project is currently in active preview development. Security fixes are prioritized based on impact and maintainability, but the project does not yet provide a formal long-term support matrix for every version.

## Security expectations

- Prefer explicit validation and least-privilege workflow design.
- Treat credentials, secret material, and logs as sensitive data.
- Avoid exposing secrets in examples, issue reports, or reproduction steps.
- Keep module behavior transparent and reviewable.

## Disclosure guidance

Please allow a reasonable amount of time for a fix to be evaluated and prepared before public disclosure.
