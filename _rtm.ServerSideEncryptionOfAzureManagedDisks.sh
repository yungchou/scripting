:'
Server-Side Encryption of Azure-Managed Disks
https://docs.microsoft.com/en-us/azure/virtual-machines/linux/disk-encryption

Data in Azure managed disks is encrypted transparently using 256-bit AES encryption and is FIPS 140-2 compliant. Encryption does not impact the performance of managed disks. 

PLATFORM-MANAGED KEYS (PMK)
By default, managed disks use platform-managed encryption keys. All new managed disks, snapshots, images, and new data written to existing managed disks are automatically encrypted-at-rest with platform-managed keys.

CUSTOMER-MANAGED KEYS (CMK)
It encrypts data using an AES 256 based data encryption key (DEK), which is, in turn, protected using your keys. The Storage service generates data encryption keys and encrypts them with customer-managed keys using RSA encryption. The envelope encryption allows you to rotate (change) your keys periodically as per your compliance policies without impacting your VMs. When you rotate your keys, the Storage service re-encrypts the data encryption keys with the new customer-managed keys.

Using CMK has the following restrictions:

- If this feature is enabled for your disk, you cannot disable it. If you need to work around this, you must copy all the data to an entirely different managed disk that is not using customer-managed keys.

- Only "soft" and "hard" RSA keys of size 2048 are supported, no other keys or sizes.

- Disks created from custom images that are encrypted using server-side encryption and customer-managed keys must be encrypted using the same customer-managed keys and must be in the same subscription.

- Snapshots created from disks that are encrypted with server-side encryption and customer-managed keys must be encrypted with the same customer-managed keys.

- All resources related to your customer-managed keys (Azure Key Vaults, disk encryption sets, VMs, disks, and snapshots) must be in the same subscription and region.

- Disks, snapshots, and images encrypted with customer-managed keys cannot move to another subscription.

- If you use the Azure portal to create your disk encryption set, you cannot use snapshots for now.

- Managed disks encrypted using customer-managed keys cannot also be encrypted with Azure Disk Encryption.

- For information about using customer-managed keys with shared image galleries, see Preview: Use customer-managed keys for encrypting images.

When you configure customer-managed keys, a managed identity is automatically assigned to your resources under the covers. If you subsequently move the subscription, resource group, or managed disk from one Azure AD directory to another, the managed identity associated with managed disks is not transferred to the new tenant, so customer-managed keys may no longer work.
'

az login -o table
az account list -o table

subscriptionId='Visual Studio Enterprise'
az account set --subscription $subscriptionId

# CUSTOMIZATION
initial='da'

region='southcentralus'
imageName='ubuntults'
vmSize='Standard_B2ms'
adminId='alice'
diskSku='Premium_LRS'

################################################################

# Session Tag
tag=$(date +%M%S)

# Session ID
ID=$initial$tag

# RESOURCES
rgName=$ID
vmName=$ID'-vm'
vmssName=$ID'-vmss'
kvName=$ID'-kv'
keyName=$ID'-key'
kekName=$ID'-kek'
sizeGb=4
desName=$ID'-des' # disk encryption set
storageSku='Standard_LRS' # Standard_LRS, Premium_LRS, StandardSSD_LRS, UltraSSD_LRS

az group create -n $rgName -l $location -o table
:'
az group delete -n $rgName --no-wait -y
az configure --defaults group=$rgName location=$region
'
################################################################

:'When creating the Key Vault instance, you must enable soft delete and purge protection.'
time \
az keyvault create -n $kvName -g $rgName -l $region \
  --enable-purge-protection true --enable-soft-delete true

az keyvault key create --vault-name $kvName -n $keyName --protection software

:'Create an instance of a DiskEncryptionSet.'
kvId=$(az keyvault show -n $kvName --query [id] -o tsv)
kvKeyUrl=$(az keyvault key show --vault-name $kvName -n $keyName --query [key.kid] -o tsv)

time \
az disk-encryption-set create -n $desName -l $region -g $rgName -o table \
  --source-vault $kvId --key-url $kvKeyUrl

:'Grant the DiskEncryptionSet resource access to the key vault.'
desIdentity=$(az disk-encryption-set show -n $desName -g $rgName --query [identity.principalId] -o tsv)

az keyvault set-policy -n $kvName -g $rgName \
  --object-id $desIdentity --key-permissions wrapkey unwrapkey get

az role assignment create --assignee $desIdentity --role Reader --scope $kvId

:'Create a VM using a Marketplace image, encrypting the OS and data disks with customer-managed keys'
diskEncryptionSetId=$(az disk-encryption-set show -n $desName -g $rgName --query [id] -o tsv)

time \
az vm create -g $rgName -n $vmName -l $region -o table \
  --image $imageName --size $vmSize --generate-ssh-keys \
  --os-disk-encryption-set $diskEncryptionSetId \
  --data-disk-sizes-gb $sizeGb $sizeGb \
  --data-disk-encryption-sets $diskEncryptionSetId $diskEncryptionSetId

# az vm show -g $rgName -n $vmName -d -o table 

:'Encrypt existing managed disks which must not be attached to a running VM

az disk update -n <disk name> -g $rgName \
  --encryption-type EncryptionAtRestWithCustomerKey \
  --disk-encryption-set $diskEncryptionSetId \
  -o table
'

:'Create a virtual machine scale set using a Marketplace image, encrypting the OS and data disks with customer-managed keys'
diskEncryptionSetId=$(az disk-encryption-set show -n $desName -g $rgName --query [id] -o tsv)

az vmss create -g $rgName -n $vmssName -o table \
  --image $imageName  --generate-ssh-keys \
  --upgrade-policy automatic \
  --admin-username $adminId \
  --os-disk-encryption-set $diskEncryptionSetId \
  --data-disk-sizes-gb $sizeGb $sizeGb \
  --data-disk-encryption-sets $diskEncryptionSetId $diskEncryptionSetId

# az vmss show -g $rgName -n $vmssName -d -o table

:'Create an empty disk encrypted using server-side encryption with customer-managed keys and attach it to a VM'

diskName=$ID'-disk'
desId=$(az disk-encryption-set show -n $desName -g $rgName --query [id] -o tsv)

:'
EncryptionAtRestWithPlatformKey: Default encrypted with XStore managed key at rest. 
EncryptionAtRestWithCustomerKey: Disk is encrypted with Customer managed key at rest.
'
az disk create -n $diskName -g $rgName -l $region -o table \
  --encryption-type EncryptionAtRestWithCustomerKey \
  --disk-encryption-set $desId \
  --size-gb $sizeGb \
  --sku $diskSku

diskId=$(az disk show -n $diskName -g $rgName --query [id] -o tsv)

diskLUN=2
az vm disk attach --vm-name $vmName --lun $diskLUN --ids $diskId

:'Change the key of a DiskEncryptionSet to rotate the key for all the resources referencing the DiskEncryptionSet'

kvId=$(az keyvault show --name $kvName --query [id] -o tsv)
kvKeyUrl=$(az keyvault key show --vault-name $kvName --name $keyName --query [key.kid] -o tsv)

az disk-encryption-set update -n $desName -g $rgName -o table \
  --key-url $kvKeyUrl --source-vault $kvId

:'Find the status of server-side encryption of a disk'
az disk show -g $rgName -n $diskName -o table \
  --query "{Name:name,resoureGroup:resourceGroup,Location:region,Sku:sku.name,DiskSizeGb:diskSizeGb,Encryption:encryption.type,Provisioning:provisioningState,DiskState:diskState}"

az disk list -g $rgName -o table \
  --query "[?name=='$diskName'].{Name:name,resoureGroup:resourceGroup,Location:region,Sku:sku.name,DiskSizeGb:diskSizeGb,Encryption:encryption.type,Provisioning:provisioningState,DiskState:diskState}"