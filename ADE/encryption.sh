:'
Azure Disk Encryption, i.e. encryptions at rest, 
https://docs.microsoft.com/en-us/azure/security/fundamentals/encryption-atrest, 
uses a key hierarchy made up of the types of keys:

Data Encryption Key (DEK)

- A symmetric AES256 key used to encrypt a partition or block of data. 
  A single resource may have many partitions and many Data Encryption Keys. 
  Encrypting each block of data with a different key makes crypto 
  analysis attacks more difficult. 

- Access to DEKs is needed by the resource provider or application instance 
  that is encrypting and decrypting a specific block. When a DEK is replaced 
  with a new key only the data in its associated block must be re-encrypted 
  with the new key.

Key Encryption Key (KEK)

- An encryption key used to encrypt the Data Encryption Keys. 
  Using a Key Encryption Key which never leaves Key Vault allows the 
  data encryption keys themselves to be encrypted and controlled.

- The entity that has access to the KEK may be different from the entity 
  that requires the DEK. An entity may broker access to the DEK to 
  limit the access of each DEK to a specific partition. Since the KEK 
  is required to decrypt the DEKs, the KEK is effectively a single point 
  by which DEKs can be effectively deleted by deletion of the KEK.

- The Data Encryption Keys, encrypted with the Key Encryption Keys are 
  stored separately and only an entity with access to the Key Encryption Key 
  can decrypt these Data Encryption Keys.

[Client Encryption model]
Encryption performed outside of Azure 
E.g. by a service or calling an application.

[Server-Side Encryption, or SSE] 
Encryption performed by Azure
Namely the Resource Provider performs the encrypt and the decrypt operations.

Azure Disk Encryption for virtual machines and virtual machine scale sets
https://docs.microsoft.com/en-us/azure/security/fundamentals/azure-disk-encryption-vms-vmss

- Your key vault and VMs must be in the same subscription. 

- To ensure that encryption secrets do not cross regional boundaries, 
  Azure Disk Encryption requires the Key Vault and the VMs to be co-located 
  in the same region. Create and use a Key Vault that is in the same subscription 
  and region as the VMs to be encrypted.
'

az login
az account list -o table

# CUSTOMIZATION
initial='da'

region='southcentralus'

imageName='ubuntults'
#imageNaME='win2016datacenter'
:'
# Looking for Gen2 image
az vm image list -l $region -o table

# URN
Canonical:UbuntuServer:18.04-LTS:latest
MicrosoftWindowsServer:WindowsServer:2019-Datacenter:latest 

az vm image list --publisher Canonical --sku gen2 --output table --all
az vm image list --publisher Windows --sku gen2 --output table --all
az vm image list --publisher SQL --sku gen2 --output table --all
'

vmSize='Standard_B2ms'
#vmSize='Standard_D2s_v3'

adminId='alice'

# Session Tag
tag=$(date +%M%S)

# Session ID
ID=$initial$tag

# RESOURCES
rgName=$ID
vmName=$ID'-vm'
dataDiskSize=4
vmssName=$ID'-vmss'
kvName=$ID'-kv'
kekName=$ID'-kek'
storageSku='Standard_LRS'
# Standard_LRS, Premium_LRS, StandardSSD_LRS, UltraSSD_LRS

az group create -n $rgName -l $region -o table
: '
az group delete -n $rgName --no-wait -y
az configure --defaults group=$rgName location=$region
'
################################################################

# Create VM
time \
vmPip=$(
  az vm create -g $rgName -n $vmName -l $region --size $vmSize \
    --image $imageName --generate-ssh-keys --authentication-type all \
    --admin-username $adminId \
    --query publicIpAddress \
    -o tsv
  ); echo "vmPip=$vmPip" 

########################################################

# KEY VAULT
time \
  az keyvault create -g $rgName -n $kvName  -l $region \
    --enable-soft-delete false \
    --enabled-for-deployment true \
    --enabled-for-disk-encryption true \
    --enabled-for-template-deployment true \
    -o table

:'
05/06/2020 
not able to create a key vault with
    --enable-soft-delete false \
'

az keyvault update -g $rgName -n $kvName  \
    --enable-soft-delete false

# KEY ENCRYPTION KEY (KEK)
:'
https://docs.microsoft.com/en-us/azure/virtual-machine-scale-sets/disk-encryption-key-vault#set-up-a-key-encryption-key-kek

- When a key encryption key is specified, Azure Disk Encryption uses 
  that key to wrap the encryption secrets before writing to Key Vault.

- Must generate an RSA key type; Azure Disk Encryption does not yet 
  support using Elliptic Curve keys.

- A key vault KEK URLs must be versioned. 

- Azure Disk Encryption does not support specifying port numbers 
  as part of key vault secrets and KEK URLs.
'
time \
  az keyvault key create -n $kekName --vault-name $kvName --kty RSA

#---------------------------------------
# ENABLING SERVER-SIDE ENCRYPTION ON VM
#---------------------------------------
# SSE-PMK - Service side encryption with platform managed key
time \
  az vm encryption enable -g $rgName -n $vmName \
    --disk-encryption-keyvault $kvName \
    --volume-type ALL \
    --encrypt-format-all \
    -o table

# Enabling KEK for a VM
time \
  az vm encryption enable -g $rgName -n $vmName \
    --disk-encryption-keyvault $kvName \
    --volume-type ALL \
    --encrypt-format-all \
    --key-encryption-key $kekName

# VM encryption status
az vm encryption show -g $rgName -n $vmName -o table

################################################################

#---------------------------------
# CREATING VMSS WITH DATA DISK(S)
#---------------------------------
# Option 1 - Miminal settings
az vmss create -g $rgName -n $vmssName \
  --vm-sku $vmSize --instance-count 2 --storage-sku $storageSku \
  --image $imageName --generate-ssh-keys \
  --data-disk-sizes-gb $dataDiskSize \
  --no-wait

az vmss list -o table

# Option 2 - Custom settings
az vmss create -g $rgName -n $vmssName \
  --vm-sku $vmSize --instance-count 2 --storage-sku $storageSku \
  --image $imageName --generate-ssh-keys \
  --upgrade-policy-mode automatic \
  --computer-name-prefix $ID'-' --os-disk-name 'OS-disk' \
  --data-disk-sizes-gb $dataDiskSize \
  --eviction-policy Delete \
  --upgrade-policy-mode Rolling \
  --app-gateway $ID'-gateway' --backend-pool-name $ID'-bepool' \
  --lb $ID'-lb' ----lb-nat-pool-name $ID'-lbnatpool'\
  --no-wait

:' 
  --admin-username $adminId \

# Not to use managed disk to persist VM.
  --use-unmanaged-disk \
'

az vmss list -o table

################################################################

#--------------------------------------
# CREATING VMSS USING KEY VAULT SECRET
#--------------------------------------
certName=$ID'-cert'

az keyvault certificate create --vault-name $kvName \
  -n $certName -p "$(az keyvault certificate get-default-policy)" \
  -o table

secrets=$(az keyvault secret list-versions --vault-name $kvName \
  -n $certName --query "[?attributes.enabled].id" -o tsv)

vm_secrets=$(az vm secret format -s "$secrets")

time \
  az vmss create -g $rgName -n $vmssName'-new' \
    --vm-sku $vmSize --instance-count 2 --storage-sku $storageSku \
    --image $imageName --generate-ssh-keys \
    --data-disk-sizes-gb $dataDiskSize \
    --secrets "$vm_secrets" 

az vmss show -n $vmssName -g $rgName -o table

#----------------------------------------------------------------
# Prepare the data disk for use with the Custom Script Extension
#----------------------------------------------------------------
az vmss extension set \
  --publisher Microsoft.Azure.Extensions \
  --version 2.0 \
  --name CustomScript \
  -g $rgName --vmss-name $vmssName \
  --settings '{"fileUris":["https://raw.githubusercontent.com/Azure-Samples/compute-automation-configurations/master/prepare_vm_disks.sh"],"commandToExecute":"./prepare_vm_disks.sh"}'

################################################################

#--------------------------------------------
# ENABLING ENCRYPTION ON VM SCALE SET (VMSS)
#--------------------------------------------
# Get the resource ID of the Key Vault
vaultResourceId=$(az keyvault show -g $rgName -n $kvName --query id -o tsv)

# Enable encryption of the data disks in a scale set
time \
  az vmss encryption enable -g $rgName -n $vmssName \
    --disk-encryption-keyvault $vaultResourceId \
    --volume-type DATA \
    -o table \
    --verbose

# If manual upgrade mode, must run the following to propagate the change.
time \
  az vmss update-instances -g $rgName -n $vmssName --instance-ids "*" 

# Query the status use the following statement:
az vmss encryption show -g $rgName -n $vmssName

:'
For Linux VM, it becomes non-accessable during encryption period.
'

:'
The upgrade policy on the scale set created in an earlier step 
is set to automatic, the VM instances automatically start the 
encryption process. 

On scale sets where the upgrade policy is to manual, start the 
encryption policy on the VM instances with az vmss update-instances.
'

# Enable encryption of the data disks in a scale set
time \
  az vmss encryption enable -g $rgName -n $vmssName \
    --disk-encryption-keyvault $kvName \
    --key-encryption-keyvault $vaultResourceId \
    --key-encryption-key $kekName \
    --volume-type DATA \
    -o table \
    --verbose

# If manual upgrade mode, must run the following to propagate the change.
time \
  az vmss update-instances -g $rgName -n $vmssName --instance-ids "*" 

# Query the status use the following statement:
az vmss encryption show -g $rgName -n $vmssName

# Disabling encryption
az vmss encryption disable -g $rgName -n $vmssName \
  --force -no-wait
#  --volume-type DATA \
