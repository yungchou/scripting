# CUSTOMIZATION
initial='yc'

# Session Start
az login

# Session Tag
tag=$initial$(date +%M%S)

# Resource Group
rgName=$tag"rg"
az group create -n $rgName --location $region -o table
 
# CREATE VM
vmName=$tag"vm"
region='southcentralus'
vmImage='ubuntults'
vmSize='Standard_DS2_v2'
vmOSDisk=$vmName"OSDisk"
snapshotName=$vmName"snap"

az vm create \
  -g $rgName \
  -n $vmName \
  -l $region \
  --size $vmSize \
  --image $vmImage \
  --os-disk-name $vmOSDisk \
  --authentication-type \
  --generate-ssh-keys \
  -o table

# If to create and attach two 5 GB data disks during vm creation
# --data-disk-sizes-gb 5 5 \

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

