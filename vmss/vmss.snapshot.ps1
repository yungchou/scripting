<#
CREATE VMSS SNAPSHOT
https://docs.microsoft.com/en-us/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-faq#how-do-i-take-a-snapshot-of-a-virtual-machine-scale-set-instance
#>

# Create a snapshot from an instance of a virtual machine scale set.

$rgName = 'dada'
$vmssName = 'vmss'
$Id = 2
$region = 'southcentralus'
$snapshotName = "$vmssName-$Id-snapshot"

$vmss1 = Get-AzVmssVM -ResourceGroupName $rgName -VMScaleSetName $vmssName -InstanceId $Id     
$snapshotConfig = New-AzSnapshotConfig `
  -Location $region `
  -AccountType Standard_LRS `
  -OsType Windows `
  -CreateOption Copy `
  -SourceUri $vmss1.StorageProfile.OsDisk.ManagedDisk.id
New-AzSnapshot -ResourceGroupName $rgName -SnapshotName $snapshotName -Snapshot $snapshotConfig

# Create a managed disk from the snapshot
$snapshot = Get-AzSnapshot -ResourceGroupName $rgName -SnapshotName $snapshotName  
$diskConfig = New-AzDiskConfig `
  -AccountType Premium_LRS `
  -Location $region `
  -CreateOption Copy `
  -SourceResourceId $snapshot.Id
$osDisk = New-AzDisk -Disk $diskConfig -ResourceGroupName $rgName -DiskName ($snapshotName + '-Disk')

