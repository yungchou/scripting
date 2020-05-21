<#
	1) Delete the VM, but keep the disks.
	2) Attach the os disk of broken vm to temp VM.
	3) Mitigate the issue.
	3) Recreate the VM.

#>

# Set the variables:
 
$subscriptionId = '??'

$rgName = "recreateVM"
$vmName = "recreateVM"
 
# ​​​​Log in and export the JSON file;
Connect-AzAccount
#Connect-AzAccount -Environment Azurechinacloud

Select-AzSubscription -SubscriptionID $subscriptionId
Set-AzContext -SubscriptionID $subscriptionId
Get-AzVM -ResourceGroupName $rgName -Name $vmName |ConvertTo-Json -depth 100|Out-file -FilePath c:\temp\$vmName.json
 
# Stop deallocate the VM;
Stop-AzVM -ResourceGroupName $rgName -Name $vmName
 
# Remove the VM
Remove-AzVM -ResourceGroupName $rgName -Name $vmName
 
## ++++++++++++++++++++++++++++ ##
 
# Recreate the VM
#import from json
$json = "c:\temp\$vmName.json"
$import = gc $json -Raw|ConvertFrom-Json
 
#create variables for redeployment
$rgName = $import.ResourceGroupName
$loc = $import.Location
$vmSize = $import.HardwareProfile.VmSize
$vmName = $import.Name
 
#create the vm config
$vm = New-AzVMConfig -VMName $vmName -VMSize $vmSize;
 
#network card info
$importNicId = $import.NetworkProfile.NetworkInterfaces.Id
$nicName = $importNicId.split("/")[-1]
$nic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $rgName;
$nicId = $nic.Id;
$vm = Add-AzVMNetworkInterface -VM $vm -Id $nicId;
 
#OS Disk info
$osDiskName = $import.StorageProfile.OsDisk.Name
$osDiskVhdUri = $import.StorageProfile.OsDisk.Vhd.Uri
$vm = Set-AzVMOSDisk -VM $vm -VhdUri $osDiskVhdUri -name $osDiskName -CreateOption attach -Windows
 
#create the VM
New-AzVM -ResourceGroupName $rgName -Location $loc -VM $vm -Verbose 
 
