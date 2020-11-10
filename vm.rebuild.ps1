#region [Establish session context]
Login-AzureRmAccount

# Set the context
Get-AzureRmSubscription
Get-AzureRmSubscription –SubscriptionID “SubscriptionID” | Select-AzureRmSubscription
#endregion

#region [Rebuild the VM using PowerShell (Non-Managed Disk)]
    
$rgname = "RGname"
$loc = "Location"
$vmsize = "VmSize"
$vmname = "VmName"
$vm = New-AzureRmVMConfig -VMName $vmname -VMSize $vmsize;
    
$nic = Get-AzureRmNetworkInterface -Name ("NicName") -ResourceGroupName $rgname;
$nicId = $nic.Id;
    
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nicId;
    
$osDiskName = "OSdiskName"
$osDiskVhdUri = "OSdiskURI"
    
$vm = Set-AzureRmVMOSDisk -VM $vm -VhdUri $osDiskVhdUri -name $osDiskName -CreateOption attach -Windows
    
New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $vm -Verbose

#endregion

#region [Rebuild the VM using PowerShell (Managed Disk)]

#Fill in all variables
$subid = "SubscriptionID"
$rgName = "ResourceGroupName";
$loc = "Location";
$vmSize = "VmSize";
$vmName = "VmName";
$nic1Name = "FirstNetworkInterfaceName";
#$nic2Name = "SecondNetworkInterfaceName";
$avName = "AvailabilitySetName";
$osDiskName = "OsDiskName";
$DataDiskName = "DataDiskName"
  
#This can be found by selecting the Managed Disks you wish you use in the Azure Portal if the format below does not match
$osDiskResouceId = "/subscriptions/$subid/resourceGroups/$rgname/providers/Microsoft.Compute/disks/$osDiskName";
$dataDiskResourceId = "/subscriptions/$subid/resourceGroups/$rgname/providers/Microsoft.Compute/disks/$DataDiskName";
  
$vm = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize;
  
#Uncomment to add Availabilty Set
#$avSet = Get-AzureRmAvailabilitySet –Name $avName –ResourceGroupName $rgName;
#$vm = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize -AvailabilitySetId $avSet.Id;
  
#Get NIC Resource Id and add
$nic1 = Get-AzureRmNetworkInterface -Name $nic1Name -ResourceGroupName $rgName;
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic1.Id -Primary;
  
#Uncomment to add a secondary NIC
#$nic2 = Get-AzureRmNetworkInterface -Name $nic2Name -ResourceGroupName $rgName;
#$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic2.Id;
  
#Windows VM
$vm = Set-AzureRmVMOSDisk -VM $vm -ManagedDiskId $osDiskResouceId -name $osDiskName -CreateOption Attach -Windows;
  
#Linux VM
#$vm = Set-AzureRmVMOSDisk -VM $vm -ManagedDiskId $osDiskResouceId -name $osDiskName -CreateOption Attach -Linux;
  
#Uncomment to add additnal Data Disk
#Add-AzureRmVMDataDisk -VM $vm -ManagedDiskId $dataDiskResourceId -Name $dataDiskName -Caching None -DiskSizeInGB 1024 -Lun 0 -CreateOption Attach;
  
New-AzureRmVM -ResourceGroupName $rgName -Location $loc -VM $vm;

#endregion
