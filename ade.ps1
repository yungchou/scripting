


$cred = Get-Credential
$vmssName = 'vmss'
$rgName = 'da-ade'
$vaultname = 'daKV'
$location = 'southcentralus'

New-AzVmss `
  -ResourceGroupName $rgName `
  -VMScaleSetName $vmssName `
  -Location $location `
  -VirtualNetworkName "$vmssNamevnet" `
  -SubnetName "default" `
  -PublicIpAddressName "$vmssNamepip" `
  -LoadBalancerName "$vmsslb" `
  -UpgradePolicy "Automatic" `
  -Credential $cred

#------------------------
# Single Pass Encryption
#------------------------
#	Encrypt a Windows VM with KEK
#	Explain how to migrate from BEK to KEK encryption.
# manage-bde –status

$KvRgName = 'daade1';
$VmRgName = 'daade1';
$vmName = 'vmnodisk';
$KeyVaultName = 'da-adekv';
$keyEncryptionKeyName = 'adekey';
$KeyVault = Get-AzKeyVault -VaultName $KeyVaultName -ResourceGroupName $KvRgName;
$diskEncryptionKeyVaultUrl = $KeyVault.VaultUri;
$KeyVaultResourceId = $KeyVault.ResourceId;
$keyEncryptionKeyUrl = (Get-AzKeyVaultKey -VaultName $KeyVaultName -Name $keyEncryptionKeyName).Key.kid;
$sequenceVersion = [Guid]::NewGuid();

Set-AzVMDiskEncryptionExtension -ResourceGroupName $VMRGname -VMName $vmName `
  -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl `
  -DiskEncryptionKeyVaultId $KeyVaultResourceId `
  -KeyEncryptionKeyUrl $keyEncryptionKeyUrl `
  -KeyEncryptionKeyVaultId $KeyVaultResourceId `
  -VolumeType "All" `
  –SequenceVersion $sequenceVersion;

Get-AzVmDiskEncryptionStatus -ResourceGroupName $vmRgName -VMName $vmName

#----------------------
# Dual Pass Encryption
#----------------------
# Encrypt a Windows VM OS disk and Data disk with Dual Pass encryption. 
# status for data disk 



