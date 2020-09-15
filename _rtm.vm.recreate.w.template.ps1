#-----------------
# Recreating a VM
#----------------- 

# Set context
Connect-AzAccount 
Get-AzSubscription

$subId = 'Subscription ID' 
Set-AzContext -SubscriptionID $subId 

#---------------------
# Export the template
#---------------------
$rgName = 'zulu-vm'
$vmName = 'w16'
#$template = "$pwd/$vmName.json"   # cloud shell
$template = "$vmName.json"

Get-AzVM -ResourceGroupName $rgName -Name $vmName `
| ConvertTo-Json -depth 100 `
| Out-file -FilePath $template
 
# Deallocate and remove the VM 
Stop-AzVM -ResourceGroupName $rgName -Name $vmName -Force -AsJob
do { Start-Sleep -s 15; echo Waiting... } 
until ((Get-AzVM -Name $vmName -Status).PowerState -eq 'VM deallocated')
Get-AzVM -Name $vmName -Status

Remove-AzVM -ResourceGroupName $rgName -Name $vmName -Force -AsJob

#-----------------
# Recreate the VM
#-----------------
# import the template
$import = gc $template -Raw | ConvertFrom-Json
 
# restore deployment settings
$rgName = $import.ResourceGroupName
$loc = $import.Location
$vmsize = $import.HardwareProfile.VmSize
$vmName = $import.Name
 
#create the vm config
$vm = New-AzVMConfig -VMName $vmName -VMSize $vmsize;
 
# network profile
$importNicId = $import.NetworkProfile.NetworkInterfaces.Id
$nicName = $importNicId.split("/")[-1]
$nic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $rgName;
$nicId = $nic.Id;
$vm = Add-AzVMNetworkInterface -VM $vm -Id $nicId;
 
# OS profile
$osDiskName = $import.StorageProfile.OsDisk.Name

# ????
# New-AzVM: This operation is not supported for a relative URI.
$osDiskVhdUri = $import.StorageProfile.OsDisk.vhd.Id

$vm = Set-AzVMOSDisk -VM $vm -VhdUri $osDiskVhdUri -name $osDiskName -CreateOption attach -Windows
 
#create the VM
New-AzVM -ResourceGroupName $rgName -Location $loc -VM $vm -Verbose
do { Start-Sleep -s 30; echo Waiting... } 
until ((Get-AzVM -Name $vmName -Status).PowerState -eq 'Running')
Get-AzVM -Name $vm.Name -Status

 
