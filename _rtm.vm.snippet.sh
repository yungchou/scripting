:'
This script is intended to be executed manually by 
copying and pasting selected statements to cloud shell.
'
#---------------
# CUSTOMIZATION
#---------------
initial='da'
region='southcentralus'

vmSize='Standard_B2ms'
vmImage='ubuntults'
osType='linux'

#--------------
# SESSION INFO
#--------------
tag=$initial$(date +%M%S)

:' As needed
az login
az logout
'

#----------------
# Resource Group
#----------------
rgName=$tag
az group create -n $rgName --location $region -o table

:'To clean up
az group delete -g $rgName -y --no-wait
'
#----------- 
# CREATE VM
#-----------
vmName=$tag'-vm'
vmOSDisk=$vmName'-OSDisk'

az vm create -g $rgName -n $vmName -l $region \
  --size $vmSize \
  --image $vmImage \
  --os-disk-name $vmOSDisk \
  --authentication-type all \
  --generate-ssh-keys \
  --no-wait

# If to create and attach two 4 GB data disks during vm creation
# --data-disk-sizes-gb 4 4 \

:'
# Wait for the VMs to be provisioned
az vm list -g $rgName --query [].provisioningState -o tsv

# if 3 items to be provisions
while [[ $(az vm list -g $rgName --query "length([?provisioningState=='Succeeded'])") != 3 ]]; do
    echo "The VMs are still not provisioned. Trying again in 20 seconds."
    sleep 20
    if [[ $(az vm list -g $rgName --query "length([?provisioningState=='Failed'])") != 0 ]]; then
        echo "At least one of the VMs failed to be provisioned."
        exit 1
    fi
done
echo 'The VMs are provisioned.'

'

#-------------------------------
# ATTACH DISK TO AN EXISTING VM
#-------------------------------
dataDiskName='mydatadisk'
diskSize=4

az vm disk attach -g $rgName -n $dataDiskName \
  --vm-name $vmName \
  --size-gb $diskSize \
  --sku Premium_LRS \
  --new 

#-----------------
# CREATE SNAPSHOT
#-----------------
osDiskName=$(az vm show \
  -g $rgName -n $vmName \
  --query storageProfile.osDisk.name \
  -o tsv)

#storageProfile.osDisk.managedDisk.id

snapshotName=$osDiskName'-snapshot'

# determine the $osdiskid here
az snapshot create \
  -g $rgName -n $snapshotName \
  --source $osDiskName \
  -o table

#---------------------------
# CREATE DISK FROM SNAPSHOT
#---------------------------
backupDisk=$vmOSDisk'-backup'
az disk create \
  -g $rgName -n $backupDisk \
  --source $snapshotName \
  -o table

#--------------------------
# RESTORE VM FROM SNAPSHOT
#--------------------------
az vm delete -g $rgName -n $vmName -o table

az vm create -g $rgName -n $vmName \
  --attach-os-disk $backupDisk \
  --os-type $osType \
  -o table

#--------------------
# REATTACH DATA DISK
#--------------------
az disk list -g $rgName -o table
az disk list -g $rgName \
   --query "[contains([].name,$vmName)]" \
   -o table

dataDiskName='mydatadisk'
az disk show -g $rgName -n $dataDiskName --query id

az vm disk attach -n $dataDiskName -g $rgName \
   --vm-name $vmName
