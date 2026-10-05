function New-PhoneticPassword
{
    <#
    .SYNOPSIS
        Generates passwords with phonetic spelling and optional exact category counts.

    .DESCRIPTION
        Retains the original phonetic alphabet, aliases, default 12-character length,
        display/color switches, clipboard option, and string output. Pipeline input is
        accumulated into one returned password, matching historical length-mode behavior.
        Generation uses secure random selection and a Fisher-Yates shuffle. Clipboard
        writes use Set-Clipboard and honor WhatIf/Confirm. Invalid counts are rejected.
    #>

    [CmdletBinding(DefaultParameterSetName = 'Default', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([string])]
    param (
        [Parameter(ParameterSetName = 'Default', ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [ValidateRange(1, 4096)]
        [Alias('length')]
        [int]$PasswordLength = 12,

        [Parameter(ParameterSetName = 'Option', ValueFromPipelineByPropertyName = $true, Position = 0)]
        [ValidateRange(0, 4096)]
        [Alias('LowerCase', 'Small')]
        [int]$LowerCaseLetters = 0,

        [Parameter(ParameterSetName = 'Option', ValueFromPipelineByPropertyName = $true, Position = 1)]
        [ValidateRange(0, 4096)]
        [Alias('UpperCase', 'Capital')]
        [int]$CapitalCaseLetters = 0,

        [Parameter(ParameterSetName = 'Option', ValueFromPipelineByPropertyName = $true, Position = 2)]
        [ValidateRange(0, 4096)]
        [int]$NumberDigits = 0,

        [Parameter(ParameterSetName = 'Option', ValueFromPipelineByPropertyName = $true, Position = 3)]
        [ValidateRange(0, 4096)]
        [Alias('SpecialLetter')]
        [int]$Symbol = 0,

        [Parameter(Position = 4)]
        [switch]$ColorOutput,

        [Parameter(Position = 5)]
        [switch]$PasswordToClipboard,

        [Alias('NoOuput', 'NoOutput')]
        [switch]$NoPasswordSpell
    )

    begin
    {
        $characters = @(Get-ITToolBoxPhoneticCharacters)
        $passwordItems = [System.Collections.Generic.List[object]]::new()
    }

    process
    {
        $currentItems = [System.Collections.Generic.List[object]]::new()

        if ($PSCmdlet.ParameterSetName -eq 'Default')
        {
            for ($index = 0; $index -lt $PasswordLength; $index++)
            {
                $currentItems.Add($characters[(Get-ITToolBoxRandomIndex -UpperBound $characters.Length)])
            }
        }
        else
        {
            $total = $LowerCaseLetters + $CapitalCaseLetters + $NumberDigits + $Symbol
            if ($total -lt 1 -or $total -gt 4096)
            {
                throw [ArgumentException]::new('Character counts must total between 1 and 4096.')
            }

            foreach ($category in @(
                    @{ Type = 'Lowercase Letter'; Count = $LowerCaseLetters }
                    @{ Type = 'Capital Letter'; Count = $CapitalCaseLetters }
                    @{ Type = 'Number'; Count = $NumberDigits }
                    @{ Type = 'Symbol'; Count = $Symbol }
                ))
            {
                $pool = @($characters | Where-Object Type -eq $category.Type)

                for ($index = 0; $index -lt $category.Count; $index++)
                {
                    $currentItems.Add($pool[(Get-ITToolBoxRandomIndex -UpperBound $pool.Length)])
                }
            }

            $shuffled = @(Get-ITToolBoxShuffledItems -Items $currentItems.ToArray())
            $currentItems.Clear()
            $currentItems.AddRange($shuffled)
        }

        $passwordItems.AddRange($currentItems.ToArray())
    }

    end
    {
        [string]$finalPassword = $passwordItems.AsciiCode -join ''

        if ($PasswordToClipboard -and $PSCmdlet.ShouldProcess('Clipboard', 'Copy generated password'))
        {
            Set-Clipboard -Value $finalPassword -ErrorAction Stop
        }

        if (-not $NoPasswordSpell)
        {
            $spellOutTable = $passwordItems | Select-Object @{ Name = 'Character'; Expression = { $_.AsciiCode } }, Phonetic, Type

            if ($ColorOutput)
            {
                Write-Host ($spellOutTable | Out-String) -ForegroundColor Green
                Write-Host $finalPassword
            }
            else
            {
                Write-Host ($spellOutTable | Out-String)
                Write-Host 'Final password is:' $finalPassword
            }
        }

        return $finalPassword
    }
}
