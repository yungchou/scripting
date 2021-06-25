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
$vmAdminUserName = 'vmAdmin'

# vm admin credential
#$cred = Get-Credential -UserName vmadmin
$cred = Get-Credential -UserName $vmAdminUserName

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

<# MANUALLY ADD DATA DISKS HERE, AS NEEDED
$storageType = 'Premium_LRS'
$dataDiskName = $vmName + 'DD1'
$diskSizeGB = 4

$diskConfig = New-AzDiskConfig `
  -SkuName $storageType -Location $region `
  -CreateOption Empty -DiskSizeGB $diskSizeGB
  
$dataDisk1 = New-AzDisk -DiskName $dataDiskName -Disk $diskConfig -ResourceGroupName $rgName
$vmObj = Get-AzVM -Name $vmName -ResourceGroupName $rgName
$vmObj = Add-AzVMDataDisk -VM $vmObj -Name $dataDiskName `
  -CreateOption Attach -ManagedDiskId $dataDisk1.Id -Lun 1

Update-AzVM -VM $vmObj -ResourceGroupName $rgName

# RDP into the VM 
Get-Disk | Where partitionstyle -eq 'raw' |
  Initialize-Disk -PartitionStyle MBR -PassThru |
  New-Partition -AssignDriveLetter -UseMaximumSize |
  Format-Volume -FileSystem NTFS -NewFileSystemLabel "myDataDisk" -Confirm:$false

# IN CLOUD SHELL
$vm.StorageProfile.DataDisks

#>

# ENABLE ADE
$KeyVault = Get-AzKeyVault -VaultName $kvName -ResourceGroupName $rgName

Set-AzVMDiskEncryptionExtension `
  -ResourceGroupName $rgName -VMName $vmName `
  -DiskEncryptionKeyVaultUrl $KeyVault.VaultUri `
  -DiskEncryptionKeyVaultId $KeyVault.ResourceId `
  -FORCE
#  -EncryptFormatAll # Encrypt-Format all data drives that are not already encrypted
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

#>
#endregion