function New-ApiRequest
{
<#
	.SYNOPSIS
		Function will query data from an URL API.
	
	.DESCRIPTION
		Function is intended as a wrapper around PowerShell built-in Invoke-RestMethod cmdlet allowing user to quickly generate web requests to APIs requiring OAuth2 authentication.
	
	.PARAMETER ApiKey
		A string representing the API key to be used.
	
	.PARAMETER ApiSecret
		A string representing the API key secret.
	
	.PARAMETER ApiUrl
		A string representing the API endpoint URL
	
	.PARAMETER GrantType
		A string representing the Grant Type supported by the API.
		
		If not specified it will default to client_credentials.
	
	.PARAMETER ContentType
		A string representing the content type to send as part of the request in case request needs to be crafted with a special ContentType.
	
	.PARAMETER Method
		A string representing the method to be used in the web request.
		
		If not specified it will default to GET.
	
	.PARAMETER Headers
		A string representing custom headers to send as part of the webrequest.
	
	.EXAMPLE
		PS C:\> New-ApiRequest -ApiKey 'Value1' -ApiUrl 'Value2' -ApiSecret 'MySecret'
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	[OutputType([pscustomobject])]
	param
	(
		[Parameter(Mandatory = $true)]
		[string]
		$ApiKey,
		[string]
		$ApiSecret,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$ApiUrl,
		[ValidateNotNullOrEmpty()]
		[string]
		$GrantType = 'client_credentials',
		[ValidateNotNullOrEmpty()]
		[string]
		$ContentType,
		[ValidateNotNullOrEmpty()]
		[ValidateSet('GET', 'POST', IgnoreCase = $true)]
		[string]
		$Method = 'GET',
		[ValidateNotNullOrEmpty()]
		[string]
		$Headers
	)
	
	Process
	{
		# Generate request post data
		[hashtable]$requestBody = @{
			'client_id'  = $ApiKey;
			'grant_type' = $GrantType
		}
		
		switch ($PSBoundParameters.Keys)
		{
			'ContentType'
			{
				$requestBody.Add('ContentType', $ContentType)
				
				break
			}
			'ApiSecret'
			{
				$requestBody.Add('client_secret', $ApiSecret)
				
				break
			}
		}
		
		# Define splat command
		$paramInvokeWebRequest = @{
			Uri  = $ApiUrl
			Body = $requestBody
		}
		
		# Get passed parameters
		switch ($PSBoundParameters.Keys)
		{
			'Headers'
			{
				# Add custom header
				$paramInvokeWebRequest.Add('Headers', $Headers)
				
				break
			}
			'Method'
			{
				# Use custom method
				$paramInvokeWebRequest.Add('Method', $Method)
				
				break
			}
		}
		
		return Invoke-RestMethod @paramInvokeWebRequest
	}
}