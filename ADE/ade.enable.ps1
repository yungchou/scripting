<# 
https://docs.microsoft.com/en-us/azure/virtual-machines/windows/disk-encryption-windows#enable-encryption-on-existing-or-running-vms-with-azure-powershell
#>

$VMRGName = 'dada'
$vmName = 'davm'

$KVRGname = 'zulu'
$KeyVaultName = 'zulu-kv'

$KeyVault = Get-AzKeyVault -VaultName $KeyVaultName -ResourceGroupName $KVRGname
$diskEncryptionKeyVaultUrl = $KeyVault.VaultUri
$KeyVaultResourceId = $KeyVault.ResourceId

Get-AzVmDiskEncryptionStatus -ResourceGroupName $vmRgName -VMName $vmName

Set-AzVMDiskEncryptionExtension `
  -ResourceGroupName $VMRGname -VMName $vmName `
  -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl `
  -DiskEncryptionKeyVaultId $KeyVaultResourceId `
  -VolumeType All `
  -Force
#  -EncryptFormatAll  # Encrypt-Format all data drives that are not already encrypted

Get-AzVmDiskEncryptionStatus -ResourceGroupName $vmRgName -VMName $vmName

# Remove-AzVMDiskEncryptionExtension -ResourceGroupName $VMRGname -VMName $vmName -Force
# Update-AzVM -ResourceGroupName $VMRGName -VM $vmName