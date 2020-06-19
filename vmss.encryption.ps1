# Encrypting VMSS
$vmssName = 'vmss'
$rgName = 'da-test'
$vaultname = 'dakv11'
$keyEncryptionKeyName = 'vmsskey'
$location = 'southcentralus'
$diskEncryptionKeyVaultUrl = (Get-AzKeyVault -ResourceGroupName $rgName -Name $vaultName).VaultUri
$keyVaultResourceId = (Get-AzKeyVault -ResourceGroupName $rgName -Name $vaultName).ResourceId
$keyEncryptionKeyUrl = (Get-AzKeyVaultKey -VaultName $vaultName -Name $keyEncryptionKeyName).Key.kid;

Set-AzVmssDiskEncryptionExtension -ResourceGroupName $rgName -VMScaleSetName $vmssName `
  -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl -DiskEncryptionKeyVaultId $keyVaultResourceId `
  -KeyEncryptionKeyUrl $keyEncryptionKeyUrl -KeyEncryptionKeyVaultId $keyVaultResourceId -VolumeType "All"

Get-AzVmssDiskEncryption -ResourceGroupName $rgName -VMScaleSetName $vmssName

$vmName='vmnodisk'
$rgName='daade1'
# Disable Encryption: 
Disable-AzVMDiskEncryption -ResourceGroupName $rgName -VMName $vmName -VolumeType "all"

# Remove Encryption: 
Remove-AzVMDiskEncryptionExtension -ResourceGroupName $rgNme -VMName $vmName
