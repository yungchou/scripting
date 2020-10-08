<#
How to upgrade ADE extension on Win/Linux VM and VMSS
https://gist.github.com/emmajdong/d3557f8f87a57afcab9026b150161da8

ADE with AAD, i.e. Dual Pass, NO ACTION is required

Extension versions impacted:
Windows: Version 2.2.0.0 to Version 2.2.0.34
Linux: Version 1.1.0.0 to Version 1.1.0.51

Once updated, the ADE extension should be:
Windows: Version 2.2.0.35 and greater
Linux: Version 1.1.0.52 and greater
#>

#----
# VM
#----
$vmRgName = '??'
$vmName = '??'

# Restart all vms in a resource group

Get-AzVM -ResourceGroupName $vmRgName | Select Name | ForEach-Object {

  # Verify the current version
  Get-AzVMExtension -ResourceGroupName $vmRgName -VMName $vmName 

  Write-Host "Restarting virtual machine: $_.Name"
  Restart-AzVM -ResourceGroupName $vmRgName -Name $_.Name

  # Verify the current version
  Get-AzVMExtension -ResourceGroupName $vmRgName -VMName $vmName

}

# Restart a list of vms in a resource group

$vmList = @("vmName1", "vmName2", "vmName3")
foreach ($vmName in $vmList) {    
  # Verify the current version
  Get-AzVMExtension -ResourceGroupName $vmRgName -VMName $vmName 

  Write-Host "Restarting virtual machine: $vmName"
  Restart-AzVM -ResourceGroupName $vmRgName -Name $vmName -Verbose

  # Verify the current version
  Get-AzVMExtension -ResourceGroupName $vmRgName -VMName $vmName 

}

#------
# VMSS
#------
vmssRgName='??'
$vmssName = '??'

# Verify the current version
Get-AzVMSS -ResourceGroupName $vmssRgName - VMScaleSetName $vmssName

# VMSS Upgrade Policy
$vmss = Get-AzVMSS -ResourceGroupName $vmssRgName - VMScaleSetName $vmssName

$vmss = Get-AzVMSS -ResourceGroupName $vmssRgName - VMScaleSetName $vmssName
Update-AzVMSS -ResourceGroupName $vmssRgame -Name $vmssName -VirtualMachineScaleSet $vmss

# Verify the current version
Get-AzVMSS -ResourceGroupName $vmssRgName - VMScaleSetName $vmssName
<#
Once updated, the ADE extension should be:
Windows: Version 2.2.0.35 and greater
Linux: Version 1.1.0.52 and greater
#>
