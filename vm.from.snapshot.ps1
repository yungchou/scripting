#region [CREATE VM FROM SNAPSHOT]
 
Write-host "
------------------------------------------------------------
 
This script is based on the following reference and for 
learning Azure and PowerShell. I have made changes to the 
original scrtip for clarity and portability.
 
Ref: Create a virtual machine from a snapshot with PowerShell
https://docs.microsoft.com/en-us/azure/virtual-machines/scripts/virtual-machines-windows-powershell-sample-create-vm-from-snapshot
 
Assuming a snapshot is in place, to test the script simply 
validate the customization part, followed by manually running
the script statement by statement in cloud shell.
Upon completing the deployment, stopwatch will display the 
deployment statistics. 
 
© 2020 Yung Chou. All Rights Reserved.
 
------------------------------------------------------------
"
 
#region [Customization]
 
#region [Needed only if an account owns multiple subscriptions]
 
Get-AzSubscription | Out-GridView  # Copy the target subscription name
 
# Set the context for subsequent operations
$context = (Get-AzSubscription | Out-GridView -Title 'Set subscription context' -PassThru)
Set-AzContext -Subscription $context | Out-Null
write-host "Azure context set for the subscription, `n$((Get-AzContext).Name)" -f green
 
#endregion
 
$snapshotName   = 'mySnapshot'
$snapshotRgName = 'mySnapshotRgName'
 
#endregion [Customization]
 
#region [Deployment Preping]
 
$tag = get-date -format 'mmss'
 
$vmRgName       = "vm-$tag"
$vmName         = "vm-$tag"
$vmSize         = 'Standard_B2ms'
$vmOsDiskName   = "osDisk-$tag"
$rdpPort        = 3389
 
$vnetName       = "vnet-$tag"
$vnetAddSpace   = '192.168.0.0/16'
$subnetAddSpace = '192.168.1.0/24'
 
($snapshot = Get-AzSnapshot `
    -ResourceGroupName $snapshotRgName `
    -SnapshotName $snapshotName)
 
$loc = $snapshot.Location
 
if (($existingRG = (Get-AzResourceGroup | Where {$_.ResourceGroupName -eq $vmRgName})) -eq $Null) { 
    write-host "Resource group, $vmRgName, not found, creating it" -f y
    New-AzResourceGroup -Name $vmRgName -Location $loc
} else {
    write-host "Using this resource group, $vmRgName, for the vm, $vmName" -f y
}
# Remove-AzResourceGroup -Name $vmRgName -AsJob
 
# Create a subnet configuration
$subnetConfig = `
New-AzVirtualNetworkSubnetConfig `
    -Name 'default' `
    -AddressPrefix $subnetAddSpace `
    -WarningAction 'SilentlyContinue'
 
# Create a virtual network
$vnet = `
New-AzVirtualNetwork `
    -ResourceGroupName $vmRgName `
    -Location $loc `
    -Name "$vmRgName-vnet" `
    -AddressPrefix $vnetAddSpace `
    -Subnet $subnetConfig
 
# Create a public IP address and specify a DNS name
$pip = `
New-AzPublicIpAddress `
    -ResourceGroupName $vmRgName `
    -Location $loc `
    -Name "$vmName-pip" `
    -AllocationMethod Static `
    -IdleTimeoutInMinutes 4
 
# Create an inbound network security group rule for port 3389
$nsgRuleRDP = `
New-AzNetworkSecurityRuleConfig `
    -Name "$vmName-rdp"  `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 1000 `
    -SourceAddressPrefix * `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange $rdpPort `
    -Access Allow
 
# Create an inbound network security group rule for port 80,443
$nsgRuleHTTP = `
New-AzNetworkSecurityRuleConfig `
    -Name "$vmName-http"  -Protocol Tcp `
    -Direction Inbound `
    -Priority 1010 `
    -SourceAddressPrefix * `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 80,443 `
    -Access Allow
 
$nsg= `
New-AzNetworkSecurityGroup `
    -ResourceGroupName $vmRgName `
    -Location $loc `
    -Name "$vmName-nsg" `
    -SecurityRules $nsgRuleRDP, $nsgRuleHTTP `
    -Force
 
# Create a virtual network card and associate with public IP address and NSG
$nic = `
New-AzNetworkInterface `
    -Name "$vmName-nic" `
    -ResourceGroupName $vmRgName `
    -Location $loc `
    -SubnetId $vnet.Subnets[0].Id `
    -PublicIpAddressId $pip.Id `
    -NetworkSecurityGroupId $nsg.Id
 
$vmConfig = `
New-AzVMConfig `
    -VMName $vmName `
    -VMSize $vmSize `
| Add-AzVMNetworkInterface `
    -Id $nic.Id 
 
$diskConfig = New-AzDiskConfig `
    -Location $snapshot.Location `
    -SourceResourceId $snapshot.Id `
    -CreateOption Copy
 
$disk = New-AzDisk `
    -Disk $diskConfig `
    -ResourceGroupName $vmRgName `
    -DiskName $vmOsDiskName
 
$vmConfig = Set-AzVMOSDisk `
    -VM $vmConfig `
    -ManagedDiskId $disk.Id `
    -CreateOption Attach `
    -Windows
 
#endregion
 
#region [Deploying]
 
$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch; $stopwatch.start()
write-host "`nDeploying the vm, $vmName, to $loc...`n" -f y
 
$vmStatus = `
New-AzVM `
    -ResourceGroupName $vmRgName `
    -Location $loc `
    -VM       $vmConfig `
    -WarningAction 'SilentlyContinue' `
    -Verbose
 
Set-AzVMBgInfoExtension `
    -ResourceGroupName $vmRgName `
    -VMName $vmName `
    -Name 'bginfo' `
    -Verbose
 
write-host '[Deployment Elapsed Time]' -f y
$stopwatch.stop(); $stopwatch.elapsed
 
#endregion
 
#region [Clean up]
# Remove-AzResourceGroup -Name $vmRgName -Force -AsJob 
#endregion
 
#endregion