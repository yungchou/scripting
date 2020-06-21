:'
Azure Disk Encryption sample scripts
https://docs.microsoft.com/en-us/azure/virtual-machines/linux/disk-encryption-sample-

Quickstart: Create and encrypt a Windows VM with the Azure CLI
https://docs.microsoft.com/en-us/azure/virtual-machines/windows/disk-encryption-cli-quickstart

Enable encryption on a running Windows VM without AAD
https://azure.microsoft.com/en-us/resources/templates/201-encrypt-running-windows-vm-without-aad/

Azure Disk Encryption only encrypts mounted volumes and provides end-to-end encryption for the OS disk, data disks, and the temporary disk with a customer-managed key.

You can encrypt both boot and data volumes, but you can not encrypt the data without first encrypting the OS volumes.

To add a key encryption key, call the enable command again passing the key encryption key parameter.
To remove a key encryption key, call the enable command again without the key encryption key parameter.

If the need is Encryption at rest, use SSE+CMK to encrypt the disk.
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

