BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../IT-ToolBox.psd1') -Force -ErrorAction Stop
    $knownUtc = [datetime]::new(2024, 2, 29, 12, 34, 56, [DateTimeKind]::Utc)
    $knownFileTime = $knownUtc.ToFileTimeUtc()
}

Describe 'Logon FILETIME conversion' {
    It 'preserves default local DateTime output for numeric and string input' {
        $date = Convert-LogonTimestamp -TimeStamp $knownFileTime
        $date.Kind | Should -Be ([DateTimeKind]::Local)
        $date.ToUniversalTime() | Should -Be $knownUtc
        Convert-LogonTimestamp "$knownFileTime" | Should -Be $date
    }
    It 'supports explicit UTC and string formats' {
        $date = Convert-LogonTimestamp $knownFileTime -Utc
        $date.Kind | Should -Be ([DateTimeKind]::Utc)
        $date | Should -Be $knownUtc
        Convert-LogonTimestamp $knownFileTime -Utc -StringOutput | Should -Be '2024-02-29'
        Convert-LogonTimestamp $knownFileTime -Utc -StringOutput -DateFormat 'yyyy-MM-dd HH:mm:ss' | Should -Be '2024-02-29 12:34:56'
        Convert-LogonTimestamp $knownFileTime -Utc -DateFormat 'yyyy' | Should -Be '2024'
    }
    It 'formats strings independently of the current culture' {
        $oldCulture = [System.Threading.Thread]::CurrentThread.CurrentCulture
        try {
            [System.Threading.Thread]::CurrentThread.CurrentCulture = [cultureinfo]'it-IT'
            Convert-LogonTimestamp $knownFileTime -Utc -DateFormat 'MMMM' | Should -Be 'February'
        }
        finally { [System.Threading.Thread]::CurrentThread.CurrentCulture = $oldCulture }
    }
    It 'emits no fabricated date for zero and preserves pipeline ordering' {
        @(Convert-LogonTimestamp 0).Count | Should -Be 0
        $results = @(0, $knownFileTime, 0, ($knownFileTime + 10000000)) | Convert-LogonTimestamp -Utc
        $results.Count | Should -Be 2
        $results[0] | Should -Be $knownUtc
        $results[1] | Should -Be $knownUtc.AddSeconds(1)
    }
    It 'rejects malformed and out-of-range input: <Value>' -ForEach @(
        @{ Value = $null }; @{ Value = '' }; @{ Value = ' ' }; @{ Value = '-1' }
        @{ Value = '+1' }; @{ Value = '1.5' }; @{ Value = '1e10' }; @{ Value = '0x10' }
        @{ Value = 'abc' }; @{ Value = ' 1' }; @{ Value = '1 ' }
        @{ Value = '9223372036854775808' }; @{ Value = '9223372036854775807' }
    ) {
        { Convert-LogonTimestamp -TimeStamp $Value } | Should -Throw
    }
    It 'accepts the FILETIME range boundaries above zero' {
        (Convert-LogonTimestamp 1 -Utc).ToFileTimeUtc() | Should -Be 1
        $maximum = [datetime]::MaxValue.ToFileTimeUtc()
        (Convert-LogonTimestamp $maximum -Utc).ToFileTimeUtc() | Should -Be $maximum
    }
    It 'propagates invalid date-format errors' {
        { Convert-LogonTimestamp $knownFileTime -DateFormat '%' } | Should -Throw
    }
}

Describe 'Local and remote OS uptime' {
    It 'preserves whole-day output and optional full TimeSpan' {
        Mock Get-Uptime -ModuleName IT-ToolBox { [timespan]::FromHours(59) }
        Get-OsUpTime | Should -Be 2
        Get-OsUpTime | Should -BeOfType ([int])
        Get-OsUpTime -FullOutput | Should -Be ([timespan]::FromHours(59))
    }
    It 'queries the actual local OS without external dependencies' {
        $before = Get-Uptime
        $actual = Get-OsUpTime -FullOutput
        $after = Get-Uptime
        $actual | Should -BeOfType ([timespan])
        $actual | Should -BeGreaterOrEqual $before
        $actual | Should -BeLessOrEqual $after
    }
    It 'forwards explicit remote credentials and preserves output types' {
        $cred = [pscredential]::new('example\test', (ConvertTo-SecureString 'example' -AsPlainText -Force))
        Mock Get-ITToolBoxRemoteUptime -ModuleName IT-ToolBox { [timespan]::FromHours(49) }
        Get-OsUpTime -ComputerName 'server01' -Credential $cred | Should -Be 2
        Get-OsUpTime -ComputerName 'server01' -Credential $cred -FullOutput | Should -Be ([timespan]::FromHours(49))
        Should -Invoke Get-ITToolBoxRemoteUptime -ModuleName IT-ToolBox -Times 2 -Exactly -ParameterFilter {
            $ComputerName -eq 'server01' -and $Credential.UserName -eq 'example\test'
        }
    }
    It 'retains the legacy interactive credential switch' {
        Mock Get-Credential -ModuleName IT-ToolBox {
            [pscredential]::new('example\prompted', (ConvertTo-SecureString 'example' -AsPlainText -Force))
        }
        Mock Get-ITToolBoxRemoteUptime -ModuleName IT-ToolBox { [timespan]::FromDays(3) }
        Get-OsUpTime -ComputerName server01 -Credentials | Should -Be 3
        Should -Invoke Get-Credential -ModuleName IT-ToolBox -Times 1 -Exactly
        Should -Invoke Get-ITToolBoxRemoteUptime -ModuleName IT-ToolBox -Times 1 -ParameterFilter {
            $Credential.UserName -eq 'example\prompted'
        }
    }
    It 'rejects mixed credential options before prompting' {
        $cred = [pscredential]::new('test', (ConvertTo-SecureString 'example' -AsPlainText -Force))
        Mock Get-Credential -ModuleName IT-ToolBox { throw 'unexpected prompt' }
        { Get-OsUpTime -ComputerName server01 -Credential $cred -Credentials } | Should -Throw '*either*'
        Should -Invoke Get-Credential -ModuleName IT-ToolBox -Times 0 -Exactly
    }
    It 'requires a computer name for remote credential options' {
        $cmd = Get-Command Get-OsUpTime -Module IT-ToolBox
        ($cmd.ParameterSets | Where-Object Name -eq RemoteMachine).Parameters.Where({ $_.Name -eq 'ComputerName' }).IsMandatory | Should -BeTrue
        { Get-OsUpTime -ComputerName ' ' } | Should -Throw
        { Get-OsUpTime -ComputerName '' } | Should -Throw
    }
    It 'propagates failures without changing the caller error preference' {
        Mock Get-ITToolBoxRemoteUptime -ModuleName IT-ToolBox { throw 'remote failed' }
        $preference = $ErrorActionPreference
        { Get-OsUpTime -ComputerName server01 } | Should -Throw '*remote failed*'
        $ErrorActionPreference | Should -Be $preference
    }
    It 'rejects a cancelled credentials prompt' {
        Mock Get-Credential -ModuleName IT-ToolBox { $null }
        { Get-OsUpTime -ComputerName server01 -Credentials } | Should -Throw '*No credential*'
    }
    It 'rejects negative or malformed uptime results' {
        Mock Get-Uptime -ModuleName IT-ToolBox { [timespan]::FromSeconds(-1) }
        { Get-OsUpTime } | Should -Throw '*nonnegative*'
        Mock Get-ITToolBoxRemoteUptime -ModuleName IT-ToolBox { 'not a duration' }
        { Get-OsUpTime -ComputerName server01 } | Should -Throw '*nonnegative*'
    }
}

Describe 'Remote Windows CIM queries' {
    BeforeAll {
        $testSession = if ($IsWindows) { [Microsoft.Management.Infrastructure.CimSession]::Create('server01') } else { 'test-session' }
        # Narrow test doubles allow testing CIM orchestration on non-Windows hosts.
        InModuleScope IT-ToolBox {
            if (-not (Get-Command Get-CimInstance -ErrorAction SilentlyContinue)) {
                function script:Get-CimInstance { param($Namespace, $ClassName, $Property, $ComputerName, $CimSession, $ErrorAction) throw 'test stub' }
                function script:New-CimSession { param($ComputerName, $Credential, $ErrorAction) throw 'test stub' }
                function script:Remove-CimSession { param($CimSession, $ErrorAction) throw 'test stub' }
                $script:UptimeTestStubs = $true
            }
        }
    }
    AfterAll {
        if ($IsWindows) { $testSession.Dispose() }
        InModuleScope IT-ToolBox {
            if ($script:UptimeTestStubs) {
                Remove-Item Function:Get-CimInstance, Function:New-CimSession, Function:Remove-CimSession
                Remove-Variable UptimeTestStubs -Scope Script
            }
        }
    }
    BeforeEach {
        Mock Get-CimInstance -ModuleName IT-ToolBox {
            [pscustomobject]@{
                LastBootUpTime = [datetime]::new(2024, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)
                LocalDateTime = [datetime]::new(2024, 1, 3, 12, 0, 0, [DateTimeKind]::Utc)
            }
        }
        Mock New-CimSession -ModuleName IT-ToolBox { $testSession }
        Mock Remove-CimSession -ModuleName IT-ToolBox {}
    }
    It 'computes uptime from the server clock and queries only required properties' {
        Get-OsUpTime -ComputerName server01 -FullOutput | Should -Be ([timespan]::FromHours(60))
        Should -Invoke Get-CimInstance -ModuleName IT-ToolBox -Times 1 -Exactly -ParameterFilter {
            $ComputerName -eq 'server01' -and $ClassName -eq 'Win32_OperatingSystem' -and
            ($Property -join ',') -eq 'LastBootUpTime,LocalDateTime'
        }
        Should -Invoke New-CimSession -ModuleName IT-ToolBox -Times 0 -Exactly
    }
    It 'disposes an explicitly created session after success' {
        $cred = [pscredential]::new('test', (ConvertTo-SecureString 'example' -AsPlainText -Force))
        Get-OsUpTime -ComputerName server01 -Credential $cred | Should -Be 2
        Should -Invoke Get-CimInstance -ModuleName IT-ToolBox -Times 1 -ParameterFilter { $CimSession -contains $testSession }
        Should -Invoke Remove-CimSession -ModuleName IT-ToolBox -Times 1 -Exactly -ParameterFilter { $CimSession -contains $testSession }
    }
    It 'disposes the session and preserves a failed query error' {
        Mock Get-CimInstance -ModuleName IT-ToolBox { throw 'CIM query failed' }
        $cred = [pscredential]::new('test', (ConvertTo-SecureString 'example' -AsPlainText -Force))
        { Get-OsUpTime -ComputerName server01 -Credential $cred } | Should -Throw '*CIM query failed*'
        Should -Invoke Remove-CimSession -ModuleName IT-ToolBox -Times 1 -Exactly
    }
    It 'preserves the query error if session cleanup also fails' {
        Mock Get-CimInstance -ModuleName IT-ToolBox { throw 'original query failed' }
        Mock Remove-CimSession -ModuleName IT-ToolBox { throw 'cleanup failed' }
        $cred = [pscredential]::new('test', (ConvertTo-SecureString 'example' -AsPlainText -Force))
        { Get-OsUpTime -ComputerName server01 -Credential $cred -WarningAction SilentlyContinue } | Should -Throw '*original query failed*'
    }
    It 'propagates session-creation failures without attempting cleanup of a missing session' {
        Mock New-CimSession -ModuleName IT-ToolBox { throw 'session failed' }
        $cred = [pscredential]::new('test', (ConvertTo-SecureString 'example' -AsPlainText -Force))
        { Get-OsUpTime -ComputerName server01 -Credential $cred } | Should -Throw '*session failed*'
        Should -Invoke Remove-CimSession -ModuleName IT-ToolBox -Times 0 -Exactly
    }
    It 'rejects incomplete server timestamps' {
        Mock Get-CimInstance -ModuleName IT-ToolBox { [pscustomobject]@{ LastBootUpTime = $null; LocalDateTime = [datetime]::UtcNow } }
        { Get-OsUpTime -ComputerName server01 } | Should -Throw '*valid LastBootUpTime*'
    }
    It 'reports a missing CIM capability clearly' {
        Mock Get-Command -ModuleName IT-ToolBox { $null } -ParameterFilter { $Name -eq 'Get-CimInstance' }
        { Get-OsUpTime -ComputerName server01 } | Should -Throw '*Windows CIM cmdlets*'
    }
}
