:'
https://docs.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage

If you have an existing VHD that was created using a paid Azure Marketplace image, you might need to supply the purchase plan information when you create a new VM from that VHD.
'
rgName='myRG'
vmName='myVM'

# Purchase plan info of an exisitng VM
az vm get-instance-view -g $rgName -n $vmName --query plan

# offline list
az vm image list -o table

# up-to-date list ith --all, here shown with partial strings for filtering 
az vm image list -o table --all \
  --publisher openlogic 
  --sku 6.5 \
  --offer hpc

;'
Find an image in a location is to run the 
az vm image list-publishers
az vm image list-offers
az vm image list-skus 
'
