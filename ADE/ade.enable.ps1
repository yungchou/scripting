<# 
https://docs.microsoft.com/en-us/azure/virtual-machines/windows/disk-encryption-windows#enable-encryption-on-existing-or-running-vms-with-azure-powershell
#>

$VMRGName = 'ADE'
$vmName = 'vm1'

$KVRGname = 'zulu'
$KeyVaultName = 'zulu-kv'
$KeyVault = Get-AzKeyVault -VaultName $KeyVaultName -ResourceGroupName $KVRGname
$diskEncryptionKeyVaultUrl = $KeyVault.VaultUri
$KeyVaultResourceId = $KeyVault.ResourceId

Set-AzVMDiskEncryptionExtension `
  -ResourceGroupName $VMRGname `
  -VMName $vmName `
  -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl `
  -DiskEncryptionKeyVaultId $KeyVaultResourceId 
#  -EncryptFormatAll  # Encrypt-Format all data drives that are not already encrypted

  