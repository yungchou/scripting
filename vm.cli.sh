#!/bin/bash

# Session Start
az login
az account list -o table

# CUSTOMIZATION
initial='yc'

# Session Tag
tag=$initial$(date +%M%S)

rgName=$tag"rg"
region='southcentralus'

vmName=$tag"vm"
adminID='alice'

uImage='ubuntults'
w16Image='win2016datacenter'
w19Image='win2019datacenter'
vmSize='Standard_B2ms'

nicName=$vmName'-nic'
vnetName=$rgName'-vnet'
subnetName='sub1'
nsgName=$rgName'-vnet-nsg'
nsgRule=$rgName"-TestOnly"
vmIP=$vmName'-ip'
priority=100
ssh=22
rdp=3389
http=80
https=443

az group create -n $rgName -l $region -o table

az network vnet create -g $rgName -n $vnetName --subnet-name $subnetName -o table

az network public-ip create -g $rgName -n $vmIP -o table

az network nsg create -g $rgName -n $nsgName -o table

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

az vm create -g $rgName -n $vmName \
  --image $uImage \
  --size $vmSize \
  --admin-username $adminID \
  --nics $nicName \
  --generate-ssh-keys \
  --authentication-type all \
  -o table

az vm show -d -g $rgName -n $vmName -o table
az network nic list-effective-nsg -g $rgName -n$nicName -o table

:' Holding place

az vm open-port -g $rgName -n $vmName \
  --nsg-name $nsgName \
  --priority $priority \
  --port ?? \
  -o table

az group delete -n $rgName --no-wait -y

'
