<#
.SYNOPSIS

There are limits to the number of read/write operations that can be performed against the Azure Resource manager proviers in Azure. When this limit is reached there will be an HTTP 429 error returned.  The documentation below outlines the specific REST call but does not provide a complete example

https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-manager-request-limits

.DESCRIPTION

This script creates the proper bearer token to invoke the REST API on the number of remaining Read Operations allowed against a specific subscription.  The function Get-AzureCachedAccessToken provides the logic to pull the access token required to pass into the REST API

REF:
https://github.com/microsoft/csa-misc-utils

#>

function Get-AzCachedAccessToken {
  <#
    .SYNOPSIS
    Get the Bearer token from the currently set AzContext

    .DESCRIPTION
    Get the Bearer token from the currently set AzContext. Retrieves from Get-AzContext

    .EXAMPLE
    Get-AzCachedAccesstoken

    .EXAMPLE
    Get-AzCachedAccesstoken -Verbose

    #>
  [cmdletbinding()]
  param()

  $currentAzureContext = Get-AzContext

  $azureRmProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
  $profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azureRmProfile)
    
  Write-Verbose ("Tenant: {0}" -f $currentAzureContext.Subscription.Name)
    
  $token = $profileClient.AcquireAccessToken($currentAzureContext.Tenant.TenantId)
  $token.AccessToken
}

Write-Host "Log in to your Azure subscription..." -ForegroundColor Green
#Connect-AzAccount
#$SubscriptionName='????'
#Get-AzSubscription -SubscriptionName $SubscriptionName | Select-AzSubscription

$token = Get-AzCachedAccessToken
$currentAzureContext = Get-AzContext
Write-Host ("Getting access ARM Throttle Limits for Subscription: " + $currentAzureContext.Subscription)


$requestHeader = @{
  "Authorization" = "Bearer " + $token
  "Content-Type"  = "application/json"
}

$Uri = "https://management.azure.com/subscriptions/" + $currentAzureContext.Subscription + "/resourcegroups?api-version=2016-09-01"
$r = Invoke-WebRequest -Uri $Uri -Method GET -Headers $requestHeader
write-host("Remaining Read Operations: " + $r.Headers["x-ms-ratelimit-remaining-subscription-reads"])