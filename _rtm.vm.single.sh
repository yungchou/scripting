#!/bin/bash

# Session Start
az login
az account list -o table
az account set -s <Subscription ID or name>

################
# CUSTOMIZATION
################
prefix='da'

vmImage='ubuntults'
#vmImage='win2016datacenter'
#vmImage='win2019datacenter'

# Required setting
osType='linux' 
#osType='windows'

region='southcentralus'
#az vm list-skus --location $region --output table
vmSize='Standard_B2ms'

adminID='alice'
ipAllocationMethod='static'

# Use '' if not to open a service port
ssh=22
rdp=3389
http=80
https=443

##########################
#  DO NOT CHANGE BELOW 
##########################

# Session Tag
tag=$prefix$(date +%M%S)

rgName=$tag

vmName=$tag'-vm'
vmSize=$vmSize

nicName=$vmName'-nic'
vnetName=$rgName'-net'
subnetName='sub1'
nsgName=$rgName'-vnet-nsg'
nsgRule=$rgName'-TestOnly'
vmIP=$vmName'-ip'
priority=100

az group create -n $rgName -l $region -o table
#az group delete -n $rgName --no-wait -y

az network vnet create -g $rgName -n $vnetName --subnet-name $subnetName -o none

az network public-ip create -g $rgName -n $vmIP -o none --allocation-method $ipAllocationMethod

az network nsg create -g $rgName -n $nsgName -o none

az network nsg rule create -g $rgName \
  --nsg-name $nsgName \
  -n $nsgRule \
  --protocol Tcp \
  --access Allow \
  --priority $priority \
  --destination-port-ranges $ssh $rdp $http $https \
  --description '*** FOR TESTING ONLY, NOT FOR PRODUCTION ***' \
  -o table

az network nic create -g $rgName \
  -n $nicName \
  --vnet-name $vnetName \
  --subnet $subnetName \
  --network-security-group $nsgName \
  --public-ip-address $vmIP \
  -o table

az network nic list -g $rgName -o table

# CREATE VM AND RETURN THE IP
if [ $(echo $osType | tr [a-z] [A-Z]) == 'LINUX' ]
then
  echo "Setting the Linux vm, $vmName, with password access" 
  linuxOnly='--generate-ssh-keys --authentication-type all '
else
  linuxOnly=''
fi

vmPip=$(
  az vm create -g $rgName -n $vmName -l $region --admin-username $adminID \
    --image $vmImage --os-disk-name $tag'-OSDisk' \
    $linuxOnly \
    --nics $nicName \
    --query publicIpAddress \
    -o tsv
)
#az vm show -d -g $rgName -n $vmName -o table

# CREATE VM AND RETURN THE IP
if [ $(echo $osType | tr [a-z] [A-Z]) == 'LINUX' ]
then
  echo "Customizing desktop and RDP for the vm, $vmName..." 
  storageContainer='https://zulustore.blob.core.windows.net/dnd'
  theScript='ubuntu.desktop.sh'
  time \
  az vm extension set \
    --name CustomScriptForLinux \
    --publisher Microsoft.OSTCExtensions \
    --resource-group $rgName \
    --vm-name $vmName \
    --protected-settings '{
      "storageAccountName": "zulustore",
      "storageAccountKey": "<storage-account-key>",
      "commandToExecute": "./$theScript"
      }' \
    --settings '{"fileUris":["$storageContainer/$theScript"]}' \
    -o table
  az vm get-instance-view -g $rgName -n $vmName \
    --query "instanceView.extensions"
fi

echo  "Voilà VM, $vmName, deployed with the public IP, $vmPip"
az network nic list-effective-nsg -g $rgName -n $nicName -o table

:' Holding place

az vm open-port -g $rgName -n $vmName \
  --nsg-name $nsgName \
  --priority $priority \
  --port ?? \
  -o table

az group delete -n $rgName --no-wait -y

'

# Confirm zone for managed disk and IP address
# https://docs.microsoft.com/en-us/azure/virtual-machines/linux/create-cli-availability-zone#confirm-zone-for-managed-disk-and-ip-address
osDiskName=$(az vm show -g $rgName -n $vmName --query "storageProfile.osDisk.name" -o tsv)
az disk show -g $rgName -n $osDiskName
ipAddressName=$(az vm list-ip-addresses -g $rgName -n $vmName --query "[].virtualMachine.network.publicIpAddresses[].name" -o tsv)
az network public-ip show -g $rgName -n $ipAddressName
