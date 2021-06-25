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
#---------------
# Customization
#---------------
$prefix='da'
tag=$prefix$(date +%M%S)
tag=ADE
region='southcentralus'

#------------------
# Standard Routine
#------------------
rgName=$tag'-ssecmk'
kvName=$rgName'-kv'

az keyvault create -n $kvName -g $rgName -l $region -o table \
  --enabled-for-disk-encryption true \
  --enabled-for-deployment true \
  --enabled-for-template-deployment true \
  --sku stndard  # premium, standard (default)

az keyvault key create --vault-name $kvName -n $tag'-sse-key' -o table \
  --kty RSA-HSM \
  --ops decrypt encrypt import sign unwrapKey verify wrapKey

#---------------------------------------
# Create Disk Encryption Set with a CMK
#---------------------------------------
desName=$rgName'-des'
kvId=$(az keyvault show -n $kvName --query [id] -o tsv)
keyUrl=$(az keyvault key show --vault-name $kvName -n $sseKeyName --query [key.kid] -o tsv)

az disk-encryption-set create -g $rgName -n $desName -l $region -o table \
  --source-vault $kvId --key-url $keyUrl  # the CMK

#-----------------------------------------------
# Create a VM using a Marketplace image and
# encrypting the OS and data disks with the CMK
# ----------------------------------------------
head='da-SSECMK'$(date +%M%S)
rg=$head
vm=$head'-vm'
loc='southcentralus'

vmSize='Standard_B2ms' 
#vmSize='Standard_DS3_V2'

#vmImage='ubuntults'
vmImage='win2016datacenter'
#vmImage='win2019datacenter'

#desId=$(az disk-encryption-set show -n $destName -g $rgName --query [id] -o tsv)

vm_Pip=$(
  az vm create -g $rg -n $vm -l $loc --query publicIpAddress -o tsv \
    --image $vm_Image --size $vm_Size \
    --os-disk-name $vm'-OS-disk' --os-disk-size-gb 50 \
    --public-ip-address $vm'-pip' --public-ip-address-allocation Static \
    --admin-username $adminID \
    --data-disk-sizes-gb 4 4 4 \
    --data-disk-encryption-sets $desName $desName
    # Here 2 data disks attached to demo all 3 can use individual des', 
    # while the 4th disk is unencrypted, since not specifying des.
    # For linux vm
    #--generate-ssh-keys --authentication-type all \
  ); echo "vm_Pip=$vm_Pip" 

az vm show -g $rg -n $vm -o table -d

#------------------------------------
# Encryt an existing disk with a CMK
#------------------------------------
az disk list -g $rgName -o table
diskName='???'
#Needed?? az vm stop -g $rg -n $vm -o table
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


