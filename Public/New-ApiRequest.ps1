function New-ApiRequest {
    <#
    .SYNOPSIS
    Sends an OAuth-style client request and returns the endpoint response.
    .DESCRIPTION
    Builds client_id and grant_type fields, plus optional client_secret. Defaults
    to POST with application/x-www-form-urlencoded. JSON is also supported. This
    helper does not acquire a token and then call another API, or manage token refresh.
    GET is allowed only without ApiSecret; Invoke-RestMethod turns its dictionary
    body into query parameters. Requests containing ApiSecret require HTTPS.
    Automatic redirects are disabled. HTTP failures terminate; no retry is performed.
    .PARAMETER Headers
    Dictionary of HTTP headers. Specify Content-Type through ContentType instead.
    .EXAMPLE
    New-ApiRequest -ApiKey 'client-id' -ApiSecret $secret -ApiUrl 'https://example.invalid/oauth/token'
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$ApiKey,
        [ValidateNotNullOrEmpty()][string]$ApiSecret,
        [Parameter(Mandatory)]
        [ValidateScript({ $_.IsAbsoluteUri -and $_.Scheme -in @('http', 'https') -and [string]::IsNullOrEmpty($_.UserInfo) })]
        [uri]$ApiUrl,
        [ValidateNotNullOrEmpty()][string]$GrantType = 'client_credentials',
        [ValidateSet('application/x-www-form-urlencoded', 'application/json')]
        [string]$ContentType = 'application/x-www-form-urlencoded',
        [ValidateSet('GET', 'POST')][string]$Method = 'POST',
        [ValidateNotNull()][System.Collections.IDictionary]$Headers,
        [Alias('TimeoutSec')][ValidateRange(1,300)][int]$ConnectionTimeoutSeconds = 30
    )
    $methodName = $Method.ToUpperInvariant()
    $hasSecret = $PSBoundParameters.ContainsKey('ApiSecret')
    if ($hasSecret -and $methodName -eq 'GET') {
        throw [ArgumentException]::new('ApiSecret cannot be sent with GET because it would enter the URL query string. Use POST.')
    }
    if ($hasSecret -and $ApiUrl.Scheme -ne 'https') {
        throw [ArgumentException]::new('Requests containing ApiSecret require HTTPS.')
    }
    if ($PSBoundParameters.ContainsKey('Headers')) {
        foreach ($name in $Headers.Keys) {
            if ([string]$name -ieq 'Content-Type') {
                throw [ArgumentException]::new('Specify Content-Type with the ContentType parameter, not Headers.')
            }
            if ([string]$name -ieq 'Authorization' -and $ApiUrl.Scheme -ne 'https') {
                throw [ArgumentException]::new('Requests containing Authorization headers require HTTPS.')
            }
        }
    }
    [hashtable]$requestBody = @{
        client_id = $ApiKey
        grant_type = $GrantType
    }
    if ($hasSecret) { $requestBody.client_secret = $ApiSecret }
    [hashtable]$request = @{
        Uri = $ApiUrl
        Method = $methodName
        Body = $requestBody
        MaximumRedirection = 0
        ConnectionTimeoutSeconds = $ConnectionTimeoutSeconds
        ErrorAction = 'Stop'
    }
    if ($methodName -eq 'POST') {
        $request.ContentType = $ContentType
        if ($ContentType -ieq 'application/json') {
            $request.Body = ConvertTo-Json -InputObject $requestBody -Compress
        }
    }
    elseif ($PSBoundParameters.ContainsKey('ContentType')) {
        throw [ArgumentException]::new('ContentType applies to POST requests. GET sends query parameters.')
    }
    if ($PSBoundParameters.ContainsKey('Headers')) { $request.Headers = $Headers }
    return Invoke-RestMethod @request
}
