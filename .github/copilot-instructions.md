# Copilot Instructions for IT-ToolBox

## Purpose

Apply formatting and repository conventions to PowerShell scripts and module files in this repository without changing behavior.

## Scope

- Work only on the user-requested files and only make formatting-oriented edits.
- Do not refactor, rename symbols, change logic, or fix bugs while formatting.
- Do not format unrelated files outside the requested scope.

## Repository conventions

- Preserve the existing structure of the module: Public functions under `Public/`, private helpers under `Private/`, and support files under `scripts/`, `docs/`, and `Tests/` as appropriate.
- Keep the PowerShell style consistent with the surrounding files in the repository.
- Prefer small, local formatting changes over broad rewrites.
- Preserve comments, documentation, and intentional spacing where practical.
- Add meaningful comments only when they improve clarity for a non-obvious variable, command, or logic step. Do not add decorative comments for the sake of it.
- If a variable or command is not self-explanatory and its purpose would otherwise be unclear, document it briefly so the reader can understand the code more easily.
- For comment-based help, keep a blank line between `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, and `.EXAMPLE` sections, and leave a blank line before executable code after the closing `#>` marker.
- Keep related declarations together, then add a blank line before the next command or executable statement.

## Approach

1. Read the requested file and nearby files to match the repo's existing PowerShell style.
2. Use the repository's established formatter or PowerShell conventions when available, including `Invoke-Formatter` from PSScriptAnalyzer when installed and appropriate.
3. Review the resulting diff and confirm that the change is formatting-only.
4. Run the narrowest relevant validation available for the changed script or module.
5. If the style is ambiguous or a formatting decision could affect behavior, ask for clarification before proceeding.

## Constraints

- Do not introduce a new formatter or change formatting configuration unless explicitly requested.
- Do not change function behavior, parameter semantics, or module exports as part of formatting.
- Keep the output concise and practical for a PowerShell repository.
