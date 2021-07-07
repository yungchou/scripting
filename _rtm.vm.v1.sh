:'
This Azure CLI script is for ad hoc deploying customized Azure vms for testing including 
- specified numebrs of vms and 
- optionally a Bastion subnet for RDP/SSH over TLS directly with the Azure portal

To deploy, 
1. Update the CUSTOMIZATION section, as preferred
2. Start an Azure Cloud Session,
   https://docs.microsoft.com/en-us/azure/cloud-shell/overview
3. Set the target subscription, if different form the current one
4. Copy and paste the statements of CUSTOMIZATION and STANDARDIZED ROUTINE  
   to the Azure Cloud Shell session

© 2021 Yung Chou. All Rights Reserved.
'
#---------
# CONTEXT
#---------
:' As needed
az login

# Set subscription
az account list -o table
subName="mySubscriptionName"
az account set -s $subName
'

################
# CUSTOMIZATION
################
prefix='da'

totalVMs=1
vmSize='Standard_B2ms'
region='southcentralus'
//vmSize='Standard_M64Is'
//region='westeurope'
#az vm list-skus --location $region --output table
//bastionSubnet='yes'
bastionSubnet='no'

# osType is a required setting
vmImage='ubuntults'
//vmImage='sles-15-sp1-byos'
osType='linux'
 
#vmImage='win2016datacenter'
#vmImage='win2019datacenter'
#osType='windows'

:' IF INTERACTIVELY
read -p "How many VMs to be deployed?" totalVM
echo "
Password must have the 3 of the following: 
1 lower case character, 1 upper case character, 1 number and 1 special character
"
read -p "Enter the admin id for the $totalVMs VMs to be deployed " adminUser
read -sp "Enter the password for the $totalVMs VMs to be deployed " adminPwd
'
# Never in production
adminID='testuser'
adminPwd='4testingonly!'

totalVM=1
ipAllocationMethod='static'

# Use '' if not to open a service port
ssh=22
rdp=3389
http=80
https=443

#################################
# STANDARDIZED ROUTINE FROM HERE
#################################
echo "
Prepping for deploying:
$totalVMs $osType $vmImage vms in $vmSize size
each with $ipAllocationMethod public IP adderss
and port $ssh $rdp $http $https open
"
#---------
# SESSION 
#---------
tag=$prefix$(date +%M%S)
echo "Session tag = $tag"

rgName=$tag
#echo "Creating the resource group, $rgName..."
az group create -n $rgName -l $region -o table
#az group delete -n $rgName --no-wait -y

# VIRTUAL NETWORK
vnetName=$rgName'-net'
subnetName='1' # 0..254
nsgName=$rgName'-vnet-nsg'
nsgRule=$rgName'-TestOnly'
priority=100

#echo "Creating the vnet, $vnetName..."
az network vnet create -g $rgName -n $vnetName -o none \
  --address-prefixes 10.10.0.0/16 \
  --subnet-name $subnetName --subnet-prefixes "10.10.$subnetName.0/24" 

# Bastion subnet
if [ $(echo $bastionSubnet | tr [a-z] [A-Z]) == 'YES' ]
then
  #echo "Adding the Bastion subnet..."
  az network vnet subnet create --vnet-name $vnetName -g $rgName -o none \
    -n AzureBastionSubnet --address-prefixes 10.10.99.0/24 \
fi

# NSG
#echo "Creating a NSG, $nsgName, associated with the vnet, $vnetName..."
az network nsg create -g $rgName -n $nsgName -o none
#echo "Creating a NSG rule, $nsgRule, associated with the NSG ,$nsgName..."
az network nsg rule create -g $rgName -n $nsgRule \
  --nsg-name $nsgName  --protocol Tcp --access Allow --priority $priority \
  --destination-port-ranges $ssh $rdp $http $https \
  --description '*** FOR TESTING ONLY, NOT FOR PRODUCTION ***' \
  --verbose \
  -o table

# VM
time \
for i in `seq 1 $totalVM`; do

  vmName=$tag'-vm'$i
  echo "Prepping deployment for the vm, $vmName..."

  osDiskName=$vmName'-OSDisk'
  nicName=$vmName'-nic'
  vmIP=$vmName'-ip'

  az network public-ip create -g $rgName -n $vmIP \
    --allocation-method $ipAllocationMethod \
    --verbose \
    -o none
  echo "Allocated the $ipAllocationMethod public IP, $vmIP"

  az network nic create -g $rgName \
    -n $nicName \
    --vnet-name $vnetName \
    --subnet $subnetName \
    --network-security-group $nsgName \
    --public-ip-address $vmIP \
    --verbose \
    -o table
  echo  "Created the $nicName with the $ipAllocationMethod public IP, $vmIP"

  # CREATE VM AND RETURN THE IP
  if [ $(echo $osType | tr [a-z] [A-Z]) == 'LINUX' ]
  then
    echo "Configuring the Linux vm, $vmName, with password access" 
    linuxOnly='--generate-ssh-keys --authentication-type all '
  else
    linuxOnly=''
  fi

  echo "Creating the vm, $vmName now..."
  pubIP=$(
    az vm create -g $rgName -n $vmName -l $region --size $vmSize \
      --admin-username $adminID --admin-password $adminPwd \
      --image $vmImage --os-disk-name $osDiskName \
      $linuxOnly \
      --nics $nicName \
      --query publicIpAddress \
      --verbose \
      -o tsv
  )
  #az vm show -d -g $rgName -n $vmName -o table
  echo  "
  Voilà! The VM, $vmName, has been deployed with the $ipAllocationMethod public IP, $pubIP
  "

done

# Deployed Resources
#az network vnet show -n $vnetName -g $rgName -o table
#az network vnet subnet list --vnet-name $vnetName -g $rgName -o table
#az network nic list -g $rgName -o table
az vm list -g $rgName -o table -d

###########
# Clean up
###########
:' If to clean up deployed resources
az group delete -n $rgName --no-wait -y
'

:'HOLDING PLACE for future improvement
#
# Confirm zone for managed disk and IP address
# https://docs.microsoft.com/en-us/azure/virtual-machines/linux/create-cli-availability-zone#confirm-zone-for-managed-disk-and-ip-address

osDiskName=$(az vm show -g $rgName -n $vmName --query "storageProfile.osDisk.name" -o tsv)
az disk show -g $rgName -n $osDiskName
ipAddressName=$(az vm list-ip-addresses -g $rgName -n $vmName --query "[].virtualMachine.network.publicIpAddresses[].name" -o tsv)
az network public-ip show -g $rgName -n $ipAddressName
'
