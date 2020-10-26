# Quickstart: Create Azure Resource Manager templates with Visual Studio Code
# https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/quickstart-create-template-specs?tabs=azure-powershell

# Tutorial: Create and deploy your first ARM template
# https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/template-tutorial-create-first-template?tabs=azure-powershell

# Quickstart: Create and deploy template spec 
# https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/quickstart-create-template-specs?tabs=azure-powershell#deploy-template-spec

$rgName = 'myRG'
$templateSpecsRgName = 'templateSpecs'

$template = 'E:\ARM Template\template\Template.json'
$params = 'E:\ARM Template\template\Parameters.json'

$adminUsername = Read-Host -Prompt "Enter the administrator username"
$adminPassword = Read-Host -Prompt "Enter the administrator password" -AsSecureString

$dnsLabelPrefix = Read-Host -Prompt "Enter an unique DNS name for the public IP"

# 1.
New-AzResourceGroup -Name $rgName -Location $region
# 2.
$id = ( 
    Get-AzTemplateSpec `
        -ResourceGroupName $templateSPecsRgName `
        -Name storageSpec `
        -Version "1.0"
).Versions.Id

New-AzResourceGroupDeployment `
    -ResourceGroupName $rgName `
    -TemplateUri $template `
    -TemplateParameterFile $params `
    -adminUsername $adminUsername `
    -adminPassword $adminPassword `
    -dnsLabelPrefix $dnsLabelPrefix `
    -Verbose
