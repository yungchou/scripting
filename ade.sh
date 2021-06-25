rgName=''
vmName=''
kvName=''

# Enable encryption on existing or running VMs with the Azure CLI
az vm encryption enable -g $rgName -n $vmName \
  --disk-encryption-keyvault $kvName \
  --volume-type All # All, OS, Data

  
