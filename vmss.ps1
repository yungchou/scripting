# This script creates a VMSS with Manual Upgrade Policy behind a LB, and an NSG rule that opens port 80

# Define the variables
$RG = "da123" # New RG will be created if it doesn't exist 
$vmssName = "vmss123"
$Location = "southcentralus"
$myVnet = "da123-vnet" # New VNET will be created if it doesn't exist 
$subnet = "default" # New subnet will be created if it doesn't exist 

# No need to modify this part
$PIP = ($vmssName + "-PIP")
$LB = ($vmssName + "-LB")

# Create VMSS
New-AzVmss `
  -ResourceGroupName $RG `
  -Location $Location `
  -VMScaleSetName $vmssName `
  -VirtualNetworkName $myVNet `
  -SubnetName $subnet `
  -PublicIpAddressName $PIP `
  -LoadBalancerName $LB `
  -UpgradePolicyMode "Automatic" 


# Get information about the scale set
$vmss = Get-AzVmss `
  -ResourceGroupName $RG `
  -VMScaleSetName $vmssName
#Create a rule to allow traffic over port 80
$nsgFrontendRule1 = New-AzNetworkSecurityRuleConfig `
  -Name Port_80 `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 200 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 80 `
  -Access Allow

#Create a network security group and associate it with the rule
$nsgFrontend = New-AzNetworkSecurityGroup `
  -ResourceGroupName  $RG `
  -Location $Location `
  -Name ($vmssName + "-NSG") `
  -SecurityRules $nsgFrontendRule1

$vnet = Get-AzVirtualNetwork `
  -ResourceGroupName  $RG `
  -Name $myVnet

$frontendSubnet = $vnet.Subnets[0]

$frontendSubnetConfig = Set-AzVirtualNetworkSubnetConfig `
  -VirtualNetwork $vnet `
  -Name $subnet `
  -AddressPrefix $frontendSubnet.AddressPrefix `
  -NetworkSecurityGroup $nsgFrontend

Set-AzVirtualNetwork -VirtualNetwork $vnet

# Get LB IP for VMSS
Get-AzPublicIPAddress `
  -ResourceGroupName $RG `
  -Name $PIP | select IpAddress