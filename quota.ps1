

Remove-AzResourceGroupDeployment -ResourceGroupName exampleGroup -Name deploymentName

(Get-AzResourceGroupDeployment -ResourceGroupName exampleGroup).Count

$deployments = Get-AzResourceGroupDeployment -ResourceGroupName exampleGroup | Where-Object Timestamp -lt ((Get-Date).AddDays(-5))

foreach ($deployment in $deployments) {
  Remove-AzResourceGroupDeployment -ResourceGroupName exampleGroup -Name $deployment.DeploymentName
}

