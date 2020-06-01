#!/bin/bash

# Session Start
az login
az account list -o table

# CUSTOMIZATION
prefix='da'

ubuntu='ubuntults'
w16='win2016datacenter'
w19='win2019datacenter'

# Specify which OS to deploy
vmImage=$w16
osType='windows'
vmSize='Standard_B2ms'
adminID="alice"

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

vmName=$tag'vm'
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

az network vnet create -g $rgName -n $vnetName --subnet-name $subnetName

az network public-ip create -g $rgName -n $vmIP

az network nsg create -g $rgName -n $nsgName

if [ $(echo $osType | [a-z] [A-Z])=='LINUX' ] 
then 
  linuxOnly='--generate-ssh-keys --authentication-type all \'
  if [$ssh==''] then ssh=22  fi # set default to open port 22 for ssh
else # OSType is windows 
  linuxOnly=''
  if [$rdp==''] then rdp=3389 fi # set default to open port 3389 for rdp
fi

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
  az vm create -g '$rgName' -n '$vmName' -l '$region'  --admin-username '$adminID' \
    --image '$vmImage' --os-disk-name '$tag'-OSDisk \
   '$linuxOnly'
    --nics $nicName --nsg '$nsgName' \
    --public-ip-address-dns-name '$vmName'-pip --public-ip-address static \
    --query publicIpAddress \
    -o tsv
  )

az vm create -g $rgName -n $vmName -l $region  --admin-username $adminID \
  --image $vmImage --os-disk-name 'OsDisk'$tag \
  --generate-ssh-keys --authentication-type all \
  --nics $nicName --nsg $nsgName \
  --public-ip-address-dns-name $vmName'-pip' --public-ip-address static \
  --query publicIpAddress \
  -o tsv


  


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
