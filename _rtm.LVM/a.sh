#---------------------------------------------
# 0. LOG IN AZURE WITH A REMOTE SHELL SESSION
#---------------------------------------------
az login -o table

# If multiple subscriptions, identifying an intended subscription
#az account list -o table
# Then set the context
#az account set --subscription 'subscription_name_or_id'

#-----------------------
# 1. CUSTOMIZE SETTINGS
#-----------------------
id=$(date +"%M%S") # Session ID

# Deploy a VM for hosting a LVM
rgName=da$id
vmNamePrefix=$rgName
numOfVMs=2
openPort='8888'

sku='UbuntuLTS'  # Azure image sku, e.g. win2016datacenter
location='westeurope'  # Azure region

# Listing VM sizes available in the Azure region
# az vm list-sizes -l $location | more

vmSize='Standard_F4s'  # For configuring LVM, at least 8 GB RAM

user='testing'
pwd='Notforproduction!'

#----------------------------------------------
# 2. CREATE A RESOURCE GROUP FOR ALL RESOURCES
#----------------------------------------------
az group create --name $rgName --location $location -o table
alias cleanup="az group delete -g $rgName --yes -y --no-wait"
echo "----> To delete the deplyed resource group, $rgName, type 'cleanup' "

#--------------------------------
# 3. DEPLOY A VM FOR HOSTING LVM
#--------------------------------
for index in $(seq 1 $numOfVMs)
do
  vmName=$vmNamePrefix-$index
  az vm create \
      -g $rgName \
      -n $vmName \
      --image $sku \
      --size $vmSize \
      --admin-username $user \
      --admin-password $pwd \
      -o none ; \
  az vm open-port -g $rgName -n $vmName --port $openPort --priority 410 -o none ; \
  az vm get-instance-view -g $rgName -n $vmName  -o table

  # VM Public IP
  pubip=$(az vm show -d -g $rgName -n $vmName --query publicIps -o tsv)
  alias ssh$index="ssh $user@$pubip"
  echo "----> To access the vm, $vmName, type ""ssh$index"" "
done

az vm list -g $rgName -d -o table

echo "----> To delete the deplyed resource group, $rgName, type 'cleanup' "
