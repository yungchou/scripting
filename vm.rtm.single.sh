#!/bin/bash

# Session Start
az login
az account list -o table
az account set -s <Subscription ID or name>

################
# CUSTOMIZATION
################
prefix='da'

ubuntu='ubuntults'
w16='win2016datacenter'
w19='win2019datacenter'

# Specify which OS to deploy
vmImage=$ubuntu
osType='linux'
linuxOnly='--generate-ssh-keys --authentication-type all '
:'
vmImage=$w16
osType='windows'
linuxOnly=''
'

vmSize='Standard_B2ms'
adminID='alice'
ipAllocationMethod='static'

# Use '' if not to open a port
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
region='southcentralus'

vmName=$tag'-vm'
vmSize=$vmSize

nicName=$vmName'-nic'
vnetName=$rgName'-vnet'
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
vmPip=$(
  az vm create -g $rgName -n $vmName -l $region --admin-username $adminID \
    --image $vmImage --os-disk-name $tag'-OSDisk' \
    $linuxOnly \
    --nics $nicName \
    --query publicIpAddress \
    -o tsv
)
#az vm show -d -g $rgName -n $vmName -o table

echo VM, $vmName, deployed with the public IP, $vmPip
az network nic list-effective-nsg -g $rgName -n $nicName -o table

:' Holding place

az vm open-port -g $rgName -n $vmName \
  --nsg-name $nsgName \
  --priority $priority \
  --port ?? \
  -o table

az group delete -n $rgName --no-wait -y

'
