#region [REFERENCE]

Quickstart: Create and encrypt a Windows virtual machine in Azure with PowerShell
https://docs.microsoft.com/en-us/azure/virtual-machines/windows/disk-encryption-powershell-quickstart

#endregion

# Assume having logged into Azure and started a cloud shell session already,
# and run the following statement by coping and pasting into the session.

$subscription = “??” 

# PARAMETERS/CUSTOMIZATION
$region = "westus"
$img = "win2019datacenter"
$vmSize = "standard_d2s_v3"

# vm admin credential
$cred = Get-Credential -UserName vmadmin
#$cred = Get-Credential -UserName fordemo -Password "neverInProduction!"

#region [DEPLOYMENT ROUTNE]

# SESSION SPECIFIC
$tag = (Get-Date -UFormat "%T" | ForEach-Object { $_ -replace ":", "" })
$rgName = ”ADETEST$tag"
$vmName = $rgName + ”vm”
$kvName = $rgName + ”kv”

# SET CONTEXT
Set-AzContext -Subscription $subscription

# REATE RESORUCE GROUP
New-AzResourceGroup -Name $rgName -Location $region

# DEPLOY VM
New-AzVM -Name $vmName -ResourceGroupName $rgName `
  -Image $img -Size $vmSize -Credential $cred 

# DEPLOY KEY VAULT
New-AzKeyvault -name $kvName -ResourceGroupName $rgName -Location $region `
  -EnabledForDeployment `
  -EnabledForDiskEncryption `
  -EnabledForTemplateDeployment

# ENABLE ADE
$KeyVault = Get-AzKeyVault -VaultName $kvName -ResourceGroupName $rgName

Set-AzVMDiskEncryptionExtension `
  -ResourceGroupName $rgName -VMName $vmName `
  -DiskEncryptionKeyVaultUrl $KeyVault.VaultUri `
  -DiskEncryptionKeyVaultId $KeyVault.ResourceId `
  -FORCE 
#  -AsJob

# VERIFY THE DEPLOYMENT
# Show VM instance properties
$vmInstance = (Get-AzVM -ResourceGroupName $rgName -Name $vmName -Status); $vmInstance
# Show VM instance disk properties
$vmInstance.disks.statuses
# Show VM instance disk properties
$vmInstance.vmagent.statuses

#endregion

#region [CLEAN UP]
<# 
Remove-AzResourceGroup -Name $rgName -Force -AsJob

# Check status
Get-AzResourceGroup -Name $rgName
#>
#endregion