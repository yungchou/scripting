:'
This script is intended to be executed manually by 
copying and pasting selected statements to cloud shell.
'
#---------------
# CUSTOMIZATION
#---------------
prefix='da'

region='southcentralus'
vmSize='Standard_B2ms'

#vmImage='ubuntults'
#osType='linux'
vmImage='win2019datacenter'
osType='windows'

:' IF INTERACTIVELY
read -p "How many VMs to be deployed?" totalVM
echo "
Password must have the 3 of the following: 
1 lower case character, 1 upper case character, 1 number and 1 special character
"
read -p "Enter the admin id for the $totalVMs VMs to be deployed " adminUser
read -sp "Enter the password for the $totalVMs VMs to be deployed " adminPwd
'
# For testing
adminID='hendrix'
adminPwd='4testingonly!'

totalVM=4
ipAllocationMethod='static'

#---------
# CONTEXT
#---------
:' As needed
az login

az account list -o table
subName="mySubscriptionName"
az account set -s $subName
'
#---------
# SESSION 
#---------
tag=$prefix$(date +%M%S)
echo "Session tag = $tag"

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
time \
for i in `seq 1 $totalVM`; do

  vmName=$tag'-vm'$i
  echo "Prepping deployment for the vm, $vmName..."

  osDiskName=$vmName'OSDisk'

  # CREATE VM AND RETURN THE IP
  if [ $(echo $osType | tr [a-z] [A-Z]) == 'LINUX' ]
  then
    echo "Configuring the Linux vm, $vmName, with password access" 
    linuxOnly='--generate-ssh-keys --authentication-type all '
  else
    linuxOnly=''
  fi

:' 
----------------
METHOD 1 - Batch
----------------
'
  az vm create -g $rgName -n $vmName -l $region --size $vmSize \
    --admin-username $adminID --admin-password $adminPwd \
    --image $vmImage --os-disk-name $osDiskName \
    $linuxOnly \
    --public-ip-address-allocation $ipAllocationMethod \
    --no-wait

  echo "Deployment submitted for the vm, $vmName ..."
:'
--------------------
METHOD 2 - REAL-TIME
--------------------

  echo "Creating the vm, $vmName now..."
  pubIP=$(
    az vm create -g $rgName -n $vmName -l $region --size $vmSize \
      --admin-username $adminID --admin-password $adminPwd \
      --image $vmImage --os-disk-name $osDiskName \
      $linuxOnly \
      --public-ip-address-allocation $ipAllocationMethod \
      --query publicIpAddress \
      --verbose \
      -o tsv

      # If to create and attach two 4 GB data disks during vm creation
      # --data-disk-sizes-gb 4 4 \

  )
  #az vm show -d -g $rgName -n $vmName -o table
  echo  "
  --------------------------------------------------------------------------------------
  Voilà! The VM, $vmName, has been deployed with the $ipAllocationMethod public IP, $pubIP
  --------------------------------------------------------------------------------------
  "
'
done

:' Check vm provisioning state
az vm list -g $rgName -d -o table
az vm list -g $rgName --query [].provisioningState -o tsv

# if 3 items (e.g. vm + 2 data disks) to be provisions
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


################################################

:' Names given
rgName=''
vmName=''
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
