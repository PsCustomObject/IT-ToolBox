function Get-OsUpTime {
    <#
    .SYNOPSIS
    Returns local OS uptime or a remote Windows computer's uptime.
    .DESCRIPTION
    Uses Get-Uptime locally on Windows, Linux and macOS. Remote queries require
    Windows CIM cmdlets and a reachable Windows CIM endpoint. Remote uptime is
    computed from the server's LocalDateTime and LastBootUpTime, avoiding use of
    the client's clock. Failures terminate; any session created here is disposed.
    .PARAMETER FullOutput
    Returns TimeSpan. Without this switch, returns whole elapsed days as Int32.
    .PARAMETER Credential
    Explicit credentials for a remote computer, without an interactive prompt.
    .PARAMETER Credentials
    Compatibility switch: prompts with Get-Credential for a remote computer.
    .EXAMPLE
    Get-OsUpTime -FullOutput
    .EXAMPLE
    Get-OsUpTime -ComputerName server01 -Credential $credential -FullOutput
    #>
    [CmdletBinding(DefaultParameterSetName = 'LocalMachine')]
    [OutputType([int], [timespan])]
    param(
        [Parameter(ParameterSetName = 'RemoteMachine', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName,
        [switch]$FullOutput,
        [Parameter(ParameterSetName = 'RemoteMachine')]
        [ValidateNotNull()]
        [pscredential]$Credential,
        [Parameter(ParameterSetName = 'RemoteMachine')]
        [switch]$Credentials
    )

    if ($Credentials -and $PSBoundParameters.ContainsKey('Credential')) {
        throw 'Use either -Credential or -Credentials, not both.'
    }
    if ($PSCmdlet.ParameterSetName -eq 'RemoteMachine') {
        if ([string]::IsNullOrWhiteSpace($ComputerName)) { throw 'ComputerName cannot be whitespace.' }
        if ($Credentials) {
            $promptedCredential = Get-Credential -Message 'Please specify alternate credentials to be used:' -ErrorAction Stop
            if ($null -eq $promptedCredential) { throw 'No credential was supplied.' }
            $Credential = $promptedCredential
        }
        $uptime = Get-ITToolBoxRemoteUptime -ComputerName $ComputerName -Credential $Credential
    }
    else {
        $uptime = Get-Uptime -ErrorAction Stop
    }
    if ($uptime -isnot [timespan] -or $uptime -lt [timespan]::Zero) {
        throw 'The uptime source did not return a nonnegative TimeSpan.'
    }
    if ($FullOutput) { return $uptime }
    return [int]$uptime.Days
}
