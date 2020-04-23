# Session Start
az login

# CUSTOMIZATION
initial='yc'

# Session Tag
tag=$initial$(date +%M%S)

# Resource Group
rgName=$tag"rg"
region='southcentralus'

az group create -n $rgName --location $region -o table
#az group delete -n $rgName --no-wait -y
az configure --defaults group=$rgName

# CREATE VM
vmName=$tag"vm"
adminID='alice'

#vmImage='ubuntults'
vmImage='win2016datacenter'
#vmImage='win2019datacenter'
vmSize='Standard_B2ms'

# MINIMAL
vmIPAddress=$(
  az vm create \
    -g $rgName \
    -n $vmName \
    -l $region \
    --size $vmSize \
    --image $vmImage \
    --admin-username $adminID \
    --query publicIpAddress \
    -o table
  ); echo "vmIPAddress=$vmIPAddress" 

az vm show \
  -g $rgName \
  -n $vmName \
  -o table

az vm list-vm-resize-options \
  -g $rgName \
  -n $vmName \
  --query "[?contains(name, 'v3')]" \
  -o table


mstsc $vmIPAddress

#  --generate-ssh-keys \

nic=$(
  az vm show \
    -g $rgName \
    -n $vmName \
    --query 'networkProfile.networkInterfaces[].id' \
    --output tsv
  )

az network nic show --ids $nic
# IP and subnet
read -d '' vmIP subnetId <<< $(az network nic show \
  --ids $nic \
  --query '[ipConfigurations[].publicIpAddress.id, ipConfigurations[].subnet.id]' \
  -o tsv); echo -e "vmIP=$vmIP \nsubnetId=$subnetId"

# The output format tsv (tab-separated values) is guaranteed to only 
# include the result data and whitespace consisting of tabs and newlines.

# CUSTOMIZED
vmIPAddress = $(
  az vm create \
    -g $rgName \
    -n $vmName \
    -l $region \
    --size $vmSize \
    --image $vmImage \
    --admin-username $adminID \
    --authentication-type all \
    --os-disk-name $vmName"-OSDisk" \
    --nics $vmName"-nic" \
    --nsg $bmName"-nsg" \
    --nsg-rume $vmName"-access" \
    --public-ip-address-allocation static \
    --vnet-name $rgName"-vnet" \
    --vnet-address-prefix  '10.0.0.0/16' \
    --subnet-name 'one' \
    --subnet-address-prefix '10.0.1.0/24' \
    --boot-diagnostics-storage $rgName"diag" \
    --query publicIpAddress \
    -o table
  ); echo "vmIPAddress=$vmIPAddress" 

ssh $vmIPAddress

#  --generate-ssh-keys \
#  --validate \
# --no-wait

# If to create and attach two 5 GB data disks during vm creation
# --data-disk-sizes-gb 5 5 \

az vm open-port \
  -n $vmName \
  --port 22,3389,80,443 \
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

