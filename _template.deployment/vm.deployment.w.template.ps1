 
# Set the variables:
 
$subscriptionID = "1f0ed1e5-b8ed-4ef8-a9b6-b65ffc80350e"
$rgname = "recreateVM"
$vmname = "recreateVM"
 
# ​​​​Log in and export the JSON file;
Add-AzureRmAccount -Environment Azurechinacloud
Select-AzureRmSubscription -SubscriptionID $subscriptionID
Set-AzureRmContext -SubscriptionID $subscriptionID
Get-AzureRmVM -ResourceGroupName $rgname -Name $vmname | ConvertTo-Json -depth 100 | Out-file -FilePath c:\temp\$vmname.json
 
# Stop deallocate the VM;
Stop-AzureRmVM -ResourceGroupName $rgName -Name $vmName
 
# Remove the VM
Remove-AzureRmVM -ResourceGroupName $rgName -Name $vmName
 
## ++++++++++++++++++++++++++++ ##
 
# Recreate the VM
#import from json
$json = "c:\temp\$vmname.json"
$import = gc $json -Raw | ConvertFrom-Json
 
#create variables for redeployment
$rgname = $import.ResourceGroupName
$loc = $import.Location
$vmsize = $import.HardwareProfile.VmSize
$vmname = $import.Name
 
#create the vm config
$vm = New-AzureRmVMConfig -VMName $vmname -VMSize $vmsize;
 
#network card info
$importnicid = $import.NetworkProfile.NetworkInterfaces.Id
$nicname = $importnicid.split("/")[-1]
$nic = Get-AzureRmNetworkInterface -Name $nicname -ResourceGroupName $rgname;
$nicId = $nic.Id;
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nicId;
 
#OS Disk info
$osDiskName = $import.StorageProfile.OsDisk.Name
$osDiskVhdUri = $import.StorageProfile.OsDisk.Vhd.Uri
$vm = Set-AzureRmVMOSDisk -VM $vm -VhdUri $osDiskVhdUri -name $osDiskName -CreateOption attach -Windows
 
#create the VM
New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $vm -Verbose 
 