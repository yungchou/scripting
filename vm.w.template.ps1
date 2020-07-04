$rgName = Read-Host -Prompt "Enter the Resource Group name"
$region = Read-Host -Prompt "Enter the location (i.e. centralus)"
$adminUsername = Read-Host -Prompt "Enter the administrator username"
$adminPassword = Read-Host -Prompt "Enter the administrator password" -AsSecureString
$dnsLabelPrefix = Read-Host -Prompt "Enter an unique DNS name for the public IP"

New-AzResourceGroup -Name $rgName -Location "$region"
New-AzResourceGroupDeployment `
    -ResourceGroupName $rgName `
    -TemplateUri "template.json" `
    -adminUsername $adminUsername `
    -adminPassword $adminPassword `
    -dnsLabelPrefix $dnsLabelPrefix

(Get-AzVm -ResourceGroupName $rgName).name
