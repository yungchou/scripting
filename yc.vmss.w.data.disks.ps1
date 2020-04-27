# vmss with data disks
# https://docs.microsoft.com/en-us/azure/virtual-machine-scale-sets/scripts/cli-sample-create-simple-scale-set?toc=/cli/azure/toc.json#sample-script

# Session Start
az login
az account list -o table

# CUSTOMIZATION
initial='yc'

# Session Tag
tag=$initial$(date +%M%S)

rgName=$tag"rg"
region='southcentralus'

vmssName=$tag"vmss"
adminID='alice'

uImage='ubuntults'
#w16Image='win2016datacenter'
#w19Image='win2019datacenter'
vmSize='Standard_B2ms'

az group create -n $rgName --location $region

az vmss create \
-g $rgName \
-n $vmssName \
-l $region \
--app-gateway $vmss"-gateway" \
--backend-pool-name $vmss"-be-pool" \
--image $uImage \
--authentication-type All \
--generate-ssh-keys \
--vm-sku $vmSize \
--admin-username $adminID \
--data-disk-sizes-gb 4 4 \
--instance-count 5 \ # default 2
--disable-overprovision $true \
--eviction-policy Delete \
--upgrade-policy Automatic \
--scale-in-policy OldestVM \
-o table

# --customer-data cloud_init.yaml
# --validate
# --no-wait

az group delete -n $rgName --no-wait --yes 