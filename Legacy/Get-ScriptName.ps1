function Get-ScriptName
{
<#
	.SYNOPSIS
		Get-ScriptName returns the name of the script.

	.OUTPUTS
		System.String
#>
	[OutputType([string])]
	param ()
	if ($null -ne $hostinvocation)
	{
		$hostinvocation.MyCommand.Name
	}
	else
	{
		$script:MyInvocation.MyCommand.Name
	}
}