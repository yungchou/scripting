# Session Start
az login -o table
az account list -o table

subName="mySubscriptionName"
az account set -s $subName

#########################################################

# CUSTOMIZATION
initial='da'

# Session Tag
tag=$initial$(date +%M%S)

# Resource Group
rgName=$tag
region='eastus2'

az group create -n $rgName --location $region -o table
: '
az group delete -n $rgName --no-wait -y
az configure --defaults group=$rgName
'

# CREATE VM
adminID='alice'

#vmImage='ubuntults'
vmImage='win2016datacenter'
#vmImage='win2019datacenter'

#vmSize='Standard_B2ms'
vmSize='Standard_D16_v3'
#vmSize='Standard_E20ds_v4'

:'
------------------------------
OPTION 2 - CUSTIMIZED SETTINGS
------------------------------
'
# storage account (for diagnostics)
storeName=$rgName"store"

az storage account create -g $rgName -n $storeName -l $region \
  --sku Standard_LRS \
  -o table

# NSG group
nsgName=$rgName"-nsg"
az network nsg create -g $rgName -n $nsgName -o table

# remote access rule
baseRule=$rgName"-TestOnly"
priority=100

az network nsg rule create \
  -g $rgName --nsg-name $nsgName  -n $baseRule \
  --protocol Tcp --access Allow --priority $priority \
  --destination-port-ranges 22 3389 80 443 \
  --description '*** FOR TESTING ONLY, NOT FOR PRODUCTION ***' \
  -o table

vnetName=$rgName'-net'
subnetName='one'
vmIP=$vmName'-pip'
vmNicName=$vmName'-nic'

# Repeat for deploying multiple VMs

vmName=$tag"-vm1"
#vmName=$tag"-vm2"
#vmName=$tag"-vm3" 

az network nic create -g $rgName \
  -n $vmNicName \
  --vnet-name $vnetName \
  --subnet $subnetName \
  --network-security-group $nsgName \
  --public-ip-address $vmIP \
  -o table

vmpip=$(
  az vm create -g $rgName -n $vmName -l $region --admin-username $adminID \
    --size $vmSize \
    --image $vmImage \
    --os-disk-name $vmName"-OS-Disk" \
    --nsg $nsgName \
    --public-ip-address-dns-name $vmIP --public-ip-address static \
    --vnet-name $vnetName \
    --vnet-address-prefix  '10.0.0.0/16' \
    --subnet $subnetName \
    --subnet-address-prefix '10.0.1.0/24' \
    --boot-diagnostics-storage $storeName \
    --query publicIpAddress \
    -o tsv
  ); echo "vmpip=$vmpip" 


# Applicable only to Linux, either ssh, password, or all
#    --authentication-type all --generate-ssh-keys \
#    --validate \

# If to create and attach two 5 GB data disks during vm creation
# --data-disk-sizes-gb 5 5 \

# IP addresses
az vm show -n $vmName -d --query "[{privateIps:privateIps, publicIps:publicIps}]" -o table
vmpip=$(az vm show -n $vmName -d --query publicIps); echo "vmpipi=$vmpip"
mstsc $vmpip

az vm open-port \
  -n $vmName \
  --port 22 3389 80 443 \
  --nsg-name $vmName"-NSG" \
  --priority 100 \
  -o table


# Wait for the VMs to be provisioned
while [[ $(az vm list -g $rgName --query "length([?provisioningState=='Succeeded'])") != 3 ]]; do
    echo "The VMs are still not provisioned. Trying again in 20 seconds."
    sleep 20
    if [[ $(az vm list -g $rgName --query "length([?provisioningState=='Failed'])") != 0 ]]; then
        echo "At least one of the VMs failed to be provisioned."
        exit 1
    fi
done
echo "The VMs are provisioned."


# ATTACH DISK TO AN EXISTING VM
diskName='mydatadisk'
diskSize=128

snapshotName=$vmName"snap"

az vm disk attach \
  -g $rgName \
  --vm-name $vmName \
  --name $vmOSDisk \
  --size-gb $diskSize \
  --sku Premium_LRS \
  --new \
  -o table

# CREATE SNAPSHOT
osdiskid=$(az vm show \
   -g $rgName \
   -n $vmName \
   --query "storageProfile.osDisk.managedDisk.id" \
   -o table)

# determine the $osdiskid here
az snapshot create \
  -g $rgName \
  --name $vmName"-snapshot" \
  --source "$osdiskid" \
  -o table

# CREATE DISK FROM SNAPSHOT
az disk create \
  -g $rgName \
  --name $snapshotName \
  --source osDisk-backup \
  -o table

# RESTORE VM FROM SNAPSHOT
az vm delete \
  -g $rgName \
  -n $vmName \
  -o table

az vm create \
  -g $rgName \
  -n $vmName \
  --attach-os-disk $snapshotName \
  --os-type linux \
  -o table

# REATTACH DATA DISK
datadisk=$(az disk list \
   -g myResourceGroupDisk \
   --query "[?contains(name,'myVM')].[id]" \
   -o tsv)

 az vm disk attach \
   –g $rgName \
   --vm-name $vmName \
   --name $datadisk \
   -o table

# CLEAN UP
az group delete -g $rgName -y --no-wait

az logout

