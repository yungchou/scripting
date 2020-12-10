
$vmName = 'w19'
$rgName = 'zulu-vm'

$SourceVmObject = get-azvm -Name $vmName -ResourceGroupName $rgName

#-----------------------
# Remove recovery point
#-----------------------
$LoopCondition = $false
$Count = 0
do { 
  try {
    Remove-AzResource -ResourceId $SourceVmRecoveryPoint.ResourceId -Force
    $LoopCondition = $true
  }
  catch {
    write-debug "Fail to delete recovery point $($SourceVmRecoveryPoint.Name) after $($Count) attentds"
  }
  $count += 1 
  if ($count -gt 5) { 
    $LoopCondition = $true
  }
} until ($LoopCondition)

# Deallocate the VM
$SourceVmPowerStatus = (get-azvm `
    -Name $SourceVmObject.Name `
    -ResourceGroupName $SourceVmObject.ResourceGroupName -Status).Statuses `
| where-object code -like "PowerState*" if ($SourceVmPowerStatus -ne "VM deallocated") {
  stop-azVm `
    -Name $SourceVmObject.Name `
    -ResourceGroupName $SourceVmObject.ResourceGroupName `
    -Force 
  Start-Sleep -Seconds 30
}

$vmNewName = "newVMName"
$NewVmObject = New-AzVMConfig -VMName $vmNewName -VMSize $SourceVmObject.HardwareProfile.VmSize 

# Now simply create a vm

