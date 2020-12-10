# Get the current model of the scale set and store it in a local PowerShell object named $vmss
$vmss = Get-AzVmss -ResourceGroupName "<RG Name>" -Name "<VMSS Name>"
    
# Get the current model of the scale set instance and store it in a local PowerShell object named $vmssvm
$vmssvm = Get-AzVmssVM -ResourceGroupName "<RG Name>" -Name "<VMSS Name>" -InstanceId <instance id number>
        
# Enabling: Create a local PowerShell object for the new desired IP configuration, which removes the BackendAddressPool and kept other current settings
$ipconf = New-AzVmssIPConfig "myNic" `
  -LoadBalancerBackendAddressPool $null `
  -SubnetId $vmss.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].Subnet.Id `
  –Name $vmss.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].Name `
  -LoadBalancerInboundNatPoolsId $vmss.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].LoadBalancerInboundNatPools[0].Id
  
#If the VMSS has multiple NatPool, use following format: -LoadBalancerInboundNatPoolsId @($vmss.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].LoadBalancerInboundNatPools[0].id, $vmss.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].LoadBalancerInboundNatPools[1].id, $vmss.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].LoadBalancerInboundNatPools[2].id )
