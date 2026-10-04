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
