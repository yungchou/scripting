:'
Azure Disk Encryption for Linux VMs
https://docs.microsoft.com/en-us/azure/virtual-machines/linux/disk-encryption-overview

Quickstart: Create and encrypt a Windows VM with the Azure CLI
https://docs.microsoft.com/en-us/azure/virtual-machines/linux/disk-encryption-cli-quickstart

Quickstart: Create and encrypt a Linux VM with the Azure CLI
https://docs.microsoft.com/en-us/azure/virtual-machines/windows/disk-encryption-cli-quickstart

Enable encryption on a running Windows VM without AAD
https://azure.microsoft.com/en-us/resources/templates/201-encrypt-running-windows-vm-without-aad/

Creating and configuring a key vault for Azure Disk Encryption
https://docs.microsoft.com/en-us/azure/virtual-machines/linux/disk-encryption-key-vault

Azure Disk Encryption only encrypts mounted volumes and provides end-to-end encryption for the OS disk, data disks, and the temporary disk with a customer-managed key.

You can encrypt both boot and data volumes, but you can not encrypt the data without first encrypting the OS volumes.

To add a key encryption key, call the enable command again passing the key encryption key parameter.
To remove a key encryption key, call the enable command again without the key encryption key parameter.

If the need is encryption-at-rest, use SSE+CMK to encrypt the disk.
If the need is end-to-end encryption, use ADE (BEK or KEK|BEK) which encrypts the OS drive.


'
#-----
# BEK
#-----
az vm encryption enable -g $rgName -n $vmName -o table \
  --disk-encryption-keyvault $kvName \
  --volume-type OS   # OS, DAT, ALL
az vm show -name $vmName -g $rgName -o table

#---------
# KEK|BEK
#---------
# Set up a key encryption key (KEK)
kekName=$tag'-kek'
az keyvault key create -n $kekName --vault-name $kvName -o table
az vm encryption enable -g $rgName -n $vmName -o table \
  --disk-encryption-keyvault $kvName \
  --volume-type OS \
  --key-encryption-key $kekName \
  --key-encryption-keyvault $kvName  

az vm show -name $vmName -g $rgName -o table

az vmss encryption enable -g MyResourceGroup -n MyVmss --disk-encryption-keyvault MyVault

#az vm encryption show -name $vmName -g $rgName --query encryption.type -o tsv
echo "$(date)
The selected disk, $thisDisk, is now with the encryption type, $(
  az disk show -g $rgName -n $thisDisk --query encryption.type
)"



#--------------------------------------------------
# 2.6 Create a Marketplace VM with a data disk and
#     with the encryption type, SSE+CMK, deployed
#     to a vmss
#--------------------------------------------------
vmssName=$tag"vmss"
adminID='alice'

az vmss create -g $rgName -n $vmssName -l $region \
--priority Spot \
--vm-sku 'Standard_DS1_v2' \
--app-gateway $vmssName"-gateway" --backend-pool-name $vmssName"-be-pool" \
--image $vmImage --vm-sku $vmSize --instance-count 2 \
--data-disk-sizes-gb 4 \
--admin-username $adminID \
--disable-overprovision $true \
--eviction-policy Delete \
--upgrade-policy Automatic \
--scale-in-policy OldestVM \
--os-disk-encryption-set $desName \
--no-wait
#--authentication-type All --generate-ssh-keys \
#--customer-data cloud_init.yaml
#--validate


vmName=$tag'-sse-cmk'

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
 

#az vm show -g $rgName -n $vmName -o table -d


# RTM TO ABOVE 

:'=====================================================================
# ISSUE to detach disk, get the following error when save the changes

Failed to update disks for the virtual machine 'da2100-ssepmk'. Error: Policy required full resource content to evaluate the request. The request to GET resource 'https://management.azure.comda2100-ssepmk?api-version=2020-05-01' failed with status 'BadRequest'.
'


