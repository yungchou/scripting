Write-Host "
This script is to facilitate the rescue operations for fixing an OS disk of a faulty VM with the steps:
	0) Set operation context.
	1) Delete a faulty VM, while keeping the os disks and export the configuration.
	2) Attach the os disk to a rescue VM. (Here, using a newly created VM for the rescue ops.) 
	3) Fix the OS disk by mitigating the issue.
	4) Recreate a VM based on the original configuration with the fixed OS disk.
" -f darkgreen

############################
# 0) Set operation context.
############################
Connect-AzAccount
#Connect-AzAccount -Environment Azurechinacloud

<#
$context = (Get-AzSubscription | Out-GridView -Title 'Set subscription context' -PassThru)
Set-AzContext -Subscription $context | Out-Null
#>
Set-AzContext -Subscription (
	Get-AzSubscription | Out-GridView -Title 'Set subscription context' -PassThru
) | Out-Null
write-host "Azure context set to the subscription, $((Get-AzContext).Subscription.Name)" -f green

$rgName = (Get-AzResourceGroup `
	| Out-GridView -PassThru -Title 'Select the resource group has the target vm').ResourceGroupName

$vmName = (Get-AzVM -ResourceGroupName $rgName `
	| Out-GridView -PassThru -Title "Select the target vm in hte resource group, $rgName").Name

write-host "Target Azure VM set to $vmName in $rgName resource group" -f green

$templateInJson = "c:\windows\$vmName.json"

# Export the template
($orgVm = Get-AzVM -ResourceGroupName $rgName -Name $vmName) | `
	ConvertTo-Json -depth 100 | `
	Out-file -FilePath $templateInJson

# Get a reference of the disk for later retrieving infomation
$orgOSDisk = Get-AzDisk -ResourceGroupName $rgName -DiskName $osDiskName

##################################################################################
# 1) Delete a faulty VM, while keeping the os disks and export the configuration.
##################################################################################

# Deallocate, then remove the VM;
Stop-AzVM -ResourceGroupName $rgName -Name $vmName
Remove-AzVM -ResourceGroupName $rgName -Name $vmName -Verbose


#############################################################################################
# 2) Attach the os disk to a rescue VM. (Here, using a newly created VM for the rescue ops.) 
#############################################################################################


##############################################
# 3) Fix the OS disk by mitigating the issue.
##############################################


###############################################################################
#	4) Recreate a VM based on the original configuration with the fixed OS disk.
###############################################################################
# import/get-conent from template
$import = gc $templateInJson -Raw | ConvertFrom-Json

# Redeployment settings
$rgName = $import.ResourceGroupName
$loc = $import.Location
$vmSize = $import.HardwareProfile.VmSize
$vmName = $import.Name
 
# Create a vm config
$vm = New-AzVMConfig -VMName $vmName -VMSize $vmSize;
 
# Network profile (NIC)
$importNicId = $import.NetworkProfile.NetworkInterfaces.Id
$nicName = $importNicId.split("/")[-1]
$nic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $rgName;
$nicId = $nic.Id;
$vm = Add-AzVMNetworkInterface -VM $vm -Id $nicId;
 
# OS profile (OS Disk)
$osDiskName = $import.StorageProfile.OsDisk.Name

#$osDiskVhdUri = $orgVm.StorageProfile.OsDisk.Vhd.Uri
$VirtualMachine = Set-AzVMOSDisk -VM $VirtualMachine -ManagedDiskId $disk.Id -CreateOption Attach -Windows


$osType = $orgVm.storageprofile.osdisk.ostype
#$vm = Set-AzVMOSDisk -VM $vm -VhdUri $osDiskVhdUri -name $osDiskName -CreateOption attach -Windows
$vm = iex('
Set-AzVMOSDisk -VM $vm -name $osDiskName `
	-ManagedDiskId "' + $orgOSDisk.Id + '" `
	-CreateOption "attach" `
	-' + $orgOSDisk.OsType
)
 
#create the VM
New-AzVM -ResourceGroupName $rgName -Location $loc -VM $vm -Verbose 
 
