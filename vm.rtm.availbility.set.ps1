<#
-------------------------------------
 CHANGE THE AVAILABILITY SET OF A VM
-------------------------------------
https://docs.microsoft.com/en-us/azure/virtual-machines/windows/change-availability-set?toc=/azure/virtual-machines/linux/toc.json&bc=/azure/virtual-machines/linux/breadcrumb/toc.json
#>

# Log in to your subscription 
Connect-AzAccount 
Get-AzSubscription

# Set context
$subId = 'Subscription ID' 
Set-AzContext -SubscriptionID $subId  

<#
region='southcentralus'

az vm list-skus -l $region \
  --resource-type availabilitySets \
  -o Table \
  --query '[?name==`Aligned`].{Location:locationInfo[0].location, MaximumFaultDomainCount:capabilities[0].value}'
#>

Get-AzComputeResourceSku | Where-Object { $_.ResourceType -eq 'availabilitySets' -and $_.Name -eq 'Aligned' }

# Session Info
$rgName = 'myRG'
$vmName = 'myVM'
$newAvailSetName = 'myAvailabilitySet'

# Get the details of the VM to be moved to the Availability Set
$originalVM = Get-AzVM -ResourceGroupName $rgName -Name $vmName

# Create new availability set if it does not exist
$availSet = Get-AzAvailabilitySet `
  -ResourceGroupName $rgName `
  -Name $newAvailSetName `
  -ErrorAction Ignore

if (-Not $availSet) {
  $availSet = New-AzAvailabilitySet `
    -Name $newAvailSetName `
    -ResourceGroupName $rgName `
    -Location $originalVM.Location `
    -PlatformFaultDomainCount 2 `
    -PlatformUpdateDomainCount 2 `
    -Sku Aligned `
    -o table
}

# Remove the original VM
Remove-AzVM -ResourceGroupName $rgName -Name $vmName -AsJob -Force

# Create the basic configuration for the replacement VM. 
$newVM = New-AzVMConfig `
  -VMName $originalVM.Name `
  -VMSize $originalVM.HardwareProfile.VmSize `
  -AvailabilitySetId $availSet.Id

$newVM = Set-AzVMOSDisk `
  -VM $newVM -CreateOption Attach `
  -ManagedDiskId $originalVM.StorageProfile.OsDisk.ManagedDisk.Id `
  -Name $originalVM.StorageProfile.OsDisk.Name

$newVM.StorageProfile.OsDisk.OsType = $originalVM.StorageProfile.OsDisk.OsType

# Add Data Disks
foreach ($disk in $originalVM.StorageProfile.DataDisks) { 
  Add-AzVMDataDisk -VM $newVM `
    -Name $disk.Name `
    -ManagedDiskId $disk.ManagedDisk.Id `
    -Caching $disk.Caching `
    -Lun $disk.Lun `
    -DiskSizeInGB $disk.DiskSizeGB `
    -CreateOption Attach
}

# Add NIC(s) and keep the same NIC as primary
foreach ($nic in $originalVM.NetworkProfile.NetworkInterfaces) {	
  if ($nic.Primary -eq "True") {
    Add-AzVMNetworkInterface -VM $newVM -Id $nic.Id -Primary
  }
  else {
    Add-AzVMNetworkInterface -VM $newVM -Id $nic.Id 
  }
}

# Recreate the VM
New-AzVM -ResourceGroupName $rgName -VM $newVM `
  -Location $originalVM.Location `
  -DisableBginfoExtension `
  -AsJob

do { Start-Sleep -s 10; echo Waiting... } 
until ((Get-AzVM -Name $newVM.Name -Status).PowerState -eq 'VM running')

Get-AzVM -Name $newVM.Name -Status
