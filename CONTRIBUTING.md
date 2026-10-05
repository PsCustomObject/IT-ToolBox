# Contributing to IT-ToolBox

Thanks for your interest in improving IT-ToolBox.

This project is a PowerShell automation toolkit focused on safe defaults, explicit validation, cross-platform compatibility, and operational clarity. Contributions should preserve that direction and avoid unnecessary scope creep.

## Project scope

Please keep changes aligned with the module’s intended purpose:

- PowerShell Core / PowerShell 7.4+ compatibility
- enterprise automation helpers and operational utilities
- validation-first behavior and safety-oriented defaults
- clear, reviewable code without hidden side effects

Avoid adding unrelated service wrappers, broad feature expansions, or breaking compatibility changes unless they are clearly called out and documented.

## Repository structure

- `Public/` contains supported, exported command implementations.
- `Private/` contains internal helper functions.
- `Legacy/` contains historical compatibility code and migration artifacts.
- `scripts/` contains packaging and build utilities.
- `Tests/` contains Pester coverage.
- `docs/` contains supporting project documentation.

When possible, keep the module behavior-isolated and avoid changing code outside the relevant scope.

## Security and support

For security-sensitive issues, do not open a public issue. Please review [SECURITY.md](./SECURITY.md) before reporting a vulnerability or other sensitive problem.

For general questions, use GitHub Issues or start with the relevant documentation in the repository.

## Development setup

Requirements:

- PowerShell 7.4 or later
- Pester 5.7.1 or later for test execution

Typical workflow:

```powershell
Install-Module Pester -RequiredVersion 5.7.1 -Scope CurrentUser
Import-Module ./IT-ToolBox.psd1 -Force -ErrorAction Stop
Invoke-Pester ./Tests
```

## Contribution workflow

1. Create a branch from the current working branch.
2. Keep changes focused on one concern or feature area.
3. Preserve existing behavior unless the change explicitly updates documented semantics.
4. Validate the changed code with the relevant Pester tests and syntax checks.
5. Update documentation if behavior, usage, or compatibility changes.

## Coding expectations

- Prefer clear, readable PowerShell idioms over clever shortcuts.
- Maintain explicit error handling and avoid silently swallowing operational failures.
- Preserve cross-platform compatibility where feasible.
- Do not add decorative comments; add comments only when they clarify intent or non-obvious logic.
- Keep the public API predictable and consistent with the existing module naming patterns.
- Do not modify `Legacy/` or staged migration code unless the work is specifically about migration or compatibility.

## Testing

Run the project tests before submitting changes:

```powershell
Invoke-Pester ./Tests
```

For packaging validation and build checks:

```powershell
./scripts/Build-Module.ps1
```

If a change affects module import behavior, command signatures, validation rules, or security-sensitive helpers, add or update tests to cover the new behavior.

## Pull requests

Please keep pull requests focused and descriptive.

Include:

- a short summary of the change
- the reasoning behind it
- any compatibility or migration impact
- test results or validation notes

## Reporting bugs

When filing an issue, include:

- the command or script that failed
- expected behavior
- actual behavior
- operating system and PowerShell version
- repository commit or branch
- any relevant sample input or redacted output

## Documentation

If a contributor adds functionality or changes behavior, update the relevant README or documentation pages so the usage remains accurate.

## License

By contributing, you agree that your contributions will be licensed under the project’s MIT license.
