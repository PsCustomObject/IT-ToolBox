BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../IT-ToolBox.psd1') -Force -ErrorAction Stop
}

Describe 'New-LogEntry' {
    BeforeEach {
        New-LogEntry -ClearBuffer
    }

    It 'writes an INFO entry to a file and returns it when PassThru is used' {
        [string]$logPath = Join-Path -Path $TestDrive -ChildPath 'info.log'

        [string[]]$entry = New-LogEntry -LogMessage 'hello' -LogFilePath $logPath -NoConsole -PassThru
        [string[]]$lines = Get-Content -LiteralPath $logPath

        $entry.Count | Should -Be 1
        $lines.Count | Should -Be 1
        $entry[0] | Should -Be $lines[0]
        $lines[0] | Should -Match '\[INFO\]: hello$'
    }

    It 'writes WARNING and ERROR entries through the Level parameter' {
        [string]$logPath = Join-Path -Path $TestDrive -ChildPath 'levels.log'

        New-LogEntry -LogMessage 'careful' -Level WARNING -LogFilePath $logPath -NoConsole
        New-LogEntry -LogMessage 'failed' -Level ERROR -LogFilePath $logPath -NoConsole

        [string[]]$lines = Get-Content -LiteralPath $logPath

        $lines[0] | Should -Match '\[WARNING\]: careful$'
        $lines[1] | Should -Match '\[ERROR\]: failed$'
    }

    It 'keeps compatibility severity switches working' {
        [string]$logPath = Join-Path -Path $TestDrive -ChildPath 'compatibility.log'

        New-LogEntry -LogMessage 'careful' -IsWarningMessage -LogFilePath $logPath -NoConsole
        New-LogEntry -LogMessage 'failed' -IsErrorMessage -LogFilePath $logPath -NoConsole -ErrorAction SilentlyContinue

        [string[]]$lines = Get-Content -LiteralPath $logPath

        $lines[0] | Should -Match '\[WARNING\]: careful$'
        $lines[1] | Should -Match '\[ERROR\]: failed$'
    }

    It 'rejects mixed Level and compatibility severity switches' {
        [string]$logPath = Join-Path -Path $TestDrive -ChildPath 'mixed-level.log'

        {
            New-LogEntry -LogMessage 'bad' -Level ERROR -IsWarningMessage -LogFilePath $logPath -NoConsole
        } | Should -Throw
    }

    It 'splits multiline messages so each line receives a prefix' {
        [string]$logPath = Join-Path -Path $TestDrive -ChildPath 'multiline.log'

        New-LogEntry -LogMessage "one`ntwo" -LogFilePath $logPath -NoConsole

        [string[]]$lines = Get-Content -LiteralPath $logPath

        $lines.Count | Should -Be 2
        $lines[0] | Should -Match '\[INFO\]: one$'
        $lines[1] | Should -Match '\[INFO\]: two$'
    }

    It 'batches pipeline input and returns formatted entries with PassThru' {
        [string]$logPath = Join-Path -Path $TestDrive -ChildPath 'pipeline.log'

        [string[]]$entry = @('a', 'b', "c`nd") | New-LogEntry -LogFilePath $logPath -NoConsole -PassThru
        [string[]]$lines = Get-Content -LiteralPath $logPath

        $entry.Count | Should -Be 4
        $lines.Count | Should -Be 4
        ($entry -join [Environment]::NewLine) | Should -Be ($lines -join [Environment]::NewLine)
        $lines[0] | Should -Match '\[INFO\]: a$'
        $lines[3] | Should -Match '\[INFO\]: d$'
    }

    It 'buffers, returns, flushes, and clears entries' {
        [string]$logPath = Join-Path -Path $TestDrive -ChildPath 'buffer.log'

        @('buffer-one', 'buffer-two') | New-LogEntry -BufferOnly

        [string[]]$buffer = New-LogEntry -GetBuffer
        [string[]]$flushed = New-LogEntry -FlushBuffer -LogFilePath $logPath -NoConsole -PassThru
        [string[]]$after = New-LogEntry -GetBuffer
        [string[]]$lines = Get-Content -LiteralPath $logPath

        $buffer.Count | Should -Be 2
        ($flushed -join [Environment]::NewLine) | Should -Be ($buffer -join [Environment]::NewLine)
        $after.Count | Should -Be 0
        ($lines -join [Environment]::NewLine) | Should -Be ($buffer -join [Environment]::NewLine)
    }

    It 'redacts built-in secret patterns before writing and returning entries' {
        [string]$logPath = Join-Path -Path $TestDrive -ChildPath 'redacted.log'
        [string]$message = 'Authorization: Bearer abc123 password=SuperSecret keep=this'

        [string[]]$entry = New-LogEntry -LogMessage $message -LogFilePath $logPath -NoConsole -PassThru -RedactSecrets
        [string[]]$lines = Get-Content -LiteralPath $logPath

        $entry[0] | Should -Be $lines[0]
        $lines[0] | Should -Not -Match 'abc123'
        $lines[0] | Should -Not -Match 'SuperSecret'
        $lines[0] | Should -Match 'Authorization: \[REDACTED\] \[REDACTED\] keep=this$'
    }

    It 'supports custom redaction patterns and replacement text' {
        [string]$logPath = Join-Path -Path $TestDrive -ChildPath 'custom-redacted.log'

        New-LogEntry -LogMessage 'sessionId=abc123 visible=yes' -LogFilePath $logPath -NoConsole -RedactPattern 'sessionId=\S+' -RedactionText '<secret>'

        [string[]]$lines = Get-Content -LiteralPath $logPath

        $lines[0] | Should -Match '<secret> visible=yes$'
        $lines[0] | Should -Not -Match 'abc123'
    }

    It 'redacts entries before adding them to the buffer' {
        New-LogEntry -LogMessage 'token=abc123' -BufferOnly -RedactSecrets

        [string[]]$buffer = New-LogEntry -GetBuffer

        $buffer.Count | Should -Be 1
        $buffer[0] | Should -Match '\[INFO\]: \[REDACTED\]$'
        $buffer[0] | Should -Not -Match 'abc123'
    }
}


Describe 'New-LogEntry audit regressions' {
    BeforeEach {
        New-LogEntry -ClearBuffer
    }

    It 'treats regex replacement expressions as literal text: <Replacement>' -ForEach @(
        @{ Replacement = '$0' }
        @{ Replacement = '$1' }
        @{ Replacement = '$&' }
        @{ Replacement = '$$' }
        @{ Replacement = '${secret}' }
    ) {
        $path = Join-Path $TestDrive ([guid]::NewGuid().ToString() + '.log')
        $line = New-LogEntry -LogMessage 'token=do-not-disclose' -RedactSecrets -RedactionText $Replacement -LogFilePath $path -NoConsole -PassThru
        $line | Should -Not -Match 'do-not-disclose'
        $line.EndsWith($Replacement) | Should -BeTrue
        (Get-Content -LiteralPath $path) | Should -Be $line
        New-LogEntry -LogMessage 'token=do-not-disclose' -BufferOnly -RedactPattern '(?<secret>token=\S+)' -RedactionText $Replacement
        (New-LogEntry -GetBuffer).EndsWith($Replacement) | Should -BeTrue
    }

    It 'rejects conflicting buffered severity switches: <First> and <Second>' -ForEach @(
        @{ First = 'BufferOnlyInfo'; Second = 'BufferOnlyWarning' }
        @{ First = 'BufferOnlyInfo'; Second = 'BufferOnlyError' }
        @{ First = 'BufferOnlyWarning'; Second = 'BufferOnlyError' }
    ) {
        $flags = @{ $First = $true; $Second = $true }
        { New-LogEntry -LogMessage 'conflict' @flags } | Should -Throw '*Use only one*'
        @(New-LogEntry -GetBuffer).Count | Should -Be 0
    }

    It 'still accepts individual buffered severity switches: <Flag>' -ForEach @(
        @{ Flag = 'BufferOnlyInfo'; Tag = 'INFO' }
        @{ Flag = 'BufferOnlyWarning'; Tag = 'WARNING' }
        @{ Flag = 'BufferOnlyError'; Tag = 'ERROR' }
    ) {
        $flags = @{ $Flag = $true }
        New-LogEntry -LogMessage 'message' -BufferOnly @flags
        (New-LogEntry -GetBuffer) | Should -Match "\[$Tag\]: message$"
    }

    It 'preserves an entry appended while the snapshot is being written' {
        InModuleScope IT-ToolBox {
            Mock Write-NewLogEntryLines {
                [System.Threading.Monitor]::IsEntered($script:NewLogEntryBufferLock) | Should -BeTrue
                Add-NewLogEntryBuffer -Lines 'arrived-during-flush'
            }
            New-LogEntry -LogMessage 'original' -BufferOnly
            $flushed = @(New-LogEntry -FlushBuffer -LogFilePath 'unused.log' -NoConsole -PassThru)
            $flushed.Count | Should -Be 1
            $flushed[0] | Should -Match ': original$'
            @(New-LogEntry -GetBuffer).Count | Should -Be 1
            (New-LogEntry -GetBuffer) | Should -Be 'arrived-during-flush'
            $script:messageBuffer | Should -Be ("arrived-during-flush" + [Environment]::NewLine)
        }
    }

    It 'retains all entries when writing fails and releases the buffer lock' {
        InModuleScope IT-ToolBox {
            Mock Write-NewLogEntryLines { throw 'write failed' }
            New-LogEntry -LogMessage 'retry-me' -BufferOnly
            { New-LogEntry -FlushBuffer -LogFilePath 'unused.log' -NoConsole } | Should -Throw '*write failed*'
            (New-LogEntry -GetBuffer) | Should -Match ': retry-me$'
            [System.Threading.Monitor]::IsEntered($script:NewLogEntryBufferLock) | Should -BeFalse
            New-LogEntry -LogMessage 'next' -BufferOnly
            @(New-LogEntry -GetBuffer).Count | Should -Be 2
        }
    }

    It 'writes buffered entries exactly once across successive flushes' {
        $path = Join-Path $TestDrive 'once.log'
        New-LogEntry -LogMessage 'once' -BufferOnly
        New-LogEntry -FlushBuffer -LogFilePath $path -NoConsole
        New-LogEntry -FlushBuffer -LogFilePath $path -NoConsole
        @(Get-Content -LiteralPath $path).Count | Should -Be 1
        @(New-LogEntry -GetBuffer).Count | Should -Be 0
    }

    It 'resolves interactive defaults in the current directory' {
        InModuleScope IT-ToolBox -Parameters @{ Directory = $TestDrive } {
            param($Directory)
            Push-Location $Directory
            try {
                $path = Resolve-NewLogEntryPath
                (Split-Path $path -Parent) | Should -Be $Directory
                (Split-Path $path -Leaf) | Should -Match '^PowerShell-LogFile-\d{8}-\d{6}\.log$'
            }
            finally { Pop-Location }
        }
    }

    It 'writes default logs beside a calling script, including buffer flushes' {
        $scriptDirectory = Join-Path $TestDrive 'caller'
        New-Item -ItemType Directory $scriptDirectory | Out-Null
        $caller = Join-Path $scriptDirectory 'automation.ps1'
        @'
New-LogEntry -LogMessage 'direct-default' -NoConsole
New-LogEntry -LogMessage 'buffer-default' -BufferOnly
New-LogEntry -FlushBuffer -NoConsole
'@ | Set-Content -LiteralPath $caller
        & $caller
        $logs = @(Get-ChildItem $scriptDirectory -Filter 'automation.ps1-LogFile-*.log')
        $logs.Count | Should -BeGreaterThan 0
        $lines = @(Get-Content -LiteralPath $logs.FullName)
        $lines.Count | Should -Be 2
        $lines[0] | Should -Match ': direct-default$'
        $lines[1] | Should -Match ': buffer-default$'
    }
}


Describe 'New-LogEntry file-write integration' {
    BeforeEach { New-LogEntry -ClearBuffer }

    It 'can retry buffered entries after a real filesystem failure' {
        New-LogEntry -LogMessage 'retained-after-failure' -BufferOnly
        { New-LogEntry -FlushBuffer -LogFilePath $TestDrive -NoConsole -ErrorAction Stop } | Should -Throw
        $before = @(New-LogEntry -GetBuffer)
        $before.Count | Should -Be 1
        $path = Join-Path $TestDrive 'retried.log'
        $written = @(New-LogEntry -FlushBuffer -LogFilePath $path -NoConsole -PassThru)
        $written[0] | Should -Be $before[0]
        (Get-Content -LiteralPath $path) | Should -Be $before[0]
        @(New-LogEntry -GetBuffer).Count | Should -Be 0
    }

    It 'preserves every direct and buffered line from concurrent processes' {
        $path = Join-Path $TestDrive 'concurrent.log'
        $manifest = [System.IO.Path]::ChangeExtension((Get-Module IT-ToolBox).Path, '.psd1')
        $jobs = @()
        try {
            $jobs = @(1..3 | ForEach-Object {
                Start-Job -ArgumentList $manifest, $path, $_ -ScriptBlock {
                    param($Manifest, $Path, $Worker)
                    Import-Module $Manifest -ErrorAction Stop
                    foreach ($i in 1..20) {
                        New-LogEntry -LogMessage "worker-$Worker-direct-$i" -LogFilePath $Path -NoConsole -ErrorAction Stop
                        New-LogEntry -LogMessage "worker-$Worker-buffer-$i" -BufferOnly -ErrorAction Stop
                    }
                    New-LogEntry -FlushBuffer -LogFilePath $Path -NoConsole -ErrorAction Stop
                }
            })
            $jobs | Receive-Job -Wait -ErrorAction Stop
            foreach ($job in $jobs) { $job.State | Should -Be 'Completed' }
            $lines = @(Get-Content -LiteralPath $path)
            $lines.Count | Should -Be 120
            $messages = @($lines | ForEach-Object { $_ -replace '^.*\[INFO\]: ', '' })
            @($messages | Select-Object -Unique).Count | Should -Be 120
            foreach ($worker in 1..3) {
                foreach ($i in 1..20) {
                    $messages | Should -Contain "worker-$worker-direct-$i"
                    $messages | Should -Contain "worker-$worker-buffer-$i"
                }
            }
        }
        finally {
            if ($jobs.Count -gt 0) { $jobs | Remove-Job -Force }
        }
    }
}


Describe 'Interactive default log path' {
    It 'writes in the current directory when called without a script file' {
        $manifest = [System.IO.Path]::ChangeExtension((Get-Module IT-ToolBox).Path, '.psd1')
        $job = Start-Job -ArgumentList $manifest, $TestDrive -ScriptBlock {
            param($Manifest, $Directory)
            Import-Module $Manifest -ErrorAction Stop
            Set-Location $Directory
            New-LogEntry -LogMessage 'interactive-default' -NoConsole -ErrorAction Stop
            New-LogEntry -LogMessage 'interactive-buffer' -BufferOnly
            New-LogEntry -FlushBuffer -NoConsole -ErrorAction Stop
        }
        try {
            $job | Receive-Job -Wait -ErrorAction Stop
            $job.State | Should -Be 'Completed'
            $logs = @(Get-ChildItem $TestDrive -Filter 'PowerShell-LogFile-*.log')
            $logs.Count | Should -BeGreaterThan 0
            $lines = @(Get-Content -LiteralPath $logs.FullName)
            $lines.Count | Should -Be 2
            $lines[0] | Should -Match ': interactive-default$'
            $lines[1] | Should -Match ': interactive-buffer$'
        }
        finally { $job | Remove-Job -Force }
    }
}
