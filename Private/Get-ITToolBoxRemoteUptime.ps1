function Get-ITToolBoxRemoteUptime
{
    param
    (
        [string]$ComputerName,
        [pscredential]$Credential
    )

    if (-not (Get-Command Get-CimInstance -ErrorAction SilentlyContinue))
    {
        throw [System.PlatformNotSupportedException]::new('Remote uptime requires Windows CIM cmdlets; run this query from PowerShell on Windows.')
    }

    $query = @{
        Namespace   = 'root/cimv2'
        ClassName   = 'Win32_OperatingSystem'
        Property    = @('LastBootUpTime', 'LocalDateTime')
        ErrorAction = 'Stop'
    }

    $session = $null
    $queryFailed = $false

    try
    {
        if ($null -ne $Credential)
        {
            $session = New-CimSession -ComputerName $ComputerName -Credential $Credential -ErrorAction Stop
            $query.CimSession = $session
        }
        else
        {
            $query.ComputerName = $ComputerName
        }

        $os = Get-CimInstance @query

        if ($os.LastBootUpTime -isnot [datetime] -or $os.LocalDateTime -isnot [datetime])
        {
            throw 'The remote OS did not return valid LastBootUpTime and LocalDateTime values.'
        }

        return ($os.LocalDateTime.ToUniversalTime() - $os.LastBootUpTime.ToUniversalTime())
    }
    catch
    {
        $queryFailed = $true
        throw
    }
    finally
    {
        if ($null -ne $session)
        {
            try
            {
                Remove-CimSession -CimSession $session -ErrorAction Stop
            }
            catch
            {
                if (-not $queryFailed)
                {
                    throw
                }

                Write-Warning ('CIM session cleanup also failed: {0}' -f $_.Exception.Message)
            }
        }
    }
}
