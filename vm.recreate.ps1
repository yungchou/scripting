<# 
Azure VM Offline Troubleshooting
1. Export the current vm configuration
2. Delete the vm and keep the disk
3. Attach the disk to a rescue vm for troubleshooting
4. Recreate the vm by impoting the configuration
#>

###################################################
#region CREATE A COPY OF THE CURRENT CONFIGURATION
###################################################

# Log in to your subscription 
Connect-AzAccount 
Get-AzSubscription

# Set context
$subId = 'Subscription ID' 
Set-AzContext -SubscriptionID $subId  

# Set up your variables 
$rgName = 'Resource group name'
$vmName = 'Virtual machine name'

$json = "$vmName.json"

# Stop deallocate the VM 
Stop-AzVM -ResourceGroupName $rgName -Name $vmName -Force -AsJob
do {Start-Sleep -s 5; echo Waiting...} until ((Get-AzVM -Name $vmName -Status).PowerState -eq 'VM deallocated')
Get-AzVM -Name $vm.Name -Status

# Export the configuration  
Get-AzVM -ResourceGroupName $rgName -Name $vmName `
| ConvertTo-Json -depth 100 | Out-file -FilePath $json 

#endregion

################
# REMOVE THE VM
################
# The command below will not remove the disks attached to this VM
Remove-AzVM -ResourceGroupName $rgName -Name $vmName -Force -AsJob

########################
#region RECREATE THE VM
########################

#------------------------------------------------
#region UNMANAGED VM Option 1.1 Import from json
#------------------------------------------------

# Log in to your subscription 
Connect-AzAccount 
Get-AzSubscription

# Set context
$subId = 'Subscription ID' 
Set-AzContext -SubscriptionID $subId  

# Set up your variables 
$rgName = 'Resource group name'
$vmName = 'Virtual machine name'

$json = "$vmName.json"
$import = gc $json -Raw | ConvertFrom-Json

#Create variables for redeployment 
$loc = $import.Location
$vmSize = $import.HardwareProfile.VmSize
$vmName = $import.Name

# Create the vm config
$vm = New-AzVMConfig -VMName $vmName -VMSize $vmSize

# Network profile
$importnicid = $import.NetworkProfile.NetworkInterfaces.Id
$nicname = $importnicid.split("/")[-1]
$nic = Get-AzNetworkInterface -Name $nicname -ResourceGroupName $rgName
$nicId = $nic.Id
$vm = Add-AzVMNetworkInterface -VM $vm -Id $nicId

# OS Disk profile
$osDiskName = $import.StorageProfile.OsDisk.Name

$osDiskVhdUri = $import.StorageProfile.OsDisk.Vhd.Uri
$vm = Set-AzVMOSDisk -VM $vm -VhdUri $osDiskVhdUri -name $osDiskName -CreateOption attach -Windows

# Create the VM
New-AzVM -ResourceGroupName $rgName -Location $loc -VM $vm -Verbose

#endregion Option 1.1

#--------------------------------------------------------
#region UNMANAGED VM Option 1.2 Recreate from PowerShell
#--------------------------------------------------------

# Log in to your subscription 
Connect-AzAccount 
Get-AzSubscription

# Set context
$subId = 'Subscription ID' 
Set-AzContext -SubscriptionID $subId  

# Set up your variables 
$rgName = 'Resource group name'
$vmName = 'Virtual machine name'

$loc = 'Locatoin'
$vmSize = 'VMsize'

$vm = New-AzVMConfig -VMName $vmName -VMSize $vmSize
          
$nic1 = Get-AzNetworkInterface -Name ('NIC1Name') -ResourceGroupName $rgName
$nic1Id = $nic1.Id;

# Uncomment if deploying with Multiple NICs
# $nic2 = Get-AzNetworkInterface -Name ('NIC2Name') -ResourceGroupName $rgName
# $nic2Id = $nic2.Id
          
$vm = Add-AzVMNetworkInterface -VM $vm -Id $nic1Id
# Uncomment if deploying with Multiple NICs
# $vm = Add-AzVMNetworkInterface -VM $vm -Id $nic2Id
          
$osDiskName = 'YourDiskOSName'
$osDiskVhdUri = 'YourDiskOSUri'
          
$vm = Set-AzVMOSDisk -VM $vm -VhdUri $osDiskVhdUri -name $osDiskName -CreateOption attach -Windows
          
New-AzVM -ResourceGroupName $rgName -Location $loc -VM $vm -Verbose

#endregion Option 1.2

#----------------------------------------------
#region MANAGED VM Option 2.1 Import from json
#----------------------------------------------

# Log in to your subscription 
Connect-AzAccount 
Get-AzSubscription

# Set context
$subId = 'Subscription ID' 
Set-AzContext -SubscriptionID $subId  

#Import from json
$json = "$vmName.json"
$import = gc $json -Raw | ConvertFrom-Json

#Create variables for redeployment 
$rgName = $import.ResourceGroupName
$vmName = $import.Name
$vmSize = $import.HardwareProfile.VmSize
$loc = $import.Location

#Create the vm config
$vm = New-AzVMConfig -VMName $vmName -VMSize $vmSize

# Network profile
$importNicId = $import.NetworkProfile.NetworkInterfaces.Id
$nicname = $importNicId.split("/")[-1]
$nic = Get-AzNetworkInterface -Name $nicname -ResourceGroupName $rgName
$nicId = $nic.Id
$vm = Add-AzVMNetworkInterface -VM $vm -Id $nicId

# Storage profile
$osDiskName = $import.StorageProfile.OsDisk.Name
$osManagedDiskId = $import.StorageProfile.OsDisk.ManagedDisk.Id

$vm = Set-AzVMOSDisk -VM $vm -ManagedDiskId $osManagedDiskId -Name $osDiskName -CreateOption attach
$vm.StorageProfile.OsDisk.OsType = $import.StorageProfile.OsDisk.OsType

# Create the VM
New-AzVM -ResourceGroupName $rgName -Location $loc -VM $vm -AsJob
do {Start-Sleep -s 10; echo Waiting...} until ((Get-AzVM -Name $vm.Name -Status).PowerState -eq 'VM running')
Get-AzVM -Name $vm.Name -Status

#endregion Option 2.1

#------------------------------------------------------
#region MANAGED VM Option 2.2 Recreate from PowerShell
#------------------------------------------------------

# Log in to your subscription 
Connect-AzAccount 
Get-AzSubscription

# Set context
$subId = 'Subscription ID' 
Set-AzContext -SubscriptionID $subId  

#Fill in all variables
$subid = 'SubscriptionId'
$rgName = 'ResourceGroupName'
$vmName = "VmName"
$vmSize = "VmSize"
$loc = 'Location'
$nic1Name = 'FirstNetworkInterfaceName'
#$nic2Name = 'SecondNetworkInterfaceName'
$avName = 'AvailabilitySetName'
$osDiskName = 'OsDiskName'
$DataDiskName = 'DataDiskName'
$osType='windows'

#This can be found by selecting the Managed Disks you wish you use in the Azure Portal if the format below does not match
$osDiskResouceId = "/subscriptions/$subid/resourceGroups/$rgName/providers/Microsoft.Compute/disks/$osDiskName";
$dataDiskResourceId = "/subscriptions/$subid/resourceGroups/$rgName/providers/Microsoft.Compute/disks/$DataDiskName";

$vm = New-AzVMConfig -VMName $vmName -VMSize $vmSize;

#Uncomment to add Availabilty Set
#$avSet = Get-AzAvailabilitySet –Name $avName –ResourceGroupName $rgName;
#$vm = New-AzVMConfig -VMName $vmName -VMSize $vmSize -AvailabilitySetId $avSet.Id;

#Get NIC Resource Id and add
$nic1 = Get-AzNetworkInterface -Name $nic1Name -ResourceGroupName $rgName;
$vm = Add-AzVMNetworkInterface -VM $vm -Id $nic1.Id -Primary;

#Uncomment to add a secondary NIC
#$nic2 = Get-AzNetworkInterface -Name $nic2Name -ResourceGroupName $rgName;
#$vm = Add-AzVMNetworkInterface -VM $vm -Id $nic2.Id;

$vm = Set-AzVMOSDisk -VM $vm -ManagedDiskId $osDiskResouceId -name $osDiskName -CreateOption Attach -Windows;
if($osType.ToUpper()=='WINDOWS'){
  $vm.StorageProfile.OsDisk.OsType='Windows'
}else{
  $vm.StorageProfile.OsDisk.OsType='Linux'
}

# Uncomment to add additnal Data Disk
# Add-AzVMDataDisk -VM $vm -ManagedDiskId $dataDiskResourceId -Name $dataDiskName -Caching None -DiskSizeInGB 1023 -Lun 0 -CreateOption Attach;

New-AzVM -ResourceGroupName $rgName -Location $loc -VM $vm -AsJob
do {Start-Sleep -s 10; echo Waiting...} until ((Get-AzVM -Name $vm.Name -Status).PowerState -eq 'VM running')
Get-AzVM -Name $vm.Name -Status

#endregion Option 2.2

#endregion RECREATE THE VM
