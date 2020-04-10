# vmss with data disks

az login

rgNmae='myRG'
vmssName='myVMSS'
region='southcentralus'
image='ubuntults'
mvAdmin='alice'

az group create -n $rgName --location $region

az vmss create \
  -g $rgName \
  -n $vmssName \
  --image $image \
  --admin-username $vmAdmin \
  --upgrade-policy automatic \
  --generate-ssh-keys \
  --data-disk-sizes-gb 5 5

az group delete -n $rgName --no-wait --yes 