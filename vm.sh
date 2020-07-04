# Session Start
az login -o table
az account list -o table

#########################################################

# CUSTOMIZATION
initial='da'

# Session Tag
tag=$initial$(date +%M%S)

# Resource Group
rgName=$tag"rg"
region='southcentralus'

az group create -n $rgName --location $region -o table
: '
az group delete -n $rgName --no-wait -y
az configure --defaults group=$rgName
'

# CREATE VM
vmName=$tag"vm"
adminID='alice'

uImage='ubuntults'
w16Image='win2016datacenter'
w19Image='win2019datacenter'
vmSize='Standard_B2ms'

:'
---------------------------
OPTION 0 - CLOUD-INIT
---------------------------
'
az vm create -n $vmName -g $rgName -l $region --image $uImage \
  --custom-data mySettings.yml

:'  
---------------------------
OPTION 1 - MINIMAL SETTINGS
---------------------------
'
vmPip=$(
  az vm create -g $rgName -n $vmName -l $region --size $vmSize \
    --image $uImage --generate-ssh-keys --authentication-type all \
    --admin-username $adminID \
    --query publicIpAddress\
    -o tsv
  ); echo "vmPip=$vmPip" 

:'
# IP addresses
az vm show -n $vmName -d --query "[{privateIps:privateIps, publicIps:publicIps}]" -o table
vmpip=$(az vm show -n $vmName -d --query publicIps); echo "vmPipi=$vmPip"

mstsc $vmPip
ssh $adminID@$vmPip

az vm list-vm-resize-options \
  -g $rgName \
  -n $vmName \
  --query "[?contains(name, 'v3')]" \
  -o table
'

nic=$(
  az vm show -g $rgName -n $vmName \
    --query 'networkProfile.networkInterfaces[].id' \
    -o tsv
  )

az network nic show --ids $nic
# IP and subnet
read -d '' vmIP subnetId <<< $(az network nic show \
  --ids $nic \
  --query '[ipConfigurations[].publicIpAddress.id, ipConfigurations[].subnet.id]' \
  -o tsv); echo -e "vmIP=$vmIP \nsubnetId=$subnetId"

# The output format tsv (tab-separated values) is guaranteed to only 
# include the result data and whitespace consisting of tabs and newlines.

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
  -g $rgName--nsg-name $nsgName  -n $baseRule \
  --protocol Tcp --access Allow --priority $priority \
  --destination-port-ranges 22 3389 80 443 \
  --description '*** FOR TESTING ONLY, NOT FOR PRODUCTION ***' \
  -o table

# vm deployment - the following settings do not specify nicsaz vm 
StartTime=$(date +%s)

time \
vmpip=$(
  az vm create -g $rgName -n $vmName -l $region --admin-username $adminID \
    --size $vmSize \
    --image $vmImage \
    --os-disk-name $vmName"-OSDisk" \
    --nsg $nsgName \
    --public-ip-address-dns-name $vmName'-pip' --public-ip-address static \
    --vnet-name $rgName"-vnet" \
    --vnet-address-prefix  '10.0.0.0/16' \
    --subnet $rgName"-subnet" \
    --subnet-address-prefix '10.0.1.0/24' \
    --boot-diagnostics-storage $storeName \
    --query publicIpAddress \
    -o tsv
  ); echo "vmpip=$vmpip" 

endTime=$(date +%s)
echo "Elapsed time = $(($endTime - $startTime))"

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

