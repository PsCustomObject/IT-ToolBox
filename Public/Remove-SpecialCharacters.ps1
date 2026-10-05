function Remove-SpecialCharacters
{
    <#
    .SYNOPSIS
        Previews or renames descendant files and directories using the historical character policy.

    .DESCRIPTION
        Replaces !@#$%^&*(){}[]":;,<>/|\+=`~ and apostrophe with a hyphen. Spaces,
        Unicode and other characters are preserved. This is a naming policy, not
        universal filename validation. The root itself and symbolic links/junctions
        are not renamed; links are never traversed. Hidden items are included.
        Without -AutoFix, returns preview records. AutoFix preflights collisions before
        any renames, then processes children before parents and honors WhatIf/Confirm.
        This is not a transaction: an I/O error can leave earlier renames completed.
        Paths in records describe each individual rename, before ancestor renames.

    .PARAMETER LogActivites
        Historical spelling; LogActivities is an alias. Logs affected-item records.

    .PARAMETER LogFilePath
        Log path; defaults to Remove-SpecialCharacters-yyyyMMdd.log inside ItemsPath.

    .EXAMPLE
        Remove-SpecialCharacters -ItemsPath ./files

    .EXAMPLE
        Remove-SpecialCharacters -ItemsPath ./files -AutoFix -WhatIf
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$ItemsPath,

        [switch]$AutoFix,

        [Alias('LogActivities')]
        [switch]$LogActivites,

        [ValidateNotNullOrEmpty()]
        [string]$LogFilePath
    )

    $root = Get-Item -LiteralPath $ItemsPath -Force -ErrorAction Stop
    if ($root.PSProvider.Name -ne 'FileSystem' -or -not $root.PSIsContainer -or ($root.Attributes -band [IO.FileAttributes]::ReparsePoint))
    {
        throw 'ItemsPath must be a filesystem directory, not a link or junction.'
    }

    if ($LogActivites -and -not $LogFilePath)
    {
        $LogFilePath = Join-Path $root.FullName ('Remove-SpecialCharacters-{0}.log' -f [datetime]::Now.ToString('yyyyMMdd'))
    }

    if ($LogActivites)
    {
        $LogFilePath = Resolve-NewLogEntryPath -Path $LogFilePath
    }

    # Characters that must be normalized into a hyphen during the rename pass.
    $invalidChars = '!@#$%^&*(){}[]":;,<>/|\+=`~'''

    # Build a single regex that matches any forbidden character so each asset can be checked consistently.
    $pattern = ($invalidChars.ToCharArray() | ForEach-Object { [regex]::Escape([string]$_) }) -join '|'

    # Use platform-aware string comparison so the rename plan is stable on Windows/macOS vs. Linux.
    $comparer = if ($IsWindows -or $IsMacOS) { [StringComparer]::OrdinalIgnoreCase } else { [StringComparer]::Ordinal }

    # Track original paths so collisions against existing items are detected before any rename occurs.
    $existing = [System.Collections.Generic.HashSet[string]]::new($comparer)

    # Track proposed destinations to flag duplicate rename targets before AutoFix runs.
    $destinations = [System.Collections.Generic.Dictionary[string, object]]::new($comparer)

    # Depth-first traversal stack that walks descendant items before parent-level rename processing.
    $pending = [System.Collections.Generic.Stack[object]]::new()
    $pending.Push(@{ Path = $root.FullName; Depth = 0 })

    # Planned rename operations used for preview output and AutoFix execution.
    $plan = [System.Collections.Generic.List[object]]::new()

    while ($pending.Count -gt 0)
    {
        $directory = $pending.Pop()

        foreach ($item in Get-ChildItem -LiteralPath $directory.Path -Force -ErrorAction Stop)
        {
            [void]$existing.Add($item.FullName)

            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
            {
                continue
            }

            $depth = $directory.Depth + 1

            if ($item.PSIsContainer)
            {
                $pending.Push(@{ Path = $item.FullName; Depth = $depth })
            }

            if ($item.Name -notmatch $pattern)
            {
                continue
            }

            $newName = $item.Name -replace $pattern, '-'
            $destination = Join-Path (Split-Path $item.FullName -Parent) $newName
            $record = [pscustomobject]@{
                Path            = $item.FullName
                NewName         = $newName
                DestinationPath = $destination
                ItemType        = if ($item.PSIsContainer) { 'Directory' } else { 'File' }
                Depth           = $depth
                HasCollision    = $false
                Status          = 'Preview'
            }

            if ($destinations.ContainsKey($destination))
            {
                $record.HasCollision = $true
                $destinations[$destination].HasCollision = $true
            }
            else
            {
                $destinations.Add($destination, $record)
            }

            $plan.Add($record)
        }
    }

    foreach ($record in $plan)
    {
        if ($existing.Contains($record.DestinationPath))
        {
            $record.HasCollision = $true
        }
    }

    if ($LogActivites)
    {
        # Compare log path prefixes using the same case-insensitive rules as the filesystem being scanned.
        $comparison = if ($IsWindows -or $IsMacOS) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }

        foreach ($record in $plan)
        {
            $sourcePrefix = $record.Path + [IO.Path]::DirectorySeparatorChar
            $destinationPrefix = $record.DestinationPath + [IO.Path]::DirectorySeparatorChar

            if ($comparer.Equals($LogFilePath, $record.Path) -or $comparer.Equals($LogFilePath, $record.DestinationPath) -or
                ($record.ItemType -eq 'Directory' -and ($LogFilePath.StartsWith($sourcePrefix, $comparison) -or $LogFilePath.StartsWith($destinationPrefix, $comparison))))
            {
                throw 'The activity log path must not participate in the rename plan or lie inside a renamed directory.'
            }
        }
    }

    if ($AutoFix -and @($plan | Where-Object HasCollision).Count -gt 0)
    {
        throw 'Rename collisions detected. Run without -AutoFix to inspect HasCollision; no items were renamed.'
    }

    foreach ($record in ($plan | Sort-Object @{ Expression = 'Depth'; Descending = $true }, Path))
    {
        if ($AutoFix)
        {
            $record.Status = 'Skipped'

            if ($PSCmdlet.ShouldProcess($record.Path, ('Rename to {0}' -f $record.NewName)))
            {
                Rename-Item -LiteralPath $record.Path -NewName $record.NewName -Force -ErrorAction Stop
                $record.Status = 'Renamed'
            }
        }

        # WhatIf suppresses optional logging as well as renames.
        if ($LogActivites -and $PSCmdlet.ShouldProcess($LogFilePath, 'Append activity log'))
        {
            New-LogEntry -LogFilePath $LogFilePath -LogMessage ('{0}: {1} -> {2}; collision={3}' -f $record.Status, $record.Path, $record.DestinationPath, $record.HasCollision) -NoConsole
        }

        $record
    }
}
