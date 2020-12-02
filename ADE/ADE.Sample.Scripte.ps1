<#
Azure Disk Encryption sample scripts
https://docs.microsoft.com/en-us/azure/virtual-machines/windows/disk-encryption-sample-scripts

#>

# List all encrypted VMs in your subscription

$osVolEncrypted = { (Get-AzVMDiskEncryptionStatus -ResourceGroupName $_.ResourceGroupName -VMName $_.Name).OsVolumeEncrypted }
$dataVolEncrypted = { (Get-AzVMDiskEncryptionStatus -ResourceGroupName $_.ResourceGroupName -VMName $_.Name).DataVolumesEncrypted }
Get-AzVm | Format-Table @{Label = "MachineName"; Expression = { $_.Name } }, @{Label = "OsVolumeEncrypted"; Expression = $osVolEncrypted }, @{Label = "DataVolumesEncrypted"; Expression = $dataVolEncrypted }

# List all encrypted VMSS instances in your subscription

Get-AzKeyVaultSecret -VaultName $KeyVaultName | where { $_.Tags.ContainsKey('DiskEncryptionKeyFileName') } | format-table @{Label = "MachineName"; Expression = { $_.Tags['MachineName'] } }, @{Label = "VolumeLetter"; Expression = { $_.Tags['VolumeLetter'] } }, @{Label = "EncryptionKeyURL"; Expression = { $_.Id } }

#-------------
# SINGLE-PASS
#-------------
# https://github.com/Azure/azure-quickstart-templates/tree/master/201-encrypt-running-windows-vm-without-aad

# Enable disk encryption on an existing or running Windows VM



# Disable encryption on a running Windows VM



#-----------
# DUAL-PASS
#-----------
# https://github.com/Azure/azure-quickstart-templates/tree/master/201-encrypt-running-windows-vm

# Enable disk encryption on an existing or running Windows VM


# Disable encryption on a running Windows VM


# Create a new encrypted managed disk from a pre-encrypted VHD/storage blob


# Creates a new encrypted managed disk provided a pre-encrypted VHD and its corresponding encryption settings
