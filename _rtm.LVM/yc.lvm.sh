:' 
Title: Azure, Ubuntu, and LVM on Encrypted Disks

Yung Chou � 2019

@yungchou
https://yungchou.wordpress.com
https://www.linkedin.com/in/yungchou/

This article documents the logical steps with step-by-step
operations for configuring LVM on encrypted disks of an 
Azure Ubuntu VM.

My intent is to provide maximal clarity on the how-to 
with the following Azure CLI and BASH statements, 
while considering little in optimizing and automating 
the process.

Notice that the flow of the steps and operations 
involves switching context between 

- a remote shell session to the Azure subscription 
- an ssh session to the deployed Azure Ubuntu VM

To follow the steps and execute the operations, first 
start a BASH shell session, log into Azure and set a 
subscription context, as applicable. Then simply 
populate the customization section with intended 
values, copy and paste selected statements into the 
Azure remote shell or an ssh session to the deployed 
Azure Ubuntu VM for execution, as directed.

STEP
0. LOG IN AZURE WITH A REMOTE SHELL SESSION
1. CUSTOMIZE SETTINGS
2. CREATE A RESOURCE GROUP FOR ALL RESOURCES
3. DEPLOY A VM FOR HOSTING LVM
4. ATTACH DATA DISKS 
5. ADD A KEY VAULT AND A KEY FOR ENCRYPTION

6. SSH INTO THE DEPLOYED VM,
   FORMAT AND MOUNT THE DATA DISKS,
   THEN EXIT AND BACK TO AZURE SESSION

7. BACK TO AZURE,
   ENABLE VM ENCRYPTION WITH KEK

8. SSH INTO THE DEPLOYED VM,
   CONFIGURE LVM, AND
   REBOOT THE VM

9. SSH INTO THE DEPLOYED VM UPON RESTART AND
   VERIFY LVM CONFIGURATION AND MOUNT POINT

X. OPTIONALLY CLEAN UP THE DEPLOYED RESOURCES

'
#---------------------------------------------
# 0. LOG IN AZURE WITH A REMOTE SHELL SESSION
#---------------------------------------------
az login -o table

# If multiple subscriptions, identifying an intended subscription
az account list -o table
# Then set the context
az account set --subscription 'subscription_name_or_id'

#-----------------------
# 1. CUSTOMIZE SETTINGS
#-----------------------
id=$(date +"%M%S") # Session ID

# Deploy a VM for hosting a LVM
rgName=da$id
vmName=da$id

sku='UbuntuLTS'  # Azure image sku, e.g. win2016datacenter
location='southcentralus'  # Azure region

# Listing VM sizes available in the Azure region
# az vm list-sizes -l $location | more

vmSize='Standard_B2ms'  # For configuring LVM, at least 8 GB RAM

diskSize=5    # GB
numOfDisks=3  # LUN {0...numOfdisks-1}
diskNamePrefix="disk$id-"

user='testing'
pwd='Notforproduction!'

kvName="kv$id"
keyName="key$id"
volType='DATA'      # Encrypting only data disks

#----------------------------------------------
# 2. CREATE A RESOURCE GROUP FOR ALL RESOURCES
#----------------------------------------------
az group create --name $rgName --location $location -o table
alias cleanup="az group delete -g $rgName --yes -y --no-wait"
echo "----> To delete the deplyed resource group, $rgName, type 'cleanup' "

#--------------------------------
# 3. DEPLOY A VM FOR HOSTING LVM
#--------------------------------
az vm create \
    -g $rgName \
    -n $vmName \
    --image $sku \
    --size $vmSize \
    --admin-username $user \
    --admin-password $pwd \
    --verbose; \
az vm get-instance-view -g $rgName -n $vmName  -o table
#az vm list -g $rgName -d -o table

# VM Public IP
pubip=$(az vm show -d -g $rgName -n $vmName --query publicIps -o tsv)

#az vm open-port --port 80 --resource-group $rgName --name $vmName

#----------------------
# 4. ATTACH DATA DISKS 
#----------------------
let n=$numOfDisks-1

for lun in $(seq 0 $n)
do
az vm disk attach \
   --vm-name $vmName \
   -g $rgName \
   -n $diskNamePrefix$diskSize$lun \
   --size-gb $diskSize \
   --new \
   --verbose
done; \
az disk list -g $rgName -o table

#---------------------------------------------
# 5. ADD A KEY VAULT AND A KEY FOR ENCRYPTION
#---------------------------------------------
az keyvault create \
  -g $rgName \
  -n $kvName \
  --location $location \
  --enabled-for-disk-encryption \
  -o table \
  --verbose

az keyvault key create \
  --vault-name $kvName \
  --name $keyName \
  --ops decrypt encrypt sign unwrapKey verify wrapKey \
  --verbose
  
az keyvault key list --vault-name $kvName -o table

#----------------------------------------
# 6. SSH INTO THE DEPLOYED VM,
#    FORMAT AND MOUNT THE DATA DISKS,
#    THEN EXIT AND BACK TO AZURE SESSION
#----------------------------------------
user_at_ip=$user@$pubip

#-----------------------------------------
# Now ssh to the VM, format and mount the 
# disks before enabling encryption.
#-----------------------------------------
ssh $user_at_ip
clear
sudo su -

# No such file, if disks not added to the VM in Azure
ls -l /dev/disk/azure/scsi1/lun*
dmesg | grep SCSI

# Here, assuming disks already added in Azure portal as LUN {0...x}
echo "y" | mkfs.ext4 /dev/disk/azure/scsi1/lun0
echo "y" | mkfs.ext4 /dev/disk/azure/scsi1/lun1
echo "y" | mkfs.ext4 /dev/disk/azure/scsi1/lun2

lsblk -f # FSTYPE and UUID populated

UUID0="$(blkid -s UUID -o value /dev/disk/azure/scsi1/lun0)"
UUID1="$(blkid -s UUID -o value /dev/disk/azure/scsi1/lun1)"
UUID2="$(blkid -s UUID -o value /dev/disk/azure/scsi1/lun2)"

mkdir /lun-0  # mount point for lun0
mkdir /lun-1  # moutn point for lun1
mkdir /lun-2  # moutn point for lun2

echo "UUID=$UUID0 /lun-0 ext4 defaults,nofail 0 0" >>/etc/fstab
echo "UUID=$UUID1 /lun-1 ext4 defaults,nofail 0 0" >>/etc/fstab
echo "UUID=$UUID2 /lun-2 ext4 defaults,nofail 0 0" >>/etc/fstab

more /etc/fstab | grep lun* 

mount -a      # Making sure disks mounted without issue
df -h /lun*   # Examining the mount point of each disk

exit  # exiting sudo
exit  # clsoing ssh and back to Azure remote shell session

#----------------------------------------
# 7. BACK TO AZURE,
#    ENABLE VM ENCRYPTION WITH KEK
#
#    The data disks to be encrypted must 
#    be mounted at this time in the VM.
#----------------------------------------
vaultResourceId=$(az keyvault show -g $rgName -n $kvName --query id -o tsv)

# The encryption may take a few minutes.
az vm encryption enable \
  -n $vmName \
  -g $rgName \
  --disk-encryption-keyvault $vaultResourceId \
  --key-encryption-keyvault $vaultResourceId \
  --key-encryption-key $keyName \
  --volume-type $volType \
  --encrypt-format-all \
  --verbose 

az vm encryption show \
  -g $rgName \
  -n $vmName \
  --query '[status,substatus]'

#------------------------------
# 8. SSH INTO THE DEPLOYED VM,
#   CONFIGURE LVM, AND
#   REBOOT THE VM
#------------------------------
ssh $user_at_ip
sudo su -

df -h /lun*

umount /lun-0  
umount /lun-1
umount /lun-2

fdisk -l | grep mapper
more /etc/crypttab  # Identifying the mapping

#----------------------------------------------
# Update the following mapping before creating
# physical volumes and volume group
#----------------------------------------------
echo "y" | pvcreate /dev/mapper/???...???
echo "y" | pvcreate /dev/mapper/???...???
echo "y" | pvcreate /dev/mapper/???...???

volGroup="vg$id"
vgcreate $volGroup \
  /dev/mapper/???...??? \
  /dev/mapper/???...??? \
  /dev/mapper/???...???

vgdisplay -v $volGroup

logicalVol='stripes3'
lvcreate --extents 100%FREE --stripes 3 -n $logicalVol $volGroup
echo "yes" | mkfs.ext4 /dev/$volGroup/$logicalVol

lvdisplay -a -m

mount -a
df -h /lun*

reboot

#----------------------------------------------
# 9. SSH INTO THE DEPLOYED VM UPON RESTRAT AND
#   VERIFY LVM CONFIGURATION AND MOUNT POINT
#----------------------------------------------
ssh $user_at_ip
sudo su -

lsblk -f
more /etc/fstab | grep mapper

# If all has gone well, LVM is up and running at this time.
vgdisplay -v $volGroup

exit # form sudo su -
exit # from the VM

#-----------------------------------------------
# X. OPTIONALLY CLEAN UP THE DEPLOYED RESOURCES
#-----------------------------------------------
az group delete -g $rgName --yes -y --no-wait
az logout
