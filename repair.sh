:'
PART 1/2
'

# CUSTOM SETTINGS
rgName='??'
brokenVMName='??'
adminId='??'
adminPwd='??'

az login
az account list -o table

# CUSTOMIZATION
initial='yc'

uImage='ubuntults'
w16Image='win2016datacenter'
w19Image='win2019datacenter'
vmSize='Standard_B2ms'

# Latest image
latest=$(az vm image list -p OpenLogic -s 7.3 --all --query     "[?offer=='CentOS'].version" -o tsv | sort -u | tail -n 1)
az vm image show -l westus -f CentOS -p OpenLogic --s 7.3 --version ${latest}

# RESCUE ROUTINE

rescueVMName='RescueVM'
SnapshotDiskName='SnapshotOfBrokenDisk'
newOSDiskName='FixedOSDisk'

# Broken VM details and status
# az vm list -d -o table
az vm list -d -o table --query "[].{Name:name, PublicIps:publicIps,admin:osProfile.adminUsername, PowerState:powerState, ResoureGroup:resourceGroup, Location:location, OSType:storageProfile.osDisk.osType, VMSzie:hardwareProfile.vmSize}"

az vm show -g ${rgName} -n ${brokenVMName} -d -o table

# Deallocate the problematic VM and verify the status
az vm deallocate -g ${rgName} -n ${brokenVMName}
az vm show -g ${rgName} -n ${brokenVMName} -d --query powerState

# Get Name and Id of the Broken disk
brokenDiskId=`az vm show -g ${rgName} -n ${brokenVMName} -o tsv --query "storageProfile.osDisk.managedDisk.id"`
brokenDiskName=`az vm show -g ${rgName} -n ${brokenVMName} -o tsv --query "storageProfile.osDisk.name"`

# Take a snapshot of the Broken VM OS disk
az snapshot create -g ${rgName} -n ${snapshotDiskName} --source ${brokenDiskId}

# List snapshots and get the target Snapshot ID
az snapshot list -o table
snapshotFromBrokenDiskId=`az snapshot show -g ${rgName} -n ${snapshotDiskName} --query "id" -o tsv`

# Create a disk from the snapshot and Get the id of the created disk
az disk create -g ${rgName} -n ${newOSDiskName} --sku Standard_LRS --source ${snapshotFromBrokenDiskId}
newOSDiskID=`az disk show -g ${rgName} -n ${newOSDiskName} --query id -o tsv`

# Create a rescue VM and attach the created disk as DATA
az vm create -n ${rescueVMName} -g ${rgName} --image UbuntuLTS --admin-username ${adminId} --admin-password ${adminPwd} --attach-data-disks ${newOSDiskId}

:'
PART 2/2
Loging into the created rescueVM, become root and mount the partition, troubleshoot from there. When then error is fixed then proceed with the following

az vm show -d --resource-group myResourceGroup --name linuxVM --query publicIps -o tsv
'
#Stop and Deallocate the RescueVM
az vm deallocate -g ${rgName} -n ${rescueVMName}

#Detach the Fixed data disk from the Rescue VM
az vm disk detach -g ${rgName} --vm-name ${rescueVMName} -n ${newOSDiskName}

#Swap the fixed data disk as an OS disk to the Broken VM
az vm update -g ${rgName} -n ${brokenVMName} --os-disk ${newOSDiskId}

#Start the Broken (Now Fixed) VM
az vm start -g ${rgName} -n ${brokenVMName}