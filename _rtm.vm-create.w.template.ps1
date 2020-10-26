<#
Create a Windows virtual machine from a Resource Manager template
https://docs.microsoft.com/en-us/azure/virtual-machines/windows/ps-template
#>

$rgName = Read-Host -Prompt "Enter the Resource Group name"
$location = Read-Host -Prompt "Enter the location (i.e. centralus)"
$adminUsername = Read-Host -Prompt "Enter the administrator username"
$adminPassword = Read-Host -Prompt "Enter the administrator password" -AsSecureString
$dnsLabelPrefix = Read-Host -Prompt "Enter an unique DNS name for the public IP"

New-AzResourceGroup -Name $rgName -Location "$location"
New-AzResourceGroupDeployment `
    -ResourceGroupName $rgName `
    -TemplateUri "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-vm-simple-windows/azuredeploy.json" `
    -adminUsername $adminUsername `
    -adminPassword $adminPassword `
    -dnsLabelPrefix $dnsLabelPrefix `
    -Verbose

($vmName = (Get-AzVm -ResourceGroupName $rgName).name)

<# CONNECT TO VM
 Get-AzRemoteDesktopFile -ResourceGroupName $rgName -Name $vmName `
  -Launch
 Get-AzRemoteDesktopFile -ResourceGroupName $rgName -Name $vmName `
  -LocalPath "C:\Path\to\folder"
 #>