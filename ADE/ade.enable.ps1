<# 
https://docs.microsoft.com/en-us/azure/virtual-machines/windows/disk-encryption-windows#enable-encryption-on-existing-or-running-vms-with-azure-powershell
#>

$VMRGName = '2106140010002933'
$vmName = 'vm2019'

$KVRGname = '2106140010002933'
$KeyVaultName = 'kv2933'

$KeyVault = Get-AzKeyVault -VaultName $KeyVaultName -ResourceGroupName $KVRGname
$diskEncryptionKeyVaultUrl = $KeyVault.VaultUri
$KeyVaultResourceId = $KeyVault.ResourceId

Set-AzVMDiskEncryptionExtension `
  -ResourceGroupName $VMRGname `
  -VMName $vmName `
  -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl `
  -DiskEncryptionKeyVaultId $KeyVaultResourceId `
  -Force
#  -EncryptFormatAll  # Encrypt-Format all data drives that are not already encrypted

Get-AzVmDiskEncryptionStatus -ResourceGroupName $vmRgName -VMName $vmName
Update-AzVM -ResourceGroupName $VMRGName -VM $vmName