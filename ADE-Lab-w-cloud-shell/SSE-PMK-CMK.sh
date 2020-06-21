:'
Server-side encryption of Azure managed disks
https://docs.microsoft.com/en-us/azure/virtual-machines/linux/disk-encryption

customer-managed keys have the following restrictions:

If this feature is enabled for your disk, you cannot disable it. If you need to work around this, you must copy all the data to an entirely different managed disk that is not using customer-managed keys.

Only "soft" and "hard" RSA keys of size 2048 are supported, no other keys or sizes.

Disks created from custom images that are encrypted using server-side encryption and customer-managed keys must be encrypted using the same customer-managed keys and must be in the same subscription.

Snapshots created from disks that are encrypted with server-side encryption and customer-managed keys must be encrypted with the same customer-managed keys.

All resources related to your customer-managed keys (Azure Key Vaults, disk encryption sets, VMs, disks, and snapshots) must be in the same subscription and region.

Disks, snapshots, and images encrypted with customer-managed keys cannot move to another subscription.
If you use the Azure portal to create your disk encryption set, you cannot use snapshots for now.

Managed disks encrypted using customer-managed keys cannot also be encrypted with Azure Disk Encryption.

For information about using customer-managed keys with shared image galleries, see Preview: Use customer-managed keys for encrypting images.
'

az login
az account list -o table

:'
=============
CUSTOMIZATION
=============
'
prefix='da'
adminID='alice'
region='southcentralus'

#vmImage='ubuntults'
vmImage='win2016datacenter'
#vmImage='win2019datacenter'

vmSize='Standard_B2ms' 
#vmSize='Standard_DS3_V2'

:'
================================
STANDARDIZED ROUTINE STARTS HERE
================================
'
# Session Tag
tag=$prefix$(date +%M%S)

# Resource Group
rgName=$tag
az group create -n $rgName -l $region -o table
: '
az group delete -n $rgName --no-wait -y
az configure --defaults group=$rgName
'
#-----------------------------------------------------------------------------------
# 1. Deploy a vm with minimal settins and the admin password interactively provided
#-----------------------------------------------------------------------------------
vmName=$tag"-sse-pmk"
vmPip=$(
  az vm create -g $rgName -n $vmName -l $region --query publicIpAddress -o tsv \
    --image $vmImage --size $vmSize --os-disk-name $vmName'-OS-Disk' \
    --public-ip-address $vmName'-pip' --public-ip-address-allocation Static \
    --admin-username $adminID
    # if adding data disk
    #--data-disk-sizes-gb 128 128
    # For linux vm
    #--generate-ssh-keys --authentication-type all \
  ); echo "vmPip=$vmPip" 

#az vm show -g $rgName -n $vmName -o table -d

#--------------------------------------------
# 2. Create and attach a data disk to the vm
#--------------------------------------------
diskName=$vmName'-dd'
diskSizeInGB=4         # using smallest disk for testing
diskSku=Standard_LRS   # Premium_LRS

az vm disk attach -g $rgName --vm-name $vmName -n $diskName -o table \
  --size-gb $diskSizeInGB \
  --sku $diskSku \
  --new 

az disk show -g $rgName -n $diskName -o table

# Key Vault
kvName=$tag'-kv'
sseKeyName=$tag'-sse-key'

az keyvault create -n $kvName -g $rgName -l $region -o table \
  --enabled-for-disk-encryption true \
  --enabled-for-deployment true \
  --enabled-for-template-deployment true \
  --sku standard  # premium, standard (default)

az keyvault key create --vault-name $kvName -n $sseKeyName --ops wrapKey unwrapKey
az keyvault key show   --vault-name $kvName -n $sseKeyName

#---------------------------------------
# Create Disk Encryption Set with a CMK
#---------------------------------------
desName=$rgName'-des'
#kvId=$(az keyvault show -g $rgName -n $kvName --query [id] -o tsv)
keyUrl=$(az keyvault key show --vault-name $kvName -n $sseKeyName --query [key.kid] -o tsv)

az disk-encryption-set create -g $rgName -n $desName -l $region -o table \
  --source-vault $kvName --key-url $keyUrl  # the CMK
# !!!
# Once DES is created, got to DES blade in portal and manually grant permission to the keyvault.

#desId=$(az disk-encryption-set show -n $destName -g $rgName --query [id] -o tsv)

#-----------------------------------------------
# Create a VM using a Marketplace image and
# encrypting the OS and data disks with the CMK
# ----------------------------------------------
vmName=$tag'-sse-cmk'
vmPip=$(
  az vm create -g $rgName -n $vmName -l $region --query publicIpAddress -o tsv \
    --image $vmImage --size $vmSize \
    --os-disk-name $vmName'-OS-disk' --os-disk-encryption-set $desName \
    --public-ip-address $vmName'-pip' --public-ip-address-allocation Static \
    --admin-username $adminID \
    --data-disk-sizes-gb 4 4 \
    --data-disk-encryption-sets $desName $desName 
    # Here attaching 2 data disks to demo each can use an individual des', 
    # For linux vm
    #--generate-ssh-keys --authentication-type all \
  ); echo "vmPip=$vmPip" 

#az vm show -g $rgName -n $vmName -o table -d


# RTM TO ABOVE 


:'=====================================================================
# ISSUE to detach disk, get the following error when save the changes

Failed to update disks for the virtual machine 'da2100-ssepmk'. Error: Policy required full resource content to evaluate the request. The request to GET resource 'https://management.azure.comda2100-ssepmk?api-version=2020-05-01' failed with status 'BadRequest'.
'


#------------------------------------
# Encryt an existing disk with a CMK
#------------------------------------
az disk list -g $rgName -o table
diskName='??'
# Must first deattach the disk, as applicable.
az disk update -n $diskName -g $rgName \
  --encryption-type EncryptionAtRestWithCustomerKey \
  --disk-encryption-set $desName

#------------------------------------------
# Creat an empty disk encrypted with a CMK
#------------------------------------------
diskName=$head'disk-'$(date +%S)
az disk create -n $diskName -g $rg -l $loc \
  --encryption-type EncryptionAtRestWithCustomerKey \
  --disk-encryption-set $desName \
  --size-gb 4 \
  --sku Standard_LRS              
  # StandardSSD_LRS, Standard_LRS, UltraSSD_LRS, Premium_LRS (default)

#diskId=$(az disk show -n $diskName -g $rgName --query [id] -o tsv)
az vm disk attach --vm-name $vm -n $diskName -o table
