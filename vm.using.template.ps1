# Tutorial: Create and deploy your first ARM template
# https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/template-tutorial-create-first-template?tabs=azure-powershell


$rgName = 'myRG'

$template = 'E:\ARM Template\template\Template.json'
$params = 'E:\ARM Template\template\Parameters.json'

$adminUsername = Read-Host -Prompt "Enter the administrator username"
$adminPassword = Read-Host -Prompt "Enter the administrator password" -AsSecureString

$dnsLabelPrefix = Read-Host -Prompt "Enter an unique DNS name for the public IP"

New-AzResourceGroup -Name $rgName -Location $region

New-AzResourceGroupDeployment `
    -ResourceGroupName $rgName `
    -TemplateUri $template `
    -TemplateParameterFile $params `
    -adminUsername $adminUsername `
    -adminPassword $adminPassword `
    -dnsLabelPrefix $dnsLabelPrefix `
    -Verbose
