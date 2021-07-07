
$rgName = 'da110'
$region = 'southcentralus'
New-AzResourceGroup -Name $rgName -Location $region 
#use this command when you need to create a new resource group for your deployment

$templateUri = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/quickstarts/microsoft.compute/encrypt-running-windows-vm/azuredeploy.json'

New-AzResourceGroupDeployment `
  -ResourceGroupName $rgName `
  -TemplateUri $templateUri
  