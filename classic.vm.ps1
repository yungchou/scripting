### Deployment Options

$usePlan = 0          # 0=No Plan Info, 1=Use Plan Info

$useAvSet = 0         # 0=No AvSet, 1=Use AvSet

$createAvSet = 0      # 0=AvSet already exists, 1=Create the AvSet (Requires $useAvSet to be 1)

### Required Variables

$rgName = '??'
$vmName = ''
$vmSize = "Standard_D13_v2_Promo"
$nicName = $vmName'-nic'

$managedDiskId = "/subscriptions/8ac8c567-6950-4e22-8895-70b45bc1a7c8/resourceGroups/NIGMS-RG-MGMT-StoreOnce/providers/Microsoft.Compute/disks/NIGMS-MAI-STO_OsDisk_1_c0267a347a41464692f8e25c7a1aad2c"

$osType = "Linux"     # Can be either "Linux" or "Windows"

### Optional Variables
$avSetName = "testavset"
$planPublisherName = "hpe"
$planProductName = "storeoncevsa"
$planName = "hpestoreoncevsa-3162"

###########################
## Begin Building the VM ##
###########################
### Create VM Configuration

if ($useAvSet) {
  if ($createAvSet) {
    $disk = Get-AzDisk -ResourceGroupName ($managedDiskId.Split("/"))[4] -Name ($managedDiskId.Split("/"))[8]
    New-AzAvailabilitySet -ResourceGroupName $rgName -Name $avSetName -Location $disk.Location
  }
  $avSetId = Get-AzAvailabilitySet -Name $avSetName
  $vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize -AvailabilitySetID $avSetId.Id
}
else {
  $vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize
}

### Set the Marketplace plan information
if ($usePlan) {
  $vmConfig = Set-AzVMPlan -VM $vmConfig -Publisher $planPublisherName -Product $planProductName -Name $planName
}

### Get the NIC
$nic = Get-AzNetworkInterface -ResourceGroupName $rgName -Name $nicName
$vmConfig = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.id
### Set OS Disk
$vmConfig = Set-AzVMOSDisk -VM $vmConfig -ManagedDiskId $managedDiskId -Name ($managedDiskId.Split("/"))[8] -CreateOption Attach -$osType

### Add Data Disk
#$lun = 0
#$diskCaching = "None"    # Can be "None", "ReadOnly", or "ReadWrite"

#$dataDiskId = "/subscriptions/8ac8c567-6950-4e22-8895-70b45bc1a7c8/resourceGroups/NIGMS-RG-MGMT-StoreOnce/providers/Microsoft.Compute/disks/NIGMS-MAI-STO_lun_0_2_53cf3ec29e124c53ad4e866a3178057d"

#$dataDiskSize = Get-AzDisk -ResourceGroupName ($dataDiskId.Split("/"))[4] -DiskName ($dataDiskId.Split("/"))[4]

#$vmConfig = Add-AzVMDataDisk -VM $vmConfig -ManagedDiskId $dataDiskId -Name ($dataDiskId.split("/"))[8] -Caching $diskCaching -DiskSizeInGB $dataDiskSize -Lun $lun -CreateOption Attach

### Deploy VM Configuration
New-AzVM -VM $vmConfig

