<# REQUIRED PARAMETERS
$VMRGName = 'da100' 
$vmName = $VMRGName+'vm'

$KVRGname = $VMRGName
$KeyVaultName = $VMRGName+'vkv'
#>

$KeyVault = Get-AzKeyVault -VaultName $KeyVaultName -ResourceGroupName $KVRGname
$diskEncryptionKeyVaultUrl = $KeyVault.VaultUri
$KeyVaultResourceId = $KeyVault.ResourceId

Set-AzVMDiskEncryptionExtension `
  -ResourceGroupName $VMRGname `
  -VMName $vmName `
  -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl `
  -DiskEncryptionKeyVaultId $KeyVaultResourceId
